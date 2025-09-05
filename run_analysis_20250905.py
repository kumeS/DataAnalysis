#!/usr/bin/env python3
"""
Comprehensive Metabolomics Analysis Workflow - Today's Run
Analysis Date: 2025-09-05
Output Directory: results/metabolomics-analysis/20250905_053855/
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
import os
warnings.filterwarnings('ignore')

# Set output directory
OUTPUT_DIR = "results/metabolomics-analysis/20250905_053855/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

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
    print(f"Missing values: {missing_values}")
    
    # Fill missing values with column median
    if missing_values > 0:
        numeric_data = numeric_data.fillna(numeric_data.median())
        print("Missing values filled with median values")
    
    print(f"Final processed data shape: {numeric_data.shape}")
    return numeric_data

def basic_statistics(data):
    """Generate basic statistics for all metabolites"""
    print("\nGenerating basic statistics...")
    
    stats_summary = pd.DataFrame({
        'Metabolite': data.columns,
        'Mean': data.mean(),
        'Std': data.std(),
        'Min': data.min(),
        'Max': data.max(),
        'Median': data.median(),
        'Q25': data.quantile(0.25),
        'Q75': data.quantile(0.75),
        'CV': (data.std() / data.mean()) * 100  # Coefficient of Variation
    })
    
    # Sort by coefficient of variation (most variable first)
    stats_summary = stats_summary.sort_values('CV', ascending=False)
    stats_summary.to_csv(os.path.join(OUTPUT_DIR, 'summary_statistics.csv'))
    
    print(f"Statistics calculated for {len(stats_summary)} metabolites")
    print("\nTop 10 most variable metabolites:")
    print(stats_summary.head(10)[['Metabolite', 'Mean', 'CV']])
    
    return stats_summary

def perform_pca_analysis(data):
    """Perform Principal Component Analysis"""
    print("\nPerforming PCA analysis...")
    
    # Standardize the data
    scaler = StandardScaler()
    scaled_data = scaler.fit_transform(data)
    
    # Perform PCA
    pca = PCA()
    pca_result = pca.fit_transform(scaled_data)
    
    # Create PCA dataframe
    pca_df = pd.DataFrame(pca_result, 
                         columns=[f'PC{i+1}' for i in range(pca_result.shape[1])],
                         index=data.index)
    
    print(f"PCA completed. First 5 PCs explain {pca.explained_variance_ratio_[:5].sum():.1%} of variance")
    
    # Create comprehensive PCA plot
    plt.figure(figsize=(16, 12))
    
    # Main PCA scatter plot
    plt.subplot(2, 2, 1)
    colors = ['red' if 'normal' in idx.lower() else 'blue' for idx in data.index]
    plt.scatter(pca_df['PC1'], pca_df['PC2'], c=colors, alpha=0.7, s=100)
    plt.xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.1%} variance)')
    plt.ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.1%} variance)')
    plt.title('PCA Analysis - Sample Distribution')
    plt.grid(True, alpha=0.3)
    
    # Add sample labels
    for i, idx in enumerate(data.index):
        plt.annotate(idx, (pca_df.iloc[i]['PC1'], pca_df.iloc[i]['PC2']), 
                    fontsize=8, alpha=0.7)
    
    # Add legend
    from matplotlib.patches import Patch
    legend_elements = [Patch(facecolor='red', label='Normal'),
                      Patch(facecolor='blue', label='Fasting')]
    plt.legend(handles=legend_elements)
    
    # Variance explained plot
    plt.subplot(2, 2, 2)
    cumvar = np.cumsum(pca.explained_variance_ratio_[:10])
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
    plt.savefig(os.path.join(OUTPUT_DIR, 'pca_analysis.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    return pca, pca_df

def correlation_analysis(data):
    """Perform correlation analysis between metabolites"""
    print("\nPerforming correlation analysis...")
    
    # Calculate correlation matrix
    corr_matrix = data.corr()
    
    # Find highly correlated pairs (|r| > 0.8)
    high_corr_pairs = []
    for i in range(len(corr_matrix.columns)):
        for j in range(i+1, len(corr_matrix.columns)):
            corr_val = corr_matrix.iloc[i, j]
            if abs(corr_val) > 0.8:
                high_corr_pairs.append({
                    'Metabolite1': corr_matrix.columns[i],
                    'Metabolite2': corr_matrix.columns[j],
                    'Correlation': corr_val
                })
    
    high_corr_df = pd.DataFrame(high_corr_pairs).sort_values('Correlation', key=abs, ascending=False)
    high_corr_df.to_csv(os.path.join(OUTPUT_DIR, 'high_correlations.csv'), index=False)
    
    print(f"Found {len(high_corr_pairs)} highly correlated pairs (|r| > 0.8)")
    
    # Create correlation heatmap
    plt.figure(figsize=(20, 16))
    
    # Select top 50 most variable metabolites for visualization
    top_metabolites = data.std().sort_values(ascending=False).head(50).index
    subset_corr = corr_matrix.loc[top_metabolites, top_metabolites]
    
    sns.heatmap(subset_corr, annot=False, cmap='RdBu_r', center=0,
                square=True, fmt='.2f', cbar_kws={"shrink": .8})
    plt.title('Correlation Matrix - Top 50 Most Variable Metabolites')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'correlation_heatmap.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
    return corr_matrix, high_corr_df

def differential_analysis(data):
    """Perform differential analysis between normal and fasting samples"""
    print("\nPerforming differential analysis...")
    
    # Identify sample groups
    normal_samples = [idx for idx in data.index if 'normal' in idx.lower()]
    fasting_samples = [idx for idx in data.index if 'fasting' in idx.lower() or 'fast' in idx.lower()]
    
    print(f"Normal samples: {normal_samples}")
    print(f"Fasting samples: {fasting_samples}")
    
    if len(normal_samples) > 0 and len(fasting_samples) > 0:
        # Perform t-tests for each metabolite
        results = []
        
        for metabolite in data.columns:
            normal_vals = data.loc[normal_samples, metabolite]
            fasting_vals = data.loc[fasting_samples, metabolite]
            
            # Perform t-test
            t_stat, p_val = stats.ttest_ind(normal_vals, fasting_vals)
            
            # Calculate effect size (Cohen's d)
            pooled_std = np.sqrt(((len(normal_vals) - 1) * normal_vals.var() + 
                                 (len(fasting_vals) - 1) * fasting_vals.var()) / 
                                (len(normal_vals) + len(fasting_vals) - 2))
            cohens_d = (normal_vals.mean() - fasting_vals.mean()) / pooled_std
            
            results.append({
                'Metabolite': metabolite,
                'Normal_Mean': normal_vals.mean(),
                'Fasting_Mean': fasting_vals.mean(),
                'Fold_Change': fasting_vals.mean() / normal_vals.mean() if normal_vals.mean() != 0 else np.inf,
                'Log2_FC': np.log2(fasting_vals.mean() / normal_vals.mean()) if normal_vals.mean() != 0 else np.inf,
                'T_Statistic': t_stat,
                'P_Value': p_val,
                'Cohens_D': cohens_d,
                'Significant': p_val < 0.05
            })
        
        ttest_df = pd.DataFrame(results).sort_values('P_Value')
        ttest_df.to_csv(os.path.join(OUTPUT_DIR, 'differential_analysis_results.csv'), index=False)
        
        print(f"Found {sum(ttest_df['Significant'])} significantly different metabolites (p < 0.05)")
        
        # Create volcano plot
        plt.figure(figsize=(12, 8))
        
        # Filter out infinite values for plotting
        plot_df = ttest_df[np.isfinite(ttest_df['Log2_FC'])]
        
        colors = ['red' if p < 0.05 and abs(fc) > 0.5 else 'gray' 
                 for p, fc in zip(plot_df['P_Value'], plot_df['Log2_FC'])]
        
        plt.scatter(plot_df['Log2_FC'], -np.log10(plot_df['P_Value']), 
                   c=colors, alpha=0.6)
        plt.xlabel('Log2 Fold Change (Fasting vs Normal)')
        plt.ylabel('-Log10(P-value)')
        plt.title('Volcano Plot - Differential Analysis')
        plt.axhline(y=-np.log10(0.05), color='red', linestyle='--', alpha=0.7, label='p=0.05')
        plt.axvline(x=0.5, color='blue', linestyle='--', alpha=0.7)
        plt.axvline(x=-0.5, color='blue', linestyle='--', alpha=0.7)
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(os.path.join(OUTPUT_DIR, 'volcano_plot.png'), dpi=300, bbox_inches='tight')
        plt.close()
        
        return ttest_df
    else:
        print("Could not identify sample groups for differential analysis")
        return None

def create_metabolite_heatmap(data):
    """Create heatmap of metabolite concentrations"""
    print("\nCreating metabolite heatmap...")
    
    # Select top 50 most variable metabolites
    top_metabolites = data.std().sort_values(ascending=False).head(50).index
    subset_data = data[top_metabolites]
    
    # Standardize for better visualization
    scaler = StandardScaler()
    scaled_subset = pd.DataFrame(scaler.fit_transform(subset_data.T).T, 
                                index=subset_data.index, 
                                columns=subset_data.columns)
    
    plt.figure(figsize=(20, 10))
    sns.heatmap(scaled_subset.T, cmap='RdYlBu_r', center=0, 
                cbar_kws={"shrink": .8}, xticklabels=True, yticklabels=True)
    plt.title('Metabolite Concentration Heatmap (Top 50 Most Variable)')
    plt.xlabel('Samples')
    plt.ylabel('Metabolites')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'metabolite_heatmap.png'), dpi=300, bbox_inches='tight')
    plt.close()

def generate_analysis_report(data, stats_summary, pca_df, corr_matrix, diff_results):
    """Generate a comprehensive analysis report"""
    print("\nGenerating analysis report...")
    
    report = f"""# Comprehensive Metabolomics Analysis Report
Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Output Directory: {OUTPUT_DIR}

