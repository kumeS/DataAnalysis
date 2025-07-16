# ローカル代謝物解析スクリプト
# 必要なパッケージのインストール
if (!require("readr")) install.packages("readr")
if (!require("dplyr")) install.packages("dplyr")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("pheatmap")) install.packages("pheatmap")
if (!require("corrplot")) install.packages("corrplot")

library(readr)
library(dplyr)
library(ggplot2)
library(pheatmap)
library(corrplot)

# データ読み込み
cat("📊 Loading fasting.csv...\n")
data <- read_csv("fasting.csv")

# 基本情報
cat("📋 Data dimensions:", dim(data), "\n")
cat("📋 Sample groups:", table(data[[1]]), "\n")

# データの前処理
numeric_data <- data[, -1]  # 最初の列（グループ名）を除外
groups <- data[[1]]

# 基本統計
cat("📈 Basic statistics:\n")
print(summary(numeric_data[,1:5]))  # 最初の5代謝物の統計

# 相関行列の作成
cat("🔗 Creating correlation matrix...\n")
cor_matrix <- cor(numeric_data, use = "complete.obs")

# 相関行列の可視化
png("correlation_matrix.png", width = 800, height = 600)
corrplot(cor_matrix[1:20, 1:20], method = "circle", tl.cex = 0.8)
dev.off()

# PCA分析
cat("🔍 Performing PCA analysis...\n")
pca <- prcomp(numeric_data, scale. = TRUE)

# PCAプロット
png("pca_plot.png", width = 800, height = 600)
pca_data <- data.frame(PC1 = pca$x[,1], PC2 = pca$x[,2], Group = groups)
ggplot(pca_data, aes(x = PC1, y = PC2, color = Group)) +
  geom_point(size = 3) +
  theme_minimal() +
  labs(title = "PCA Analysis: Normal vs 12h Fasting")
dev.off()

# t検定による差異解析
cat("🔬 Performing t-tests...\n")
normal_data <- numeric_data[grepl("normal", groups), ]
fasting_data <- numeric_data[grepl("12h_fasting", groups), ]

# 各代謝物に対するt検定
p_values <- c()
for (i in 1:ncol(numeric_data)) {
  test_result <- t.test(normal_data[,i], fasting_data[,i])
  p_values[i] <- test_result$p.value
}

# 有意な代謝物の特定
significant_metabolites <- which(p_values < 0.05)
cat("🎯 Significant metabolites found:", length(significant_metabolites), "\n")

# 結果の保存
results <- data.frame(
  metabolite = names(numeric_data),
  p_value = p_values,
  significant = p_values < 0.05
)
write.csv(results, "metabolite_analysis_results.csv", row.names = FALSE)

# 上位の差異代謝物のヒートマップ
if (length(significant_metabolites) > 0) {
  cat("🔥 Creating heatmap of top differential metabolites...\n")
  top_metabolites <- head(significant_metabolites, 20)
  heatmap_data <- numeric_data[, top_metabolites]
  
  png("heatmap_top_metabolites.png", width = 1000, height = 800)
  pheatmap(t(heatmap_data), 
           annotation_col = data.frame(Group = groups, row.names = rownames(heatmap_data)),
           scale = "row",
           clustering_distance_rows = "correlation")
  dev.off()
}

cat("✅ Analysis completed! Check output files:\n")
cat("  - correlation_matrix.png\n")
cat("  - pca_plot.png\n")
cat("  - heatmap_top_metabolites.png\n")
cat("  - metabolite_analysis_results.csv\n")