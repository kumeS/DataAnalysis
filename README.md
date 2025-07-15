# DataAnalysis

## GitHub Actions ワークフロー

このリポジトリには、Claude Codeを使用した代謝物解析のためのGitHub Actionsワークフローが含まれています。

### 1. metabolomics-analysis.yml - 統合的代謝物解析

**概要:**
単一のジョブで包括的な代謝物解析を実行するワークフローです。

**実行内容:**
- **データ読み込み:** `readr::read_csv()` を使用してCSVファイルを読み込み
- **探索的データ解析:** データの次元、要約統計量の確認
- **統計解析:** normal vs 12h_fasting グループ間のt検定による比較
- **可視化:** 
  - PCA プロット（主成分分析）
  - 有意差のある代謝物のヒートマップ
- **結果出力:** 解析結果とプロットをファイルとして保存
- **レポート作成:** 発見事項をまとめたMarkdownレポートの生成

**使用パッケージ:** readr, dplyr, ggplot2, pheatmap, corrplot

**実行方法:**
```bash
# 手動実行
gh workflow run "Claude · Metabolomics Analysis" --field data_path=fasting.csv

# またはGitHub UI から workflow_dispatch で実行
```

**成果物:**
- 解析結果（PNG、PDF、MD、Rファイル）がアーティファクトとして保存

### 2. metabolomics-parallel.yml - 並列代謝物解析

**概要:**
解析を3つの並列タスクに分割し、効率的に実行する並列処理ワークフローです。

**並列実行タスク:**

#### タスク1: EDA（探索的データ解析）
- 基本的なデータ探索
- 要約統計量の算出
- 相関行列の作成
- PCAプロットの生成

#### タスク2: Modeling（統計モデリング）
- normal vs 12h_fasting グループ間のt検定
- 有意な結果の保存
- 統計的有意性の評価

#### タスク3: Viz（可視化）
- 有意差のある代謝物のヒートマップ
- 重要な代謝物のボックスプロット
- 視覚的な結果の提示

**統合処理:**
並列タスク完了後、すべての結果を統合した最終レポートを生成します。

**実行方法:**
```bash
# 手動実行
gh workflow run "Claude · Parallel Metabolomics Analysis" --field csv=fasting.csv

# またはGitHub UI から workflow_dispatch で実行
```

**成果物:**
- 各タスクの結果が個別のアーティファクトとして保存
- 最終的に統合レポート（FINAL_REPORT.md）を生成

### 共通仕様

**トリガー条件:**
- 手動実行（workflow_dispatch）
- data/フォルダ内のCSVファイルが更新された場合（push）

**必要な設定:**
- `ANTHROPIC_API_KEY` をGitHub Secretsに設定
- R環境とパッケージの自動インストール

**使用技術:**
- Claude Code (anthropics/claude-code-action@beta)
- R統計解析環境
- GitHub Actions並列処理機能