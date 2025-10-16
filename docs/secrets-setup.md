# Secrets Setup

This repository uses a secure approach for managing secrets that avoids storing sensitive data in the repository.

## Approach

Instead of hardcoded secrets in YAML files, we generate secrets at runtime using random passwords. This approach:

- ✅ Keeps no secrets in the repository
- ✅ Uses cryptographically secure random passwords
- ✅ Works well with CI/CD pipelines
- ✅ Prevents accidental exposure of sensitive data

## Quick Setup

Run the provided script to generate and apply secrets:

```bash
./scripts/generate-secrets.sh
```

## Manual Setup

If you prefer to create secrets manually:

```bash
# Generate random passwords
ROOT_PW=$(openssl rand -hex 16)
USER_PW=$(openssl rand -hex 16)

# Apply secrets
kubectl apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ghost-mysql-secret
type: Opaque
stringData:
  mysql-root-password: "$ROOT_PW"
  mysql-user-password: "$USER_PW"
---
apiVersion: v1
kind: Secret
metadata:
  name: ghost-smtp-secret
type: Opaque
stringData:
  SMTP_USER: "your-smtp-user@example.com"
  SMTP_PASS: "your-smtp-password"
  SMTP_HOST: "smtp.your-provider.com"
  SMTP_PORT: "587"
  SMTP_FROM: "noreply@yourdomain.com"
  SMTP_SERVICE: "YourProvider"
YAML
```

## Required Secrets

### MySQL Secrets (`ghost-mysql-secret`)
- `mysql-root-password`: Root password for MySQL
- `mysql-user-password`: Password for the Ghost database user

### SMTP Secrets (`ghost-smtp-secret`)
- `SMTP_USER`: SMTP username
- `SMTP_PASS`: SMTP password
- `SMTP_HOST`: SMTP server hostname
- `SMTP_PORT`: SMTP server port (usually 587 or 465)
- `SMTP_FROM`: From email address
- `SMTP_SERVICE`: SMTP service name (optional, for some providers)

## CI/CD Integration

For automated deployments, you can integrate secret generation into your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Generate and apply secrets
  run: |
    ROOT_PW=$(openssl rand -hex 16)
    USER_PW=$(openssl rand -hex 16)
    
    kubectl apply -f - <<YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: ghost-mysql-secret
    type: Opaque
    stringData:
      mysql-root-password: "$ROOT_PW"
      mysql-user-password: "$USER_PW"
    YAML
```

## Security Notes

- Never commit actual secrets to the repository
- Use environment variables for sensitive data in CI/CD
- Rotate passwords regularly in production
- Consider using external secret management systems (e.g., HashiCorp Vault, AWS Secrets Manager) for production environments
