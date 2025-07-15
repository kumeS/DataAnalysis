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
- **Claude解釈:** 統計解析結果の統計的意義を解釈
- **レポート作成:** Claudeが発見事項とインサイトをまとめたMarkdownレポートを生成

**使用パッケージ:** readr, dplyr, ggplot2, pheatmap, corrplot

**実行方法:**
```bash
# 手動実行
gh workflow run "Claude · Metabolomics Analysis" --field data_path=fasting.csv

# またはGitHub UI から workflow_dispatch で実行
```

**成果物:**
- 解析結果（PNG、PDF、MD、Rファイル）がアーティファクトとして保存
- **Claudeによる解釈レポート:** 統計的結果の意義と生物学的インサイトを含むMarkdownレポート

### 2. metabolomics-parallel.yml - 並列代謝物解析

**概要:**
解析を3つの並列タスクに分割し、効率的に実行する並列処理ワークフローです。

**並列実行タスク:**

#### タスク1: EDA（探索的データ解析）
- 基本的なデータ探索
- 要約統計量の算出
- 相関行列の作成
- PCAプロットの生成
- **Claude解釈:** データの特徴とパターンを解釈し`note.md`に記録

#### タスク2: Modeling（統計モデリング）
- normal vs 12h_fasting グループ間のt検定
- 有意な結果の保存
- 統計的有意性の評価
- **Claude解釈:** 統計的結果の生物学的意義を解釈し`note.md`に記録

#### タスク3: Viz（可視化）
- 有意差のある代謝物のヒートマップ
- 重要な代謝物のボックスプロット
- 視覚的な結果の提示
- **Claude解釈:** 可視化結果から読み取れるパターンを解釈し`note.md`に記録

**統合処理:**
並列タスク完了後、各タスクのClaude解釈結果を統合した最終レポートを生成します。

**実行方法:**
```bash
# 手動実行
gh workflow run "Claude · Parallel Metabolomics Analysis" --field csv=fasting.csv

# またはGitHub UI から workflow_dispatch で実行
```

**成果物:**
- 各タスクの結果が個別のアーティファクトとして保存
- **各タスクの解釈レポート:** 各タスクでClaudeが生成した`note.md`（発見事項とインサイト）
- **統合解釈レポート:** 全タスクの解釈を統合した最終レポート（FINAL_REPORT.md）

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

### Claude解釈機能の詳細

両方のワークフローでは、単なる統計計算の実行だけでなく、**Claudeによる知的な解釈とレポート生成**が重要な機能として組み込まれています：

**解釈内容:**
- **統計的意義の説明:** t検定結果、p値、信頼区間の生物学的意味
- **可視化パターンの読み取り:** PCA、ヒートマップ、相関行列から読み取れる代謝パターン
- **生物学的インサイト:** 代謝経路、生理学的プロセスとの関連性
- **研究的発見:** データから導かれる新しい発見や仮説の提示
- **実用的な示唆:** 結果が示す臨床的・実践的な意味

**レポート生成プロセス:**
1. R統計解析の実行
2. 結果の数値・グラフの生成
3. **Claude による結果の解釈・分析**
4. 発見事項とインサイトのMarkdown形式での文書化
5. 研究者が理解しやすい形でのレポート作成