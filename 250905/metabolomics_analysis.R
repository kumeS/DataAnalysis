# Comprehensive Metabolomics Analysis Workflow
# Analysis Date: 2025-09-05
# Data Source: fasting.csv

# Load required libraries
suppressMessages({
  library(readr)
  library(dplyr) 
  library(ggplot2)
  library(pheatmap)
  library(corrplot)
  library(RColorBrewer)
})

cat("=== Comprehensive Metabolomics Analysis Workflow ===\n")
cat("Starting analysis...\n\n")

# Read data with semicolon separator (detected from file inspection)
tryCatch({
  data <- read_csv2("fasting.csv")
  cat("Data loaded successfully with semicolon separator\n")
}, error = function(e) {
  cat("Error reading CSV file:", e$message, "\n")
  cat("Trying comma separator...\n")
  data <<- read_csv("fasting.csv")
})

# Data overview
cat("Data dimensions:", dim(data), "\n")
cat("Sample types found:\n")
print(data[,1])

# Extract numeric data (all columns except first which contains sample IDs)
numeric_data <- data[, -1]
numeric_data <- sapply(numeric_data, as.numeric)
rownames(numeric_data) <- data[[1]]

cat("Numeric data shape:", dim(numeric_data), "\n")

# Basic statistics
summary_stats <- data.frame(
  Metabolite = colnames(numeric_data),
  Mean = colMeans(numeric_data, na.rm = TRUE),
  SD = apply(numeric_data, 2, sd, na.rm = TRUE),
  Min = apply(numeric_data, 2, min, na.rm = TRUE),
  Max = apply(numeric_data, 2, max, na.rm = TRUE),
  Median = apply(numeric_data, 2, median, na.rm = TRUE),
  Q25 = apply(numeric_data, 2, quantile, 0.25, na.rm = TRUE),
  Q75 = apply(numeric_data, 2, quantile, 0.75, na.rm = TRUE)
)

# Save summary statistics
write.csv(summary_stats, "summary_statistics.csv", row.names = FALSE)
cat("Summary statistics saved to summary_statistics.csv\n")

# PCA Analysis
cat("\nPerforming PCA analysis...\n")
# Replace NAs with 0 and scale data
numeric_data_clean <- numeric_data
numeric_data_clean[is.na(numeric_data_clean)] <- 0
pca_result <- prcomp(numeric_data_clean, scale. = TRUE)

# PCA plot
png("pca_analysis.png", width = 1200, height = 900)
par(mfrow = c(2, 2))

# Main PCA plot
sample_colors <- ifelse(grepl("normal", rownames(numeric_data_clean), ignore.case = TRUE), "red", "blue")
plot(pca_result$x[,1], pca_result$x[,2], 
     col = sample_colors, pch = 19, cex = 1.5,
     xlab = paste0("PC1 (", round(summary(pca_result)$importance[2,1]*100, 1), "% variance)"),
     ylab = paste0("PC2 (", round(summary(pca_result)$importance[2,2]*100, 1), "% variance)"),
     main = "PCA Analysis - Sample Distribution")
text(pca_result$x[,1], pca_result$x[,2], rownames(numeric_data_clean), pos = 3, cex = 0.8)
grid(TRUE)
legend("topright", legend = c("Normal", "Fasting"), col = c("red", "blue"), pch = 19)

# Variance explained
var_explained <- summary(pca_result)$importance[2, 1:10]
plot(1:10, cumsum(var_explained), type = "b", pch = 19,
     xlab = "Principal Component", ylab = "Cumulative Variance Explained",
     main = "PCA Variance Explained")
grid(TRUE)

# Top PC1 loadings
pc1_loadings <- sort(abs(pca_result$rotation[,1]), decreasing = TRUE)[1:20]
barplot(pc1_loadings, las = 2, cex.names = 0.7,
        main = "Top 20 PC1 Loadings", ylab = "Absolute Loading")

# Top PC2 loadings  
pc2_loadings <- sort(abs(pca_result$rotation[,2]), decreasing = TRUE)[1:20]
barplot(pc2_loadings, las = 2, cex.names = 0.7,
        main = "Top 20 PC2 Loadings", ylab = "Absolute Loading")

dev.off()
cat("PCA analysis saved to pca_analysis.png\n")

# Correlation Analysis
cat("Performing correlation analysis...\n")
cor_matrix <- cor(numeric_data_clean, use = "complete.obs")

# Find high correlations
high_corr_pairs <- data.frame()
for(i in 1:(ncol(cor_matrix)-1)) {
  for(j in (i+1):ncol(cor_matrix)) {
    corr_val <- cor_matrix[i,j]
    if(abs(corr_val) > 0.7) {
      high_corr_pairs <- rbind(high_corr_pairs, data.frame(
        Metabolite1 = colnames(cor_matrix)[i],
        Metabolite2 = colnames(cor_matrix)[j], 
        Correlation = corr_val
      ))
    }
  }
}
high_corr_pairs <- high_corr_pairs[order(-abs(high_corr_pairs$Correlation)),]
write.csv(high_corr_pairs, "high_correlations.csv", row.names = FALSE)
cat("Found", nrow(high_corr_pairs), "high correlation pairs (>0.7)\n")

