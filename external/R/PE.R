# Loading libraries
library(R.matlab); library(tidyverse); library(reshape2)
#setwd("/Users/kaankeskin/projects/sch_pe/")
# Microsoft
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
#
dat <- list(readMat("./data/processed/normalized_pe_array2.mat"), # Cemre RW PE
            readMat("./data/processed/x2_array.mat"), # HGF X2
            readMat("./data/processed/x3_array.mat"), # HGF X3
            readMat("./data/processed/x2_pe_array.mat"), # HGF low level PE
            readMat("./data/processed/x3_pe_array.mat"), # HGF high level PE
            readMat("./data/processed/alfa2_array.mat"), # learning rate level 2
            readMat("./data/processed/alfa3_array.mat"), # learning rate level 3
            readMat("./data/processed/rw_pe.mat") # RW model PE from TAPAS
)

subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 44)))
#dat <- readMat("/Users/kaankeskin/projects/sch_pe/data/processed/normalized_pe_array.mat")

convert_to_long <- function(dat, subj_table, exclude=TRUE) {
  # Extract PE matrix (first 60 columns) and group information (column 61)
  if (exclude) dat$merged.matrix <- dat$merged.matrix[-c(9, 44), ]
  
  pe_mat <- dat$merged.matrix[,1:60]
  group <- factor(ifelse(dat$merged.matrix[,61], "sz", "hc"))
  task <- factor(rep(1:3, each = 20))  # Assuming 3 tasks with 20 trials each
  sex <- factor(ifelse(subj_table$sex, "M", "F"))
  age <- as.numeric(subj_table$age)
  doi <- as.numeric(subj_table$DoI)
  
  # Convert PE matrix to a data frame
  pe_df <- as.data.frame(pe_mat)
  
  # Add Subject IDs
  pe_df$Subject <- seq_len(nrow(pe_mat))  # Assign unique IDs to subjects
  
  # Reshape to long format
  long_pe <- melt(pe_df, id.vars = "Subject", variable.name = "Trial", value.name = "PE")
  
  # Convert Trial variable to numeric
  #long_pe$Trial <- as.numeric(gsub("V", "", long_pe$Trial))  # Remove "V" prefix if needed
  
  # Add Group information (repeat for each trial)
  long_pe$Group <- rep(group, each = ncol(pe_mat))
  
  # Add Task information (repeat for each subject)
  long_pe$Task <- rep(task, times = nrow(pe_mat))
  
  # Add Sex information (repeat for each trial)
  long_pe$Sex <- rep(sex, each = ncol(pe_mat))
  
  # Add Age information (repeat for each trial)
  long_pe$Age <- rep(age, each = ncol(pe_mat)) 
  
  # Add DoI information (repeat for each trial)
  long_pe$DoI <- rep(doi, each = ncol(pe_mat)) 
  
  
  return(long_pe)
}

# Usage
long_pe_list <- lapply(dat, convert_to_long, subj_table = subj_table)

library(lme4)
library(lmerTest)

# Apply the mixed-effects model to list elements 1-5
model_results <- lapply(long_pe_list[c(2:3,6,7)], function(df) {
  lmer(PE ~ Group * Task * Sex + (1 | Subject), data = df)
})

# Display summaries for all models
lapply(model_results, summary)

# Apply the mixed-effects model to list elements 4-5
model_results <- lapply(long_pe_list[c(4:5,8)], function(df) {
  lm(PE ~ Group * Task * Sex , data = df)
})

# Display summaries for all models
lapply(model_results, summary)

# Gamma modelling is more appropriate due to skewed nature of the data
long_pe_list[[1]]$PE_shifted <- long_pe_list[[1]]$PE + abs(min(long_pe_list[[1]]$PE)) + 0.25

library(lme4)
gamma_model <- glmer(PE_shifted ~ Group + Task + (1 | Subject), 
                     data = long_pe_list[[1]], 
                     family = Gamma(link = "log"),
                     control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e5)))
