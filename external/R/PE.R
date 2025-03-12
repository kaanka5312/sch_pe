# Loading libraries
library(R.matlab); library(tidyverse)
#setwd("/Users/kaankeskin/projects/sch_pe/")
# Microsoft
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
#
dat <- readMat("./data/processed/pe_array2.mat")
subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 44)))

#dat <- readMat("/Users/kaankeskin/projects/sch_pe/data/processed/normalized_pe_array.mat")
pe_mat <- dat$merged.matrix[,1:60]
group <- factor(ifelse(dat$merged.matrix[,61],"sz","hc"))
task <- factor(rep(c(1,2,3),each=20))
sex <- factor(ifelse(subj_table$sex,"M","F"))
library(reshape2)

# Convert pe_mat to a data frame
pe_df <- as.data.frame(pe_mat)

# Add Subject IDs
pe_df$Subject <- 1:51  # Assign a unique ID to each subject

# Reshape to long format
long_pe <- melt(pe_df, id.vars = "Subject", variable.name = "Trial", value.name = "PE")

# Add Group information
long_pe$Group <- rep(group, times = ncol(pe_mat))  # Repeat for each column

# Add Task information
long_pe$Task <- rep(task, each = nrow(pe_mat))  # Assign the correct task for each trial

# Add Sex information
long_pe$Sex <- rep(sex, times = ncol(pe_mat))  # Assign the correct task for each trial

# Check structure
str(long_pe)
head(long_pe)

anova_model <- aov(PE ~ Group * Task * Sex + Error(Subject/Task), data = long_pe)
summary(anova_model)

library(emmeans)

# Estimated Marginal Means (EMMs) for Task within each Group
task_emmeans <- emmeans(anova_model, pairwise ~ Task | Group, adjust = "bonferroni")
# Show pairwise comparisons
task_emmeans

long_pe %>% group_by(Task) %>% rstatix::t_test

###############################
#=#= B E H A V I O R A L=#=#=#=
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

T_raw <- read.csv("./data/raw/response.csv")
T <- T_raw[T_raw$denekId %in% subj_table$task.id,]

# Just for control. Shoul equal to 51
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

model <- glmer(
  yatirim ~ group * phase + (1 | denekId),
  data = T_last,
  family = binomial(link = "logit")
)

model <- glm(
  yatirim ~ group * phase ,
  data = T_last,
  family = binomial(link = "logit")
)

summary(model)

# Create a 2x2 table for each group
tables <- by(T_last, T_last$group, function(sub_df) table(yatirim = sub_df$yatirim, rakip = sub_df$rakip))

# Display tables
tables

T_last <- T_last %>%
  arrange(denekId, sayac) %>%  # Ensure data is ordered by subject and trial
  group_by(denekId) %>%
  mutate(cum_rakip = cumsum(lag(rakip, default = 0))) %>%  # Cumulative sum of previous rakip values
  ungroup()

