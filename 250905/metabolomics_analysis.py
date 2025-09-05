#!/usr/bin/env python3
"""
Comprehensive Metabolomics Analysis Workflow
Analysis Date: 2025-09-05
Data Source: fasting.csv
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

def load_data(filename):
    """Load and preprocess metabolomics data"""
    print("Loading metabolomics data...")
    try:
        # Try reading with different separators
        data = pd.read_csv(filename, sep=';', index_col=0)
        print(f"Data loaded successfully with semicolon separator")
    except:
        try:
            data = pd.read_csv(filename, sep=',', index_col=0)
            print(f"Data loaded successfully with comma separator")
        except Exception as e:
            print(f"Error loading data: {e}")
            return None
    
    print(f"Data dimensions: {data.shape}")
    print(f"Columns: {data.columns.tolist()[:10]}...")  # Show first 10 columns
    return data

def preprocess_data(data):
    """Clean and preprocess the data"""
    print("\nPreprocessing data...")
    
    # Convert to numeric, handling any text values
    numeric_data = data.apply(pd.to_numeric, errors='coerce')
    
    # Remove columns with all NaN values
    numeric_data = numeric_data.dropna(axis=1, how='all')
    
    # Basic data info
    print(f"Numeric data shape: {numeric_data.shape}")
    missing_values = numeric_data.isnull().sum().sum()
    total_values = numeric_data.size
    missing_percent = (missing_values / total_values) * 100
    print(f"Missing values: {missing_values}/{total_values} ({missing_percent:.2f}%)")
    
    return numeric_data

def basic_statistics(data):
    """Calculate basic statistics"""
    print("\nCalculating basic statistics...")
    
    stats_summary = pd.DataFrame({
        'Mean': data.mean(),
        'Std': data.std(),
        'Min': data.min(),
        'Max': data.max(),
        'Median': data.median(),
        'Q25': data.quantile(0.25),
        'Q75': data.quantile(0.75)
    })
    
    # Save summary statistics
    stats_summary.to_csv('summary_statistics.csv')
    print("Basic statistics saved to summary_statistics.csv")
    
    return stats_summary

def perform_pca_analysis(data):
    """Perform Principal Component Analysis"""
    print("\nPerforming PCA analysis...")
    
    # Standardize the data
    scaler = StandardScaler()
    data_scaled = scaler.fit_transform(data.fillna(0))
    
    # Perform PCA
    pca = PCA()
    pca_result = pca.fit_transform(data_scaled)
    
    # Create PCA dataframe
    pca_df = pd.DataFrame(pca_result, 
                         columns=[f'PC{i+1}' for i in range(pca_result.shape[1])],
                         index=data.index)
    
    # Plot PCA
    plt.figure(figsize=(12, 8))
    
    # Create subplot for PCA plot
    plt.subplot(2, 2, 1)
    colors = ['red' if 'normal' in idx.lower() else 'blue' for idx in data.index]
    plt.scatter(pca_df['PC1'], pca_df['PC2'], c=colors, alpha=0.7)
    plt.xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.1%} variance)')
    plt.ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.1%} variance)')
    plt.title('PCA Analysis - Sample Distribution')
    plt.grid(True, alpha=0.3)
    
    # Add sample labels
    for i, idx in enumerate(data.index):
        plt.annotate(idx, (pca_df.iloc[i]['PC1'], pca_df.iloc[i]['PC2']), 
                    fontsize=8, alpha=0.7)
    
    # Variance explained plot
    plt.subplot(2, 2, 2)
    cumvar = np.cumsum(pca.explained_variance_ratio_)[:10]
    plt.plot(range(1, len(cumvar)+1), cumvar, 'bo-')
    plt.xlabel('Principal Component')
    plt.ylabel('Cumulative Variance Explained')
    plt.title('PCA Variance Explained')
    plt.grid(True, alpha=0.3)
    
    # Feature contributions to PC1
    plt.subplot(2, 2, 3)
    pc1_contributions = pd.DataFrame({
        'Metabolite': data.columns,
        'PC1_Loading': pca.components_[0]
    }).sort_values('PC1_Loading', key=abs, ascending=False).head(20)
    
    plt.barh(range(len(pc1_contributions)), pc1_contributions['PC1_Loading'])
    plt.yticks(range(len(pc1_contributions)), 
               [m[:20]+'...' if len(m)>20 else m for m in pc1_contributions['Metabolite']])
    plt.xlabel('PC1 Loading')
    plt.title('Top 20 Metabolite Contributions to PC1')
    plt.grid(True, alpha=0.3)
    
    # Feature contributions to PC2
    plt.subplot(2, 2, 4)
    pc2_contributions = pd.DataFrame({
        'Metabolite': data.columns,
        'PC2_Loading': pca.components_[1]
    }).sort_values('PC2_Loading', key=abs, ascending=False).head(20)
    
    plt.barh(range(len(pc2_contributions)), pc2_contributions['PC2_Loading'])
    plt.yticks(range(len(pc2_contributions)), 
               [m[:20]+'...' if len(m)>20 else m for m in pc2_contributions['Metabolite']])
    plt.xlabel('PC2 Loading')
    plt.title('Top 20 Metabolite Contributions to PC2')
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('pca_analysis.png', dpi=300, bbox_inches='tight')
    print("PCA analysis saved to pca_analysis.png")
    
    return pca, pca_df

def correlation_analysis(data):
    """Perform correlation analysis"""
    print("\nPerforming correlation analysis...")
    
    # Calculate correlation matrix
    corr_matrix = data.corr()
    
    # Find high correlations
    high_corr_pairs = []
    for i in range(len(corr_matrix.columns)):
        for j in range(i+1, len(corr_matrix.columns)):
            corr_val = corr_matrix.iloc[i, j]
            if abs(corr_val) > 0.7:
                high_corr_pairs.append({
                    'Metabolite1': corr_matrix.columns[i],
                    'Metabolite2': corr_matrix.columns[j],
                    'Correlation': corr_val
                })
    
    high_corr_df = pd.DataFrame(high_corr_pairs).sort_values('Correlation', 
                                                           key=abs, 
                                                           ascending=False)
    high_corr_df.to_csv('high_correlations.csv', index=False)
    print(f"Found {len(high_corr_pairs)} high correlation pairs (>0.7)")
    
    # Create correlation heatmap for top metabolites
    plt.figure(figsize=(15, 12))
    
    # Select top 50 most variable metabolites for visualization
    top_metabolites = data.std().nlargest(50).index
    corr_subset = corr_matrix.loc[top_metabolites, top_metabolites]
    
    sns.heatmap(corr_subset, 
                cmap='RdBu_r', 
                center=0, 
                square=True,
                fmt='.2f',
                cbar_kws={'label': 'Correlation'})
    plt.title('Metabolite Correlation Matrix (Top 50 Most Variable)')
    plt.xticks(rotation=45, ha='right')
    plt.yticks(rotation=0)
    plt.tight_layout()
    plt.savefig('correlation_heatmap.png', dpi=300, bbox_inches='tight')
    print("Correlation heatmap saved to correlation_heatmap.png")
    
    return corr_matrix, high_corr_df

def differential_analysis(data):
    """Compare normal vs fasting conditions"""
    print("\nPerforming differential analysis...")
    
    # Separate normal and fasting samples
    normal_samples = [idx for idx in data.index if 'normal' in idx.lower()]
    fasting_samples = [idx for idx in data.index if 'fasting' in idx.lower()]
    
    print(f"Normal samples: {len(normal_samples)}")
    print(f"Fasting samples: {len(fasting_samples)}")
    
    if len(normal_samples) > 0 and len(fasting_samples) > 0:
        # Perform t-tests for each metabolite
        ttest_results = []
        
        for metabolite in data.columns:
            normal_values = data.loc[normal_samples, metabolite].dropna()
            fasting_values = data.loc[fasting_samples, metabolite].dropna()
            
            if len(normal_values) >= 2 and len(fasting_values) >= 2:
                # Perform t-test
                stat, pvalue = stats.ttest_ind(normal_values, fasting_values)
                
                # Calculate fold change
                normal_mean = normal_values.mean()
                fasting_mean = fasting_values.mean()
                if normal_mean > 0:
                    fold_change = fasting_mean / normal_mean
                else:
                    fold_change = np.nan
                
                ttest_results.append({
                    'Metabolite': metabolite,
                    'Normal_Mean': normal_mean,
                    'Fasting_Mean': fasting_mean,
                    'Fold_Change': fold_change,
                    'Log2_FC': np.log2(fold_change) if fold_change > 0 else np.nan,
                    'T_Statistic': stat,
                    'P_Value': pvalue,
                    'Significant': pvalue < 0.05
                })
        
        # Convert to dataframe and sort by p-value
        ttest_df = pd.DataFrame(ttest_results).sort_values('P_Value')
        ttest_df.to_csv('differential_analysis_results.csv', index=False)
        
        # Create volcano plot
        plt.figure(figsize=(10, 8))
        
        # Filter out invalid values for plotting
        plot_data = ttest_df.dropna(subset=['Log2_FC', 'P_Value'])
        log_pval = -np.log10(plot_data['P_Value'])
        
        # Color points based on significance and fold change
        colors = []
        for _, row in plot_data.iterrows():
            if row['P_Value'] < 0.05 and abs(row['Log2_FC']) > 1:
                colors.append('red')  # Significant and large fold change
            elif row['P_Value'] < 0.05:
                colors.append('orange')  # Significant but small fold change
            else:
                colors.append('gray')  # Not significant
        
        plt.scatter(plot_data['Log2_FC'], log_pval, c=colors, alpha=0.6)
        plt.xlabel('Log2 Fold Change (Fasting/Normal)')
        plt.ylabel('-Log10 P-Value')
        plt.title('Volcano Plot: Normal vs Fasting')
        
        # Add significance lines
        plt.axhline(y=-np.log10(0.05), color='black', linestyle='--', alpha=0.5)
        plt.axvline(x=1, color='black', linestyle='--', alpha=0.5)
        plt.axvline(x=-1, color='black', linestyle='--', alpha=0.5)
        
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig('volcano_plot.png', dpi=300, bbox_inches='tight')
        
        print(f"Differential analysis completed. {len(ttest_df)} metabolites analyzed.")
        print(f"Significant metabolites (p<0.05): {sum(ttest_df['Significant'])}")
        
        return ttest_df
    
    return None

def create_metabolite_heatmap(data):
    """Create comprehensive metabolite heatmap"""
    print("\nCreating metabolite concentration heatmap...")
    
    # Select top most variable metabolites
    top_metabolites = data.std().nlargest(50).index
    data_subset = data.loc[:, top_metabolites]
    
    # Create heatmap
    plt.figure(figsize=(20, 10))
    
    # Log transform for better visualization (add small constant to avoid log(0))
    data_log = np.log2(data_subset + 1e-6)
    
    sns.heatmap(data_log, 
                cmap='viridis',
                cbar_kws={'label': 'Log2 Concentration'},
                xticklabels=[col[:30]+'...' if len(col)>30 else col for col in data_subset.columns],
                yticklabels=data_subset.index)
    
    plt.title('Metabolite Concentration Heatmap (Top 50 Most Variable)')
    plt.xlabel('Metabolites')
    plt.ylabel('Samples')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('metabolite_heatmap.png', dpi=300, bbox_inches='tight')
    print("Metabolite heatmap saved to metabolite_heatmap.png")

def generate_report(data, stats_summary, pca, high_corr_df, ttest_df=None):
    """Generate comprehensive analysis report"""
    print("\nGenerating analysis report...")
    
    report = f"""# Metabolomics Analysis Report

