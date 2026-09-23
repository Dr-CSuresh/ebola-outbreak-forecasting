# Ebola Outbreak Forecasting
# 04_five_year_simulation.R
#
# Purpose:
# Simulate hypothetical 2026-2030 Ebola reporting under
# negative-binomial distributions estimated from:
#
# 1. All historical years, 1996-2025
# 2. A sensitivity scenario excluding 2014
#
# Simulations describe country-level outbreak reporting,
# not case incidence or cross-border transmission.



library(tidyverse)
library(MASS)


# 1. Load annual Ebola data


ebola_by_year <- read_rds(
  "data/processed/ebola_by_year.rds"
)


# 2. Refit negative-binomial models

ebola_nb <- MASS::glm.nb(
  ebola_records ~ 1,
  data = ebola_by_year
)

ebola_nb_no_2014 <- MASS::glm.nb(
  ebola_records ~ 1,
  data = ebola_by_year %>%
    filter(year != 2014)
)


# Extract parameters

ebola_mu <- exp(
  coef(ebola_nb)[1]
)

ebola_theta <- ebola_nb$theta


ebola_mu_no_2014 <- exp(
  coef(ebola_nb_no_2014)[1]
)

ebola_theta_no_2014 <- ebola_nb_no_2014$theta


# 3. Simulation settings


set.seed(123)

n_sim <- 100000
n_years <- 5


# 4. Simulate 2026-2030 using all historical years


future_all <- matrix(
  rnbinom(
    n = n_sim * n_years,
    size = ebola_theta,
    mu = ebola_mu
  ),
  nrow = n_sim,
  ncol = n_years
)

colnames(future_all) <- 2026:2030


# 5. Simulate sensitivity scenario excluding 2014


set.seed(123)

future_no_2014 <- matrix(
  rnbinom(
    n = n_sim * n_years,
    size = ebola_theta_no_2014,
    mu = ebola_mu_no_2014
  ),
  nrow = n_sim,
  ncol = n_years
)

colnames(future_no_2014) <- 2026:2030


# 6. Probability of events occurring at least once in five years

future_summary_all <- tibble(
  outcome = c(
    "At least one Ebola-reporting year",
    "At least one year with >=2 countries",
    "At least one year with >=3 countries",
    "At least one year with >=5 countries"
  ),
  probability = c(
    mean(apply(future_all >= 1, 1, any)),
    mean(apply(future_all >= 2, 1, any)),
    mean(apply(future_all >= 3, 1, any)),
    mean(apply(future_all >= 5, 1, any))
  )
) %>%
  mutate(
    percent = round(
      probability * 100,
      1
    )
  )


future_summary_no_2014 <- tibble(
  outcome = c(
    "At least one Ebola-reporting year",
    "At least one year with >=2 countries",
    "At least one year with >=3 countries",
    "At least one year with >=5 countries"
  ),
  probability = c(
    mean(apply(future_no_2014 >= 1, 1, any)),
    mean(apply(future_no_2014 >= 2, 1, any)),
    mean(apply(future_no_2014 >= 3, 1, any)),
    mean(apply(future_no_2014 >= 5, 1, any))
  )
) %>%
  mutate(
    percent = round(
      probability * 100,
      1
    )
  )


future_comparison <- bind_rows(
  future_summary_all %>%
    mutate(scenario = "All years"),
  
  future_summary_no_2014 %>%
    mutate(scenario = "Excluding 2014")
)


future_comparison


# 7. Maximum geographic extent within each five-year simulation


max_countries_all <- apply(
  future_all,
  1,
  max
)

max_countries_no_2014 <- apply(
  future_no_2014,
  1,
  max
)


# Summarise simulated maxima

maximum_summary <- tibble(
  scenario = c(
    "All years",
    "Excluding 2014"
  ),
  median = c(
    median(max_countries_all),
    median(max_countries_no_2014)
  ),
  lower_95 = c(
    quantile(max_countries_all, 0.025),
    quantile(max_countries_no_2014, 0.025)
  ),
  upper_95 = c(
    quantile(max_countries_all, 0.975),
    quantile(max_countries_no_2014, 0.975)
  )
)


maximum_summary


# 8. Prepare distribution for plotting


max_future_comparison <- tibble(
  maximum_countries = c(
    max_countries_all,
    max_countries_no_2014
  ),
  scenario = c(
    rep(
      "All years",
      n_sim
    ),
    rep(
      "Excluding 2014",
      n_sim
    )
  )
)


# Collapse very rare extreme simulated values into 10+

max_future_plot <- max_future_comparison %>%
  mutate(
    maximum_group = if_else(
      maximum_countries >= 10,
      "10+",
      as.character(maximum_countries)
    ),
    maximum_group = factor(
      maximum_group,
      levels = c(
        as.character(0:9),
        "10+"
      )
    )
  ) %>%
  count(
    scenario,
    maximum_group
  ) %>%
  group_by(scenario) %>%
  mutate(
    percent = n / sum(n) * 100
  ) %>%
  ungroup()


# 9. Plot maximum geographic extent


maximum_extent_plot <- ggplot(
  max_future_plot,
  aes(
    x = maximum_group,
    y = percent,
    fill = scenario
  )
) +
  geom_col(
    position = "dodge"
  ) +
  labs(
    title = "Simulated maximum geographic extent of Ebola reporting, 2026-2030",
    subtitle = "100,000 five-year simulations from negative-binomial models",
    x = "Maximum countries/territories with an Ebola record in any one year",
    y = "Simulated five-year periods (%)",
    fill = NULL,
    caption = "Sensitivity analysis excludes the exceptional 2014 observation."
  ) +
  theme_minimal()


maximum_extent_plot


ggsave(
  "figures/ebola_five_year_maximum_extent.png",
  maximum_extent_plot,
  width = 10,
  height = 7,
  dpi = 300
)


# 10. Save results


write_csv(
  future_comparison,
  "results/tables/five_year_simulation_probabilities.csv"
)

write_csv(
  maximum_summary,
  "results/tables/five_year_maximum_summary.csv"
)

write_csv(
  max_future_plot,
  "results/tables/five_year_maximum_distribution.csv"
)