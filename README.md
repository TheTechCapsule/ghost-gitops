# Ghost Capsule 🚀

[![Validate Kustomize overlays](https://github.com/TheTechCapsule/ghost-gitops/actions/workflows/validate.yaml/badge.svg)](https://github.com/TheTechCapsule/ghost-gitops/actions/workflows/validate.yaml)
[![Smoke test](https://github.com/TheTechCapsule/ghost-gitops/actions/workflows/smoke-kind.yaml/badge.svg)](https://github.com/TheTechCapsule/ghost-gitops/actions/workflows/smoke-kind.yaml)

Ghost blog on Kubernetes with GitOps

This repository contains a Ghost (the open source publishing platform) deployment using modern GitOps practices. I found this approach interesting and use it myself for the TTC blog.

This repo is an opinionated deployment using:

- **Kustomize** (base + overlays for dev/prod)
- **ArgoCD** (GitOps-first, no manual kubectl applys)
- **MySQL** (in-cluster by default, with hooks for external DB if you want later)
- **cert-manager + nginx-ingress** (TLS with Let's Encrypt baked in)
- **Backup jobs** (PVC snapshots + MySQL dumps, with restore jobs included)

The goal is simple:
👉 Spin up Ghost in a cluster — clean, reproducible, Git-driven.
👉 A solid base, which can be extended and tweaked as required.

## 📂 Repo Structure

```
apps/ghost/
  base/           # shared manifests (Ghost, MySQL, PVCs, backups, monitoring, PDBs)
  overlays/
    dev/          # dev overlay (local hostnames, no TLS hardening)
    staging/      # staging overlay (TLS, real domain, SMTP)
    prod/         # prod overlay (TLS, real domain, SMTP, hardened ingress)
    e2e/          # e2e testing overlay
argo/             # ArgoCD Application definitions
docs/             # setup notes, SMTP, runbooks
cert-manager/     # TLS certificate management
scripts/          # automation scripts
.github/workflows # CI validation
```

## 🛠️ Prerequisites

- **Kubernetes cluster** (tested with k3s + k8s 1.30+)
- **Ingress controller** (nginx-ingress recommended, Traefik works with tweaks)
- **cert-manager installed + DNS access** (any DNS provider with API support)
- **ArgoCD running** (this repo expects GitOps, not manual applies)
- **SMTP account** (any provider: Gmail, Mailgun, SES, Postmark, SendGrid, etc.)

## 🚦 Quick Start

### Option 1: ArgoCD (Recommended)

Clone + apply the Argo app of choice:

**Dev (local hosts file, no TLS):**
```bash
git clone https://github.com/yourusername/ghost-k8s-production.git
cd ghost-k8s-production
kubectl apply -f argo/ghost-dev-app.yaml
```

**Prod (with TLS + real domain):**
```bash
# Update your domain in apps/ghost/overlays/prod/ingress.yaml first
kubectl apply -f argo/ghost-prod-app.yaml
```

### Option 2: Manual Kustomize

**Dev (no TLS):**
```bash
kustomize build apps/ghost/overlays/dev | kubectl apply -f -
kubectl rollout status -n default statefulset/ghost-mysql --timeout=5m
kubectl rollout status -n default deploy/ghost --timeout=5m
```

**Staging/Prod (TLS via DNS-01):**
```bash
kustomize build apps/ghost/overlays/staging | kubectl apply -f -
# or
kustomize build apps/ghost/overlays/prod | kubectl apply -f -
```

## 🔐 Secrets Setup

Secrets are managed with Kubernetes Secret objects. You'll need:

- **MySQL**: `ghost-mysql-secret` with `mysql-root-password` + `mysql-user-password`
- **SMTP**: `ghost-smtp-secret` with `SMTP_USER` + `SMTP_PASS`

### Quick Secret Creation

**MySQL Secret:**
```bash
kubectl create secret generic ghost-mysql-secret \
  --from-literal=mysql-root-password="your-root-password" \
  --from-literal=mysql-user-password="your-user-password"
```

**SMTP Secret:**
```bash
kubectl create secret generic ghost-smtp-secret \
  --from-literal=SMTP_USER="no-reply@yourdomain.com" \
  --from-literal=SMTP_PASS="your-smtp-password"
```

### Automated Secret Generation

Use the provided script for development:
```bash
./scripts/generate-secrets.sh
```

For production, see [Secrets Setup Guide](docs/secrets-setup.md).

## 🌐 Access Your Blog

**Dev:**
```bash
kubectl -n default port-forward svc/ghost 8080:2368
# browser → http://localhost:8080
```

**Staging/Prod:** Browse to your domain (e.g., https://staging.example.com/blog)

## 🔐 TLS with cert-manager (DNS-01 challenge)

Install cert-manager (CRDs + controller).

Create DNS token secret:
```bash
kubectl -n cert-manager create secret generic dns-api-token-secret \
  --from-literal=api-token='YOUR_DNS_TOKEN_VALUE'
```

Apply issuer:
```bash
kubectl apply -f cert-manager/clusterissuer-dns-01.yaml
```

Ingresses reference:
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod-dns01
```

## ♻️ Backups & Restore

### Automated Backups

- **DB backup CronJob**: `ghost-db-backup` (02:00 daily)
- **Content backup CronJob**: `ghost-content-backup` (02:30 daily)
- **Verify CronJob**: `ghost-backup-verify` (03:25 daily)
- **Prune CronJob**: `ghost-backup-prune` (03:55 daily; 14-day retention)

Backups saved to `ghost-backups-pvc` (flat files). Each backup does a quick integrity test; nightly verify does deeper checks.

### Manual Backup Triggers

```bash
# namespace may be default or ghost-staging depending on env
NS=default
kubectl -n $NS create job --from=cronjob/ghost-db-backup ghost-db-backup-now-$(date +%s)
kubectl -n $NS create job --from=cronjob/ghost-content-backup ghost-content-backup-now-$(date +%s)
kubectl -n $NS create job --from=cronjob/ghost-backup-verify ghost-backup-verify-now-$(date +%s)
kubectl -n $NS logs -l job-name=ghost-backup-verify-now- --tail=200 --prefix
```

### Restore Operations

**Restore DB from latest dump:**
```bash
NS=default
DB_SECRET=$(kubectl -n $NS get secret ghost-mysql-secret -o jsonpath='{.data.mysql-root-password}' | base64 -d)
LATEST=$(kubectl -n $NS exec deploy/ghost -- sh -lc 'ls -1t /backups/db-*.sql.gz 2>/dev/null | head -n1')
kubectl -n $NS exec -it sts/ghost-mysql -- sh -lc "
  set -e
  echo Restoring: $LATEST
  gzip -cd $LATEST | mysql -uroot -p$DB_SECRET ghostdb
"
```

**Restore content from latest archive:**
```bash
NS=default
LATEST_CONTENT=$(kubectl -n $NS exec deploy/ghost -- sh -lc 'ls -1t /backups/content-*.t*z 2>/dev/null | head -n1')
# Stop Ghost briefly to avoid concurrent writes
kubectl -n $NS scale deploy/ghost --replicas=0
kubectl -n $NS exec deploy/ghost -- sh -lc "
  set -e
  cd /var/lib/ghost
  tar -xzf $LATEST_CONTENT
"
kubectl -n $NS scale deploy/ghost --replicas=1
kubectl -n $NS rollout status deploy/ghost --timeout=5m
```

## 🧰 Features

- **Ghost pinned to 6.0.5** for stability
- **MySQL pinned to 8.0.37** (runs as StatefulSet with PVC)
- **Config generated from env vars** via initContainer (no manual config.production.json)
- **cert-manager DNS-01** with Let's Encrypt (Cloudflare example provided, works with any DNS provider)
- **Automated PVC + MySQL backups**, restore jobs included
- **PodDisruptionBudgets** for Ghost + MySQL
- **Health/readiness probes** configured
- **Network policies** for security
- **Optional monitoring** with Prometheus/Grafana (see [Monitoring Setup](docs/monitoring-setup.md))
- **CI workflow validates** YAML + kustomize builds

## 🔒 Network Policies

- **default-deny-all** (Ingress/Egress)
- **Allow Ghost ↔ MySQL** (3306) and backup jobs to MySQL
- **Allow DNS egress** (TCP/UDP 53)
- **Allow SMTP egress** (587)
- **Optional**: allow Prometheus → Ghost (if monitoring enabled)

## 🧭 ArgoCD (optional)

App-of-apps under `argo/apps/`:

- **ghost-dev** (auto)
- **ghost-staging** (auto)
- **ghost-prod** (manual at first)

Sync waves: MySQL -1 → Ghost 0 → Ingress 1
ignoreDifferences covers HPA/status/clusterIP/LB.

## 🧪 Troubleshooting

**Ghost loops or 502?**
Check probes (env-specific paths / vs /blog/) and Host headers in probes for staging/prod.

**TLS won't issue?**
Verify DNS token scope; set DNS to grey cloud; check cert-manager logs.

**Backups empty?**
Check PVCs mounted correctly; verify CronJob logs and verify job output.

**Argo fights replicas?**
HPA enabled? Ensure ignoreDifferences includes /spec/replicas.

## 📈 CI/CD

- **validate.yaml** — builds all overlays, schema-validates, guards against :latest in prod
- **smoke-kind.yaml** — boots Kind, applies dev overlay with dummy secrets, waits for rollout, curls endpoint

## 🚧 Roadmap

- [ ] **CI smoke test** (deploy to kind + curl check)
- [ ] **Upgrade PR bot** (auto bumps Ghost/MySQL images with review gate)
- [ ] **External DB overlay** (Amazon RDS/Aurora, Cloud SQL, PlanetScale)
- [ ] **Object storage overlay** for Ghost content (S3, GCS, MinIO)
- [ ] **Optional hardening**: Cloudflare Access for /ghost, OAuth2-proxy, etc.
- [ ] **Monitoring dashboards** (Grafana JSON included)

## 🤝 Contributing

Feel free to fork, extend, or contribute back. Open a PR or file an issue if you have suggestions.

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🔒 Security

Please report security vulnerabilities responsibly. See [SECURITY.md](SECURITY.md) for details.

## 📖 License

MIT. See [LICENSE](LICENSE) for details.

## ⚡ About

This is part of The Tech Capsule — pre-built, opinionated deployments for indie hackers, devs, and teams that want to self-host apps without reinventing the wheel.

**Ready to deploy?** [Get started now](docs/secrets-setup.md) or [visit the website](https://thetechcapsule.com)!