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