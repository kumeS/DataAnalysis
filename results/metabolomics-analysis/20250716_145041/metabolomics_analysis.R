# Load required libraries
library(readr)
library(dplyr)
library(ggplot2)
library(pheatmap)
library(corrplot)

# Read data (CSV with comma separator)
tryCatch({
  data <- read_csv("data/fasting.csv")
  cat("Data loaded successfully\n")
}, error = function(e) {
  cat("Error reading CSV file:", e$message, "\n")
  cat("Trying different separator...\n")
  data <<- read_csv2("data/fasting.csv")
})

# Basic exploration
cat("Data dimensions:", dim(data), "\n")
print(summary(data))

# Save basic info
write.csv(summary(data), "summary_stats.csv")

# PCA analysis
numeric_data <- data %>% select_if(is.numeric)

# Check if we have enough numeric data
if (ncol(numeric_data) > 1 && nrow(numeric_data) > 1) {
  pca_result <- prcomp(numeric_data, scale. = TRUE)
  
  # PCA plot
  png("pca_plot.png", width = 800, height = 600)
  biplot(pca_result, main = "PCA Analysis")
  dev.off()
  
  # Correlation matrix
  cor_matrix <- cor(numeric_data, use = "complete.obs")
  png("correlation_matrix.png", width = 800, height = 600)
  corrplot(cor_matrix, method = "circle")
  dev.off()
  
  # Heatmap (use correlation matrix for visualization)
  png("heatmap.png", width = 800, height = 600)
  pheatmap(cor_matrix, main = "Metabolite Correlation Heatmap")
  dev.off()
} else {
  cat("Warning: Not enough numeric data for analysis\n")
  # Create empty plots as placeholders
  png("pca_plot.png", width = 800, height = 600)
  plot(1, type="n", main="PCA Analysis - Not enough data")
  dev.off()
  
  png("correlation_matrix.png", width = 800, height = 600)
  plot(1, type="n", main="Correlation Matrix - Not enough data")
  dev.off()
  
  png("heatmap.png", width = 800, height = 600)
  plot(1, type="n", main="Heatmap - Not enough data")
  dev.off()
}

# Create detailed report
cat("# Metabolomics Analysis Report\n\n", file = "analysis_report.md")
cat("**Analysis Date:**", Sys.Date(), "\n", file = "analysis_report.md", append = TRUE)
cat("**Data Source:** data/fasting.csv\n\n", file = "analysis_report.md", append = TRUE)

cat("## Data Overview\n", file = "analysis_report.md", append = TRUE)
cat("- **Dimensions:**", dim(data)[1], "rows x", dim(data)[2], "columns\n", file = "analysis_report.md", append = TRUE)
cat("- **Numeric columns:**", ncol(numeric_data), "\n", file = "analysis_report.md", append = TRUE)
cat("- **Data type:** Metabolomics concentration data\n\n", file = "analysis_report.md", append = TRUE)

# Data quality assessment
if (ncol(numeric_data) > 1) {
  missing_data <- sum(is.na(numeric_data))
  total_values <- nrow(numeric_data) * ncol(numeric_data)
  missing_percent <- round(missing_data / total_values * 100, 2)
  
  cat("## Data Quality Assessment\n", file = "analysis_report.md", append = TRUE)
  cat("- **Missing values:**", missing_data, "out of", total_values, "(", missing_percent, "%)\n", file = "analysis_report.md", append = TRUE)
  cat("- **Data completeness:**", round(100 - missing_percent, 2), "%\n", file = "analysis_report.md", append = TRUE)
  
  # Statistical summary
  cat("\n## Statistical Summary\n", file = "analysis_report.md", append = TRUE)
  cat("- **Mean concentration range:**", round(min(apply(numeric_data, 2, mean, na.rm=TRUE)), 6), 
      "to", round(max(apply(numeric_data, 2, mean, na.rm=TRUE)), 6), "\n", file = "analysis_report.md", append = TRUE)
  cat("- **Standard deviation range:**", round(min(apply(numeric_data, 2, sd, na.rm=TRUE)), 6), 
      "to", round(max(apply(numeric_data, 2, sd, na.rm=TRUE)), 6), "\n", file = "analysis_report.md", append = TRUE)
}

cat("\n## Analysis Results\n", file = "analysis_report.md", append = TRUE)
if (ncol(numeric_data) > 1 && nrow(numeric_data) > 1) {
  cat("- ✅ PCA analysis completed successfully\n", file = "analysis_report.md", append = TRUE)
  cat("- ✅ Correlation matrix generated\n", file = "analysis_report.md", append = TRUE)
  cat("- ✅ Heatmap visualization created\n", file = "analysis_report.md", append = TRUE)
  
  if (exists("pca_result")) {
    # PCA insights
    variance_explained <- round(summary(pca_result)$importance[2,1:2] * 100, 2)
    cat("- **PCA PC1 variance explained:**", variance_explained[1], "%\n", file = "analysis_report.md", append = TRUE)
    cat("- **PCA PC2 variance explained:**", variance_explained[2], "%\n", file = "analysis_report.md", append = TRUE)
    cat("- **Total variance explained (PC1+PC2):**", sum(variance_explained), "%\n", file = "analysis_report.md", append = TRUE)
  }
  
  if (exists("cor_matrix")) {
    # Correlation insights
    high_corr <- sum(abs(cor_matrix) > 0.7 & cor_matrix != 1, na.rm=TRUE) / 2
    cat("- **High correlations (>0.7):**", high_corr, "metabolite pairs\n", file = "analysis_report.md", append = TRUE)
  }
} else {
  cat("- ⚠️ Insufficient data for statistical analysis\n", file = "analysis_report.md", append = TRUE)
  cat("- ⚠️ Placeholder plots generated\n", file = "analysis_report.md", append = TRUE)
}

cat("\n## Generated Files\n", file = "analysis_report.md", append = TRUE)
cat("- `pca_plot.png` - Principal Component Analysis biplot\n", file = "analysis_report.md", append = TRUE)
cat("- `correlation_matrix.png` - Metabolite correlation heatmap\n", file = "analysis_report.md", append = TRUE)
cat("- `heatmap.png` - Metabolite concentration heatmap\n", file = "analysis_report.md", append = TRUE)
cat("- `summary_stats.csv` - Statistical summary of the data\n", file = "analysis_report.md", append = TRUE)
cat("- `analysis_report.md` - This comprehensive report\n", file = "analysis_report.md", append = TRUE)

cat("\n## Interpretation Notes\n", file = "analysis_report.md", append = TRUE)
cat("This analysis provides insights into metabolite concentration patterns in fasting samples. ", file = "analysis_report.md", append = TRUE)
cat("The PCA analysis reveals the main sources of variation in the metabolite profile, ", file = "analysis_report.md", append = TRUE)
cat("while correlation analysis identifies metabolites that show similar patterns. ", file = "analysis_report.md", append = TRUE)
cat("These results can inform understanding of metabolic states and potential biomarkers.\n", file = "analysis_report.md", append = TRUE)
