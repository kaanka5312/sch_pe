# %% Loading libraries
library(tidyverse)
library(broom)
library(ggpubr)
# 1. Load Data
# Assuming these are in your project folder
params <- read.csv("./data/processed/model_parameters.csv")
subjects <- read.csv("./data/raw/subjects_list.csv")
# 2. Pre-processing & Exclusion
# Exclude subjects 9, 44, and 77
exclude_ids <- c(9, 44, 77)

# %% Data cleaning
# Handle the specific spacing in your subjects_list.csv column names
df_clean <- params %>%
  filter(!denekId %in% exclude_ids) %>%
  inner_join(subjects, by = c("denekId" = "task.id")) %>%
  rename(
    Group = group,
    Age = age,
    Sex = sex,
    DoI = DoI # Ensure this matches your file's spacing
  ) %>%
  mutate(
    Group = factor(Group, labels = c("HC", "SZ")),
    Sex = factor(Sex, labels = c("F", "M")),
    # Log-transform Tau for normality (standard in RL papers)
    log_tau = log(as.numeric(tau)),
    # Scale continuous variables for model stability
    Age_z = scale(as.numeric(Age)),
    AP_z = scale(as.numeric(ap)),
    education_z = scale(as.numeric(education)),
    PANSS_neg_z = scale(as.numeric(PANSS.Negative)) 
)

  # %% Model fitting
# 3. Model 1: Group Differences (Across all subjects)
# Controls for Age and Sex
fit_alpha_group <- lm(alpha ~ Group + PANSS_neg_z+  education_z , data = df_clean)
fit_tau_group   <- lm(log_tau ~ Group + PANSS_neg_z+  education_z , data = df_clean)
print("--- Group Differences: Alpha ---")
summary(fit_alpha_group)
print("--- Group Differences: Tau ---")
summary(fit_tau_group)

# 4. Model 2: Clinical Confounding (SZ Group Only)
# Testing if Duration of Illness (DoI) predicts parameters in patients
sz_only <- df_clean %>% filter(Group == "SZ")

fit_alpha_clinical <- lm(alpha ~ DoI + Age_z + Sex, data = sz_only)
fit_tau_clinical   <- lm(log_tau ~ DoI + Age_z + Sex, data = sz_only)

print("--- SZ Clinical Correlates: Alpha ---")
summary(fit_alpha_clinical)

# 5. Visualization: Parameter Distribution by Group
p1 <- ggplot(df_clean, aes(x = Group, y = alpha, fill = Group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.5) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  theme_minimal() +
  labs(title = "Learning Rate (Alpha)", y = expression(alpha))

p2 <- ggplot(df_clean, aes(x = Group, y = tau, fill = Group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.5) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  scale_y_log10() +
  theme_minimal() +
  labs(title = "Decision Noise (Tau)", y = "Tau (Log Scale)")

ggarrange(p1, p2, ncol = 2, common.legend = TRUE, legend = "bottom")
