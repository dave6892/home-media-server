# Home Media Server

A Kubernetes-based home media server stack featuring Plex Media Server, Tautulli, and Overseerr. This project uses Helm charts for deployment with independent service management and follows GitOps best practices.

## 📦 What's Included

- **[Plex Media Server](https://www.plex.tv/)** - Stream your media library to any device
- **[Tautulli](https://tautulli.com/)** - Monitor and track Plex usage and statistics
- **[Overseerr](https://overseerr.dev/)** - Media request and discovery management

## 🏗️ Architecture

This project uses a multi-chart Helm architecture where each service is independently deployable:

```
app/
├── shared/              # Shared resources (namespace, storage)
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-microk8s.yaml
│   └── templates/
│       ├── namespace.yaml
│       └── storage.yaml
├── plex/                # Plex Media Server chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-microk8s.yaml
│   └── templates/
│       ├── pvc.yaml
│       ├── deployment.yaml
│       └── service.yaml
├── tautulli/            # Tautulli monitoring chart
└── overseerr/           # Overseerr requests chart
```

### GitOps Best Practices

Environment-specific values (like NFS server IPs) are kept **outside of version control**:
- Configuration templates are versioned (`.example` files)
- Actual values in `secrets.yaml` are gitignored
- Helm loads values from multiple files at deployment time

## 📋 Prerequisites

### Required Tools

```bash
# Install Helm
brew install helm

# Install kubectl
brew install kubectl
```

### Kubernetes Distribution

Choose one of the following:

#### Option 1: MicroK8s (Recommended for Production)
```bash
# Install MicroK8s
sudo snap install microk8s --classic

# Enable required addons
microk8s enable dns storage
```

#### Option 2: Minikube (For Local Testing)
```bash
# Install Minikube
brew install minikube

# Start Minikube
minikube start --cpus=4 --memory=8192
```

### Additional Requirements
- NFS server with media storage (for MicroK8s production)

## 🚀 Quick Start

### For Minikube (Development)

```bash
# Clone the repository
git clone https://github.com/dave6892/home-media-server.git
cd home-media-server

# Deploy everything
./scripts/deploy.sh minikube
```

### For MicroK8s (Production)

1. **Create secrets file**:
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
   ```

## 📚 Deployment

### Automated Deployment

Use the provided scripts for easy deployment:

```bash
# Deploy all services
./scripts/deploy.sh [minikube|microk8s]

# Uninstall all services
./scripts/uninstall.sh
```

### Manual Deployment

Deploy services individually:

```bash
# 1. Deploy shared resources (required first)
helm upgrade --install media-shared app/shared \
  -f app/shared/values-microk8s.yaml \
  -f secrets.yaml

# 2. Deploy Plex
helm upgrade --install plex app/plex \
  -f app/plex/values-microk8s.yaml

# 3. Deploy Tautulli
helm upgrade --install tautulli app/tautulli \
  -f app/tautulli/values-microk8s.yaml

# 4. Deploy Overseerr
helm upgrade --install overseerr app/overseerr \
  -f app/overseerr/values-microk8s.yaml
```

## 🌐 Accessing Your Services

### For MicroK8s

Services are exposed via NodePort on your host machine:

- **Plex**: http://YOUR_HOST_IP:32400/web
- **Tautulli**: http://YOUR_HOST_IP:32181
- **Overseerr**: http://YOUR_HOST_IP:32055

### For Minikube

Get the Minikube IP address:
```bash
minikube ip
```

Access services at:
- **Plex**: http://MINIKUBE_IP:32400/web
- **Tautulli**: http://MINIKUBE_IP:32181
- **Overseerr**: http://MINIKUBE_IP:32055

### Alternative: Port Forwarding

Access services via `localhost`:

```bash
# Plex
kubectl port-forward -n media svc/plex 32400:32400

# Tautulli  
kubectl port-forward -n media svc/tautulli 8181:8181

# Overseerr
kubectl port-forward -n media svc/overseerr 5055:5055
```

## 🛠️ Usage

### Initial Setup

1. **Configure Plex**:
   - Navigate to http://YOUR_IP:32400/web
   - Sign in with your Plex account
   - Add your media libraries (mounted at `/media` inside the container)

2. **Configure Tautulli**:
   - Navigate to http://YOUR_IP:32181
   - Connect to Plex (use `http://plex.media.svc.cluster.local:32400`)

3. **Configure Overseerr**:
   - Navigate to http://YOUR_IP:32055
   - Connect to Plex for media discovery and requests

### Managing Deployments

```bash
# View all releases
helm list

# Upgrade a service
helm upgrade plex app/plex -f app/plex/values-microk8s.yaml

# Rollback a service
helm rollback plex

# Uninstall a service
helm uninstall plex
```

### Viewing Logs

```bash
# View Plex logs
kubectl logs -n media deployment/plex -f

# View Tautulli logs
kubectl logs -n media deployment/tautulli -f

# View Overseerr logs
kubectl logs -n media deployment/overseerr -f
```

### Checking Status

```bash
# Check pod status
kubectl get pods -n media

# Check storage
kubectl get pvc -n media

# Check services
kubectl get svc -n media
```

## 🗂️ Storage Configuration

### Persistent Volumes

| Volume | Size | Purpose | Access Mode |
|--------|------|---------|-------------|
| `plex-config-pv` | 20Gi | Plex configuration and metadata | ReadWriteMany |
| `plex-media-pv` | 500Gi | Media library (NFS on MicroK8s) | ReadWriteMany |

### Persistent Volume Claims

| Service | PVC | Size | Purpose |
|---------|-----|------|---------|
| Plex | `plex-config` | 20Gi | Configuration |
| Plex | `plex-media` | 500Gi | Media library |
| Plex | `plex-transcode` | 50Gi | Transcoding temp |
| Tautulli | `tautulli-config` | 5Gi | Configuration |
| Overseerr | `overseerr-config` | 5Gi | Configuration |

### Storage Classes

- **MicroK8s**: `microk8s-hostpath` (local) + NFS for media
- **Minikube**: `standard` (hostPath provisioner)

## 🔧 Customization

### Adjusting Resource Limits

Edit service values files (e.g., `app/plex/values.yaml`):

```yaml
resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"
```

Or use `--set` flag:
```bash
helm upgrade plex app/plex \
  --set resources.limits.memory=16Gi \
  --set resources.limits.cpu=8000m
```

### Changing Image Versions

```bash
# Update Plex to specific version
helm upgrade plex app/plex --set image.tag=1.32.0

# Update via values file
# Edit app/plex/values.yaml:
# image:
#   tag: "1.32.0"
```

### Environment Variables

Common environment variables are configured in each chart's `values.yaml`:

**Plex** (`app/plex/values.yaml`):
- `TZ`: Timezone (default: `UTC`)
- `ADVERTISE_IP`: Server IP for Plex discovery
- `PLEX_UID`/`PLEX_GID`: User/Group IDs for file permissions

**Tautulli/Overseerr**:
- `TZ`: Timezone
- `PUID`/`PGID`: User/Group IDs

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status and events
kubectl describe pod -n media POD_NAME

# Check logs
kubectl logs -n media POD_NAME
```

### Storage Issues

```bash
# Check PVC binding status
kubectl get pvc -n media

# Check PV status
kubectl get pv

# Describe PVC for details
kubectl describe pvc -n media plex-media
```

### NFS Mount Issues (MicroK8s)

If Plex pod can't mount NFS:
1. Verify NFS server is accessible from the Kubernetes node
2. Check NFS exports: `showmount -e NFS_SERVER_IP`
3. Ensure proper permissions on NFS share
4. Verify `secrets.yaml` has correct NFS server and path

### Helm Issues

```bash
# Lint chart before deploying
helm lint app/plex

# Debug template rendering
helm template plex app/plex --debug

# View release history
helm history plex
```

## 📖 Documentation

- **[HELM.md](docs/HELM.md)** - Comprehensive Helm deployment guide

## 🏆 Benefits of Helm Architecture

Compared to traditional Kustomize approach:

| Feature | Previous (Kustomize) | Current (Helm) |
|---------|---------------------|----------------|
| **Service Management** | All-or-nothing | Independent per service |
| **Templating** | JSON patches | Go templates |
| **Rollback** | Manual | `helm rollback` |
| **Versioning** | Git only | Helm releases + Git |
| **Customization** | Overlay files | Values files + `--set` |
| **Package Management** | None | Built-in |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Resources

- [Plex Documentation](https://support.plex.tv/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)