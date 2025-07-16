# DataAnalysis

## GitHub Actions ワークフロー

このリポジトリには、**Claude Code統合による高度な代謝物解析**のためのGitHub Actionsワークフローが含まれています。統計的妥当性の評価、群間比較、分散分析、効果量の定量化を含む包括的な解析と、GitHub Pages対応のHTML報告書生成機能を提供します。

### 🔄 ハイブリッドワークフロー設計

本システムは、Claude Code Actionの技術的制約に対応するため、**解析実行フェーズ**と**AI解釈フェーズ**を分離したハイブリッド設計を採用しています：

- **解析ワークフロー**: `workflow_dispatch`イベントで手動実行
- **Claude解釈ワークフロー**: `push`イベントで自動的にトリガー

この設計により、Claude Code Actionの制約（`workflow_dispatch`イベント非対応）を回避しつつ、完全自動化された解析・解釈パイプラインを実現しています。

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
- **Claude解釈:** 統計解析結果の統計的意義を解釈（群間比較、分散分析、効果量評価含む）
- **HTMLレポート作成:** GitHub Pages対応のHTMLレポートと詳細なMarkdownレポートを生成
- **統計的妥当性評価:** 生物学的妥当性、再現性、臨床的意義の検討

**使用パッケージ:** readr, dplyr, ggplot2, pheatmap, corrplot

**実行方法:**
```bash
# 手動実行
gh workflow run "Claude · Metabolomics Analysis" --field data_path=fasting.csv

# またはGitHub UI から workflow_dispatch で実行
```

**成果物:**
- 解析結果（PNG、PDF、MD、Rファイル）がアーティファクトとして保存
- **Claudeによる解釈レポート:** 
  - claude_interpretation.md（詳細なMarkdownレポート）
  - claude_interpretation.html（GitHub Pages対応のHTMLレポート）
  - 統計的結果の意義と生物学的インサイトを含む包括的解釈

### 2. metabolomics-parallel.yml - 並列代謝物解析

**概要:**
解析を3つの並列タスクに分割し、効率的に実行する並列処理ワークフローです。

**並列実行タスク:**

#### タスク1: EDA（探索的データ解析）
- 基本的なデータ探索
- 要約統計量の算出
- 相関行列の作成
- PCAプロットの生成
- **Claude解釈:** データの特徴とパターンを解釈し`note.md`に記録（分散分析、分布評価含む）

#### タスク2: Modeling（統計モデリング）
- normal vs 12h_fasting グループ間のt検定
- 有意な結果の保存
- 統計的有意性の評価
- **Claude解釈:** 統計的結果の生物学的意義を解釈し`note.md`に記録（効果量、検定力、多重比較補正含む）

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
- **統合解釈レポート:** 
  - FINAL_REPORT.md（統合マークダウンレポート）
  - claude_parallel_interpretation.md（詳細解釈レポート）
  - claude_parallel_interpretation.html（GitHub Pages対応HTMLレポート）
  - 統計的妥当性と生物学的意義の包括的評価

### 共通仕様

**ワークフロートリガー:**
- **解析実行**: 手動実行（`workflow_dispatch`）
- **Claude解釈**: 解析結果のコミット時に自動実行（`push`イベント）

**必要な設定:**
- `CLAUDE_CODE_OAUTH_TOKEN` をGitHub Secretsに設定
- R環境とパッケージの自動インストール
- GitHub Pagesの有効化（HTML報告書閲覧用）

**使用技術:**
- **Claude Code**: anthropics/claude-code-action@beta
- **統計解析**: R統計環境（readr, dplyr, ggplot2, pheatmap, corrplot）
- **並列処理**: GitHub Actions matrix strategy
- **報告書生成**: Markdown + HTML（GitHub Pages対応）

### 📊 統計解析の強化機能

**新たに追加された統計的評価:**
- 群間比較と分散分析（群内・群間分散パターンの評価）
- 効果量の定量化と統計的検定力の評価
- 多重比較補正と分布の正規性検定
- 感度分析とブートストラップ解析による頑健性評価
- 外れ値の影響評価と統計的仮定の妥当性確認

**批判的考察機能:**
- 生物学的妥当性の検証
- 方法論的制約と交絡因子の評価
- 再現性と汎用性の考察
- サンプルの代表性と統計的仮定の検討

### 🤖 Claude AI解釈機能の詳細

両方のワークフローでは、単なる統計計算の実行だけでなく、**Claudeによる高度な統計的解釈と包括的レポート生成**が重要な機能として組み込まれています：

### 📄 GitHub Pages対応HTML報告書

**新機能**: 各解析について、以下の2つの形式で報告書を生成します：
- **claude_interpretation.md**: 技術的詳細を含む完全なMarkdown報告書
- **claude_interpretation.html**: GitHub Pages対応の視覚的HTML報告書
  - プロフェッショナルなCSS styling
- インタラクティブ要素とナビゲーション
  - レスポンシブデザイン（モバイル対応）
  - 埋め込み画像と可視化
  - 目次とセクション間ナビゲーション

**強化された解釈内容:**
- **統計的妥当性評価:** 
  - 群間比較と分散分析（群内・群間分散パターン）
  - 効果量の定量化と統計的検定力の評価
  - 多重比較補正と分布の正規性検定
  - 信頼区間と統計的仮定の妥当性確認
- **批判的考察とディスカッション:**
  - 生物学的妥当性の検証
  - 方法論的制約と交絡因子の評価
  - 再現性と汎用性の考察
  - サンプルの代表性と統計的仮定の検討
- **可視化パターンの高度解釈:** PCA、ヒートマップ、相関行列から読み取れる代謝パターン
- **代謝ネットワーク解析:** 代謝経路の濃縮解析と相互作用ネットワーク評価
- **臨床的意義と応用:** 
  - バイオマーカーの診断性能評価（感度、特異度、予測値）
  - 臨床応用への要件と検証研究デザインの提案
  - 治療標的の評価と介入ポイントの特定

**レポート生成プロセス:**
1. R統計解析の実行（統計的検定、効果量計算、検定力分析）
2. 結果の数値・グラフの生成（可視化とデータ品質評価）
3. **Claude による高度な統計的解釈・分析**
   - 統計的妥当性の包括的評価
   - 生物学的妥当性と方法論的制約の検討
   - 臨床的意義と応用可能性の評価
4. 発見事項とインサイトの文書化
   - **Markdown形式:** 詳細な技術的解釈レポート
   - **HTML形式:** GitHub Pages対応の視覚的レポート（CSS styling、ナビゲーション、レスポンシブデザイン）
5. 研究者と臨床医が理解しやすい形での統合レポート作成

### 🔗 GitHub Pagesでの閲覧

生成されたHTML報告書は、GitHub Pagesを通じてWebブラウザで直接閲覧できます：
- `https://[username].github.io/DataAnalysis/results/metabolomics-analysis/[timestamp]/claude_interpretation.html`
- `https://[username].github.io/DataAnalysis/results/parallel-metabolomics-analysis/[timestamp]/claude_parallel_interpretation.html`

### 🛠️ 実行手順

**1. 単一解析の実行:**
```bash
gh workflow run "Claude · Metabolomics Analysis" --field data_path=fasting.csv
```

**2. 並列解析の実行:**
```bash
gh workflow run "Claude · Parallel Metabolomics Analysis" --field data_path=fasting.csv
```

**3. 解析結果の確認:**
- GitHub Actions タブで実行状況を確認
- 完了後、results/ ディレクトリに解析結果が保存
- HTML報告書はGitHub Pages URLで閲覧可能