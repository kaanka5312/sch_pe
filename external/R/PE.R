# Loading libraries
library(R.matlab); library(tidyverse)

#
dat <- readMat("/Users/kaankeskin/projects/sch_pe/data/processed/pe_array.mat")
#dat <- readMat("/Users/kaankeskin/projects/sch_pe/data/processed/normalized_pe_array.mat")
pe_mat <- dat$merged.matrix[,1:60]
group <- factor(ifelse(dat$merged.matrix[,61],"sz","hc"))
task <- factor(rep(c(1,2,3),each=20))

library(reshape2)

# Convert pe_mat to a data frame
pe_df <- as.data.frame(pe_mat)

# Add Subject IDs
pe_df$Subject <- 1:52  # Assign a unique ID to each subject

# Reshape to long format
long_pe <- melt(pe_df, id.vars = "Subject", variable.name = "Trial", value.name = "PE")

# Add Group information
long_pe$Group <- rep(group, times = ncol(pe_mat))  # Repeat for each column

# Add Task information
long_pe$Task <- rep(task, each = nrow(pe_mat))  # Assign the correct task for each trial

# Check structure
str(long_pe)
head(long_pe)

anova_model <- aov(PE ~ Group * Task + Error(Subject/Task), data = long_pe)
summary(anova_model)

library(emmeans)

# Estimated Marginal Means (EMMs) for Task within each Group
task_emmeans <- emmeans(anova_model, pairwise ~ Task | Group, adjust = "bonferroni")
# Show pairwise comparisons
task_emmeans