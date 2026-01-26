#!/bin/bash
# Run this script using bash

# Exit immediately if any command fails
# Prevents partial restores that could corrupt Jenkins
set -e

# ------------------------------------------------------------
# Load environment variables from .env at project root
# ------------------------------------------------------------
if [ -f "$(dirname "$0")/../../.env" ]; then
  set -a
  source "$(dirname "$0")/../../.env"
  set +a
else
  echo "ERROR: .env file not found at project root"
  exit 1
fi

# ------------------------------------------------------------
# Validate required environment variables
# ------------------------------------------------------------
: "${S3_BUCKET:?ERROR: S3_BUCKET is not set}"
: "${AWS_REGION:?ERROR: AWS_REGION is not set}"
: "${BACKUP_FILE:?ERROR: BACKUP_FILE is not set}"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
JENKINS_HOME="/var/lib/jenkins"
RESTORE_DIR="/tmp"

# ------------------------------------------------------------
# Restore process
# ------------------------------------------------------------
echo "Stopping Jenkins service..."
sudo systemctl stop jenkins

echo "Downloading backup from S3..."
aws s3 cp "${S3_BUCKET}/${BACKUP_FILE}" "${RESTORE_DIR}/" \
  --region "${AWS_REGION}"

echo "Clearing existing Jenkins data..."
sudo rm -rf "${JENKINS_HOME:?}/*"

echo "Restoring Jenkins backup..."
sudo tar -xzf "${RESTORE_DIR}/${BACKUP_FILE}" -C /var/lib

echo "Fixing ownership..."
sudo chown -R jenkins:jenkins "${JENKINS_HOME}"

echo "Starting Jenkins service..."
sudo systemctl start jenkins

echo "Restore completed successfully."