summary(gamma_model)

# For the publication, we will use the gamma distribution
# Log-normal as alternative
long_pe_list[[1]]$logPE <- log(long_pe_list[[1]]$PE_shifted)
alpha_long$DoI_z <- scale(alpha_long$DoI)  # mean=0, sd=1
long_pe_list[[1]]$DoI_z <- scale(long_pe_list[[1]]$DoI)

lognormal_model <- glmmTMB(logPE ~ Group * Sex + Task + (1 | Subject) + DoI_z, data = long_pe_list[[1]])

summary(lognormal_model)
# Check Distribition of dependent variable ####
# Histogram
hist(long_pe_list[[1]]$PE_shifted, breaks = 30, main = "Histogram of PE_shifted", xlab = "PE_shifted")

# Q-Q plot (log-transformed, optional)
qqnorm(log(long_pe_list[[1]]$PE_shifted), main = "Q-Q Plot of log(PE_shifted)")
qqline(log(long_pe_list[[1]]$PE_shifted))

#### Justify Random Effects (ICC and LRT) ####
# You want to assess whether adding a random intercept for 
# Subject significantly improves model fit. If Pr(>Chi) is significant 
# (typically p < 0.05), then including random effects is justified. 
# This means there's substantial between-subject variability 
# in PE_shifted not captured by the fixed effects alone.


# Model without random intercept (fixed effects only)
model_fixed <- glm(logPE ~ Group + Task , 
                   data = long_pe_list[[1]])
# Model with random intercept (your full model)
model_random <- lmer(logPE ~ Group + Task + (1 | Subject), 
                     data = long_pe_list[[1]])

# Compare the two models
anova(model_fixed, model_random, test = "Chisq")

### Model Diagnostics ####
library(DHARMa)

# Simulate residuals
sim_res <- simulateResiduals(lognormal_model)

# Plot residual diagnostics
plot(sim_res)

#### Checking model multicollinearity
library(car)
vif(lognormal_model)

### ICC 
library(performance)
icc(lognormal_model)


# Estimated Marginal Means (EMMs) for Task within each Group
# Pairwise comparisons for Group differences in each Task
posthoc_group_task <- emmeans(mixed_model, pairwise ~ Group | Task, lmer.df = "satterthwaite",adjust = "bonferroni")
summary(posthoc_group_task)

posthoc_task_group <- emmeans(mixed_model, pairwise ~ Task | Group, lmer.df = "satterthwaite")
summary(posthoc_task_group)

# Poisson regression
dat <-readMat("./data/processed/p3_pe_discrete.mat")
dat2=list()
dat2$merged.matrix = as.matrix(dat$neg.pe)
dat2_long <- convert_to_long(dat = dat2,subj_table = subj_table)

library(lme4)

# Poisson mixed model with Subject as a random effect
poisson_model <- glm(PE ~ Group * Task * Sex, 
                       data = dat2_long, 
                       family = poisson(link = "log"))

summary(poisson_model)


###############################
#=#= B E H A V I O R A L=#=#=#=
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

T_raw <- read.csv("./data/raw/response.csv")
T <- T_raw[T_raw$denekId %in% subj_table$task.id,]

T_aslihan <- read.csv("./data/processed/aslihan_filtered.csv")
T <- rbind(T,T_aslihan)

# Control the number of subject
#sum(T$sayac==59) 
T_last <- T[,c(2,3,4,5)]
T_last$group <- rep(subj_table$group,each=60)
T_last$sex <- rep(subj_table$sex,each=60)
T_last$age <- rep(as.numeric(subj_table$age),each=60)
T_last$doi <- rep(as.numeric(subj_table$DoI),each=60)


T_last$phase <- cut(
  T_last$sayac,
  breaks = c(0,19,39,59),
  labels = c("1", "2", "3"),
  include.lowest = TRUE
)

library(lme4)