## Dataset Overview
- **Total Samples**: {data.shape[0]}
- **Total Metabolites**: {data.shape[1]}
- **Sample Types**: {list(data.index)}

## Summary Statistics
- **Most Variable Metabolite**: {stats_summary.iloc[0]['Metabolite']} (CV: {stats_summary.iloc[0]['CV']:.2f}%)
- **Least Variable Metabolite**: {stats_summary.iloc[-1]['Metabolite']} (CV: {stats_summary.iloc[-1]['CV']:.2f}%)
- **Average CV**: {stats_summary['CV'].mean():.2f}%

## PCA Analysis Results
- **PC1 Variance Explained**: {pca_df.var()['PC1']/pca_df.var().sum()*100:.1f}%
- **PC2 Variance Explained**: {pca_df.var()['PC2']/pca_df.var().sum()*100:.1f}%
- **First 2 PCs Combined**: {(pca_df.var()['PC1']+pca_df.var()['PC2'])/pca_df.var().sum()*100:.1f}%

## Correlation Analysis
- **Total Metabolite Pairs**: {len(corr_matrix.columns) * (len(corr_matrix.columns) - 1) // 2}
- **Highly Correlated Pairs (|r| > 0.8)**: {len([1 for i in range(len(corr_matrix)) for j in range(i+1, len(corr_matrix)) if abs(corr_matrix.iloc[i,j]) > 0.8])}

"""
    
    if diff_results is not None:
        significant_metabolites = diff_results[diff_results['Significant']].shape[0]
        report += f"""## Differential Analysis (Normal vs Fasting)
- **Significantly Different Metabolites (p < 0.05)**: {significant_metabolites}
- **Top Upregulated in Fasting**: {diff_results.sort_values('Log2_FC', ascending=False).iloc[0]['Metabolite']} (Log2FC: {diff_results.sort_values('Log2_FC', ascending=False).iloc[0]['Log2_FC']:.2f})
- **Top Downregulated in Fasting**: {diff_results.sort_values('Log2_FC', ascending=True).iloc[0]['Metabolite']} (Log2FC: {diff_results.sort_values('Log2_FC', ascending=True).iloc[0]['Log2_FC']:.2f})

### Top 10 Significantly Different Metabolites:
"""
        top_significant = diff_results[diff_results['Significant']].head(10)
        for _, row in top_significant.iterrows():
            report += f"- **{row['Metabolite']}**: Log2FC = {row['Log2_FC']:.3f}, p = {row['P_Value']:.2e}\n"
    
    report += f"""
## Generated Files
- `summary_statistics.csv`: Comprehensive statistics for all metabolites
- `pca_analysis.png`: Principal component analysis visualization
- `correlation_heatmap.png`: Correlation matrix heatmap
- `high_correlations.csv`: Highly correlated metabolite pairs
- `metabolite_heatmap.png`: Sample vs metabolite concentration heatmap
"""
    
    if diff_results is not None:
        report += f"""- `differential_analysis_results.csv`: Statistical comparison between groups
- `volcano_plot.png`: Volcano plot of differential analysis
"""
    
    report += f"""
## Analysis Summary
This comprehensive metabolomics analysis examined {data.shape[1]} metabolites across {data.shape[0]} samples. 
The analysis identified key metabolic differences and patterns in the dataset through multiple 
analytical approaches including PCA, correlation analysis, and differential testing.

Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
    
    with open(os.path.join(OUTPUT_DIR, 'analysis_report.md'), 'w', encoding='utf-8') as f:
        f.write(report)

def main():
    """Main analysis workflow"""
    print("=== Comprehensive Metabolomics Analysis Workflow ===")
    print(f"Output Directory: {OUTPUT_DIR}")
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
    diff_results = differential_analysis(numeric_data)
    
    # Create metabolite heatmap
    create_metabolite_heatmap(numeric_data)
    
    # Generate comprehensive report
    generate_analysis_report(numeric_data, stats_summary, pca_df, corr_matrix, diff_results)
    
    # Copy input data to results folder
    import shutil
    shutil.copy('fasting.csv', os.path.join(OUTPUT_DIR, 'fasting.csv'))
    
    print(f"\n=== Analysis Complete ===")
    print(f"All results saved to: {OUTPUT_DIR}")
    print(f"Generated files:")
    print(f"- summary_statistics.csv")
    print(f"- pca_analysis.png")
    print(f"- correlation_heatmap.png") 
    print(f"- high_correlations.csv")
    print(f"- metabolite_heatmap.png")
    print(f"- analysis_report.md")
    print(f"- fasting.csv (input data copy)")
    if diff_results is not None:
        print(f"- differential_analysis_results.csv")
        print(f"- volcano_plot.png")

if __name__ == "__main__":
    main()