# Correlation heatmap (top 50 most variable metabolites)
top_var_metabolites <- names(sort(apply(numeric_data_clean, 2, var), decreasing = TRUE)[1:50])
cor_subset <- cor_matrix[top_var_metabolites, top_var_metabolites]

png("correlation_heatmap.png", width = 1200, height = 1200)
pheatmap(cor_subset, 
         color = colorRampPalette(c("blue", "white", "red"))(100),
         main = "Metabolite Correlation Matrix (Top 50 Most Variable)",
         fontsize = 8)
dev.off()
cat("Correlation heatmap saved to correlation_heatmap.png\n")

# Differential Analysis
cat("Performing differential analysis...\n")
normal_idx <- grep("normal", rownames(numeric_data_clean), ignore.case = TRUE)
fasting_idx <- grep("fasting", rownames(numeric_data_clean), ignore.case = TRUE)

cat("Normal samples:", length(normal_idx), "\n")
cat("Fasting samples:", length(fasting_idx), "\n")

if(length(normal_idx) > 0 & length(fasting_idx) > 0) {
  diff_results <- data.frame()
  
  for(i in 1:ncol(numeric_data_clean)) {
    normal_values <- numeric_data_clean[normal_idx, i]
    fasting_values <- numeric_data_clean[fasting_idx, i]
    
    # T-test
    if(length(normal_values) >= 2 & length(fasting_values) >= 2) {
      ttest <- t.test(normal_values, fasting_values)
      
      normal_mean <- mean(normal_values, na.rm = TRUE)
      fasting_mean <- mean(fasting_values, na.rm = TRUE)
      fold_change <- ifelse(normal_mean > 0, fasting_mean / normal_mean, NA)
      
      diff_results <- rbind(diff_results, data.frame(
        Metabolite = colnames(numeric_data_clean)[i],
        Normal_Mean = normal_mean,
        Fasting_Mean = fasting_mean,
        Fold_Change = fold_change,
        Log2_FC = ifelse(fold_change > 0, log2(fold_change), NA),
        T_Statistic = ttest$statistic,
        P_Value = ttest$p.value,
        Significant = ttest$p.value < 0.05
      ))
    }
  }
  
  diff_results <- diff_results[order(diff_results$P_Value),]
  write.csv(diff_results, "differential_analysis_results.csv", row.names = FALSE)
  
  # Volcano plot
  png("volcano_plot.png", width = 1000, height = 800)
  plot_data <- diff_results[!is.na(diff_results$Log2_FC) & !is.na(diff_results$P_Value),]
  
  colors <- ifelse(plot_data$P_Value < 0.05 & abs(plot_data$Log2_FC) > 1, "red",
                  ifelse(plot_data$P_Value < 0.05, "orange", "gray"))
  
  plot(plot_data$Log2_FC, -log10(plot_data$P_Value), 
       col = colors, pch = 19, 
       xlab = "Log2 Fold Change (Fasting/Normal)",
       ylab = "-Log10 P-Value",
       main = "Volcano Plot: Normal vs Fasting")
  
  abline(h = -log10(0.05), lty = 2, col = "black")
  abline(v = c(-1, 1), lty = 2, col = "black") 
  grid(TRUE)
  
  dev.off()
  
  cat("Differential analysis completed.\n")
  cat("Significant metabolites (p<0.05):", sum(diff_results$Significant), "\n")
}

# Metabolite concentration heatmap
cat("Creating metabolite concentration heatmap...\n")
top_var_data <- numeric_data_clean[, top_var_metabolites]

# Log transform for better visualization
log_data <- log2(top_var_data + 1e-6)

png("metabolite_heatmap.png", width = 1500, height = 800)
pheatmap(log_data,
         scale = "row",
         color = colorRampPalette(c("blue", "white", "yellow"))(100),
         main = "Metabolite Concentration Heatmap (Top 50 Most Variable)",
         fontsize = 8,
         fontsize_row = 8,
         fontsize_col = 6)
dev.off()
cat("Metabolite heatmap saved to metabolite_heatmap.png\n")

# Generate comprehensive report
cat("Generating analysis report...\n")

