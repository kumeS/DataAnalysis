# n8n × Claude Code 自動化システム ドキュメント

## 概要

このシステムは、**n8n**（ワークフロー自動化プラットフォーム）と**Claude Code**（AI支援コーディング）を組み合わせた、完全自動化されたワークフロー実装・実行システムです。

### 🎯 主要機能

- **自然言語によるワークフロー生成**: Claude Codeが日本語プロンプトからn8nワークフローJSONを自動生成
- **ワンクリックデプロイ**: CLIコマンド一つでn8nインスタンスにワークフローをデプロイ
- **自動スケジューリング**: Cronベースの定期実行設定
- **Cloud Run統合**: Google Cloud Runでの本番運用対応
- **Claude統合解析**: ワークフロー実行結果をClaude Codeで自動解析・レポート生成

## 🚀 クイックスタート

### 1. 環境セットアップ

```bash
# リポジトリクローン
git clone <repository-url>
cd n8n

# 依存関係インストール
npm install

# 環境変数設定
cp examples/env-template .env
# .env ファイルを編集して必要な値を設定
```

### 2. 基本的な使用方法

```bash
# CLIツールの確認
npm start -- --help

# ワークフロー生成
npm start -- generate --prompt "CSVデータを分析してSlackに結果を通知"

# ワークフローデプロイ
npm start -- deploy --file ./workflows/generated-workflow.json --url $N8N_URL --key $N8N_API_KEY

# ワークフロースケジューリング
npm start -- schedule --workflow-id WORKFLOW_ID --cron "0 9 * * *"

# 完全自動化（生成→デプロイ→スケジュール）
npm start -- auto --prompt "データ分析ワークフロー" --url $N8N_URL --key $N8N_API_KEY --cron "0 9 * * *"
```

### 3. Cloud Runデプロイ

```bash
# 環境変数設定
export PROJECT_ID="your-project-id"
export N8N_API_KEY="your-api-key"
export CLAUDE_API_KEY="your-claude-key"

# デプロイ実行
chmod +x deployment/deploy.sh
./deployment/deploy.sh
```

## 📁 ディレクトリ構造

```
n8n/
├── cli/                          # CLIツール
│   ├── index.js                  # メインCLI
│   ├── workflow-generator.js     # ワークフロー生成
│   ├── n8n-client.js            # n8n API クライアント
│   ├── scheduler.js              # スケジューラー
│   └── utils/
│       └── logger.js             # ログ管理
├── workflows/
│   └── templates/                # ワークフローテンプレート
│       ├── data-analysis-template.json
│       ├── api-monitoring-template.json
│       └── report-generation-template.json
├── deployment/                   # デプロイメント設定
│   ├── Dockerfile
│   ├── cloudbuild.yaml
│   ├── cloud-run-service.yaml
│   ├── deploy.sh
│   └── terraform/
│       └── main.tf
├── examples/                     # 使用例
│   ├── basic-usage.js
│   └── env-template
└── docs/                         # ドキュメント
    ├── README.md
    ├── api-reference.md
    ├── workflow-templates.md
    └── deployment-guide.md
```

## 🤖 Claude Code統合機能

### ワークフロー生成プロセス

1. **プロンプト解析**: 自然言語の要求を解析
2. **テンプレート選択**: 最適なワークフローテンプレートを選択
3. **カスタマイゼーション**: プロンプトに基づいてテンプレートを調整
4. **JSON生成**: n8n互換のワークフローJSONを生成

### 対応ワークフロータイプ

- **データ解析** (`data-analysis`): CSV処理、統計解析、レポート生成
- **API監視** (`api-monitoring`): ヘルスチェック、アラート、障害分析
- **レポート生成** (`report-generation`): 定期レポート、HTML/Markdown出力

### Claude解析機能

各ワークフローテンプレートには、Claude Codeによる高度な解析機能が組み込まれています：

