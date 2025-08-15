## This script id for sociodemographic table of the study ##
library(tableone)
library(readxl)
library(tidyverse)

# Windows
setwd("C:/Users/kaank/OneDrive/Belgeler/GitHub/sch_pe/")

# Macos 
# setwd("/Users/kaankeskin/projects/sch_pe/")
#dat <- read_xlsx("./data/raw/DataElif.xlsx")

subj_table <- read.csv("./data/raw/subjects_list.csv")
subj_table <- subset(subj_table, !(subj %in% c(9, 39, 44, 74)))

# Education Years will be added 
varsToNum <- c("age", "ap", "AgeOfOnset", "DoI", "education", "PANSS.Total", "PANSS.Positive", "PANSS.Negative", "PANSS.General", "SCORS.GA", "FROGS")
# First trim whitespace
subj_table[varsToNum] <- lapply(subj_table[varsToNum], function(x) as.numeric(trimws(x)))

varsToFactor <- c("marriage", "group", "sex")
subj_table[varsToFactor] <- lapply(subj_table[varsToFactor], function(x) as.factor(trimws(x)))

# For transforming the names
subj_table$sex <- factor(ifelse(subj_table$sex==1,"M", "F"))
subj_table$group <- factor(ifelse(subj_table$group==1,"SZ", "HC"))

# Define variables
vars <- c("age", "ap", "AgeOfOnset", "DoI", "education", "sex",
          "PANSS.Total", "PANSS.Positive", "PANSS.Negative", "PANSS.General", "SCORS.GA", "FROGS")
group_var <- "group"

tab <- CreateTableOne(vars = vars,
               strata = group_var,
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
  "PANSS.Total (mean (SD))" = "PANSS Total (mean (SD)) ",
  "PANSS.Positive (mean (SD))" = "PANSS Positive (mean (SD))",
  "PANSS.Negative (mean (SD))" = "PANSS Negative (mean (SD))",
  "PANSS.General (mean (SD))" = "PANSS General (mean (SD))",
  "SCORS.GA (mean (SD))" = "SCORS-GA (mean (SD))",
  "FROGS (mean (SD))" = "FROGS (mean (SD))"
)

tab_df$Variable <- custom_labels[tab_df$Variable]

tab_df <- tab_df[, c("Variable", setdiff(names(tab_df), "Variable"))]

# Reordering the rows according to clinical and demographics
tab_df <- tab_df %>% slice(c(1,7,2,6,4,5,3,8,9,10,11,12,13)
                           )%>% select(Variable, Schizophrenia, Control, p)

# REMOVING THE CLINICAL MEASURE COMPARISON #
tab_df[5:13,3] <- rep("",9)
tab_df[5:13,4] <- rep("",9)


### FOR ADDING TEST t(df) ###
# ---- Copy???paste all of this ----
suppressPackageStartupMessages({
  library(tableone)
  library(dplyr)
})

# Helper to derive the parent variable name from TableOne rownames robustly
.extract_var <- function(rn) {
  rn <- trimws(rn)
  rn <- sub("\\s*=.*$", "", rn)        # drop " = level"
  rn <- sub("\\s*\\(.*\\)$", "", rn)   # drop trailing " ( ... )"
  rn <- trimws(rn)
  rn
}

