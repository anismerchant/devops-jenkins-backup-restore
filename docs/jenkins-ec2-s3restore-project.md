## Jenkins EC2 ← S3 Restore Project

### Overview

This Jenkins job **validates and optionally restores** a Jenkins backup from **Amazon S3** onto an **EC2-hosted Jenkins server**.

The restore process is **intentionally safety-first**:

* Jenkins jobs run in **validation-only (safe mode)** by default
* **Destructive restore is blocked** unless explicitly confirmed
* Full restore is designed to be run **manually via SSH**, not automatically by Jenkins

This mirrors real-world operational discipline.

### Architecture (High Level)

```
Amazon S3
   |
   |-- Jenkins backup (.tar.gz)
   v
Jenkins Restore Job (EC2)
   |
   |-- GitHub checkout
   |-- Validation-only restore script
   v
Manual SSH Restore (explicit confirmation)
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

The restore job also uses a single **Execute shell** build step.

#### Environment Variables

```bash
export AWS_EC2_METADATA_DISABLED=false
export S3_BUCKET=s3://jenkins-backup-and-restore-anis
export AWS_REGION=us-east-2
export BACKUP_FILE=jenkins-backup-2026-01-27_21-39-47.tar.gz
```

* `BACKUP_FILE` explicitly selects the backup to restore
* No guessing or “latest backup” logic is used

#### Restore Script Execution

```bash
chmod +x scripts/restore/jenkins-restore.sh
scripts/restore/jenkins-restore.sh
```

### Default Behavior: SAFE MODE

By default, the restore script **does not modify Jenkins**.

What the Jenkins job does:

1. Verifies the backup exists in S3
2. Downloads the backup to a temp directory
3. Validates archive integrity (`tar -tzf`)
4. Exits successfully **without stopping Jenkins**

Output clearly indicates safe mode:

```
Restore validation completed successfully.
⚠️  Safe mode enabled. No changes applied.
```

This ensures:

* Jenkins never shuts itself down
* No accidental data loss
* Job is safe to re-run repeatedly

Build logs confirm this behavior

### Manual Restore (SSH Only)

Actual restoration **must be performed manually via SSH**.

This is by design.

#### Required Flags for Destructive Restore

```bash
REQUIRE_CONFIRM=true
CONFIRM_RESTORE=YES
```

These flags **cannot be accidentally set** by Jenkins UI alone.

### Manual Restore Command (Example)

Run **on the EC2 instance via SSH**, not from Jenkins:

```bash
sudo S3_BUCKET=s3://jenkins-backup-and-restore-anis \
     AWS_REGION=us-east-2 \
     BACKUP_FILE=jenkins-backup-2026-01-27_21-39-47.tar.gz \
     REQUIRE_CONFIRM=true \
     CONFIRM_RESTORE=YES \
     ./scripts/restore/jenkins-restore.sh
```

### What the Script Does (Confirmed Restore)

1. Stops Jenkins
2. Clears `/var/lib/jenkins`
3. Extracts backup contents
4. Fixes ownership (`jenkins:jenkins`)
5. Restarts Jenkins

This guarantees:

* Clean restore
* Correct permissions
* Predictable behavior

### Execution Context

* Jenkins workspace:

  ```
  /var/lib/jenkins/workspace/jenkins-ec2-s3restore-project
  ```
* Jenkins service control:

  ```
  systemctl stop|start jenkins
  ```

### Safety Design Rationale

| Risk                     | Mitigation                  |
| ------------------------ | --------------------------- |
| Accidental restore       | Explicit confirmation flags |
| Jenkins self-termination | Manual SSH restore only     |
| Data corruption          | Archive integrity check     |
| Credential leakage       | IAM role only               |
| Script misuse            | Safe mode default           |

This is aligned with **production-grade restore workflows**.

### Result

* Jenkins job: **SUCCESS**
* Jenkins service: **Running**
* No restore executed automatically
* Restore path verified and documented

This job completes the **backup / restore lifecycle**.

