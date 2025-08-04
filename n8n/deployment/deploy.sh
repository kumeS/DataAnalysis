#!/bin/bash

# n8n × Claude Code Cloud Run Deployment Script
set -e

# Configuration
PROJECT_ID=${PROJECT_ID:-"your-project-id"}
REGION=${REGION:-"asia-northeast1"}
SERVICE_NAME="n8n-claude-automation"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Starting deployment of n8n × Claude Code automation to Cloud Run..."

# Check required environment variables
if [ -z "$PROJECT_ID" ]; then
    echo "❌ ERROR: PROJECT_ID environment variable is required"
    exit 1
fi

if [ -z "$N8N_API_KEY" ]; then
    echo "❌ ERROR: N8N_API_KEY environment variable is required"
    exit 1
fi

if [ -z "$CLAUDE_API_KEY" ]; then
    echo "❌ ERROR: CLAUDE_API_KEY environment variable is required"
    exit 1
fi

# Set Google Cloud project
echo "📝 Setting project: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required Google Cloud APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Create secrets for API keys
echo "🔐 Creating secrets for API keys..."
echo -n "$N8N_API_KEY" | gcloud secrets create n8n-api-key --data-file=- --replication-policy="automatic" || true
echo -n "$CLAUDE_API_KEY" | gcloud secrets create claude-api-key --data-file=- --replication-policy="automatic" || true

# Update secrets if they already exist
echo -n "$N8N_API_KEY" | gcloud secrets versions add n8n-api-key --data-file=- || true
echo -n "$CLAUDE_API_KEY" | gcloud secrets versions add claude-api-key --data-file=- || true

# Build and deploy using Cloud Build
echo "🏗️ Building and deploying with Cloud Build..."
gcloud builds submit --config=deployment/cloudbuild.yaml .

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
gcloud run services wait $SERVICE_NAME --region=$REGION

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo "✅ Deployment completed successfully!"
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "📋 Next steps:"
echo "1. Test the service: curl $SERVICE_URL/health"
echo "2. Use the CLI: n8n-claude-cli --help"
echo "3. Generate workflow: n8n-claude-cli generate --prompt 'データ解析ワークフロー'"
echo "4. Deploy workflow: n8n-claude-cli deploy --file ./workflows/generated-workflow.json"
echo "5. Schedule workflow: n8n-claude-cli schedule --workflow-id WORKFLOW_ID --cron '0 9 * * *'"
echo ""
echo "🔧 For complete automation:"
echo "n8n-claude-cli auto --prompt 'データ解析とレポート生成' --url $SERVICE_URL --key \$N8N_API_KEY"