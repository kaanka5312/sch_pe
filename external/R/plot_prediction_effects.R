plot_prediction_effects <- function(model, exclude_intercept = TRUE, custom_labels = NULL, TITLE = "") {
  library(broom.mixed)
  library(ggplot2)
  library(dplyr)
  
  # Tidy fixed effects with confidence intervals
  coefs <- broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE)
  
  # Exponentiate to get multiplicative effects on raw PE
  coefs <- coefs %>%
    mutate(
      multiplier = exp(estimate),
      mult_low = exp(conf.low),
      mult_high = exp(conf.high)
    )
  
  # Optionally remove intercept
  if (exclude_intercept) {
    coefs <- coefs[coefs$term != "(Intercept)", ]
  }
  
  # Optionally relabel terms
  if (!is.null(custom_labels)) {
    coefs$term <- factor(coefs$term, levels = coefs$term)
    coefs$term <- dplyr::recode(coefs$term, !!!custom_labels)
  }
  
  # Plot
  p <- ggplot(coefs, aes(x = multiplier, y = term)) +
    geom_point(size = 4) +
    geom_errorbarh(aes(xmin = mult_low, xmax = mult_high), height = 0.2, linewidth = 1.2) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "gray", linewidth = 1) +
    labs(
      x = "Multiplicative Effect on Raw Prediction Error",
      y = "",
      title = paste0("Prediction Error Effects with 95% CI", TITLE)
    ) +
    theme_minimal(base_size = 14) +
    theme(
      axis.text.x = element_text(size = 14),
      axis.text.y = element_text(size = 14),
      axis.title.x = element_text(size = 16, face = "bold"),
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
    )
  
  return(p)
}
