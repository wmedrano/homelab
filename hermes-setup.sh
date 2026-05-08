#!/usr/bin/env bash
set -euo pipefail

# Hermes Setup Script
# Reproducible deployment script for Hermes via Podman Quadlet (systemd user service)
# Run from the server-config repo directory
# Prerequisite: Run init-preprequisites.sh first (system-level setup)

HERMES_DOMAIN="hermes.wmedrano.dev"  # Optional domain for reference
QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="hermes.container"

echo "=== Hermes Setup Script ==="
echo "Domain: $HERMES_DOMAIN (for reference)"
echo "Prerequisite: Ensure init-preprequisites.sh has been run first."
echo ""

# --- User-Level Setup ---

echo "[1/3] Setting up Podman volume and Quadlet service..."
if podman volume exists hermes-data; then
    echo "  Volume hermes-data already exists."
else
    echo "  Creating Podman volume hermes-data..."
    podman volume create hermes-data
fi

echo "  Creating Quadlet directory..."
mkdir -p "$QUADLET_DIR"

if [[ -f "$CONTAINER_FILE" ]]; then
    echo "  Copying $CONTAINER_FILE to $QUADLET_DIR..."
    cp "$CONTAINER_FILE" "$QUADLET_DIR/"
else
    echo "  ERROR: $CONTAINER_FILE not found in current directory!"
    echo "  Please run this script from the server-config repo directory."
    exit 1
fi

echo "  Reloading systemd user daemon..."
systemctl --user daemon-reload

echo "  Enabling and starting Hermes service..."
systemctl --user enable --now hermes

# --- Post-Setup ---

echo ""
echo "[2/3] Waiting for Hermes to start..."
sleep 3

echo ""
echo "[3/3] Setup Complete!"
echo ""
echo "Hermes container is now running and accessible via:"
echo "  podman exec -it hermes /bin/sh"
echo ""

echo "Useful commands:"
echo "  systemctl --user status hermes   # Check service status"
echo "  podman logs hermes               # View container logs"
echo "  systemctl --user restart hermes  # Restart service"
echo "  podman exec -it hermes /bin/sh   # Access container shell"
echo ""
echo "To install packages inside the container:"
echo "  podman exec -it hermes apk add <package-name>"
echo ""
