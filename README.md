# Jenkins Backup and Restore on AWS S3

## Objective

Implement a reliable backup and restore solution for Jenkins using Amazon S3 to
ensure data protection and fast recovery in the event of server failure.

## Project Context

This project simulates a real-world DevOps scenario where Jenkins job
configurations, plugins, and build data must be preserved after an
infrastructure crash or EC2 replacement.

Backup and restore workflows are executed via **Jenkins Freestyle jobs**, with
the restore process protected by **safe validation and explicit confirmation**
to prevent accidental data loss.

## High-Level Architecture

Jenkins stores all critical state inside the `JENKINS_HOME` directory.  
This project backs up that directory to Amazon S3 and restores it when needed.

```

Jenkins EC2
|
|  backup (tar.gz)
v
Amazon S3
^
|  restore
|
Jenkins EC2

```

## Repository Structure

```

.
├── docs/                # Architecture notes and setup guides
├── scripts/
│   ├── backup/          # Jenkins backup script
│   └── restore/         # Jenkins restore (safe + confirmed) script
├── env/                 # Environment variable documentation
├── keys/                # EC2 keypair documentation
├── evidence/
│   ├── logs/            # Jenkins console output
│   └── screenshots/     # Jenkins job configuration screenshots
├── .env                 # Local environment variables (ignored)
├── Jenkinsfile
└── README.md

````

## Jenkins Jobs

### 1. Jenkins EC2 → S3 Backup Job
- Packages `JENKINS_HOME` into a timestamped archive
- Uploads the archive to Amazon S3
- Executed entirely via Jenkins

### 2. Jenkins EC2 → S3 Restore Job
- Defaults to **safe validation mode**
- Verifies backup existence and archive integrity
- Requires explicit confirmation to perform destructive restore
- Designed to prevent accidental Jenkins data loss

## Environment Configuration (.env)

This project uses a `.env` file at the repository root for local and Jenkins
configuration.

### Required Variables

```env
S3_BUCKET=s3://jenkins-backup-your-bucket-name
AWS_REGION=us-east-2
BACKUP_FILE=jenkins-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
````

> ⚠️ The `.env` file is intentionally excluded from version control.

## Evidence

Execution evidence is provided under the `evidence/` directory, including:

* Jenkins build logs
* Jenkins job configuration screenshots
* Successful backup and restore validations

## Status

✅ Backup job implemented and verified
✅ Restore job implemented with safety controls
🚧 Restore execution performed step-by-step via SSH as documented

## Source Code

Project repository:
[https://github.com/anismerchant/devops-jenkins-backup-restore](https://github.com/anismerchant/devops-jenkins-backup-restore)