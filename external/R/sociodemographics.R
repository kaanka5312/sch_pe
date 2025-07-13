## This script id for sociodemographic table of the study ##
library(tableone)
library(readxl)
library(tidyverse)

# Windows
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")

# Macos 
setwd("/Users/kaankeskin/projects/sch_pe/")
#dat <- read_xlsx("./data/raw/DataElif.xlsx")

subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 44)))

# Education Years will be added 
varsToNum <- c("age", "ap", "AgeOfOnset", "DoI", "education", "PANSS.Total")
# First trim whitespace
subj_table[varsToNum] <- lapply(subj_table[varsToNum], function(x) as.numeric(trimws(x)))

varsToFactor <- c("marriage", "group", "sex")
subj_table[varsToFactor] <- lapply(subj_table[varsToFactor], function(x) as.factor(trimws(x)))

# For transforming the names
subj_table$sex <- factor(ifelse(subj_table$sex==1,"M", "F"))
subj_table$group <- factor(ifelse(subj_table$group==1,"SZ", "HC"))


tab <- CreateTableOne(vars = c("age", "ap", "AgeOfOnset", "DoI", "education", "PANSS.Total"),
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
  "sex = M (%)" = "sex = M (%)",
  "education (mean (SD))" = "Education Years (mean (SD))",
  "PANSS.Total (mean (SD))" = "Total PANSS (mean (SD)) "
)

tab_df$Variable <- custom_labels[tab_df$Variable]

tab_df <- tab_df[, c("Variable", setdiff(names(tab_df), "Variable"))]

# Reordering the rows according to clinical and demographics
tab_df <- tab_df %>% slice(c(1,2,6,4,5,3,7)
                           )%>% select(Variable, Schizophrenia, Control, p)

# REMOVING THE CLINICAL MEASURE COMPARISON #
tab_df[4:7,3] <- rep("",4)
tab_df[4:7,4] <- rep("",4)

# Manually adding subheaders
df <- bind_rows(
  tibble(Variable = "Demographics", Schizophrenia = NA, Control = NA, p = NA),
  tab_df[1:3, ],
  tibble(Variable = "Clinical measures", Schizophrenia = NA, Control = NA, p = NA),
  tab_df[4:nrow(tab_df), ]
)

library(flextable)
ft <- flextable(df)

# Merge and style subheader rows
ft <- merge_h(ft, i = c(1, 5))  # rows 1 and 5 are subheaders
ft <- bold(ft, i = c(1, 5))
ft <- italic(ft, i = c(1, 5))
ft <- align(ft, i = c(1, 5), align = "left", part = "body")

ft <- ft |>
  autofit() |>
  theme_vanilla()

library(officer)

# Create a Word document
doc <- read_docx()

# Add title (optional)
doc <- body_add_par(doc, "Table 1. Demographic and Clinical Characteristics", style = "heading 2")

# Add the flextable
doc <- body_add_flextable(doc, ft)

# Save the document
print(doc, target = "./writing/table1_demographics.docx")