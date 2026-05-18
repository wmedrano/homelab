#!/usr/bin/env bash
set -euo pipefail

# Forgejo Actions Runner Setup Script
# Deploys the runner via Podman Quadlet (systemd user service).
#
# Prerequisites:
#   - Forgejo must already be running (bash forgejo-setup.sh)
#   - podman.socket user service must be active
#   - A runner token from https://git.wmedrano.dev Site Administration → Actions → Runners
#
# Usage:
#   bash runner-setup.sh <TOKEN>
#
# The token is written into runner-config.yml inside the data volume
# (the v12 connections block), so the daemon can authenticate on startup.

if [[ $# -lt 1 ]]; then
    echo "Usage: bash runner-setup.sh <RUNNER_TOKEN>"
    echo ""
    echo "Get a token from: https://git.wmedrano.dev -> Site Administration -> Actions -> Runners -> Create new runner"
    exit 1
fi

TOKEN="$1"
QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="forgejo_actions_runner.container"
CONFIG_FILE="runner-config.yml"
VOLUME_NAME="forgejo-actions-runner-data"

# --- Create data volume if it doesn't exist ---
if ! podman volume exists "$VOLUME_NAME" 2>/dev/null; then
    podman volume create "$VOLUME_NAME"
fi

# --- Install runner-config.yml into the volume with the token filled in ---
VOLUME_DIR="$(podman volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')"

# Use a temp file so we can substitute the token without sed escaping issues
TMP_CONFIG="$(mktemp)"
sed "s|token: \"\".*# Fill in your runner token before deploying|token: ${TOKEN}|" "$CONFIG_FILE" > "$TMP_CONFIG"

# podman unshare gives us access to the rootless volume mountpoint
podman unshare cp "$TMP_CONFIG" "$VOLUME_DIR/runner-config.yml"
rm -f "$TMP_CONFIG"

# --- Install quadlet ---
mkdir -p "$QUADLET_DIR"
cp "$CONTAINER_FILE" "$QUADLET_DIR/"

# --- Start the service ---
systemctl --user daemon-reload
systemctl --user restart forgejo_actions_runner.service

# --- Verify ---
sleep 2
if systemctl --user is-active forgejo_actions_runner.service &>/dev/null; then
    echo ""
    echo "Forgejo Actions Runner is running."
else
    echo ""
    echo "WARNING: Runner service is not active. Check:"
    echo "  systemctl --user status forgejo_actions_runner.service"
    echo "  journalctl --user -u forgejo_actions_runner.service --no-pager -n 20"
fi