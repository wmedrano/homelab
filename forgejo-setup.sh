#!/usr/bin/env bash
set -euo pipefail

# Forgejo Setup Script
# Reproducible deployment script for Forgejo via Podman Quadlet (systemd user service)
# Run from the server-config repo directory
# Prerequisite: Run init-preprequisites.sh first (system-level setup)

FORGEJO_DOMAIN="git.wmedrano.dev"
QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="forgejo.container"

echo "=== Forgejo Setup Script ==="
echo "Domain: $FORGEJO_DOMAIN"
echo "Prerequisite: Ensure init-preprequisites.sh has been run first."
echo ""

# --- User-Level Setup ---

echo "[1/3] Setting up Podman volume and Quadlet service..."
if podman volume exists forgejo-data; then
    echo "  Volume forgejo-data already exists."
else
    echo "  Creating Podman volume forgejo-data..."
    podman volume create forgejo-data
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

echo "  Enabling and starting Forgejo service..."
systemctl --user enable --now forgejo

# --- Post-Setup ---

echo ""
echo "[2/3] Waiting for Forgejo to start..."
sleep 3

echo ""
echo "[3/3] Setup Complete!"
echo ""
echo "Forgejo should now be running at: https://$FORGEJO_DOMAIN"
echo ""
echo "If this is a fresh install, complete the initial web setup:"
echo "  1. Visit https://$FORGEJO_DOMAIN"
echo "  2. Create an admin account"
echo "  3. SQLite will be auto-detected"
echo ""
echo "Useful commands:"
echo "  systemctl --user status forgejo   # Check service status"
echo "  podman logs forgejo               # View container logs"
echo "  systemctl --user restart forgejo  # Restart service"
echo ""
