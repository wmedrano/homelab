#!/usr/bin/env bash
set -euo pipefail

# Forgejo Actions Runner Setup Script
# Reproducible deployment script for the Forgejo Runner via Podman Quadlet (systemd user service)
# Run from the server-config repo directory
# Prerequisite: Forgejo must already be running (bash forgejo-setup.sh)

QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="act_runner.container"
CONFIG_FILE="runner-config.yml"
VOLUME_NAME="act-runner-data"

if podman volume exists "$VOLUME_NAME"; then
    :
else
    podman volume create "$VOLUME_NAME"
fi

VOLUME_DIR="$(podman volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')"

if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$VOLUME_DIR/"
else
    echo "ERROR: $CONFIG_FILE not found in current directory."
    exit 1
fi

mkdir -p "$QUADLET_DIR"

if [[ -f "$CONTAINER_FILE" ]]; then
    cp "$CONTAINER_FILE" "$QUADLET_DIR/"
else
    echo "ERROR: $CONTAINER_FILE not found in current directory."
    exit 1
fi

systemctl --user daemon-reload
systemctl --user start act_runner.service

sleep 3

echo ""
echo "Forgejo Actions Runner is running."
echo ""
echo "To register the runner with your Forgejo instance:"
echo "  1. Go to https://git.wmedrano.dev -> Site Administration -> Actions -> Runners -> Create new runner"
echo "  2. Copy the registration token"
echo "  3. Run: podman exec act_runner forgejo-runner register --config /data/runner-config.yml --instance https://git.wmedrano.dev --token <TOKEN>"