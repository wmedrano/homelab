#!/usr/bin/env bash
set -euo pipefail

# Forgejo Setup Script
# Reproducible deployment script for Forgejo via Podman Quadlet (systemd user service)
# Run from the server-config repo directory
# Prerequisite: Run init-preprequisites.sh first (system-level setup)

FORGEJO_DOMAIN="git.wmedrano.dev"
QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="forgejo.container"

if podman volume exists forgejo-data; then
    :
else
    podman volume create forgejo-data
fi

mkdir -p "$QUADLET_DIR"

if [[ -f "$CONTAINER_FILE" ]]; then
    cp "$CONTAINER_FILE" "$QUADLET_DIR/"
else
    echo "ERROR: $CONTAINER_FILE not found in current directory."
    exit 1
fi

systemctl --user daemon-reload
systemctl --user start forgejo.service

sleep 3

echo "Forgejo running at: https://$FORGEJO_DOMAIN"
echo "If this is a fresh install, visit the URL above to create an admin account."
