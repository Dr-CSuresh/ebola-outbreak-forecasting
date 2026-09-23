# Ebola Interventions (SEIRDV Vaccination & Dynamic Rt)
# Evaluates ring vaccination and non-pharmaceutical interventions.


# 1. Load Packages
required_packages <- c("deSolve", "ggplot2", "reshape2")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages) > 0) install.packages(new_packages, repos = "https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(deSolve)
  library(ggplot2)
  library(reshape2)
})

if (!dir.exists("plots")) dir.create("plots")

# 2. Parameters & Models Setup
pop_size <- 100000
I0       <- 886
sigma    <- 1 / 10
gamma    <- 1 / 12
cfr      <- 0.48
times    <- seq(0, 180, by = 1)

init_full <- c(S = pop_size - I0, E = 0, I = I0, R = 0, D = 0, V = 0)

# Model A: SEIRDV (Vaccination)
seirdv_model <- function(time, state, parameters) {
  with(as.list(c(state, parameters)), {
    N <- S + E + I + R + D + V
    vax <- ifelse(S > 0, min(S, vax_rate), 0)
    
    dS <- -beta * S * I / N - vax
    dE <- (beta * S * I / N) - (sigma * E)
    dI <- (sigma * E) - (gamma * I)
    dR <- (1 - cfr) * gamma * I
    dD <- cfr * gamma * I
    dV <- vax
    
    return(list(c(dS, dE, dI, dR, dD, dV)))
  })
}

# Model B: SEIRD Dynamic Rt (Intervention)
seird_rt_model <- function(time, state, parameters) {
  with(as.list(c(state, parameters)), {
    N <- S + E + I + R + D
    current_R0 <- ifelse(time >= 30, 0.8, 2.0)
    current_beta <- current_R0 * gamma
    
    dS <- -current_beta * S * I / N
    dE <- (current_beta * S * I / N) - (sigma * E)
    dI <- (sigma * E) - (gamma * I)
    dR <- (1 - cfr) * gamma * I
    dD <- cfr * gamma * I
    
    return(list(c(dS, dE, dI, dR, dD)))
  })
}

# 3. Simulations
# Run Vaccination Comparison
parms_vax <- c(sigma = sigma, gamma = gamma, beta = 2.0 * gamma, cfr = cfr, vax_rate = 200)
df_vax <- as.data.frame(ode(y = init_full, times = times, func = seirdv_model, parms = parms_vax))

parms_no_vax <- parms_vax
parms_no_vax["vax_rate"] <- 0
df_no_vax <- as.data.frame(ode(y = init_full, times = times, func = seirdv_model, parms = parms_no_vax))

df_no_vax$Strategy <- "No Intervention"
df_vax$Strategy    <- "Ring Vaccination (200/day)"
df_vax_compare     <- rbind(df_no_vax, df_vax)

# Run Rt Dynamic Intervention
df_rt <- as.data.frame(ode(y = init_full[1:5], times = times, func = seird_rt_model, parms = c(sigma = sigma, gamma = gamma, cfr = cfr)))

# 4. Plot & Save Outputs
p_vax <- ggplot(df_vax_compare, aes(x = time, y = D, color = Strategy, linetype = Strategy)) +
  geom_line(size = 1.2) +
  labs(title = "Vaccination Impact on Cumulative Fatalities", x = "Days", y = "Deaths (D)") +
  theme_minimal(base_size = 13)

p_rt <- ggplot(df_rt, aes(x = time, y = I)) +
  geom_line(color = "darkorange", size = 1.2) +
  geom_vline(xintercept = 30, linetype = "dashed", color = "gray30") +
  labs(title = "Dynamic Rt Intervention Effect (Rt Drops to 0.8 at Day 30)", x = "Days", y = "Active Cases (I)") +
  theme_minimal(base_size = 13)

print(p_vax)
print(p_rt)

ggsave("plots/02_vaccination_impact.png", plot = p_vax, width = 8, height = 5, dpi = 300)
ggsave("plots/03_rt_intervention.png", plot = p_rt, width = 8, height = 5, dpi = 300)