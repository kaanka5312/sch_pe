library(brms)
library(R.matlab)
library(tidyverse); library(reshape2)
#setwd("/Users/kaankeskin/projects/sch_pe/")
# Microsoft

# Data Preparation 
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
alpha_mat <- readMat("./results/models/alpha_matrix.mat")
subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 44)))

dat <- readMat("./data/processed/normalized_pe_array2.mat")

convert_to_long <- function(dat, group,subj_table, exclude=TRUE) {
  # Extract PE matrix (first 60 columns) and group information (column 61)
  if (exclude) dat <- dat[-c(9, 44), ]
  
  pe_mat <- dat[,1:60]
  group <- group
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

alpha_long <- convert_to_long(alpha_mat$alpha.matrix, dat$merged.matrix[-c(9, 44),61], subj_table, TRUE)
alpha_long$PE_logit <- qlogis(alpha_long$PE)  # qlogis = logit function


# Model fitting 
fit <- brm(
  formula = PE ~ Task * Group + (1 + Task | Subject),
  family =  Beta(), 
  data = alpha_long,
  prior = c(
    prior(normal(0, 1), class = "b"),
    prior(cauchy(0, 1), class = "sd"),
    prior(lkj(2), class = "cor")  # regularizing prior for random slopes
  ),
  chains = 4,
  cores = 4,
  iter = 2000
)
