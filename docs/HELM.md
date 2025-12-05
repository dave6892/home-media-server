# Helm Deployment Guide

This guide explains how to deploy the media server stack using Helm instead of Kustomize.

## Prerequisites

Install Helm:
```bash
# macOS
brew install helm

# or download from https://helm.sh/docs/intro/install/
```

## Chart Structure

The project uses a multi-chart architecture:

```
app/
├── shared/          # Namespace and shared PersistentVolumes
├── plex/            # Plex Media Server chart
├── tautulli/        # Tautulli monitoring chart
└── overseerr/       # Overseerr request management chart
```

Each chart is independently deployable and versioned.

##  Quick Start

### For Minikube (Development)

```bash
# Deploy everything
./scripts/deploy.sh minikube

# Or manually:
helm upgrade --install media-shared app/shared
helm upgrade --install plex app/plex
helm upgrade --install tautulli app/tautulli
helm upgrade --install overseerr app/overseerr
```

### For MicroK8s (Production)

1. **Create secrets file** from template:
   ```bash
   cp secrets.yaml.example secrets.yaml
   ```

2. **Edit `secrets.yaml`** with your NFS server details:
   ```yaml
   shared:
     storage:
       plexMedia:
         nfs:
           server: "192.168.1.142"
           path: "/mnt/universe7-pool/media"
   ```

3. **Deploy**:
   ```bash
   ./scripts/deploy.sh microk8s
   
   # Or manually:
   helm upgrade --install media-shared app/shared \
     -f app/shared/values-microk8s.yaml \
     -f secrets.yaml
   
   helm upgrade --install plex app/plex -f app/plex/values-microk8s.yaml
   helm upgrade --install tautulli app/tautulli -f app/tautulli/values-microk8s.yaml
   helm upgrade --install overseerr app/overseerr -f app/overseerr/values-microk8s.yaml
   ```

## Individual Chart Operations

### Deploy a Single Service

```bash
# Deploy only Plex
helm upgrade --install plex app/plex

# Deploy with custom values
helm upgrade --install plex app/plex \
  -f app/plex/values-microk8s.yaml \
  --set image.tag=1.32.0
```

### View Rendered Templates

```bash
# See what will be created
helm template media-shared app/shared

# With production values
helm template media-shared app/shared \
  -f app/shared/values-microk8s.yaml \
  -f secrets.yaml
```

### Upgrade a Service

```bash
# Upgrade Plex with new values
helm upgrade plex app/plex -f app/plex/values-microk8s.yaml

# Upgrade and show diff
helm diff upgrade plex app/plex -f app/plex/values-microk8s.yaml
```

### Uninstall Services

```bash
# Uninstall everything
./scripts/uninstall.sh

# Or selectively
helm uninstall plex
helm uninstall tautulli
helm uninstall overseerr
helm uninstall media-shared
```

## Configuration

### Values Files

Each chart has two values files:

- `values.yaml` - Default (minikube/dev) configuration
- `values-microk8s.yaml` - Production overrides

### Common Customizations

#### Change Plex Image Tag

Edit `app/plex/values.yaml` or use `--set`:
```bash
helm upgrade --install plex app/plex --set image.tag=1.32.0
```

#### Adjust Resource Limits

Edit `app/plex/values.yaml`:
```yaml
resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"
```

#### Change Storage Class

Edit environment-specific values file:
```yaml
storage:
  storageClass: your-storage-class
```

## Verification

Check deployment status:
```bash
# List all releases
helm list

# Check pods
kubectl get pods -n media

# Check PVCs
kubectl get pvc -n media

# View logs
kubectl logs -n media deployment/plex -f
```

## Troubleshooting

### Helm Not Found

```bash
# Install Helm
brew install helm
```

### Chart Validation Errors

```bash
# Lint chart before deploying
helm lint app/plex

# Debug template rendering
helm template plex app/plex --debug
```

### Storage Issues

```bash
# Check PV status
kubectl get pv

# Describe PVC
kubectl describe pvc -n media plex-media
```

### Rollback

```bash
# View release history
helm history plex

# Rollback to previous version
helm rollback plex

# Rollback to specific revision
helm rollback plex 2
```

## Advanced Usage

### Using Custom Namespaces

```bash
helm upgrade --install plex app/plex \
  --namespace my-media \
  --create-namespace \
  --set namespace=my-media
```

### Multiple Environments

Create additional values files:
```bash
# app/plex/values-staging.yaml
# app/plex/values-production.yaml

helm upgrade --install plex app/plex -f app/plex/values-staging.yaml
```

### Chart Dependencies

If you add chart dependencies in`Chart.yaml`:
```bash
# Update dependencies
helm dependency update app/plex

# Install with dependencies
helm upgrade --install plex app/plex
```

## Differences from Kustomize

| Feature | Kustomize | Helm |
|---------|-----------|------|
| Templating | JSON patches | Go templates |
| Values | Multiple overlays | Values files |
| Package Management | No | Yes (versioning, rollback) |
| Deployment | kubectl apply -k | helm upgrade --install |
| Independence | All-or-nothing | Per-service |



## Learn More

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Development Guide](https://helm.sh/docs/topics/charts/)