T_last$yatirim <- factor(T_last$yatirim)
#T_last$rakip <- factor(T_last$rakip)
T_last$group <- factor(T_last$group)
T_last$phase <- factor(T_last$phase)

write.csv(T_last, "./data/processed/behavioral_last.csv", row.names = FALSE)


# Investigating the table 
# DO NOT FORGET ! THIS DOESNT CONSIDERED THE REPEATED MEASURE DESIGN SO CONTINUE
# TO GLM MODEL
# Create a 2x2 table for each group
tables <- by(T_last, T_last$group, function(sub_df) table(yatirim = sub_df$yatirim, rakip = sub_df$rakip))

# Display tables
tables

# Addition of the interaction doesn't improve the model
model_simple <- glmer(yatirim ~ group + phase + sex +  (1 | denekId) + doi, 
                      data = T_last, 
                      family = binomial(link = "logit"))

summary(model_simple)

### Model Diagnostics ####
library(DHARMa)

# Simulate residuals
sim_res <- simulateResiduals(model_simple)

# Plot residual diagnostics
plot(sim_res)

#### Checking model multicollinearity
library(car)
vif(model_simple)

### ICC 
library(performance)
icc(model_simple)

#### THIS PART IS TO CHECK IF CHANGING BEHAVIOUR EXISTS FOR THE SZ GROUP####
# Summarize investment behavior for each subject in each phase
T_last$yatirim <- as.numeric(as.character(T_last$yatirim))
subject_phase_summary <- T_last %>%
  group_by(denekId, group, phase) %>%
  summarise(mean_yatirim = mean(yatirim, na.rm = TRUE)) %>%
  pivot_wider(names_from = phase, values_from = mean_yatirim, names_prefix = "phase")

# Compute investment change between phases
subject_phase_summary <- subject_phase_summary %>%
  mutate(Change_P2_P3 = phase3 - phase2)

# Print the summary
print(subject_phase_summary)

# Compare mean investment change by group
group_change_summary <- subject_phase_summary %>%
  group_by(group) %>%
  summarise(mean_change = mean(Change_P2_P3, na.rm = TRUE),
            sd_change = sd(Change_P2_P3, na.rm = TRUE))

print(group_change_summary)

#### FIGURES ######
library(broom.mixed)
library(ggplot2)

# Custom labels (optional)
labels <- c(
  "group1" = "SZ vs. HC",
  "phase2" = "Phase 2 vs. Phase 1",
  "phase3" = "Phase 3 vs. Phase 1",
  "group1:phase2" = "Group x Phase 2",
  "group1:phase3" = "Group x Phase 3",
  "sex" = "Sex",
  "doi" = "Illness Duration"
)

# Run the function on your model
plot_odds_ratios(model_simple, custom_labels = labels, TITLE=" (Binomial GLMM)")



labels <- c(
  "Groupsz" = "SZ vs. HC",
  "Task2" = "Phase 2 vs. Phase 1",
  "Task3" = "Phase 3 vs. Phase 1",
  "Groupsz:Task2" = "Group x Phase 2",
  "Groupsz:Task3" = "Group x Phase 3",
  "SexM" = "M vs. F",
  "Groupsz:SexM" = "Group x Sex",
  "DoI" = "Illness Duration"
)

plot_prediction_effects(lognormal_model,custom_labels = labels,TITLE = " (LogNormal GLMM)")

custom_labels <- c(
  "GroupSZ" = "SZ vs. HC",
  "Task2" = "Phase 2 vs. Phase 1",
  "Task3" = "Phase 3 vs. Phase 1",
  "SexM" = "M vs. F",
  "GroupSZ:SexM" = "Group x Sex",
  "DoI_z" = "Illness Duration"
)

plot_prediction_effects(fit_glmm, exclude_intercept = TRUE, custom_labels = custom_labels, 
                        TITLE = "Learning Rate Effects with 95% CI (Logit Gaussian GLMM)",
                        XLAB = "Multiplicative Effect on Raw Learning Rate")




