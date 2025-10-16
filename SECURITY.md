# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public issue
2. Email security details to: security@thetechcapsule.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Considerations

### Secrets Management

- Never commit actual secrets to the repository
- Use external secret management systems in production
- Rotate secrets regularly
- Follow principle of least privilege

### Network Security

- Network policies are included by default
- Review and customize for your environment
- Consider additional security layers (WAF, etc.)

### Container Security

- Images are pinned to specific versions
- Regular security updates via Renovate
- Non-root containers where possible
- Read-only root filesystems

### TLS/SSL

- Automatic certificate management via cert-manager
- TLS 1.2+ enforced
- HSTS headers included

## Security Best Practices

1. **Regular Updates**: Keep all components updated
2. **Access Control**: Use RBAC and network policies
3. **Monitoring**: Enable security monitoring and logging
4. **Backups**: Regular, tested backups
5. **Auditing**: Regular security audits

## Response Timeline

- **Critical vulnerabilities**: 24-48 hours
- **High severity**: 1 week
- **Medium/Low severity**: 2-4 weeks

We appreciate your help in keeping this project secure!
