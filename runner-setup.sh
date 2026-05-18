#!/usr/bin/env bash
set -euo pipefail

# Forgejo Actions Runner Setup Script
# Deploys the runner via Podman Quadlet (systemd user service).
#
# Prerequisites:
#   - Forgejo must already be running (bash forgejo-setup.sh)
#   - podman.socket user service must be active
#   - A runner token and UUID from https://git.wmedrano.dev Site Administration -> Actions -> Runners
#
# Usage:
#   bash runner-setup.sh <TOKEN> <UUID>
#
# The token and UUID are written into runner-config.yml inside the data volume
# (the v12 server.connections block), so the daemon can authenticate on startup.

if [[ $# -lt 2 ]]; then
    echo "Usage: bash runner-setup.sh <RUNNER_TOKEN> <RUNNER_UUID>"
    echo ""
    echo "Get token + UUID from: https://git.wmedrano.dev -> Site Administration -> Actions -> Runners -> Create new runner"
    exit 1
fi

TOKEN="$1"
UUID="$2"
QUADLET_DIR="$HOME/.config/containers/systemd"
CONTAINER_FILE="forgejo_actions_runner.container"
VOLUME_NAME="forgejo-actions-runner-data"

# --- Create data volume if it doesn't exist ---
if ! podman volume exists "$VOLUME_NAME" 2>/dev/null; then
    podman volume create "$VOLUME_NAME"
fi

# --- Write runner-config.yml into the volume with token + uuid ---
VOLUME_DIR="$(podman volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')"

# Write config to a temp file first (avoids quoting issues with heredoc
# through podman unshare), then copy into the volume using podman unshare.
TMP_CONFIG="$(mktemp)"
cat > "$TMP_CONFIG" << EOF
runner:
  name: homelab-runner
  file: .runner
  capacity: 1
  env_file: .env
  timeout: 3h
  shutdown_timeout: 0s
  labels:
    - "ubuntu-latest:docker://debian:bookworm"

cache:
  enabled: true
  dir: /data/cache
  host: ""
  port: 0
  external_server: ""

container:
  network: ""
  enable_ipv6: false
  options: ""
  workdir_parent: /data/workspace
  valid_volumes: []
  docker_hosts: []
  force_pull: false
  force_rebuild: false

log:
  level: info

server:
  connections:
    forgejo:
      url: https://git.wmedrano.dev/
      uuid: ${UUID}
      token: ${TOKEN}
EOF

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