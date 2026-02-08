# %% Loading libraries
library(tidyverse)
library(reshape2)
library(lme4)
library(lmerTest)
library(ggplot2)
library(ggpubr)
# Set path
setwd("/Users/kaankeskin/projects/sch_pe/")
# 1. Load Data
# Reading pe_raw.csv (Rows: Subjects, Cols: denekId + trial_1...trial_60)
pe_raw <- read.csv("./data/processed/pe_raw.csv")
subj_table <- read.csv("./data/raw/subjects_list.csv")
# 2. Filtering
# Exclude subjects 9, 44, and 77 from both tables
exclude_ids <- c(9, 44, 77)
pe_raw <- pe_raw %>% filter(!denekId %in% exclude_ids)
subj_table <- subj_table %>% filter(!task.id %in% exclude_ids)

# %% 3. Reshape to Long Format
# This moves 'trial_1', 'trial_2', etc., into a single column called 'PE'
long_pe <- melt(pe_raw, id.vars = "denekId", variable.name = "Trial", value.name = "PE")
# 4. Clean Trial and Add Phase (Task) Information
# Convert 'trial_1' string to numeric 1
long_pe$Trial_Num <- as.numeric(gsub("trial_", "", long_pe$Trial))
# Define Phase/Task (1: Trials 1-20, 2: 21-40, 3: 41-60)
long_pe$Task <- factor(case_when(
  long_pe$Trial_Num <= 20 ~ 1,
  long_pe$Trial_Num <= 40 ~ 2,
  TRUE ~ 3
))
# 5. Merge with Clinical Data (Using your specific spaced column names)
# We join on 'denekId' from long_pe and ' task-id' from subj_table
final_df <- long_pe %>%
  inner_join(subj_table, by = c("denekId" = "task.id")) %>%
  rename(
    Group = `group`,
    Sex = `sex`,
    Age = `age`
  ) %>% 
  mutate (
	Group = factor(Group),
	Sex = factor(Sex),
	Task = factor(Task),
	Age_scaled = scale(as.numeric(Age)),
	absPE = abs(PE)
	)
# 6. Create Magnitude Variable
# Addressing the bimodal distribution by taking the absolute value
# 1. Pre-process data outside the model
final_df_clean <- final_df %>%
  # Remove any rows with NA or Infinite values in key columns
  filter(is.finite(absPE), !is.na(Group), !is.na(denekId))
# 2. Run the model with a robust optimizer
# install.packages("glmmTMB")
library(glmmTMB)

res_model <- glmmTMB(absPE ~ Group * Task + Sex + Age_scaled + (1 | denekId), 
                     data = final_df_clean)

summary(res_model)

# %% Visualization for Referee 2
# Show the distribution of magnitude to confirm bimodality is resolved
ggplot(final_df, aes(x = absPE, fill = factor(Group))) +
  geom_density(alpha = 0.5) +
  facet_wrap(~Task) +
  labs(title = "Magnitude of Prediction Error (|PE|) by Group and Phase",
       x = "Absolute PE (Surprise Amount)", y = "Density", fill = "Group (0=HC, 1=SZ)") +
  theme_minimal()

# %% Model Diagnostics
# Sonuclar gayet iyi
library(DHARMa)
# 1. Simulate residuals (1000 simulations is standard)
simulationOutput <- simulateResiduals(fittedModel = res_model, n = 1000)
# 2. Plot the main diagnostics
# This produces a QQ-plot (left) and Residual vs. Predicted plot (right)
plot(simulationOutput)

# 3. Specific tests for clinical data
testDispersion(simulationOutput)  # Checks if variance is higher than the model expects
testOutliers(simulationOutput)    # Checks if specific subjects are pulling the model too hard
