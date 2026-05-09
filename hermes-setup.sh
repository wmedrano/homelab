#!/usr/bin/env bash
set -euo pipefail

# Hermes Setup Script
# Reproducible deployment script for Hermes Agent via Podman Quadlet (systemd user service)
# Run from the server-config repo directory
# Prerequisite: Run init-prerequisites.sh first (system-level setup)

QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="hermes.container"

# [1/3] Create volume if it doesn't exist; run setup wizard on first install
if podman volume exists hermes-data; then
    echo "[1/3] Volume hermes-data already exists, skipping setup wizard. See 'Reset' in README to recreate."
else
    podman volume create hermes-data
    echo "[1/3] Running Hermes setup wizard (interactive)..."
    podman run -it --rm \
        -v hermes-data:/opt/data \
        docker.io/nousresearch/hermes-agent setup
fi

# [2/3] Copy Quadlet container file
mkdir -p "$QUADLET_DIR"
if [[ -f "$CONTAINER_FILE" ]]; then
    cp "$CONTAINER_FILE" "$QUADLET_DIR/"
else
    echo "ERROR: $CONTAINER_FILE not found in current directory."
    exit 1
fi

# [3/3] Enable and start the service
systemctl --user daemon-reload
systemctl --user start hermes.service

sleep 3

echo "Hermes gateway running on port 8642."
