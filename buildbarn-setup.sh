#!/usr/bin/env bash
set -euo pipefail

# BuildBarn RBE Setup Script
# Reproducible deployment for BuildBarn via Podman Quadlet (systemd user service)
# Run from the homelab repo directory.
#
# Prerequisites:
#   1. Run init-prerequisites.sh first (system-level setup)
#   2. Podman must be configured for rootless operation
#   3. The buildbarn.network file must be installed for inter-container DNS

QUADLET_DIR="$HOME/.config/containers/systemd"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RBE_DIR="$SCRIPT_DIR/rbe"

echo "=== BuildBarn RBE Setup ==="
echo ""

# Create Quadlet directory
mkdir -p "$QUADLET_DIR"

# Create named volumes for persistent storage
echo "Creating Podman volumes..."
for vol in \
    buildbarn-config \
    buildbarn-storage-cas \
    buildbarn-storage-ac \
    buildbarn-storage-fsac \
    buildbarn-worker \
    buildbarn-bb; do
    if podman volume exists "$vol" 2>/dev/null; then
        echo "  Volume $vol already exists, skipping"
    else
        podman volume create "$vol"
        echo "  Created volume $vol"
    fi
done

# Copy JSONnet config files into the config volume
echo "Copying config files into buildbarn-config volume..."
podman run --rm \
    -v buildbarn-config:/config:Z \
    -v "$RBE_DIR/config":/src:ro \
    docker.io/alpine:latest \
    sh -c "cp /src/*.jsonnet /src/*.libsonnet /config/ && ls -la /config/"

# Copy Quadlet files
echo "Installing Quadlet files..."
for file in "$SCRIPT_DIR"/containers/buildbarn-*.container "$SCRIPT_DIR"/containers/buildbarn-*.network; do
    if [[ -f "$file" ]]; then
        cp "$file" "$QUADLET_DIR/"
        echo "  Installed $(basename "$file")"
    fi
done

# Reload systemd
echo "Reloading systemd daemon..."
systemctl --user daemon-reload

# Start services in dependency order
echo ""
echo "Starting BuildBarn services..."
echo ""

# 1. Storage backend (must be up before frontend and scheduler)
echo "Starting buildbarn-storage..."
systemctl --user start buildbarn-storage.service
sleep 2

# 2. Frontend (proxies to storage backend)
echo "Starting buildbarn-frontend..."
systemctl --user start buildbarn-frontend.service
sleep 2

# 3. Scheduler (must be up before worker)
echo "Starting buildbarn-scheduler..."
systemctl --user start buildbarn-scheduler.service
sleep 2

# 4. Runner installer (ephemeral - copies bb_runner binary to shared volume)
echo "Running buildbarn-runner-installer..."
systemctl --user start buildbarn-runner-installer.service
sleep 3

# 5. Worker
echo "Starting buildbarn-worker..."
systemctl --user start buildbarn-worker.service
sleep 1

# 6. Runner (waits for installer, then starts in siso-chromium environment)
echo "Starting buildbarn-runner..."
systemctl --user start buildbarn-runner.service
sleep 2

echo ""
echo "=== BuildBarn RBE Status ==="
systemctl --user status 'buildbarn-*' --no-pager 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "BuildBarn RBE is now running!"
echo ""
echo "Services:"
echo "  buildbarn-frontend      - RBE API endpoint (port 8980)"
echo "  buildbarn-storage       - CAS/action-cache backend (port 8981)"
echo "  buildbarn-scheduler     - Action scheduler (port 8982/8983/8984)"
echo "  buildbarn-worker        - Build action executor"
echo "  buildbarn-runner        - Build runner (siso-chromium environment)"
echo "  buildbarn-runner-installer - Ephemeral: installs bb_runner binary"
echo ""
echo "To connect from a remote client via SSH tunnel:"
echo "  ssh -L 8980:localhost:8980 <server-host>"
echo ""
echo "Then configure your Siso build:"
echo "  autoninja -C out/Default --reapi-address=localhost:8980"
echo ""
echo "Or copy rbe/backend.star to your Chromium source at:"
echo "  build/config/siso/backend_config/backend.star"