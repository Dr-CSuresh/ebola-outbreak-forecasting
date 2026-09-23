# Ebola Outbreak Forecasting
# 02_exploratory_time_series.R
#
# Purpose:
# Visualise annual Ebola outbreak reporting and explore
# whether the annual series contains a detectable temporal
# trend or autocorrelation using ARIMA.



library(tidyverse)
library(forecast)


# 1. Load annual Ebola series


ebola_by_year <- read_rds(
  "data/processed/ebola_by_year.rds"
)


# 2. Plot annual Ebola outbreak reporting


ebola_annual_plot <- ggplot(
  ebola_by_year,
  aes(
    x = year,
    y = ebola_records
  )
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Annual Ebola outbreak reporting, 1996-2025",
    subtitle = "Countries/territories with an Ebola outbreak record",
    x = "Year",
    y = "Countries/territories reporting Ebola",
    caption = "2026 excluded because the calendar year is incomplete."
  ) +
  theme_minimal()


ebola_annual_plot


ggsave(
  "figures/ebola_annual_reporting.png",
  ebola_annual_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# 3. Convert to annual time series


ebola_ts <- ts(
  ebola_by_year$ebola_records,
  start = 1996,
  frequency = 1
)


ebola_ts


# 4. Fit exploratory ARIMA model


ebola_arima <- auto.arima(
  ebola_ts,
  seasonal = FALSE,
  stepwise = FALSE,
  approximation = FALSE
)


ebola_arima

# 5. Five-year ARIMA forecast


ebola_arima_forecast <- forecast(
  ebola_arima,
  h = 5
)


ebola_arima_forecast


# 6. Save ARIMA forecast plot


png(
  "figures/ebola_arima_forecast.png",
  width = 1600,
  height = 1200,
  res = 150
)

plot(
  ebola_arima_forecast,
  main = "Exploratory ARIMA forecast of annual Ebola reporting",
  xlab = "Year",
  ylab = "Countries/territories with an Ebola record"
)

dev.off()


# 7. Save forecast values


arima_forecast_table <- tibble(
  year = 2026:2030,
  point_forecast = as.numeric(
    ebola_arima_forecast$mean
  ),
  lower_80 = as.numeric(
    ebola_arima_forecast$lower[, "80%"]
  ),
  upper_80 = as.numeric(
    ebola_arima_forecast$upper[, "80%"]
  ),
  lower_95 = as.numeric(
    ebola_arima_forecast$lower[, "95%"]
  ),
  upper_95 = as.numeric(
    ebola_arima_forecast$upper[, "95%"]
  )
)


arima_forecast_table


write_csv(
  arima_forecast_table,
  "results/tables/arima_forecast.csv"
)