**Analysis Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Data Source:** fasting.csv

## Data Overview
- **Dimensions:** {data.shape[0]} samples × {data.shape[1]} metabolites
- **Sample Types:** Normal control and 12h fasting conditions
- **Data Type:** Metabolite concentration measurements

## Data Quality Assessment
- **Missing values:** {data.isnull().sum().sum()}/{data.size} ({(data.isnull().sum().sum()/data.size)*100:.2f}%)
- **Data completeness:** {100-(data.isnull().sum().sum()/data.size)*100:.2f}%

## Statistical Summary
- **Concentration range:** {stats_summary['Mean'].min():.6f} to {stats_summary['Mean'].max():.6f}
- **Most variable metabolites:** {', '.join(data.std().nlargest(5).index[:3])}...

## Principal Component Analysis Results
- **PC1 variance explained:** {pca.explained_variance_ratio_[0]:.1%}
- **PC2 variance explained:** {pca.explained_variance_ratio_[1]:.1%}
- **Total variance explained (PC1+PC2):** {(pca.explained_variance_ratio_[0] + pca.explained_variance_ratio_[1]):.1%}

## Correlation Analysis Results
- **High correlations (>0.7):** {len(high_corr_df)} metabolite pairs identified
- **Strongest positive correlation:** {high_corr_df.iloc[0]['Correlation']:.3f} between {high_corr_df.iloc[0]['Metabolite1'][:30]}... and {high_corr_df.iloc[0]['Metabolite2'][:30]}...

