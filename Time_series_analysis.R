library(dplyr)
library(readxl)
library(lubridate)
library(zoo)
library(tseries)
library(dynamac)
library(lmtest)

# INPUT DATA 

data <- read_excel("tsa_test.xlsx")
data$date <- ymd(data$date) 



# DATA TRANSFORMATIONS

## deseasonalizing NCPI and M2
### Function parameters:
#### df - data frame
#### vars - variables in data frame

ds_data <- function(df, vars) {
  
  for (var in vars) {
    
    start_year <- 2014
    start_month <- 1
    
    ts_temp <- ts(df[[var]], start = c(start_year, start_month), frequency = 12)
    
    ts_temp_seas <- stl(ts_temp, s.window = 7) ## applying loess filter
    ts_temp_ds <- ts_temp - ts_temp_seas$time.series[, 1] ## removing seasonal part of data
    
    df[[paste0(var, "_ds")]] <- ts_temp_ds
    
  }
  
  return (df)
}

data <- ds_data(data, c("ncpi_adj", "m2"))

## defining functions for data transformations

transform_data <- function(df, vars) {
  
  for (var in vars) {
    
    df <- df %>%
      
    ### first difference
    mutate(!!paste0("diff_", var) := c(NA, diff(!!sym(var)))) %>%
    
    ### log transform
    mutate(!!paste0("log_", var) := log(!!sym(var))) %>%
      
    ### first difference of log
    mutate(!!paste0("diff_log_", var) := c(NA, diff(log(!!sym(var))))) 
  }
  
  return(df)
}

data <- transform_data(data, c("ncpi", "ncpi_adj", "ncpi_adj_ds", "ir", "er", "m2", "m2_ds", "wr", "gdp"))

## defining function for modified log transform 
### modified log required for the variables inf and inf_adj because inflation can take negative and zero values, so the log funciton cannot be used with them

transform_data_modified_log <- function(df, vars) {
  
  for (var in vars) {
    
    df <- df %>%
      
      ### first difference
      mutate(!!paste0("diff_", var) := c(NA, diff(!!sym(var)))) %>%
      
      ### modified log transform
      mutate(!!paste0("log_", var) := if_else(!!sym(var) == 0, 0,(!!sym(var)/abs(!!sym(var)))*log(abs(!!sym(var))))) %>%
      
      ### first difference of modified log
      mutate(!!paste0("diff_log_", var) := c(NA, diff(if_else(!!sym(var) == 0, 0,(!!sym(var)/abs(!!sym(var)))*log(abs(!!sym(var))))))) 
  }
  
  return(df)
}

data <- transform_data_modified_log(data, c("inf", "inf_adj"))

## removing unnecessary columns
data <- select(data, -ncpi_21, -ncpi_21_adj, -w)



# STATIONARITY TESTS

## Most time series have length n = 120. Some are shorter because of data unavailability. 

### time series available for full period, i.e., till Dec 2023 (n = 120)  
data_dec_2023 <- select(data, -index, -year, -month, -date, 
                        -ncpi, -diff_ncpi, -log_ncpi, -diff_log_ncpi,
                        -inf, -diff_inf, -log_inf, -diff_log_inf, 
                        -wr, -diff_wr, -log_wr, -diff_log_wr)

### time series available till Dec 2022 (n = 108)
data_dec_2022 <- data %>%
  select(ncpi, diff_ncpi, log_ncpi, diff_log_ncpi, 
         inf, diff_inf, log_inf, diff_log_inf) %>%
  slice(1:108)

### time series available till Oct 2022 (n = 106)
data_oct_2022 <- data %>%
  select(wr, diff_wr, log_wr, diff_log_wr) %>%
  slice(1:106)


## Function to convert data frames into time series elements

start_year = 2014

time_series <- function(df) {
  
  ts_list <- lapply(df, function(column) {
    ts(column, start = start_year, frequency = 12)
  }
  )
  
  ts_object <- do.call(merge, lapply(ts_list, zoo))
  
  return(ts_object)
}

### Dec 2023
ts_dec_2023 <- time_series(data_dec_2023)

### Dec 2022
ts_dec_2022 <- time_series(data_dec_2022)

### Oct 2022
ts_oct_2022 <- time_series(data_oct_2022)


