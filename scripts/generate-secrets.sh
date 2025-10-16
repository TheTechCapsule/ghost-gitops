#!/bin/bash
# Example script to generate Ghost secrets at runtime
# This approach is recommended for CI/CD and production deployments

set -euo pipefail

# Generate random passwords
ROOT_PW=$(openssl rand -hex 16)
USER_PW=$(openssl rand -hex 16)

# Apply secrets to Kubernetes
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
  SMTP_USER: "dummy"
  SMTP_PASS: "dummy"
  SMTP_HOST: "smtp.example.com"
  SMTP_PORT: "587"
  SMTP_FROM: "noreply@example.com"
  SMTP_SERVICE: "YourProvider"
YAML

echo "✅ Secrets generated and applied successfully"
echo "🔐 MySQL root password: $ROOT_PW"
echo "🔐 MySQL user password: $USER_PW"
echo "📧 SMTP configuration uses dummy values - update with your SMTP provider"
