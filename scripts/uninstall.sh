#!/bin/bash
# Uninstall all media server services

echo "Uninstalling media server services..."

echo "1. Uninstalling Overseerr..."
helm uninstall overseerr 2>/dev/null || echo "  (not installed)"

echo "2. Uninstalling Tautulli..."
helm uninstall tautulli 2>/dev/null || echo "  (not installed)"

echo "3. Uninstalling Plex..."
helm uninstall plex 2>/dev/null || echo "  (not installed)"

echo "4. Uninstalling shared resources..."
helm uninstall media-shared 2>/dev/null || echo "  (not installed)"

echo ""
echo "✅ Uninstall complete!"
