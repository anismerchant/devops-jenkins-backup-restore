#!/bin/bash
# Jenkins restore script
# Default: SAFE validation-only
# Destructive restore requires explicit confirmation

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
# Required env vars
# ------------------------------------------------------------
: "${S3_BUCKET:?ERROR: S3_BUCKET is not set}"
: "${AWS_REGION:?ERROR: AWS_REGION is not set}"
: "${BACKUP_FILE:?ERROR: BACKUP_FILE is not set}"

# ------------------------------------------------------------
# Optional safety flags
# ------------------------------------------------------------
# REQUIRE_CONFIRM=true → requires CONFIRM_RESTORE=YES
REQUIRE_CONFIRM="${REQUIRE_CONFIRM:-false}"
CONFIRM_RESTORE="${CONFIRM_RESTORE:-}"

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
JENKINS_HOME="/var/lib/jenkins"
RESTORE_DIR="/tmp"
BACKUP_PATH="${RESTORE_DIR}/${BACKUP_FILE}"

# ------------------------------------------------------------
# Validation (always runs)
# ------------------------------------------------------------
echo "Validating backup exists in S3..."
aws s3 ls "${S3_BUCKET}/${BACKUP_FILE}" --region "${AWS_REGION}" >/dev/null

echo "Downloading backup for integrity check..."
aws s3 cp "${S3_BUCKET}/${BACKUP_FILE}" "${BACKUP_PATH}" \
  --region "${AWS_REGION}"

echo "Validating archive integrity..."
tar -tzf "${BACKUP_PATH}" >/dev/null

# ------------------------------------------------------------
# Safe exit unless explicitly confirmed
# ------------------------------------------------------------
if [ "$REQUIRE_CONFIRM" != "true" ]; then
  echo "Restore validation completed successfully."
  echo "⚠️  Safe mode enabled. No changes applied."
  exit 0
fi

if [ "$CONFIRM_RESTORE" != "YES" ]; then
  echo "ERROR: Restore blocked. Set CONFIRM_RESTORE=YES to proceed."
  exit 1
fi

# ------------------------------------------------------------
# Destructive restore (explicitly confirmed)
# ------------------------------------------------------------
echo "Stopping Jenkins..."
sudo systemctl stop jenkins

echo "Clearing Jenkins home..."
sudo rm -rf "${JENKINS_HOME:?}"/*

echo "Restoring Jenkins backup..."
sudo tar -xzf "${BACKUP_PATH}" -C /var/lib

echo "Fixing ownership..."
sudo chown -R jenkins:jenkins "${JENKINS_HOME}"

echo "Starting Jenkins..."
sudo systemctl start jenkins

echo "Restore completed successfully."
