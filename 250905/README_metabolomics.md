# Metabolomics Analysis Workflow

This directory contains a comprehensive metabolomics analysis workflow for analyzing the fasting vs normal control dataset.

## Quick Start

### Option 1: Python Analysis
```bash
python3 metabolomics_analysis.py
```

### Option 2: R Analysis  
```bash
Rscript metabolomics_analysis.R
```

## Dataset Information
- **File:** `fasting.csv`
- **Samples:** 10 (5 normal + 4 fasting)
- **Metabolites:** 262+
- **Conditions:** Normal control vs 12-hour fasting

## Analysis Features

### 🔬 Statistical Analysis
- Principal Component Analysis (PCA)
- Correlation analysis  
- Differential metabolite analysis
- Statistical summaries

### 📊 Visualizations
- PCA plots with sample separation
- Metabolite correlation heatmaps
- Concentration heatmaps
- Volcano plots for differential analysis

### 📁 Generated Files
- `pca_analysis.png` - PCA visualization
- `correlation_heatmap.png` - Correlation matrix
- `metabolite_heatmap.png` - Concentration patterns
- `volcano_plot.png` - Differential analysis
- `summary_statistics.csv` - Statistical summary
- `high_correlations.csv` - Correlated metabolites
- `differential_analysis_results.csv` - Complete results
- `analysis_report.md` - Comprehensive report

## Requirements

### Python Dependencies
```bash
pip install pandas numpy matplotlib seaborn scikit-learn scipy
```

### R Dependencies
```r
install.packages(c("readr", "dplyr", "ggplot2", "pheatmap", "corrplot", "RColorBrewer"))
```

## Analysis Results Expected

### Key Findings
- **PCA:** Clear separation between normal and fasting samples
- **Differential Analysis:** Significant changes in energy metabolism
- **Correlations:** Metabolite pathway relationships

### Biological Insights  
- Metabolic adaptations to fasting state
- Identification of fasting biomarkers
- Pathway-level changes in metabolism

## File Structure
```
├── fasting.csv                    # Primary dataset
├── metabolomics_analysis.py       # Python analysis script  
├── metabolomics_analysis.R        # R analysis script
├── analysis_report.md             # Comprehensive report
└── README_metabolomics.md         # This file
```

## Previous Analyses
See `/results/metabolomics-analysis/` for historical analysis runs with timestamps.

---
*Comprehensive metabolomics workflow for fasting study analysis*