## Function to run stationarity tests on each time series variable 
### parameter: ts_object - time series object, i.e., zoo object
stationarity_tests <- function(ts_object) {
  
  results_list <- list()
  
  for(col_name in colnames(ts_object)) {
    
    ts_data <- ts_object[, col_name]
    ts_data <- na.omit(ts_data)
    
    warning_messages <- list()
    
    ## Function to capture warnings if any 
    capture_warnings <- function(expr) {
      
      warnings <- NULL
      result <- withCallingHandlers(
      
          expr,
        
          warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          
          invokeRestart("muffleWarning")
        }
      )
      
      return(list(result = result, warnings = warnings))
    }
    
    ## augmented Dickey-Fuller test with lag order 1
    adf <- capture_warnings(adf.test(ts_data, k= 1)) 
    adf_stat <- adf$result$statistic
    adf_p <- adf$result$p.value
    
    if (length(adf$warnings) > 0) {
      warning_messages <- c(warning_messages, paste("ADF:", adf$warnings))
    }
    
    ## Phillips-Perron test
    pp <- capture_warnings(pp.test(ts_data)) 
    pp_stat <- pp$result$statistic
    pp_p <- pp$result$p.value
    
    if (length(pp$warnings) > 0) {
      warning_messages <- c(warning_messages, paste("PP:", pp$warnings))
    }
    
    ## KPSS test
    kpss <- capture_warnings(kpss.test(ts_data)) 
    kpss_stat <- kpss$result$statistic
    kpss_p <- kpss$result$p.value
    
    if (length(kpss$warnings) > 0) {
      warning_messages <- c(warning_messages, paste("KPSS:", kpss$warnings))
    }
    
    ## star notation 
    ### Edge cases: for p > 0.1, R reports a p-value of 0.1; for p < 0.01, R reports a p-value of 0.01.
    ### To account for these edge cases, the inequality conditions are adjusted accordingly. 
    ### For these cases, R provides a warning message, e.g., for p > 0.1, it reports 'p-value greater than printed p-value'
    ### The warning messages are stored in the results for the edge cases and checked individually before final reporting.
    get_stars <- function(pval) {
      if (pval <= 0.01) return("***")
      if (pval > 0.01 & pval <= 0.05) return("**")
      if (pval > 0.05 & pval < 0.10) return("*")
      return("")
    }
    
    adf_stat_with_stars <- paste0(round(adf_stat, 4), get_stars(adf_p))
    pp_stat_with_stars <- paste0(round(pp_stat, 4), get_stars(pp_p))
    kpss_stat_with_stars <- paste0(round(kpss_stat, 4), get_stars(kpss_p))
    
    results_list[[col_name]] <- c(
      
      ADF = adf_stat_with_stars,
      PP = pp_stat_with_stars,
      KPSS = kpss_stat_with_stars,
      Warnings = ifelse(length(warning_messages) > 0, paste(warning_messages, collapse = "; "), "")
      
    )
  }
  
  results_df <- do.call(rbind, results_list)
  colnames(results_df) <- c("ADF", "PP", "KPSS", "Warning")
  rownames(results_df) <- colnames(ts_object)
  
  return(results_df)
}

stationarity_tests_dec_2023 <- stationarity_tests(ts_dec_2023)
stationarity_tests_dec_2022 <- stationarity_tests(ts_dec_2022)
stationarity_tests_oct_2022 <- stationarity_tests(ts_oct_2022)


# ARDL MODELS

## Function to run ARDL models and store results along with diagnostic tests
### Function parameters explained below:
#### df - data frame 
#### y - dependent variable as string, e.g., "log_ncpi"
#### x - independent variables as vector of strings, e.g., c("log_m2", "log_er")
#### lags - lags of different variables specified as list, e.g., list("log_ncpi" = 1, "log_m2" = 1, "log_er" = 1)
#### diffs - variables of order of integration greater than 0, specified in vector form, e.g., c("log_ncpi", "log_m2", "log_er")
#### ec - error correction; input 1 for TRUE and 0 for FALSE

regression_model <- function(df, y, x, lags = list(), diffs = NULL, ec = 1, simulate = FALSE) {
  
  x <- paste(x, collapse = " + ")
  formula_str <- paste(y, " ~ ", x)
  formula <- as.formula(formula_str)
  
  ec_logical <- as.logical(ec)
  
  model <- dynardl(
    formula, 
    data = df, 
    lags = lags,
    diffs = diffs, 
    ec = ec_logical,
    simulate = FALSE
  )
  
  return(model)
 
}

stats <- function(df, regression_model) {
  
  summary_model <- summary(regression_model)
  
  adjusted_r_squared <- summary_model$adj.r.squared
  f_statistic <- summary_model$fstatistic[1]
  p_value <- pf(f_statistic, summary_model$fstatistic[2], summary_model$fstatistic[3], lower.tail = FALSE)
  n_obs <- nrow(df)
  
  model_stats <- data.frame(
    Statistic = c("Adjusted R-squared", "F-statistic", "p-value", "N"),
    Value = c(adjusted_r_squared, f_statistic, p_value, n_obs)
  )
  
  return(model_stats)
}


## Monetarist models 
M1 <- regression_model(data_dec_2023, "log_ncpi_adj", c("log_m2"), list("log_ncpi_adj" = 1, "log_m2" = 1), c("log_m2"), 1, FALSE)
M1_stats <- stats(data_dec_2023, M1)

M2 <- regression_model(data_dec_2023, "diff_log_ncpi_adj", c("diff_log_m2"), list("diff_log_ncpi_adj" = 1, "diff_log_m2" = 1), NULL, 1, FALSE)
M2_stats <- stats(data_dec_2023, M2)

