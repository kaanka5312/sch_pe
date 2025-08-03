# Aim of this script to related the PE with personal scores as well as table-2
# that is subject characteristics

library(R.matlab); library(tidyverse); library(reshape2)
#setwd("/Users/kaankeskin/projects/sch_pe/")
# Microsoft
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
dat <- readxl::read_xlsx("./data/raw/DataElif.xlsx")
subj_table <- read.csv("./data/raw/subjects_list.csv")


subj_table <- subj_table[complete.cases(subj_table[, c(
    "PANSS.Total","SANS","CDSS","SCORS.GA","OSCARS.TA","FROGS"
    )]), 
]


varsToNum <- c("age", "ap", "AgeOfOnset", "DoI", "PANSS.Total", 
               "SANS", "CDSS","SCORS.GA","OSCARS.TA","FROGS")
# First trim whitespace
subj_table[varsToNum] <- lapply(subj_table[varsToNum], function(x) as.numeric(trimws(x)))



df_sz <- subj_table[subj_table$group==1, ]
df_sz <- df_sz[order(df_sz$name),]

dat_sz <- dat %>% filter(Dx==1
               ) %>% arrange(NameSurname
               ) %>% filter(!is.na(subj)) 

pe <- readMat("./data/processed/normalized_pe_array2.mat")
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
pe_long <- convert_to_long(pe,subj_table = subj_table)

rmse_summary <- pe_long %>% 
  filter(Subject %in% df_sz$subj) %>%
  group_by(Subject) %>%
  summarise(rmse_PE = sqrt(mean(PE^2)))

df_sz$rmse <- rmse_summary$rmse_PE

dat_sz$`PANSS-Positive` <- as.numeric(dat_sz$`PANSS-Positive`)

dat_sz <- dat_sz %>% filter(!is.na(`PANSS-Positive`)) 
dat_sz$`PANSS-Positive` <- ordered(dat_sz$`PANSS-Positive`,levels=c(7,8,9,10,11))

library(MASS)

model <- polr(`PANSS-Positive` ~ rmse, data = dat_sz, Hess = TRUE)
summary(model)

selected_vars <- c("PANSS.Total", "SANS", "CDSS","SCORS.GA","OSCARS.TA","FROGS")

# Example data
# df <- data.frame(target = ..., var1 = ..., var2 = ..., var3 = ...)

results <- lapply(selected_vars, function(var) {
  test <- cor.test(df_sz$rmse, df_sz[[var]], use = "complete.obs")
  data.frame(
    variable = var,
    correlation = test$estimate,
    p_value = test$p.value
  )
})

cor_df <- do.call(rbind, results)

# Testing are scores statistically different between different sex
library(rstatix);library(tidyverse)

subj_table %>%
  slice(-c(9, 44)) %>%
  filter(group == 1) %>%
  filter(!is.na(PANSS.Total)) %>%
  rstatix::t_test(PANSS.Total ~ sex)

  library(dplyr)

library(tidyr)
library(rstatix)

# Clean and filter the data first
filtered_data <- subj_table %>%
  mutate(
    education = as.numeric(education),
    marriage = as.numeric(marriage)
  ) %>%
  slice(-c(9, 44)) %>%
  filter(group == 1)

# Specify outcome variables you want to test
outcomes <- c("PANSS.Total", "SANS", "CDSS", "SCORS.GA","OSCARS.TA","FROGS")

# Reshape and run t-tests
filtered_data %>%
  select(sex, all_of(outcomes)) %>%
  pivot_longer(cols = -sex, names_to = "variable", values_to = "value") %>%
  drop_na() %>%
  group_by(variable) %>%
  t_test(value ~ sex) %>%
  adjust_pvalue(method = "bonferroni")
