# Monitoring Setup (Optional)

This guide explains how to set up monitoring for your Ghost deployment using Prometheus and Grafana.

## Prerequisites

To use the built-in monitoring, you need:

1. **Prometheus Operator** installed in your cluster
2. **Grafana** (optional, for dashboards)

## Installation Options

### Option 1: Install Prometheus Operator

**Using Helm:**
```bash
# Add the Prometheus Operator Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

**Using kubectl:**
```bash
# Install the Prometheus Operator CRDs
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
```

### Option 2: Enable Monitoring in Your Deployment

Once Prometheus Operator is installed, enable monitoring:

1. **Edit the prod overlay:**
```bash
# Edit apps/ghost/overlays/prod/kustomization.yaml
# Uncomment the monitoring line:
# - ../../base/monitoring.yaml
```

2. **Apply the changes:**
```bash
kubectl apply -f argo/ghost-prod-app.yaml
```

## What Gets Installed

When monitoring is enabled, you get:

- **ServiceMonitor**: Tells Prometheus to scrape Ghost metrics
- **Metrics Service**: Exposes Ghost metrics on port 2368
- **Prometheus Targets**: Ghost will appear in Prometheus targets

## Accessing Metrics

### Prometheus UI
```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
```

Visit: http://localhost:9090

### Grafana Dashboards
```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Visit: http://localhost:3000 (admin/prom-operator)

## Ghost Metrics

Ghost exposes these metrics by default:

- **Request counts** by endpoint
- **Response times** by endpoint
- **Error rates** by endpoint
- **Memory usage**
- **Process metrics**

## Custom Dashboards

Create a custom Grafana dashboard for Ghost:

1. Go to Grafana → Dashboards → Import
2. Use dashboard ID or JSON
3. Configure the Prometheus data source

## Troubleshooting

### ServiceMonitor Not Found
```
Error: no matches for kind "ServiceMonitor"
```

**Solution:** Install Prometheus Operator first.

### No Metrics Available
```
No targets found for ServiceMonitor
```

**Solution:** Check that:
1. Ghost is running and healthy
2. ServiceMonitor is properly configured
3. Prometheus can reach the Ghost service

### Check ServiceMonitor Status
```bash
kubectl get servicemonitor ghost-monitor -o yaml
kubectl describe servicemonitor ghost-monitor
```

## Disabling Monitoring

To disable monitoring:

1. **Comment out the monitoring line** in `apps/ghost/overlays/prod/kustomization.yaml`
2. **Apply the changes:**
```bash
kubectl apply -f argo/ghost-prod-app.yaml
```

## Alternative Monitoring

If you don't want to use Prometheus Operator, consider:

- **Datadog**: Cloud-based monitoring
- **New Relic**: Application performance monitoring
- **CloudWatch**: AWS-native monitoring
- **Stackdriver**: GCP-native monitoring

These can be configured to scrape Ghost metrics without requiring ServiceMonitor CRDs.
