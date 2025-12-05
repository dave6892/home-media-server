# Kustomize Setup

This project uses Kustomize to manage environment-specific configurations for different Kubernetes distributions.

## Directory Structure

```
app/
├── base/
│   ├── kustomization.yaml    # Base kustomization config
│   ├── namespace.yaml        # Namespace definition
│   ├── storage.yaml          # Shared PersistentVolumes
│   ├── plex.yaml             # Plex service manifests
│   ├── tautulli.yaml         # Tautulli service manifests
│   └── overseerr.yaml        # Overseerr service manifests
└── overlays/
    ├── minikube/
    │   └── kustomization.yaml # Minikube-specific patches (StorageClass: standard)
    └── microk8s/
        ├── kustomization.yaml # MicroK8s-specific patches (StorageClass: microk8s-hostpath)
        ├── nfs.properties     # Environment-specific NFS config (not in version control)
        └── nfs.properties.example  # Template for NFS configuration
```

## How Kustomize Works

**Base**: Contains your common/default Kubernetes manifests that work across environments.

**Overlays**: Environment-specific modifications (patches) applied on top of the base.
- Each overlay references the base with `bases: [../../base]`
- Patches use JSON Patch (RFC 6902) to modify specific fields
- Multiple overlays can exist for different environments

## Usage

### Deploy to Minikube

```bash
# Preview the generated manifests
kubectl kustomize app/overlays/minikube

# Apply to cluster
kubectl apply -k app/overlays/minikube
```

### Deploy to MicroK8s

```bash
# Preview the generated manifests
kubectl kustomize app/overlays/microk8s

# Apply to cluster
kubectl apply -k app/overlays/microk8s
```

## What Gets Changed?

### Minikube Overlay
- Changes `storageClassName: microk8s-hostpath` → `storageClassName: standard`
- Updates hostPath from `/var/snap/microk8s/...` → `/tmp/hostpath-provisioner/...`

### MicroK8s Overlay
- Converts `plex-media-pv` from hostPath to NFS using values from `nfs.properties`
- Injects NFS server IP and path at build time via Kustomize replacements

## Key Kustomize Concepts

1. **Resources**: List of Kubernetes manifests to include
2. **Bases**: Reference to other kustomization directories
3. **Patches**: Modifications to apply on top of base resources
4. **Target**: Selects which resource(s) to patch (by kind, name, namespace)
5. **JSON Patch**: Standard way to describe changes (op: replace/add/remove)

## Advantages

- ✅ Single source of truth (base deployment)
- ✅ Environment-specific overrides without duplication
- ✅ No templating - pure YAML
- ✅ Built into kubectl (no external tools)
- ✅ Easy to preview changes before applying

## Learn More

- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Kustomization File Fields](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)
