# AWS S3 Setup for Jenkins Backups

## Purpose
Create durable, external storage for Jenkins backups so data survives
EC2 failure or termination.

## Why S3
- High durability (designed for 11 nines)
- Cheap storage for archives
- Native integration with AWS CLI
- Industry-standard backup destination

## S3 Bucket Design

- Bucket name: jenkins-backup-<**unique-id**>
- Region: same as EC2 (to reduce latency)
- Access: private
- Versioning: optional (recommended)

## Architecture Context

```

[Jenkins EC2]
|
|  aws s3 cp
v
[S3 Bucket]

```

## Security Model

Preferred:
- EC2 **IAM Role** with S3 access
- No hardcoded AWS credentials

Avoid:
- Storing access keys in scripts
- Committing credentials to Git

## Required Permissions (High Level)

- s3:PutObject
- s3:GetObject
- s3:ListBucket

## Validation Checklist

- Bucket exists
- EC2 can list bucket contents
- No public access enabled