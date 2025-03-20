# Loading libraries
library(R.matlab); library(tidyverse); library(reshape2)
setwd("/Users/kaankeskin/projects/sch_pe/")
# Microsoft
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
#
dat <- list(readMat("./data/processed/pe_array2.mat"), # Cemre RW PE
            readMat("./data/processed/x2_array.mat"), # HGF X2
            readMat("./data/processed/x3_array.mat"), # HGF X3
            readMat("./data/processed/x2_pe_array.mat"), # HGF low level PE
            readMat("./data/processed/x3_pe_array.mat"), # HGF high level PE
            readMat("./data/processed/alfa2_array.mat"), # learning rate level 2
            readMat("./data/processed/alfa3_array.mat"), # learning rate level 3
            readMat("./data/processed/rw_pe.mat") # RW model PE from TAPAS
)

subj_table <- read.csv("./data/raw/subjects_list.csv")
#subj_table <- subset(subj_table, !(subj %in% c(9, 44)))
#dat <- readMat("/Users/kaankeskin/projects/sch_pe/data/processed/normalized_pe_array.mat")

convert_to_long <- function(dat, subj_table) {
  # Extract PE matrix (first 60 columns) and group information (column 61)
  pe_mat <- dat$merged.matrix[,1:60]
  group <- factor(ifelse(dat$merged.matrix[,61], "sz", "hc"))
  task <- factor(rep(1:3, each = 20))  # Assuming 3 tasks with 20 trials each
  sex <- factor(ifelse(subj_table$sex, "M", "F"))
  
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
long_pe_list[[1]]$PE_shifted <- long_pe_list[[1]]$PE + abs(min(long_pe_list[[1]]$PE)) + 0.01

library(lme4)
gamma_model <- glmer(PE_shifted ~ Group + Task + (1 | Subject), 
                     data = long_pe_list[[1]], 
                     family = Gamma(link = "log"),
                     control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e5)))
summary(gamma_model)

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

# Investigating the table 
# DO NOT FORGET ! THIS DOESNT CONSIDERED THE REPEATED MEASURE DESIGN SO CONTINUE
# TO GLM MODEL
# Create a 2x2 table for each group
tables <- by(T_last, T_last$group, function(sub_df) table(yatirim = sub_df$yatirim, rakip = sub_df$rakip))

# Display tables
tables

# Addition of the interaction doesn't improve the model
model_simple <- glmer(yatirim ~ group + phase + (1 | denekId), 
                      data = T_last, 
                      family = binomial(link = "logit"))

summary(model_simple)


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


plot(density(long_pe_list[[4]]$PE))
max(long_pe_list[[4]]$PE)
