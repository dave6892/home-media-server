#!/bin/bash
# Deploy all media server services
# Usage: ./deploy.sh [minikube|microk8s]

OVERLAY=${1:-minikube}

echo "Deploying media server with $OVERLAY overlay..."

# Deploy shared resources first
echo "1. Deploying shared resources (namespace, storage)..."
if [ "$OVERLAY" = "microk8s" ]; then
  helm upgrade --install media-shared app/shared \
    -f app/shared/values-microk8s.yaml \
    -f secrets.yaml
else
  helm upgrade --install media-shared app/shared
fi

echo ""
echo "2. Deploying Plex..."
if [ "$OVERLAY" = "microk8s" ]; then
  helm upgrade --install plex app/plex -f app/plex/values-microk8s.yaml
else
  helm upgrade --install plex app/plex
fi

echo ""
echo "3. Deploying Tautulli..."
if [ "$OVERLAY" = "microk8s" ]; then
  helm upgrade --install tautulli app/tautulli -f app/tautulli/values-microk8s.yaml
else
  helm upgrade --install tautulli app/tautulli
fi

echo ""
echo "4. Deploying Overseerr..."
if [ "$OVERLAY" = "microk8s" ]; then
  helm upgrade --install overseerr app/overseerr -f app/overseerr/values-microk8s.yaml
else
  helm upgrade --install overseerr app/overseerr
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Check pod status:"
echo "  kubectl get pods -n media"
