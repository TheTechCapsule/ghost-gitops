## What changed?
- [ ] Dev
- [ ] Staging
- [ ] Prod

## Why?
Brief reason / link to issue.

## Checklists
- [ ] Kustomize builds for all overlays
- [ ] No `:latest` in prod
- [ ] No PVC spec mutations (name, storageClassName, selector, volumeName)
- [ ] No Ingress snippet annotations
- [ ] ArgoCD sync is expected to be rolling, not destructive

## Screens/Logs (optional)