report_lines <- c(
  "# Metabolomics Analysis Report",
  "",
  paste("**Analysis Date:**", Sys.Date()),
  "**Data Source:** fasting.csv",
  "",
  "## Data Overview",
  paste("- **Dimensions:**", nrow(numeric_data), "samples ×", ncol(numeric_data), "metabolites"),
  "- **Sample Types:** Normal control and 12h fasting conditions", 
  "- **Data Type:** Metabolite concentration measurements",
  "",
  "## Data Quality Assessment",
  paste("- **Missing values:**", sum(is.na(numeric_data)), "/", length(numeric_data), 
        paste0("(", round(sum(is.na(numeric_data))/length(numeric_data)*100, 2), "%)")),
  paste("- **Data completeness:**", round(100 - sum(is.na(numeric_data))/length(numeric_data)*100, 2), "%"),
  "",
  "## Statistical Summary", 
  paste("- **Concentration range:**", sprintf("%.6f", min(summary_stats$Mean)), "to", sprintf("%.6f", max(summary_stats$Mean))),
  paste("- **Most variable metabolites:**", paste(head(summary_stats$Metabolite[order(-summary_stats$SD)], 3), collapse = ", ")),
  "",
  "## Principal Component Analysis Results",
  paste("- **PC1 variance explained:**", paste0(round(summary(pca_result)$importance[2,1]*100, 1), "%")),
  paste("- **PC2 variance explained:**", paste0(round(summary(pca_result)$importance[2,2]*100, 1), "%")),
  paste("- **Total variance explained (PC1+PC2):**", paste0(round(sum(summary(pca_result)$importance[2,1:2])*100, 1), "%")),
  "",
  "## Correlation Analysis Results",
  paste("- **High correlations (>0.7):**", nrow(high_corr_pairs), "metabolite pairs identified"),
  ifelse(nrow(high_corr_pairs) > 0, 
         paste("- **Strongest correlation:**", sprintf("%.3f", high_corr_pairs$Correlation[1]), 
               "between", substr(high_corr_pairs$Metabolite1[1], 1, 30), "and", substr(high_corr_pairs$Metabolite2[1], 1, 30)),
         ""),
  ""
)

if(exists("diff_results") && nrow(diff_results) > 0) {
  diff_lines <- c(
    "## Differential Analysis Results (Normal vs Fasting)",
    paste("- **Total metabolites analyzed:**", nrow(diff_results)),
    paste("- **Significantly different metabolites (p<0.05):**", sum(diff_results$Significant, na.rm = TRUE)),
    paste("- **Upregulated in fasting:**", sum(diff_results$Significant & diff_results$Log2_FC > 0, na.rm = TRUE)),
    paste("- **Downregulated in fasting:**", sum(diff_results$Significant & diff_results$Log2_FC < 0, na.rm = TRUE)),
    paste("- **Most significant metabolite:**", substr(diff_results$Metabolite[1], 1, 50), 
          paste0("(p=", sprintf("%.2e", diff_results$P_Value[1]), ")")),
    ""
  )
  report_lines <- c(report_lines, diff_lines)
}

final_lines <- c(
  "## Generated Files",
  "- `pca_analysis.png` - Principal Component Analysis plots",
  "- `correlation_heatmap.png` - Metabolite correlation visualization",
  "- `metabolite_heatmap.png` - Concentration heatmap of top variable metabolites",
  "- `volcano_plot.png` - Differential analysis volcano plot",
  "- `summary_statistics.csv` - Statistical summary of all metabolites", 
  "- `high_correlations.csv` - List of highly correlated metabolite pairs",
  "- `differential_analysis_results.csv` - Complete differential analysis results",
  "- `analysis_report.md` - This comprehensive report",
  "",
  "## Interpretation & Insights",
  "",
  "### PCA Insights",
  "The PCA analysis reveals the main sources of metabolic variation between normal and fasting states.",
  "The first two principal components capture the primary metabolic differences, helping identify", 
  "which metabolites contribute most to the distinction between conditions.",
  "",
  "### Correlation Patterns", 
  "The correlation analysis identifies metabolites that show coordinated changes, potentially indicating:",
  "- Shared metabolic pathways",
  "- Co-regulated metabolites", 
  "- Technical correlations in measurement",
  "",
  "### Differential Analysis",
  "The comparison between normal and fasting states reveals metabolites that show significant changes",
  "during the fasting period. These could represent:",
  "- Metabolic adaptations to fasting",
  "- Biomarkers of fasting state", 
  "- Key metabolites in energy metabolism",
  "",
  "## Conclusion", 
  "This comprehensive metabolomics analysis provides insights into the metabolic changes associated",
  "with 12-hour fasting. The results identify key metabolites and patterns that distinguish fasting",
  "from normal metabolic states, which may be valuable for understanding metabolic regulation and",
  "identifying potential biomarkers.",
  "",
  "---",
  "*Analysis performed with R-based metabolomics workflow*"
)

report_lines <- c(report_lines, final_lines)

writeLines(report_lines, "analysis_report.md")

cat("\n=== Analysis Complete! ===\n")
cat("All results saved to current directory.\n")
cat("Generated files:\n")
cat("- pca_analysis.png\n")
cat("- correlation_heatmap.png\n") 
cat("- metabolite_heatmap.png\n")
cat("- volcano_plot.png\n")
cat("- summary_statistics.csv\n")
cat("- high_correlations.csv\n")
cat("- differential_analysis_results.csv\n")
cat("- analysis_report.md\n")