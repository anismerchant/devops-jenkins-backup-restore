## Jenkins EC2 → S3 Backup Project

### Overview

This Jenkins job creates **on-demand backups of Jenkins state** and uploads them to **Amazon S3**.
It runs as a **freestyle Jenkins job** on an **EC2-hosted Jenkins server**, pulling scripts from GitHub and executing them via the Jenkins workspace.

The job is intentionally **simple, explicit, and transparent**, favoring shell scripts over plugins to demonstrate core DevOps concepts.

### Architecture (High Level)

```
Jenkins (EC2)
   |
   |-- Freestyle Job
   |-- GitHub checkout
   |-- Shell script execution
   v
Jenkins Backup (.tar.gz)
   |
   v
Amazon S3 (backup storage)
```

### Repository

* **GitHub Repo**

  ```
  https://github.com/anismerchant/devops-jenkins-backup-restore.git
  ```

* **Branch**

  ```
  main
  ```

The job pulls the latest version of the backup script on each run.

### Jenkins Job Configuration

#### Job Type

* **Freestyle project**

#### Source Code Management

* **Git**
* Repository URL:

  ```
  https://github.com/anismerchant/devops-jenkins-backup-restore.git
  ```
* Credentials:

  ```
  none
  ```
* Branch:

  ```
  */main
  ```

### Build Step (Execute Shell)

The backup job uses a single **Execute shell** build step.

#### Environment Variables

These variables are exported directly inside the build step:

```bash
export AWS_EC2_METADATA_DISABLED=false
export S3_BUCKET=s3://jenkins-backup-and-restore-anis
export AWS_REGION=us-east-2
```

* `AWS_EC2_METADATA_DISABLED=false`
  Allows AWS CLI to use the EC2 instance IAM role.
* `S3_BUCKET`
  Target bucket for Jenkins backups.
* `AWS_REGION`
  AWS region hosting the S3 bucket.


#### Backup Script Execution

```bash
chmod +x scripts/backup/jenkins-backup.sh
scripts/backup/jenkins-backup.sh
```

What this does:

1. Ensures the backup script is executable
2. Executes the backup logic from the checked-out GitHub repo
3. Creates a timestamped Jenkins backup archive
4. Uploads the archive to Amazon S3

---

### Execution Context

* Script runs inside:

  ```
  /var/lib/jenkins/workspace/jenkins-ec2-s3backup-project
  ```
* Jenkins runs as:

  ```
  SYSTEM
  ```
* AWS access is provided via:

  ```
  EC2 IAM Role (no static credentials)
  ```

### Backup Behavior

* Jenkins home data is archived into a `.tar.gz`
* Backup files are named with timestamps:

  ```
  jenkins-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
  ```
* Files are uploaded to:

  ```
  s3://jenkins-backup-and-restore-anis/
  ```

### Verification

Successful runs show:

* Git checkout from `main`
* Backup script execution
* S3 upload completion
* Jenkins build marked **SUCCESS**

Build logs confirm the job completes without modifying Jenkins runtime state 

---

### Design Notes

* No Jenkins plugins required
* No hard-coded AWS credentials
* Script-driven, version-controlled backups
* Safe to run repeatedly
* Works even if restore job is disabled

This job serves as the **foundation** for disaster recovery and pairs with the restore job.