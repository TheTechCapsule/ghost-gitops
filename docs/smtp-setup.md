# SMTP Configuration for Ghost

This guide explains how to configure SMTP for email functionality in your Ghost blog.

## Creating the SMTP Secret

Since we don't include secrets in the repository for security reasons, you'll need to create the SMTP secret manually in your cluster.

### Option 1: Using kubectl

```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=your-email@domain.com \
  --from-literal=SMTP_PASS=your-app-password
```

### Option 2: Using a Secret Management Service

For production environments, consider using:
- **HashiCorp Vault**
- **AWS Secrets Manager**
- **Azure Key Vault**
- **Google Secret Manager**

### Option 3: Using Sealed Secrets (GitOps friendly)

```bash
# Install kubeseal if you haven't already
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create the secret
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=your-email@domain.com \
  --from-literal=SMTP_PASS=your-app-password \
  --dry-run=client -o yaml | kubeseal > sealed-smtp-secret.yaml

# Apply the sealed secret
kubectl apply -f sealed-smtp-secret.yaml
```

## Supported SMTP Providers

### Gmail
```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=your-email@gmail.com \
  --from-literal=SMTP_PASS=your-app-password
```

### Generic SMTP Provider
```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=your-email@yourdomain.com \
  --from-literal=SMTP_PASS=your-smtp-password
```

### SendGrid
```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=apikey \
  --from-literal=SMTP_PASS=your-sendgrid-api-key
```

### Amazon SES
```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER=your-ses-access-key \
  --from-literal=SMTP_PASS=your-ses-secret-key
```

## Configuration Details

The SMTP configuration is handled by an init container that generates the Ghost configuration file. The configuration includes:

- **Host**: SMTP server hostname
- **Port**: SMTP port (usually 587 for TLS or 465 for SSL)
- **Security**: TLS/SSL settings
- **Authentication**: Username and password from secrets

## Testing Email Configuration

After deployment, you can test the email configuration by:

1. Going to Ghost Admin → Settings → Email
2. Sending a test email
3. Checking the Ghost logs for any SMTP errors

## Troubleshooting

### Common Issues

1. **Authentication Failed**: Check your SMTP credentials
2. **Connection Timeout**: Verify SMTP host and port
3. **TLS Issues**: Ensure correct security settings

### Debugging

Check the Ghost logs for SMTP-related errors:
```bash
kubectl logs -f deployment/ghost
```

## Security Best Practices

1. **Never commit secrets to Git**
2. **Use app-specific passwords** (not your main password)
3. **Rotate credentials regularly**
4. **Use external secret management** for production
5. **Limit secret access** with RBAC