# Add a "Test (stat)" column to a printed TableOne:
# - Continuous: Welch t-test [t(df)=..] for 2 groups; Welch ANOVA [F(df1, df2)=..] for >2 groups
# - Categorical: Chi-square [X^2(df)=..] or Fisher's exact when expected counts < 5
augment_tableone_with_tests <- function(tab, data, group_var, vars, factorVars = NULL,
                                        fisher_if_needed = TRUE) {
  if (is.null(factorVars)) factorVars <- character(0)
  cont_vars <- setdiff(vars, factorVars)
  cat_vars  <- intersect(vars, factorVars)
  
  # ---- continuous tests ----
  cont_list <- lapply(cont_vars, function(v) {
    d <- data[, c(v, group_var)]
    names(d) <- c("x", "g")
    d <- d[!is.na(d$x) & !is.na(d$g), , drop = FALSE]
    d$g <- as.factor(d$g)
    
    if (!is.numeric(d$x)) {
      return(data.frame(variable = v, test_name = "(non-numeric)", stat = "???", stringsAsFactors = FALSE))
    }
    
    g_levels <- nlevels(d$g)
    if (g_levels <= 1L) {
      data.frame(variable = v, test_name = "(insufficient groups)", stat = "???", stringsAsFactors = FALSE)
    } else if (g_levels == 2L) {
      tt <- stats::t.test(x ~ g, data = d)  # Welch t-test
      data.frame(
        variable  = v,
        test_name = "Welch t-test",
        stat      = sprintf("t(%.1f)=%.2f", unname(tt$parameter), unname(tt$statistic)),
        stringsAsFactors = FALSE
      )
    } else {
      ow  <- stats::oneway.test(x ~ g, data = d)  # Welch ANOVA
      df1 <- unname(ow$parameter[1])
      df2 <- unname(ow$parameter[2])
      data.frame(
        variable  = v,
        test_name = "Welch ANOVA",
        stat      = sprintf("F(%.1f, %.1f)=%.2f", df1, df2, unname(ow$statistic)),
        stringsAsFactors = FALSE
      )
    }
  })
  cont_tests <- if (length(cont_list)) do.call(rbind, cont_list) else
    data.frame(variable = character(), test_name = character(), stat = character())
  
  # ---- categorical tests ----
  cat_list <- lapply(cat_vars, function(v) {
    tabx <- table(data[[v]], data[[group_var]], useNA = "no")
    if (all(dim(tabx) > 1)) {
      chi <- suppressWarnings(stats::chisq.test(tabx, correct = FALSE))
      use_fisher <- isTRUE(fisher_if_needed) && any(chi$expected < 5, na.rm = TRUE)
      if (use_fisher) {
        data.frame(variable = v, test_name = "Fisher's exact", stat = "???", stringsAsFactors = FALSE)
      } else {
        data.frame(
          variable  = v,
          test_name = "Chi-square",
          stat      = sprintf("X^2(%d)=%.2f", unname(chi$parameter), unname(chi$statistic)),
          stringsAsFactors = FALSE
        )
      }
    } else {
      data.frame(variable = v, test_name = "(insufficient levels)", stat = "???", stringsAsFactors = FALSE)
    }
  })
  cat_tests <- if (length(cat_list)) do.call(rbind, cat_list) else
    data.frame(variable = character(), test_name = character(), stat = character())
  
  tests <- dplyr::bind_rows(cont_tests, cat_tests) %>%
    dplyr::mutate(variable = as.character(variable))
  
  # ---- get printable TableOne ----
  printed <- as.data.frame(
    print(tab, smd = TRUE, test = TRUE, quote = FALSE, noSpaces = TRUE, printToggle = FALSE)
  )
  
  # Build a clean variable key from rownames (robust to formatting)
  rn <- rownames(printed)
  printed$variable <- vapply(rn, .extract_var, character(1))
  printed$.row_id  <- ave(seq_len(nrow(printed)), printed$variable, FUN = seq_along)
  
  # ---- join & build the "Test (stat)" column only on the first row of each variable ----
  out <- printed %>%
    dplyr::left_join(tests, by = "variable") %>%
    dplyr::mutate(
      `Test (stat)` = ifelse(
        .row_id == 1,
        ifelse(is.na(test_name) | test_name == "",
               "",
               ifelse(stat == "???",
                      test_name,
                      paste0(test_name, " [", stat, "]"))
        ),
        ""
      )
    ) %>%
    dplyr::select(-.row_id, -variable, -dplyr::any_of(c("test_name", "stat")))
  
  out
}

# ==== Your variables & usage ====
vars <- c("age", "ap", "AgeOfOnset", "DoI", "education", "sex",
          "PANSS.Total", "PANSS.Positive", "PANSS.Negative",
          "PANSS.General", "SCORS.GA", "FROGS")
group_var <- "group"

tab <- CreateTableOne(vars = vars,
                      strata = group_var,
                      data = subj_table,
                      factorVars = c("sex"),
                      smd = TRUE)

tbl_with_stats <- augment_tableone_with_tests(
  tab, data = subj_table, group_var = group_var, vars = vars, factorVars = c("sex")
)

# View it
tab_df$Stat <- 
c("",c(tbl_with_stats[7,6],tbl_with_stats[2,6], tbl_with_stats[6,6]),rep("",9))

# Manually adding subheaders
df <- bind_rows(
  tibble(Variable = "Demographics", Schizophrenia = NA, Control = NA, p = NA),
  tab_df[1:4, ],
  tibble(Variable = "Clinical measures", Schizophrenia = NA, Control = NA, p = NA),
  tab_df[5:nrow(tab_df), ]
)

library(flextable)
ft <- flextable(df)

# Merge and style subheader rows
ft <- merge_h(ft, i = c(1, 6))  # rows 1 and 5 are subheaders
ft <- bold(ft, i = c(1, 6))
ft <- italic(ft, i = c(1, 6))
ft <- align(ft, i = c(1, 6), align = "left", part = "body")

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