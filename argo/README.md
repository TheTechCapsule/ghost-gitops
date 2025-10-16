# ArgoCD Applications

This directory contains ArgoCD Application manifests for deploying the Ghost blog stack.

## Structure

```
argo/
├── README.md                    # This file
├── app-root.yaml               # Root application (example)
├── examples/                   # Example applications for each overlay
│   ├── ghost-dev-app.yaml
│   ├── ghost-staging-app.yaml
│   └── ghost-prod-app.yaml
└── apps/                       # Your actual applications
    └── kustomization.yaml
```

## Setup Instructions

### 1. Copy Example Applications

Copy the example applications from `examples/` to `apps/` and customize them:

```bash
cp argo/examples/*.yaml argo/apps/
```

### 2. Update Repository URL

Edit each application file in `apps/` and update the `repoURL`:

```yaml
spec:
  source:
    repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO.git
    targetRevision: main
```

### 3. Update Application Names

Customize the application names to match your setup:

```yaml
metadata:
  name: your-ghost-dev      # instead of ghost-dev
  name: your-ghost-staging  # instead of ghost-staging
  name: your-ghost-prod     # instead of ghost-prod
```

### 4. Update Namespaces

Adjust namespaces as needed:

```yaml
spec:
  destination:
    namespace: your-namespace  # instead of default/ghost-staging
```

### 5. Apply Applications

Apply the root application to bootstrap everything:

```bash
kubectl apply -f argo/app-root.yaml
```

## Application Types

### Development (`ghost-dev-app.yaml`)
- **Namespace**: `default`
- **Sync Policy**: Automated with self-heal
- **Purpose**: Development and testing

### Staging (`ghost-staging-app.yaml`)
- **Namespace**: `ghost-staging`
- **Sync Policy**: Automated with self-heal
- **Purpose**: Pre-production testing

### Production (`ghost-prod-app.yaml`)
- **Namespace**: `default`
- **Sync Policy**: Manual (recommended for production)
- **Purpose**: Live production environment

## Customization

### Adding New Environments

1. Copy an existing application file
2. Update the `name`, `namespace`, and `path` fields
3. Adjust sync policies as needed
4. Add to `apps/kustomization.yaml`

### Branch-based Deployments

For branch-based deployments, update the `targetRevision`:

```yaml
spec:
  source:
    targetRevision: staging  # deploy from staging branch
```

### Multi-cluster Deployments

For multi-cluster setups, update the destination:

```yaml
spec:
  destination:
    server: https://your-cluster.example.com
    namespace: your-namespace
```

## Security Considerations

- **Secrets**: Never commit actual secrets to the repository
- **RBAC**: Configure proper ArgoCD RBAC for production
- **Sync Policies**: Use manual sync for production environments
- **Namespaces**: Use dedicated namespaces for different environments

## Troubleshooting

### Common Issues

1. **Application not syncing**: Check repository URL and permissions
2. **Namespace issues**: Ensure namespaces exist or `CreateNamespace=true`
3. **Resource conflicts**: Check for duplicate resource names across applications

### Useful Commands

```bash
# Check application status
kubectl get applications -n argocd

# Force sync an application
argocd app sync your-ghost-dev

# Check application logs
kubectl logs -n argocd deployment/argocd-application-controller
```
