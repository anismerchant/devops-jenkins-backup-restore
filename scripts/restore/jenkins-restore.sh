#!/bin/bash
# Safe Jenkins restore script with optional guards

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
# Optional safety flags
# ------------------------------------------------------------
# REQUIRE_CONFIRM=true   → requires CONFIRM_RESTORE=YES
# DRY_RUN=true           → validates only, no changes
REQUIRE_CONFIRM="${REQUIRE_CONFIRM:-false}"
DRY_RUN="${DRY_RUN:-false}"

if [ "$REQUIRE_CONFIRM" = "true" ] && [ "${CONFIRM_RESTORE:-}" != "YES" ]; then
  echo "ERROR: Restore blocked. Set CONFIRM_RESTORE=YES to proceed."
  exit 1
fi

# ------------------------------------------------------------
# Config
# ------------------------------------------------------------
JENKINS_HOME="/var/lib/jenkins"
RESTORE_DIR="/tmp"
BACKUP_PATH="${RESTORE_DIR}/${BACKUP_FILE}"

# ------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------
echo "Checking backup exists in S3..."
aws s3 ls "${S3_BUCKET}/${BACKUP_FILE}" --region "${AWS_REGION}" >/dev/null

if [ "$DRY_RUN" = "true" ]; then
  echo "DRY_RUN enabled — restore validated, no changes made."
  exit 0
fi

# ------------------------------------------------------------
# Restore
# ------------------------------------------------------------
echo "Stopping Jenkins..."
sudo systemctl stop jenkins

echo "Downloading backup..."
aws s3 cp "${S3_BUCKET}/${BACKUP_FILE}" "${BACKUP_PATH}" \
  --region "${AWS_REGION}"

echo "Clearing Jenkins home..."
sudo rm -rf "${JENKINS_HOME:?}"/*

echo "Extracting backup..."
sudo tar -xzf "${BACKUP_PATH}" -C /var/lib

echo "Fixing ownership..."
sudo chown -R jenkins:jenkins "${JENKINS_HOME}"

echo "Starting Jenkins..."
sudo systemctl start jenkins

echo "Restore completed successfully."