- **データ解析**: 統計的洞察、異常検出、予測分析
- **監視アラート**: 障害原因分析、復旧提案、予防策
- **レポート生成**: トレンド分析、ビジネスインサイト、推奨事項

## 🔧 CLI コマンドリファレンス

### `generate` - ワークフロー生成

```bash
npm start -- generate [options]

オプション:
  -p, --prompt <prompt>    ワークフロー説明プロンプト
  -o, --output <file>      出力ファイルパス (default: "./workflows/generated-workflow.json")
```

### `deploy` - ワークフローデプロイ

```bash
npm start -- deploy [options]

オプション:
  -f, --file <file>        ワークフローJSONファイル
  -u, --url <url>          n8nインスタンスURL
  -k, --key <key>          APIキー
```

### `schedule` - ワークフロースケジューリング

```bash
npm start -- schedule [options]

オプション:
  -w, --workflow-id <id>   ワークフローID
  -c, --cron <expression>  Cron式
```

### `auto` - 完全自動化

```bash
npm start -- auto [options]

オプション:
  -p, --prompt <prompt>        ワークフロー説明
  -u, --url <url>              n8nインスタンスURL
  -k, --key <key>              APIキー
  -c, --cron <expression>      Cron式 (default: "0 9 * * *")
```

## 🌐 API エンドポイント

スケジューラーサーバーが提供するAPI:

- `GET /schedules` - スケジュール一覧取得
- `POST /schedules` - 新規スケジュール作成
- `PUT /schedules/:jobKey` - スケジュール更新
- `DELETE /schedules/:jobKey` - スケジュール削除

## 📋 使用例

### 例1: データ解析の自動化

```bash
# CSVファイルの統計解析を毎日実行
npm start -- auto \
  --prompt "fasting.csvを読み込んで統計解析を実行し、結果をSlackの#data-analysisチャンネルに投稿" \
  --url "https://your-n8n.com" \
  --key "your-api-key" \
  --cron "0 9 * * *"
```

### 例2: API監視の設定

```bash
# APIヘルスチェックを5分毎に実行
npm start -- auto \
  --prompt "https://api.example.com/healthをモニタリングし、異常時はアラートを送信してClaude Codeで障害分析を実行" \
  --url "https://your-n8n.com" \
  --key "your-api-key" \
  --cron "*/5 * * * *"
```

### 例3: 週次レポート生成

```bash
# 毎週月曜日にレポート生成
npm start -- auto \
  --prompt "週次業績データを収集してHTMLレポートを生成し、経営陣にメール送信" \
  --url "https://your-n8n.com" \
  --key "your-api-key" \
  --cron "0 8 * * 1"
```

## 🛠️ カスタマイゼーション

### カスタムワークフローテンプレート

新しいワークフロータイプを追加する場合：

1. `workflows/templates/` に新しいテンプレートJSONを作成
2. `cli/workflow-generator.js` の `templates` オブジェクトに追加
3. `analyzePrompt` メソッドにキーワード判定ロジックを追加

### Claude統合のカスタマイゼーション

ワークフロー内のClaude解析ロジックは、各テンプレートの `function` ノードで定義されています。必要に応じてカスタマイズ可能です。

## 🚨 トラブルシューティング

### よくある問題

1. **API接続エラー**: n8nのURLとAPIキーを確認
2. **ワークフロー生成失敗**: プロンプトの内容を具体的に記述
3. **デプロイエラー**: n8nインスタンスのバージョン互換性を確認
4. **スケジュール実行失敗**: Cron式の構文を確認

### ログ確認

```bash
# ログファイルの確認
tail -f logs/combined.log
tail -f logs/error.log
```

## 🔒 セキュリティ考慮事項

- APIキーは環境変数で管理
- Cloud RunではSecret Managerを使用
- ワークフロー実行時の権限を最小限に制限
- ログに機密情報を記録しない

## 📞 サポート

- 技術的な質問: GitHub Issues
- 機能要望: GitHub Discussions
- バグレポート: GitHub Issues

---

**Generated by n8n × Claude Code Integration**