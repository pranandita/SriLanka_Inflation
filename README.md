# Investigating the root of inflation in Sri Lanka–Money supply or exchange rate

<p>This project aims to disentangle the root cause of high inflation during the Sri Lankan financial crisis of 2022. Two theoretical models are formulated—a monetarist model and a post-Keynesian model—which blame monetary expansion and exchange rate dynamics, respectively, as the proximal cause of the inflationary spiral. The proposed models are then tested using autoregressive distributed lag (ARDL) econometric methodology with macroeoconomic monetary and fiscal data. A detailed report on the project can be found [here](https://pranandita.github.io/portfolio/1_Inflation/).</p>

## Data 
### Time_series_analysis.lsx
<p>The data set `Time_series_analysis.xlsx` contains relevant macroeoconomic parameters used for evaluating the time-series ARDL models. The time series ranges from January 2014 to December 2023 except where mentioned. Some data series have shorter lengths due to data unavailability. The variables are explained as follows:</p>

* **'ncpi_21'**: National Consumer Price Index (NCPI), reported with respect to base year 2021. Obviously, this data is reported only from 2022.
* **'ncpi_21_adj'**: NCPI (base 2021) adjusted to base year 2013 using the approximation described in Appendix 2 of the [report](https://pranandita.github.io/portfolio/1_Inflation/).
* **'ncpi'**: Raw (unadjusted) NCPI values. From 2014 to 2022, the values are reported in base year 2013. As the Central Bank stopped reporting base-2013 values from 2023 onwards, the base-2021 value is used for the 2023. 
* **'inf'**: Monthly inflation calculated as the first difference of monthly values of raw NCPI ('ncpi').
* **'ncpi_adj'**: NCPI series adjusted to base year 2013. From 2014 to 2022, the data used are the base-2013 values reported by the Central Bank. For the 2023, the 'ncpi_21_adj' values are used.
* **'inf_adj'**: Inflation calculated as the first difference of monthly *adjusted* NCPI values ('ncpi_adj').
* **'m2'**: Broad money M2 in million LKR (Lankan rupees).
* **'ir'**: Interest rate, taken as average weighted lending rate.
* **'er'**: Real exchange rate of LKR with respect to USD.
* **'w'**: Nominal wage index in LKR with respect to base year 2012. Only the informal private sector is considered.
* **'wr'**: Wage rate, calculated as the ratio of the wage index ('w') to the general level of prices, taken as the adjusted NCPI value ('ncpi_adj').
* **'gdp'**: Real GDP in million LKR. Reported with respect to base year 2015.

<p>The data are obtained from the [database](https://www.cbsl.lk/eresearch/)  of the Central Bank of Sri Lanka. All data are available in monthly intervals with the exception of GDP, which is reported quarterly. For the analysis, the quarterly data are triplicated for approximate monthly values. </p>

<p>The wage index ('w') was available until only October 2022 at the time of conducting the analysis. Hence, the wage rate ('wr') is also calculated until October 2022.</p>

### SriLanka_compiled_macro_data.xlsx

<p>Further, several the data set named 'SriLanka_compiled_macro_data.xlsx' compiles several macroeoconomic and financial variables for Sri Lanka from 2018 to 2023. These were compiled from the database of the Central Bank of Sri Lanka as well as from other sources, such as the International Monetary Fund's International Reserves and Foreign Currency Liquidity and International Investment Position databases. Users are encouraged to use and expand the data set according to their needs.</p>


