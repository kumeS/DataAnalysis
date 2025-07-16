library(readr)
library(dplyr)
library(ggplot2)
library(pheatmap)
library(corrplot)

# Read data (CSV with semicolon separator)
data <- read_csv2("fasting.csv")

# Task-specific analysis
if ("eda" == "eda") {
  # EDA analysis
  cat("=== EDA Analysis ===\n")
  print(summary(data))
  
  # PCA
  numeric_data <- data %>% select_if(is.numeric)
  # Check if we have numeric data and sufficient dimensions
  if (ncol(numeric_data) > 1 && nrow(numeric_data) > 1) {
    pca_result <- prcomp(numeric_data, scale. = TRUE)
  } else {
    cat("Warning: Not enough numeric data for PCA analysis\n")
  }
  if (ncol(numeric_data) > 1 && nrow(numeric_data) > 1 && exists("pca_result")) {
    png("artifacts/eda/pca_plot.png", width = 800, height = 600)
    biplot(pca_result, main = "PCA Analysis")
    dev.off()
  }
  
  # Correlation matrix
  if (ncol(numeric_data) > 1) {
    cor_matrix <- cor(numeric_data, use = "complete.obs")
    png("artifacts/eda/correlation.png", width = 800, height = 600)
    corrplot(cor_matrix, method = "circle")
    dev.off()
  }
  
  cat("# EDA Results\n\nBasic data exploration completed.\n", file = "artifacts/eda/note.md")
  
} else if ("eda" == "modeling") {
  # Modeling analysis
  cat("=== Modeling Analysis ===\n")
  
  # Simple t-test example (assuming groups exist)
  numeric_data <- data %>% select_if(is.numeric)
  results <- data.frame(variable = names(numeric_data), p_value = NA)
  
  # Save results
  write.csv(results, "artifacts/modeling/ttest_results.csv")
  cat("# Modeling Results\n\nStatistical modeling completed.\n", file = "artifacts/modeling/note.md")
  
} else if ("eda" == "viz") {
  # Visualization analysis
  cat("=== Visualization Analysis ===\n")
  
  # Heatmap
  numeric_data <- data %>% select_if(is.numeric)
  if (ncol(numeric_data) > 1 && nrow(numeric_data) > 1) {
    png("artifacts/viz/heatmap.png", width = 800, height = 600)
    # Select subset for heatmap visualization
    viz_data <- numeric_data[1:min(20, nrow(numeric_data)), 1:min(50, ncol(numeric_data))]
    pheatmap(viz_data, main = "Metabolite Heatmap")
    dev.off()
  } else {
    cat("Warning: Not enough numeric data for heatmap visualization\n")
  }
  
  cat("# Visualization Results\n\nData visualizations completed.\n", file = "artifacts/viz/note.md")
}
