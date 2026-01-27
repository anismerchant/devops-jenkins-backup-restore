# Jenkins Installation (EC2)

## Purpose
Provision a Jenkins server whose data can later be backed up and restored.

## Target Environment

- Cloud: AWS EC2
- OS: Amazon Linux 2
- Jenkins runs as a system service
- Jenkins data stored under `JENKINS_HOME`

Default:
```

/var/lib/jenkins

```

## Installation Steps (High Level)

1. Launch EC2 instance
2. Install Java (Jenkins dependency)
3. Install Jenkins
4. Start and enable Jenkins service
5. Access Jenkins UI and complete setup

## Architecture Context

```

[EC2 Instance]
|
|-- Jenkins service
|-- JENKINS_HOME (/var/lib/jenkins)

```

Jenkins configuration, jobs, plugins, and credentials all live inside
`JENKINS_HOME`. This directory is the **backup target**.

**Backup target** = **the exact data you choose to protect**.

In this project, the **backup target is the `JENKINS_HOME` directory**.

### Concretely

```
Backup target
└── /var/lib/jenkins
```

### Why this is the backup target

* Jenkins is **stateful**
* Everything Jenkins needs to function lives here:

  * Jobs
  * Pipelines
  * Plugins
  * Credentials (encrypted)
  * Build history
  * Global config

If you restore this directory, Jenkins is restored.

### In architecture terms

* **Backup target** → *source of truth*
* **Backup destination** → S3
* **Backup mechanism** → tar + upload script

```
[JENKINS_HOME]  ← backup target
      |
      v
   [S3 bucket]  ← backup destination
```

## Why Jenkins Must Be Installed First

- Backup scripts depend on `JENKINS_HOME`
- Freestyle jobs must exist to validate restore
- Confirms Jenkins runs correctly before automation

## Validation Checklist

- Jenkins UI accessible on port 8080
- Jenkins service running
- `JENKINS_HOME` directory populated

## Jenkins Backup to S3 on AWS EC2

This project sets up **Jenkins on EC2** and backs up `/var/lib/jenkins` to **Amazon S3** using an **IAM Role (no access keys)**.

The documentation intentionally includes **real gotchas** encountered during setup, because these are the exact issues engineers hit in production.


## Architecture (High Level)

```
GitHub Repo
   ↓
Jenkins (EC2, t3.medium)
   ↓
Shell Script (backup)
   ↓
Amazon S3 (versioned backups)
```

## EC2 Setup (Important Gotchas)

### ✅ Instance Type Matters

**Use `t3.medium` (minimum).**

**Why:**

* Jenkins + Git + Java + tar + S3 upload easily overwhelm `t3.micro`
* Low-memory instances caused:

  * Jenkins UI freezes
  * SSH hanging
  * Jobs appearing “stuck”

**Lesson:** Jenkins is not a “free-tier-friendly” service.

### ✅ Attach IAM Role at Launch (or After)

Jenkins relies on **EC2 Instance Metadata (IMDSv2)** to obtain AWS credentials.

**IAM Role permissions (minimum):**

```json
s3:ListBucket        → bucket
s3:GetObject         → bucket/*
s3:PutObject         → bucket/*
```

**No access keys are stored anywhere.**

## SSH Access & GitHub Deploy Key (Lab Setup)

For labs and learning environments, Jenkins authenticates to GitHub using a **one-off deploy key**.

### Generate SSH key on EC2

```bash
ssh-keygen -t ed25519 -C "jenkins" -f ~/.ssh/jenkins_github -N ""
```

### Copy public key

```bash
cat ~/.ssh/jenkins_github.pub
```

### GitHub

* Repo → **Settings → Deploy Keys**
* Add key (Read-only is sufficient)

### Make Key Available to Jenkins User

```bash
sudo mkdir -p /var/lib/jenkins/.ssh
sudo cp ~/.ssh/jenkins_github* /var/lib/jenkins/.ssh/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/jenkins_github
```

Optional SSH config:

```bash
sudo vi /var/lib/jenkins/.ssh/config
```

```text
Host github.com
  IdentityFile ~/.ssh/jenkins_github
  StrictHostKeyChecking no
```

## Jenkins Installation (Amazon Linux 2023)

### Install Java (Required)

```bash
sudo dnf install -y java-17-amazon-corretto-headless fontconfig
java -version
```

### Install Jenkins

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

### Get Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins:

```
http://<EC2_PUBLIC_IP>:8080
```

## Git Is NOT Installed by Default (Critical Gotcha)

Jenkins **does not bundle git**.
If `git` is missing, jobs fail with:

```
Cannot run program "git": No such file or directory
```

### Fix

```bash
sudo dnf install -y git
which git
git --version
sudo systemctl restart jenkins
```

✔ This was the root cause of repeated checkout failures.

## Backup Script Behavior

### Script Location

```
scripts/backup/jenkins-backup.sh
```

### What It Does

* Archives `/var/lib/jenkins`
* Names backups with timestamps
* Uploads to S3
* Uses **IAM role credentials only**

### Environment Variables

Provided via Jenkins job (not committed):

```bash
S3_BUCKET=s3://jenkins-backup-and-restore-anis
AWS_REGION=us-east-2
```

## Jenkins Job Configuration (Freestyle)

**Why Freestyle?**
Clear separation of concerns for learning:

* Jenkins orchestrates
* Shell script does the work

### Build Step

```bash
chmod +x scripts/backup/jenkins-backup.sh
scripts/backup/jenkins-backup.sh
```

## Gotchas & Lessons Learned (Read This)

### 🔴 Git Installed ≠ Jenkins Can Use It

* Jenkins must be restarted after installing system binaries
* Jenkins runs as its own user with its own PATH

### 🔴 “Unable to locate credentials”

This does **not** mean IAM is broken.

Root causes encountered:

* IAM role not attached to instance
* IMDS disabled
* Jenkins started before role attachment
* EC2 instance too small → metadata calls timing out

**Fix that worked:**

```bash
export AWS_EC2_METADATA_DISABLED=false
```

(Then restart Jenkins)

### 🔴 Jenkins UI / SSH Hanging

Caused by:

* `t3.micro`
* Memory pressure during tar + S3 upload

**Solution:** resize to `t3.medium`

## Verification Checklist

```bash
aws sts get-caller-identity
aws s3 ls s3://jenkins-backup-and-restore-anis
```

Jenkins build log should end with:

```
Backup completed successfully
Finished: SUCCESS
```

## Why This Design Is Correct (Engineering Reasoning)

* ✅ IAM Role → no secret sprawl
* ✅ Scripts are reusable locally and in CI
* ✅ Jenkins job stays thin
* ✅ Failure modes are observable in logs
* ✅ Matches real AWS production patterns