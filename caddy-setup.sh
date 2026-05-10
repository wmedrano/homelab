#!/usr/bin/env bash
set -euo pipefail

# Caddy Setup Script
# Installs Caddy and deploys the Caddyfile for reverse-proxying services
# Prerequisite: Run init-prerequisites.sh first (system-level setup)

CADDYFILE="Caddyfile"
CADDY_DEST="/etc/caddy/Caddyfile"

echo "=== Caddy Setup Script ==="
echo ""

# Install Caddy (Arch-based)
echo "[1/3] Installing Caddy..."
if ! command -v caddy &> /dev/null; then
	echo "  Caddy not found, installing..."
	sudo pacman -S caddy --noconfirm
else
	echo "  Caddy already installed."
fi

# Copy Caddyfile to /etc/caddy/
echo ""
echo "[2/3] Copying Caddyfile to $CADDY_DEST..."
if [[ -f "$CADDYFILE" ]]; then
	sudo cp "$CADDYFILE" "$CADDY_DEST"
	sudo chown root:root "$CADDY_DEST"
	sudo chmod 644 "$CADDY_DEST"
	echo "  Caddyfile deployed."
else
	echo "ERROR: $CADDYFILE not found in current directory."
	exit 1
fi

# Enable and start Caddy
echo ""
echo "[3/3] Enabling and starting Caddy service..."
sudo systemctl enable caddy
sudo systemctl restart caddy

echo ""
echo "=== Caddy Setup Complete ==="
echo "Caddy is running and serving:"
echo "  - blog.wmedrano.dev / www.wmedrano.dev / wmedrano.dev (static files)"
echo "  - git.wmedrano.dev (Forgejo reverse proxy)"
echo "  - hermes.wmedrano.dev (Hermes reverse proxy with basicauth)"