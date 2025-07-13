## This script id for sociodemographic table of the study ##
library(tableone)
library(readxl)

# Windows
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")
#dat <- read_xlsx("./data/raw/DataElif.xlsx")

subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 44)))

# Education Years will be added 
varsToNum <- c("age", "ap", "AgeOfOnset", "DoI")
# First trim whitespace
subj_table[varsToNum] <- lapply(subj_table[varsToNum], function(x) as.numeric(trimws(x)))

varsToFactor <- c("marriage", "group", "sex")
subj_table[varsToFactor] <- lapply(subj_table[varsToFactor], function(x) as.factor(trimws(x)))

# For transforming the names
subj_table$sex <- factor(ifelse(subj_table$sex==1,"M", "F"))
subj_table$group <- factor(ifelse(subj_table$group==1,"SZ", "HC"))


tab <- CreateTableOne(vars = c("age", "ap", "AgeOfOnset", "DoI", "sex"),
               strata = "group",
               data = subj_table,
               factorVars = c("sex"),
               smd = TRUE)

tab_print <- print(tab, quote = FALSE, noSpaces = TRUE, printToggle = FALSE)

tab_df <- as.data.frame(tab_print) %>% select(c(1,2,3))
# Rename columns
colnames(tab_df) <- sub("^HC$", "Control", colnames(tab_df))
colnames(tab_df) <- sub("^SZ$", "Schizophrenia", colnames(tab_df))

tab_df$Variable <- rownames(tab_df)
custom_labels <- c(
  "n" = "Number of Subject",
  "age (mean (SD))" = "Age (mean (SD))",
  "ap (mean (SD))" = "CBZ (mean (SD))",
  "AgeOfOnset (mean (SD))" = "Age of Onset (mean (SD))",
  "DoI (mean (SD))" = "Duration of Illness (mean (SD))",
  "sex = M (%)" = "sex = M (%)"
)

tab_df$Variable <- custom_labels[tab_df$Variable]

tab_df <- tab_df[, c("Variable", setdiff(names(tab_df), "Variable"))]

library(flextable)

flextable(tab_df) |>
  autofit() |>
  theme_vanilla()