"""

    if ttest_df is not None:
        significant_metabolites = sum(ttest_df['Significant'])
        upregulated = sum((ttest_df['Significant']) & (ttest_df['Log2_FC'] > 0))
        downregulated = sum((ttest_df['Significant']) & (ttest_df['Log2_FC'] < 0))
        
        report += f"""## Differential Analysis Results (Normal vs Fasting)
- **Total metabolites analyzed:** {len(ttest_df)}
- **Significantly different metabolites (p<0.05):** {significant_metabolites}
- **Upregulated in fasting:** {upregulated}
- **Downregulated in fasting:** {downregulated}
- **Most significant metabolite:** {ttest_df.iloc[0]['Metabolite'][:50]}... (p={ttest_df.iloc[0]['P_Value']:.2e})

"""

    report += """## Generated Files
- `pca_analysis.png` - Principal Component Analysis plots
- `correlation_heatmap.png` - Metabolite correlation visualization  
- `metabolite_heatmap.png` - Concentration heatmap of top variable metabolites
- `volcano_plot.png` - Differential analysis volcano plot
- `summary_statistics.csv` - Statistical summary of all metabolites
- `high_correlations.csv` - List of highly correlated metabolite pairs
- `differential_analysis_results.csv` - Complete differential analysis results
- `analysis_report.md` - This comprehensive report

