# Investigating the root of inflation in Sri Lanka–Money supply or exchange rate

This project aims to disentangle the root cause of high inflation during the Sri Lankan financial crisis of 2022. Two theoretical models are proposed—a monetarist model and a post-Keynesian model—which blame monetary expansion and exchange rate dynamics, respectively, as the proximal cause of the inflationary spiral. The proposed models are then tested using autoregressive distributed lag (ARDL) econometric methodology with macroeoconomic monetary and fiscal data. A detailed report on the project can be found [here](https://pranandita.github.io/portfolio/1_Inflation/).

## Data 
### Time_series_data.lsx
The data set *Time_series_data.xlsx* contains the relevant macroeoconomic parameters used for evaluating the time-series ARDL models. All time series range from January 2014 to December 2023 except where mentioned. Some data series have shorter lengths due to data unavailability. The time series variables are explained as follows.

* **ncpi_21**: National Consumer Price Index (NCPI), reported with respect to base year 2021. Obviously, this data is reported only from 2022.
* **ncpi_21_adj**: NCPI (base 2021) adjusted to base year 2013 using the approximation described in Appendix 2 of the [report](https://pranandita.github.io/files/Biswas_SriLanka_Inflation.pdf).
* **ncpi**: Raw (unadjusted) NCPI values. From 2014 to 2022, the values are reported in base year 2013. As the Central Bank stopped reporting base-2013 values from 2023 onwards, the base-2021 value is used for the 2023. 
* **inf**: Monthly inflation calculated as the first difference of monthly values of raw NCPI ('ncpi').
* **ncpi_adj**: NCPI series adjusted to base year 2013. From 2014 to 2022, the data used are the base-2013 values reported by the Central Bank. For the 2023, the 'ncpi_21_adj' values are used.
* **inf_adj**: Inflation calculated as the first difference of monthly *adjusted* NCPI values ('ncpi_adj').
* **m2**: Broad money M2 in million LKR (Lankan rupees).
* **ir**: Interest rate (average weighted lending rate).
* **er**: Real exchange rate of LKR with respect to USD.
* **w**: Nominal wage index in LKR with respect to base year 2012. Only the informal private sector is considered.
* **wr**: Wage rate, calculated as the ratio of the wage index ('w') to the general level of prices, taken as the adjusted NCPI value ('ncpi_adj').
* **gdp**: Real GDP in million LKR. Reported with respect to base year 2015.

The data are obtained from the [database](https://www.cbsl.lk/eresearch/) of the Central Bank of Sri Lanka. All data are available in monthly intervals with the exception of GDP, which is reported quarterly. For the analysis, the quarterly GDP data are triplicated to approximate monthly values. 

<p>The wage index ('w') was available until only October 2022 at the time of conducting the analysis. Hence, the wage rate ('wr') is also calculated until October 2022.</p>

### SriLanka_compiled_macro_data.xlsx
Further, the data set named *SriLanka_compiled_macro_data.xlsx* compiles several macroeoconomic and financial variables for Sri Lanka from 2018 to 2023. These were obtained from the database of the Central Bank of Sri Lanka as well as from other sources, such as the International Monetary Fund's International Reserves and Foreign Currency Liquidity and International Investment Position databases. Users are encouraged to use and expand the data set according to their needs.

## Code
The R file named *Time_series_data.R* contains the code to conduct time-series analysis on the data set *Time_series_anlaysis.xlsx*. 

### Code structure
#### Data transformations
**1. Deseasonalize data** <br>
The function `ds_data(df, vars)` uses the loess filter for deseasonalizing data.
It takes the following arguments. 
* `df`: The data frame.
* `vars`: The variables in `df` to be deseasonalized, specified as a column vector.

It returns the data frame `df` with the deseasonalized data appended as new columns. <br>

**2. Data transformations** <br>
The following transformations are performed on all the data series.
* First difference
* Log transformation
* First difference of log transformation

The following functions are used: `transform_data(df, vars)` and `transform_data_modified_log(df, vars)`. The `transform_data_modified_log(df, vars)` function is used for data series that contain zero and negative values, such as the inflation time series `inf` and `inf_adj`, for which a regular log transformation is not possible. The modified log transform takes the logarithm of the magnitude of the data point and assigns it the same sign as the data point. This is explained in Chapter 4 of the [report](https://pranandita.github.io/files/Biswas_SriLanka_Inflation.pdf).  <br> 

Both functions take the following arguments. 
* `df`: The data frame.
* `vars`: The variables in `df` to be deseasonalized, specified as a column vector.

The functions returns the data frame `df` with the transformed data appended as new columns.

#### Stationarity tests
First, the function `time_series(df)` is used to convert the data frames into `zoo` elements, which contain time series data and can be used for running stationarity tests. The argument `df` is the data frame to be converted to a `zoo element`. Documentation on the `zoo` package can be found [here](https://cran.r-project.org/web/packages/zoo/index.html). <br>

Next, the function `stationarity_tests(ts_object)` takes a `zoo` element as the argument `ts_object` and performs stationarity tests on each time series in `ts_object`. The following tests are performed. 
* Augmented Dickey–Fuller (ADF)
* Phillips–Perron (PP)
* Kwiatkowski–Phillips–Schmidt–Shin (KPSS)

For the ADF and PP tests, the null hypothesis is that the series is non-stationary. For the KPSS test, the null hypothesis is that the series is stationary. <br>

The function `stationarity_tests(ts_object)` returns a data frame containing the F-statistics of the three tests for each time series in `ts_object`. The p-values are denoted through the star notation. Further, warnings are displayed, which are important for the **edge cases**: for $p>0.1$, R reports a p-value of $0.1$; for $p<0.01$, R reports a p-value of $0.01$. To account for these, the inequality conditions are adjusted accordingly in `stationarity_tests(ts_object)`. In such cases, R provides a warning message, e.g., for $p>0.1$, it reports 'p-value greater than printed p-value'. Whenever a warning message is displayed, the results of the stationarity tests should be re-checked individually before final reporting.

#### ARDL models
The ARDL models are run using the R package [`dynamac`](https://cran.r-project.org/web/packages/dynamac/index.html). The function `regression_model(df, y, x, lags, diffs, ec, simulate)` uses the `dynamac` function `dynardl` to run the models. The function `regression_model(df, y, x, lags, diffs, ec, simulate)` takes the following arguments. 
* `df`: The data frame.
* `y`: The dependent variable.
* `x`: The independent variables, specified as a column vector.
* `lags`: The number of lags to be included for each variable. Specified as a list, e.g., `list("log_ncpi_adj" = 1, "log_m2" = 1)`. The default value is zero lags for each variable, i.e., `lags = list()`.
* `diffs`: The variables that need to be differenced. Only first differences are supported by `dynamac`. The variables to be differenced should be chosen based on model requirements and from the results of the stationarity tests: variables that are stationary in their first differences need to be differenced. `diffs` is specified as a vector, e.g., `c("log_er", "log_wr")`. The default value is a NULL vector, i.e., no variable is differenced.
* `ec`: Binary value indicating whether model should be estimated in error-correction form (i.e., whether `y` should be included in first differences) or not. If `ec` is 1, then error correction is applied; if `ec` is 0, then it is not. The default value is 1.
* `simulate`: Binary value (`TRUE` / `FALSE`) indicating whether response should be simulated or not. If `FALSE`, only the regression model is estimated. The default value assigned is `FALSE`.

The function `regression_model(...)` returns the estimated model. The models run in this project and their parameters are described in detail in Chapter 4, Section 4.4 of the [report](https://pranandita.github.io/files/Biswas_SriLanka_Inflation.pdf). <br> 

**Diagnostic tests** <br>

The `dynamac` package provides built-in functions to run diagnostic tests using dynamic model simulations. For this project, the Breusch–Pagan LM test and Shapiro–Wilk test for checking for the assumptions of no autocorrelation and non-normality of residuals, respectively, were run using the `dynardl.auto.correlated` function. The `dynamac` [documentation](https://cran.r-project.org/web/packages/dynamac/dynamac.pdf) can be consulted to run the function. These two tests are not included in the code here for brevity as users can run them easily. <br>

The `dynamac` package does not provide the ability to run the White test for homomskedasticity, which is a crucial assumption for ARDL models. Hence, the function `white_test(df, x, model)` is written to run the White test. The arguments are as follows. 
* `df`: The data frame.
* `x`: The *independent* variables of the model, specified as a column vector.
* `model`: The ARDL model estimated using `dynardl` (done here using the `regression_model(...)` function).

The `white_test(df, x, model)` function returns a data frame with the F-statistic and p-value of the White test. The White test regresses the square of the model residuals on the independent variables `x` to check that there is no significant dependence of the residuals on the model parameters. Hence, the assumption is satisfied if the null hypothesis of the White test is *rejected*, i.e., if the p-value is greater than the desired level of significance. 
