#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-maestro-592cd}"
REGION="${REGION:-europe-west1}"
SERVICE_NAME="${SERVICE_NAME:-focuslane-ai-backend}"
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-$PROJECT_ID}"
CORS_ALLOWLIST="${CORS_ALLOWLIST:-https://tu-dominio.com}"
REQUIRE_APP_CHECK="${REQUIRE_APP_CHECK:-false}"
OPENAI_SECRET_NAME="${OPENAI_SECRET_NAME:-OPENAI_API_KEY}"
MAX_INSTANCES="${MAX_INSTANCES:-20}"

gcloud config set project "$PROJECT_ID"

gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com

if ! gcloud secrets describe "$OPENAI_SECRET_NAME" >/dev/null 2>&1; then
  echo "Secret $OPENAI_SECRET_NAME not found."
  echo "Create it with:"
  echo "  printf '%s' '<OPENAI_API_KEY>' | gcloud secrets create $OPENAI_SECRET_NAME --data-file=- --replication-policy=automatic"
  exit 1
fi

gcloud run deploy "$SERVICE_NAME" \
  --source . \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --allow-unauthenticated \
  --port 8080 \
  --max-instances "$MAX_INSTANCES" \
  --set-env-vars "ENV=production,FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,CORS_ALLOWLIST=$CORS_ALLOWLIST,REQUIRE_APP_CHECK=$REQUIRE_APP_CHECK" \
  --set-secrets "OPENAI_API_KEY=$OPENAI_SECRET_NAME:latest"

SERVICE_URL="$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project "$PROJECT_ID" --format='value(status.url)')"
echo "Cloud Run URL: $SERVICE_URL"
echo "Health check: $SERVICE_URL/v1/healthz"
