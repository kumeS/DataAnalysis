# n8n × Claude Code 自動化パイプライン

n8nワークフローとClaude Codeを組み合わせた自動化システム

## 目標
- CLIからワークフローを自動実装
- スケジュール設定による自動実行
- Cloud Run上での定期実行

## ディレクトリ構造
```
n8n/
├── cli/                    # CLI tools
├── workflows/              # Workflow templates
├── deployment/             # Cloud Run configuration
├── examples/               # Usage examples
└── docs/                   # Documentation
```