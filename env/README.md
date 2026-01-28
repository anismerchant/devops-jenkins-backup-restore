# .env File Usage

The `.env` file is used to store **environment-specific configuration values** required by Jenkins backup and restore scripts.

It allows running scripts locally or via SSH **without hardcoding sensitive or environment-dependent values** into the repository.

Typical values stored in `.env` include:
- `S3_BUCKET`
- `AWS_REGION`
- `BACKUP_FILE` (for restore operations)
- Optional safety flags (e.g. `REQUIRE_CONFIRM`)

### Important notes
- The `.env` file is **never committed to Git**
- It is loaded automatically by scripts if present
- Jenkins jobs typically inject these values directly via **Build Steps**, making `.env` optional on the server

The `.env` file exists to:
- Simplify local testing
- Reduce repetition
- Keep scripts portable and environment-agnostic

If `.env` is missing, scripts will rely entirely on environment variables provided by Jenkins or the shell.
