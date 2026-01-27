#!/bin/bash
# Jenkins restore validation script (SAFE MODE)
# This script is intentionally non-destructive.
# Actual restore must be performed manually via SSH.

set -euo pipefail

# ------------------------------------------------------------
# Optional: load .env for local runs
# ------------------------------------------------------------
ENV_FILE="$(dirname "$0")/../../.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# ------------------------------------------------------------
# Required env vars (Jenkins should inject these)
# ------------------------------------------------------------
: "${S3_BUCKET:?ERROR: S3_BUCKET is not set}"
: "${AWS_REGION:?ERROR: AWS_REGION is not set}"
: "${BACKUP_FILE:?ERROR: BACKUP_FILE is not set}"

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
RESTORE_DIR="/tmp"
BACKUP_PATH="${RESTORE_DIR}/${BACKUP_FILE}"

# ------------------------------------------------------------
# Validation only (SAFE)
# ------------------------------------------------------------
echo "Validating backup exists in S3..."
aws s3 ls "${S3_BUCKET}/${BACKUP_FILE}" --region "${AWS_REGION}" >/dev/null

echo "Downloading backup for integrity check..."
aws s3 cp "${S3_BUCKET}/${BACKUP_FILE}" "${BACKUP_PATH}" \
  --region "${AWS_REGION}"

echo "Validating archive integrity..."
tar -tzf "${BACKUP_PATH}" >/dev/null

echo "Restore validation completed successfully."
echo "⚠️  Manual restore must be executed via SSH with Jenkins stopped."
