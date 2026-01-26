#!/bin/bash
# Use bash shell to run this script

# Exit immediately if any command fails (non-zero exit code)
# This prevents partial or corrupted backups
set -e

# ------------------------------------------------------------
# Load environment variables from .env at project root
# ------------------------------------------------------------
# We compute the path relative to this script so it works
# no matter where the script is executed from.
if [ -f "$(dirname "$0")/../../.env" ]; then
  # Automatically export all variables loaded from the file
  set -a
  source "$(dirname "$0")/../../.env"
  # Stop auto-exporting variables
  set +a
else
  echo "ERROR: .env file not found at project root"
  exit 1
fi

# ------------------------------------------------------------
# Validate required environment variables
# ------------------------------------------------------------
# The ":" is a no-op command.
# This syntax fails the script immediately if a variable is unset.
: "${S3_BUCKET:?ERROR: S3_BUCKET is not set}"
: "${AWS_REGION:?ERROR: AWS_REGION is not set}"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
# JENKINS_HOME is where Jenkins stores ALL state
JENKINS_HOME="/var/lib/jenkins"

# Temporary directory to store the backup archive
BACKUP_DIR="/tmp"

# Timestamp ensures every backup file is unique
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Final backup archive name
BACKUP_FILE="jenkins-backup-${TIMESTAMP}.tar.gz"

# ------------------------------------------------------------
# Backup process
# ------------------------------------------------------------
echo "Creating Jenkins backup..."

# Create a compressed tar archive of JENKINS_HOME
# -c : create archive
# -z : gzip compression
# -f : output file
# -C : change directory before archiving
# This avoids embedding absolute paths in the archive
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" -C /var/lib jenkins

echo "Uploading backup to S3..."

# Upload the archive to S3 using AWS CLI
# IAM role is assumed automatically (no credentials in code)
aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "${S3_BUCKET}/" \
  --region "${AWS_REGION}"

echo "Backup completed successfully: ${BACKUP_FILE}"