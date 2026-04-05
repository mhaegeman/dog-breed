#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# deploy.sh — Deploy the dlt pipeline to Cloud Functions Gen2 and configure
#              Cloud Scheduler for daily 02:00 UTC runs.
#
# Prerequisites:
#   - gcloud CLI authenticated with sufficient permissions
#   - Environment variables set (see below)
#
# Required env vars:
#   GCP_PROJECT_ID          — GCP project ID
#   GCP_REGION              — e.g. us-central1
#   SA_EMAIL                — Service account email for the function
#   DOG_API_KEY             — The Dog API key
#   GCS_BUCKET_URL          — gs://your-bucket-name
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

: "${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
: "${GCP_REGION:?Set GCP_REGION}"
: "${SA_EMAIL:?Set SA_EMAIL}"
: "${DOG_API_KEY:?Set DOG_API_KEY}"
: "${GCS_BUCKET_URL:?Set GCS_BUCKET_URL}"

FUNCTION_NAME="dog-breed-ingest"
SCHEDULER_JOB="dog-breed-daily"

echo "▶ Deploying Cloud Function '${FUNCTION_NAME}' …"
gcloud functions deploy "${FUNCTION_NAME}" \
  --gen2 \
  --project="${GCP_PROJECT_ID}" \
  --region="${GCP_REGION}" \
  --runtime=python312 \
  --source=. \
  --entry-point=handler \
  --trigger-http \
  --no-allow-unauthenticated \
  --timeout=540 \
  --memory=512Mi \
  --set-env-vars="DOG_API_KEY=${DOG_API_KEY},DESTINATION__FILESYSTEM__BUCKET_URL=${GCS_BUCKET_URL}" \
  --service-account="${SA_EMAIL}"

# Retrieve the function URL for the scheduler target
FUNCTION_URL=$(gcloud functions describe "${FUNCTION_NAME}" \
  --gen2 \
  --project="${GCP_PROJECT_ID}" \
  --region="${GCP_REGION}" \
  --format="value(serviceConfig.uri)")

echo "▶ Creating/updating Cloud Scheduler job '${SCHEDULER_JOB}' …"
gcloud scheduler jobs delete "${SCHEDULER_JOB}" \
  --project="${GCP_PROJECT_ID}" \
  --location="${GCP_REGION}" \
  --quiet 2>/dev/null || true

gcloud scheduler jobs create http "${SCHEDULER_JOB}" \
  --project="${GCP_PROJECT_ID}" \
  --location="${GCP_REGION}" \
  --schedule="0 2 * * *" \
  --time-zone="UTC" \
  --uri="${FUNCTION_URL}" \
  --http-method=POST \
  --oidc-service-account-email="${SA_EMAIL}"

echo "✔ Deployment complete."
echo "  Function URL : ${FUNCTION_URL}"
echo "  Schedule     : daily at 02:00 UTC"
