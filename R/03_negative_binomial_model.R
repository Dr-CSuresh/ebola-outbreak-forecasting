# Ebola Outbreak Forecasting
# 03_negative_binomial_model.R
#
# Purpose:
# Model annual Ebola country-level outbreak reporting using
# count distributions and quantify probabilities of
# multi-country reporting.
#
# A sensitivity analysis excludes the exceptional 2014
# observation.



library(tidyverse)
library(MASS)


# 1. Load annual Ebola series


ebola_by_year <- read_rds(
  "data/processed/ebola_by_year.rds"
)


# 2. Fit intercept-only Poisson model


ebola_poisson <- glm(
  ebola_records ~ 1,
  family = poisson(link = "log"),
  data = ebola_by_year
)


summary(ebola_poisson)


# 3. Fit intercept-only negative-binomial model


ebola_nb <- MASS::glm.nb(
  ebola_records ~ 1,
  data = ebola_by_year
)


summary(ebola_nb)


# 4. Compare model fit


model_comparison <- AIC(
  ebola_poisson,
  ebola_nb
)


model_comparison


# 5. Extract negative-binomial parameters


ebola_mu <- exp(
  coef(ebola_nb)[1]
)

ebola_theta <- ebola_nb$theta


ebola_mu

ebola_theta


# 6. Annual probabilities of multi-country reporting


ebola_spread_probabilities <- tibble(
  threshold = c(
    "At least 1 country",
    "At least 2 countries",
    "At least 3 countries",
    "At least 5 countries"
  ),
  probability = c(
    1 - pnbinom(
      0,
      size = ebola_theta,
      mu = ebola_mu
    ),
    
    1 - pnbinom(
      1,
      size = ebola_theta,
      mu = ebola_mu
    ),
    
    1 - pnbinom(
      2,
      size = ebola_theta,
      mu = ebola_mu
    ),
    
    1 - pnbinom(
      4,
      size = ebola_theta,
      mu = ebola_mu
    )
  )
) %>%
  mutate(
    percent = round(
      probability * 100,
      1
    )
  )


ebola_spread_probabilities


# 7. Sensitivity analysis excluding 2014


ebola_nb_no_2014 <- MASS::glm.nb(
  ebola_records ~ 1,
  data = ebola_by_year %>%
    filter(
      year != 2014
    )
)


summary(ebola_nb_no_2014)


ebola_mu_no_2014 <- exp(
  coef(ebola_nb_no_2014)[1]
)

ebola_theta_no_2014 <- ebola_nb_no_2014$theta


ebola_mu_no_2014

ebola_theta_no_2014


# 8. Probabilities excluding 2014


ebola_probabilities_no_2014 <- tibble(
  threshold = c(
    "At least 1 country",
    "At least 2 countries",
    "At least 3 countries",
    "At least 5 countries"
  ),
  probability = c(
    1 - pnbinom(
      0,
      size = ebola_theta_no_2014,
      mu = ebola_mu_no_2014
    ),
    
    1 - pnbinom(
      1,
      size = ebola_theta_no_2014,
      mu = ebola_mu_no_2014
    ),
    
    1 - pnbinom(
      2,
      size = ebola_theta_no_2014,
      mu = ebola_mu_no_2014
    ),
    
    1 - pnbinom(
      4,
      size = ebola_theta_no_2014,
      mu = ebola_mu_no_2014
    )
  )
) %>%
  mutate(
    percent = round(
      probability * 100,
      1
    )
  )


ebola_probabilities_no_2014


# 9. Combine sensitivity results


ebola_probability_comparison <- bind_rows(
  ebola_spread_probabilities %>%
    mutate(
      scenario = "All years"
    ),
  
  ebola_probabilities_no_2014 %>%
    mutate(
      scenario = "Excluding 2014"
    )
)


ebola_probability_comparison


# 10. Plot annual modelled probabilities


probability_plot <- ggplot(
  ebola_probability_comparison,
  aes(
    x = threshold,
    y = percent,
    fill = scenario
  )
) +
  geom_col(
    position = "dodge"
  ) +
  labs(
    title = "Modelled annual probability of multi-country Ebola reporting",
    subtitle = "Negative-binomial models using 1996-2025 outbreak records",
    x = NULL,
    y = "Modelled annual probability (%)",
    fill = NULL,
    caption = "Country-level records do not imply cross-border transmission between countries."
  ) +
  theme_minimal()


probability_plot


ggsave(
  "figures/ebola_annual_probability_comparison.png",
  probability_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# 11. Save results


write_csv(
  ebola_probability_comparison,
  "results/tables/ebola_annual_probabilities.csv"
)


negative_binomial_summary <- tibble(
  scenario = c(
    "All years",
    "Excluding 2014"
  ),
  mean_annual_records = c(
    ebola_mu,
    ebola_mu_no_2014
  ),
  theta = c(
    ebola_theta,
    ebola_theta_no_2014
  ),
  AIC = c(
    AIC(ebola_nb),
    AIC(ebola_nb_no_2014)
  )
)


negative_binomial_summary


write_csv(
  negative_binomial_summary,
  "results/tables/negative_binomial_summary.csv"
)