# EC2 Key Pair Requirement

When launching a new EC2 instance, an **EC2 key pair must be generated or selected**.

This key pair is required to:
- SSH into the EC2 instance
- Perform administrative tasks (install Jenkins, manage services, restore backups)
- Recover or troubleshoot the instance if Jenkins becomes unavailable

AWS only allows downloading the **private key (.pem)** at creation time.  
If the key is lost, it **cannot be recovered**.  A new key pair must be created and attached via instance recovery steps.

For this project:
- The EC2 key pair is generated during instance launch
- The `.pem` file is stored securely and **never committed to Git**
- All Jenkins backup/restore operations assume SSH access via this key

Without an EC2 key pair, Jenkins restore operations **cannot be safely executed**.