M3 <- regression_model(data_dec_2023, "diff_log_ncpi_adj", c("diff_log_m2", "diff_log_gdp", "diff_log_ir"), list("diff_log_ncpi_adj" = 1, "diff_log_m2" = 1, "diff_log_gdp" = 1, "diff_log_ir" = 1), c("diff_log_ir"), 1, FALSE) 
M3_stats <- stats(data_dec_2023, M3)

M4 <- regression_model(data_dec_2023, "diff_log_ncpi_adj_ds", c("diff_log_m2_ds"), list("diff_log_ncpi_adj_ds" = 1, "diff_log_m2_ds" = 1), NULL, 1, FALSE) 
M4_stats <- stats(data_dec_2023, M4)

## Conflicting-claims model
CC1 <- regression_model(data_dec_2023, "inf_adj", c("er"), list("inf_adj" = 1, "er" = 1), c("er"), 1, FALSE)
CC1_stats <- stats(data_dec_2023, CC1)

CC2 <- regression_model(data_dec_2023, "log_inf_adj", c("log_er"), list("log_inf_adj" = 1, "log_er" = 1), c("log_er"), 0, FALSE)
CC2_stats <- stats(data_dec_2023, CC2)

### truncated data series for wage rate model (wage data is available only till Oct 2022, i.e., 106 data points)
data_oct_2022_ardl <- slice(data, 1:106)
  
CC3 <- regression_model(data_oct_2022_ardl, "log_inf_adj", c("log_er", "log_wr"), list("log_inf_adj" = 1, "log_er" = 1, "log_wr" = 1), c("log_er", "log_wr"), 0, FALSE)
CC3_stats <- stats(data_oct_2022_ardl, CC3)

## Heuristic models 
H1 <- regression_model(data_dec_2023, "log_inf_adj", c("log_er", "log_m2"), list("log_inf_adj" = 1, "log_er" = 1, "log_m2" = 1), c("log_er", "log_m2"), 0, FALSE)  
H1_stats <- stats(data_dec_2023, H1)

H2 <- regression_model(data_dec_2023, "diff_log_inf_adj", c("diff_log_er", "diff_log_m2"), list("diff_log_inf_adj" = 1, "diff_log_er" = 1, "diff_log_m2" = 1), c("log_er", "log_m2"), 0, FALSE)
H2_stats <- stats(data_dec_2023, H2)

H3 <- regression_model(data_oct_2022_ardl, "diff_log_inf_adj", c("diff_log_er", "diff_log_m2", "diff_log_wr"), list("diff_log_inf_adj" = 1, "diff_log_er" = 1, "diff_log_m2" = 1, "diff_log_wr" = 1), c("log_er", "log_m2", "log_wr"), 0, FALSE)
H3_stats <- stats(data_oct_2022_ardl, H3)



## Diagnostic tests

### For Breusch_Pagan LM test (no autocorrelation) and Shapiro-Wilk test (normality), run dynardl.auto.correlated(model_name) from dynamac package

### Function to run White test (homoskedasticity)
#### Parameters:
#### df: data frame
#### x: independent variables of model in vector form, e.g., c("log_m2", "log_er")
#### model: ARDL model 

white_test <- function(df, x, model) {
  
  residuals <- model[["model"]][["residuals"]]
  
  len_res <- length(residuals)
  len_x <- nrow(df)
  
  if (len_res < len_x) {
    residuals <- c(rep(NA, len_x - len_res), residuals)
  }
  
  residuals_sq <- residuals^2
  
  white_test_df <- data.frame(residuals_sq, df[, x])
  
  formula <- as.formula(paste("residuals_sq ~ ", paste(x, collapse = " + ")))
  white_test_model <- lm(formula, data = white_test_df)
  
  f_statistic <- summary(white_test_model)$fstatistic[1]
  f_statistic <- round(f_statistic, 4)
  
  p_value <- pf(f_statistic, summary(white_test_model)$fstatistic[2], summary(white_test_model)$fstatistic[3], lower.tail = FALSE)
  p_value <- round(p_value, 4)
  
  f <- list("F-statistic", as.numeric(f_statistic))
  p <- list("p-value", as.numeric(p_value))
  
  result <- do.call(cbind, list(f, p))
  
  return(result)
}

### results of White test

M1_white <- white_test(data_dec_2023, c("log_m2"), M1)
M2_white <- white_test(data_dec_2023, c("diff_log_m2"), M2)
M3_white <- white_test(data_dec_2023, c("diff_log_m2", "diff_log_gdp", "diff_log_ir"), M3)
M4_white <- white_test(data_dec_2023, c("diff_log_m2_ds"), M4)

CC1_white <- white_test(data_dec_2023, c("er"), CC1)
CC2_white <- white_test(data_dec_2023, c("log_er"), CC2)
CC3_white <- white_test(data_oct_2022_ardl, c("log_er", "log_wr"), CC3)

H1_white <- white_test(data_dec_2023, c("log_er", "log_m2"), H1)
H2_white <- white_test(data_dec_2023, c("diff_log_er", "diff_log_m2"), H2)
H3_white <- white_test(data_oct_2022_ardl, c("diff_log_er", "diff_log_m2", "diff_log_wr"), H3)