## Interpretation & Insights

### PCA Insights
The PCA analysis reveals the main sources of metabolic variation between normal and fasting states. The first two principal components capture the primary metabolic differences, helping identify which metabolites contribute most to the distinction between conditions.

### Correlation Patterns
The correlation analysis identifies metabolites that show coordinated changes, potentially indicating:
- Shared metabolic pathways
- Co-regulated metabolites
- Technical correlations in measurement

### Differential Analysis
The comparison between normal and fasting states reveals metabolites that show significant changes during the fasting period. These could represent:
- Metabolic adaptations to fasting
- Biomarkers of fasting state
- Key metabolites in energy metabolism

## Conclusion
This comprehensive metabolomics analysis provides insights into the metabolic changes associated with 12-hour fasting. The results identify key metabolites and patterns that distinguish fasting from normal metabolic states, which may be valuable for understanding metabolic regulation and identifying potential biomarkers.

---
*Analysis performed with Python-based metabolomics workflow*
"""

    with open('analysis_report.md', 'w') as f:
        f.write(report)
    
    print("Analysis report saved to analysis_report.md")

def main():
    """Main analysis workflow"""
    print("=== Comprehensive Metabolomics Analysis Workflow ===")
    print("Starting analysis...")
    
    # Load data
    data = load_data('fasting.csv')
    if data is None:
        print("Failed to load data. Exiting.")
        return
    
    # Preprocess data
    numeric_data = preprocess_data(data)
    
    # Basic statistics
    stats_summary = basic_statistics(numeric_data)
    
    # PCA analysis
    pca, pca_df = perform_pca_analysis(numeric_data)
    
    # Correlation analysis
    corr_matrix, high_corr_df = correlation_analysis(numeric_data)
    
    # Differential analysis
    ttest_df = differential_analysis(numeric_data)
    
    # Create heatmap
    create_metabolite_heatmap(numeric_data)
    
    # Generate comprehensive report
    generate_report(numeric_data, stats_summary, pca, high_corr_df, ttest_df)
    
    print("\n=== Analysis Complete! ===")
    print("All results saved to current directory.")

if __name__ == "__main__":
    main()