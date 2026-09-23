
# Script 1: Baseline Ebola SEIR Model (R0 = 1.5 vs 2.0)
# Description: Models early epidemic growth starting from 1 index case.


# 1. Load Packages

required_packages <- c("deSolve", "ggplot2")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages) > 0) install.packages(new_packages, repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(deSolve)
  library(ggplot2)
})

if (!dir.exists("plots")) dir.create("plots")

# 2. Parameters & Differential Equations

incubation_period <- 10  # Days spent in Exposed state
infectious_period <- 12  # Days spent in Infectious state
sigma <- 1 / incubation_period
gamma <- 1 / infectious_period

seir_model <- function(time, state, parameters) {
  with(as.list(c(state, parameters)), {
    N <- S + E + I + R
    dS <- -beta * S * I / N
    dE <- (beta * S * I / N) - (sigma * E)
    dI <- (sigma * E) - (gamma * I)
    dR <- gamma * I
    
    return(list(c(dS, dE, dI, dR)))
  })
}

# 3. Simulation Runner Function

simulate_ebola <- function(R0_value, population = 100000, days = 180) {
  beta <- R0_value * gamma
  init <- c(S = population - 1, E = 0, I = 1, R = 0)
  times <- seq(0, days, by = 1)
  parms <- c(sigma = sigma, gamma = gamma, beta = beta)
  
  out <- as.data.frame(ode(y = init, times = times, func = seir_model, parms = parms))
  out$R0 <- as.factor(R0_value)
  return(out)
}

# 4. Run Model Runs & Combine Data

df_15 <- simulate_ebola(1.5)
df_20 <- simulate_ebola(2.0)
df_combined <- rbind(df_15, df_20)

# 5. Visual Output

p_baseline <- ggplot(df_combined, aes(x = time, y = I, color = R0)) +
  geom_line(size = 1.2) +
  labs(
    title = "Ebola Projections: Impact of R0 (1.5 vs 2.0)",
    x = "Days from Index Case",
    y = "Active Infected Cases",
    color = "Basic Reproduction Number (R0)"
  ) +
  theme_minimal(base_size = 13)

print(p_baseline)

# Save image for repository

ggsave("plots/01_baseline_r0_comparison.png", plot = p_baseline, width = 8, height = 5, dpi = 300)