#!/bin/bash

# Claude · Metabolomics Analysis をローカルで実行

echo "🧪 Starting Metabolomics Analysis workflow..."

# 必要に応じてAPI keyを設定
if [ -f .env ]; then
    echo "Loading environment variables from .env"
    export $(cat .env | xargs)
fi

# M1/M2 Mac用の設定
act workflow_dispatch \
    --container-architecture linux/amd64 \
    --workflows .github/workflows/metabolomics-analysis.yml \
    --input data_path="fasting.csv" \
    --env-file .env \
    --verbose

echo "✅ Workflow completed!"