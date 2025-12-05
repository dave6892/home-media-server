# Home Media Server

A Kubernetes-based home media server stack featuring Plex Media Server, Tautulli, and Overseerr. This project uses Kustomize for environment-specific configurations and follows GitOps best practices.

## 📦 What's Included

- **[Plex Media Server](https://www.plex.tv/)** - Stream your media library to any device
- **[Tautulli](https://tautulli.com/)** - Monitor and track Plex usage and statistics
- **[Overseerr](https://overseerr.dev/)** - Media request and discovery management

## 🏗️ Architecture

This project uses Kustomize to manage configurations across different Kubernetes environments:

```
app/
├── base/                    # Base Kubernetes manifests
│   ├── deployment.yaml     # All service definitions
│   └── kustomization.yaml  # Base kustomize config
└── overlays/               # Environment-specific configs
    ├── minikube/           # For local Minikube testing
    └── microk8s/           # For MicroK8s production (with NFS support)
```

### GitOps Best Practices

Environment-specific values (like NFS server IPs) are kept **outside of version control**:
- Configuration templates are versioned (`.example` files)
- Actual values are in `.gitignore`
- Kustomize injects values at deployment time

## 📋 Prerequisites

Choose one of the following Kubernetes distributions:

### Option 1: MicroK8s (Recommended for Production)
```bash
# Install MicroK8s
sudo snap install microk8s --classic

# Enable required addons
microk8s enable dns storage
```

### Option 2: Minikube (For Local Testing)
```bash
# macOS with Homebrew
brew install minikube

# Start Minikube
minikube start --cpus=4 --memory=8192
```

### Additional Requirements
- `kubectl` command-line tool
- NFS server with media storage (for MicroK8s overlay)
- You may need the plex claim token to claim the media server into your Plex account

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/dave6892/home-media-server.git
cd home-media-server
```

### 2. Configure Your Environment

Choose the overlay that matches your Kubernetes distribution:

#### For MicroK8s (Production with NFS)

1. Create your NFS configuration from the template:
   ```bash
   cd app/overlays/microk8s
   cp nfs.properties.example nfs.properties
   ```

2. Edit `nfs.properties` with your NFS server details:
   ```properties
   server=YOUR_SERVER_IP
   path=YOUR_MOUNTED_NFS_PATH
   ```

#### For Minikube (Local Testing)

No additional configuration needed! The Minikube overlay uses local hostPath storage.

### 3. Deploy to Kubernetes

#### Deploy to MicroK8s
```bash
# Preview what will be deployed
kubectl kustomize app/overlays/microk8s

# Apply the configuration
kubectl apply -k app/overlays/microk8s
```

#### Deploy to Minikube
```bash
# Preview what will be deployed
kubectl kustomize app/overlays/minikube

# Apply the configuration
kubectl apply -k app/overlays/minikube
```

### 4. Verify Deployment

```bash
# Check pod status
kubectl get pods -n media

# Check storage
kubectl get pvc -n media

# Watch pods until they're ready
kubectl get pods -n media -w
```

Expected output:
```
NAME                         READY   STATUS    RESTARTS   AGE
overseerr-xxxxxxxxx-xxxxx    1/1     Running   0          2m
plex-xxxxxxxxx-xxxxx         1/1     Running   0          2m
tautulli-xxxxxxxxx-xxxxx     1/1     Running   0          2m
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

#### Alternative: Port Forwarding (Both Environments)

Access services via `localhost`:

```bash
# Plex
kubectl port-forward -n media svc/plex 32400:32400

# Tautulli  
kubectl port-forward -n media svc/tautulli 8181:8181

# Overseerr
kubectl port-forward -n media svc/overseerr 5055:5055
```

Then access at:
- **Plex**: http://localhost:32400/web
- **Tautulli**: http://localhost:8181
- **Overseerr**: http://localhost:5055

## 🛠️ Usage

### Initial Setup

1. **Configure Plex**:
   - Navigate to http://YOUR_IP:32400/web
   - Sign in with your Plex account
   - Add your media libraries (mounted at `/media` inside the container)

2. **Configure Tautulli**:
   - Navigate to http://YOUR_IP:32181
   - Connect to Plex (use `http://plex:32400`)

3. **Configure Overseerr**:
   - Navigate to http://YOUR_IP:32055
   - Connect to Plex for media discovery and requests

### Managing Media Files

#### MicroK8s (NFS)
Your media is automatically mounted from your NFS server at the path specified in `nfs.properties`.

#### Minikube (HostPath)
Add media files to the Minikube VM:

```bash
# SSH into Minikube
minikube ssh

# Navigate to media directory
cd /tmp/hostpath-provisioner/plex-media

# Copy files (from another terminal)
minikube cp /path/to/your/media/file.mp4 /tmp/hostpath-provisioner/plex-media/
```

### Updating the Deployment

After making changes to the manifests:

```bash
# Preview changes
kubectl diff -k app/overlays/microk8s

# Apply updates
kubectl apply -k app/overlays/microk8s
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

## 🗂️ Storage Configuration

### Persistent Volumes

| Volume | Size | Purpose | Access Mode |
|--------|------|---------|-------------|
| `plex-config` | 20Gi | Plex configuration and metadata | ReadWriteMany |
| `plex-media` | 500Gi | Media library (NFS on MicroK8s) | ReadWriteMany |
| `plex-transcode` | 50Gi | Temporary transcoding files | ReadWriteOnce |
| `tautulli-config` | 5Gi | Tautulli configuration | ReadWriteOnce |
| `overseerr-config` | 5Gi | Overseerr configuration | ReadWriteOnce |

### Storage Classes

- **MicroK8s**: `microk8s-hostpath` (local) + NFS for media
- **Minikube**: `standard` (hostPath provisioner)

## 🔧 Customization

### Resource Limits

Edit `app/base/deployment.yaml` to adjust resource allocations:

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"
```

### Environment Variables

Common environment variables in `deployment.yaml`:

- `TZ`: Timezone (default: `UTC`)
- `ADVERTISE_IP`: Server IP for Plex discovery
- `PLEX_UID`/`PLEX_GID`: User/Group IDs for file permissions

### Adding New Overlays

Create a new environment configuration:

```bash
mkdir -p app/overlays/production
cd app/overlays/production

# Create kustomization.yaml
cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

# Add your environment-specific patches here
EOF
```

## 📚 Additional Documentation

- [Kustomize Setup Guide](docs/KUSTOMIZE.md) - Detailed Kustomize usage and concepts

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
```

### NFS Mount Issues (MicroK8s)

If Plex pod can't mount NFS:
1. Verify NFS server is accessible from the Kubernetes node
2. Check NFS exports: `showmount -e NFS_SERVER_IP`
3. Ensure proper permissions on NFS share

### Plex Not Accessible

1. Verify the service is running:
   ```bash
   kubectl get svc -n media plex
   ```

2. Check firewall rules allow port 32400

3. Try using the ADVERTISE_IP environment variable with your server's IP

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Resources

- [Plex Documentation](https://support.plex.tv/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)