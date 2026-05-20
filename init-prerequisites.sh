#!/usr/bin/env bash
set -euo pipefail

# Init Prerequisites Script
# System-level prerequisites for Forgejo deployment (requires sudo)
# Run this once before forgejo-setup.sh

echo "=== Init Prerequisites Script ==="
echo ""

# Install Podman (Arch-based)
echo "[1/6] Installing Podman..."
if ! command -v podman &> /dev/null; then
    echo "  Podman not found, installing..."
    sudo pacman -S podman --noconfirm
else
    echo "  Podman already installed."
fi

# Configure subuid/subgid
echo ""
echo "[2/6] Configuring subuid/subgid for user $USER..."
if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
    echo "  Adding $USER to /etc/subuid..."
    echo "$USER:100000:65536" | sudo tee -a /etc/subuid > /dev/null
else
    echo "  subuid already configured."
fi

if ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
    echo "  Adding $USER to /etc/subgid..."
    echo "$USER:100000:65536" | sudo tee -a /etc/subgid > /dev/null
else
    echo "  subgid already configured."
fi

# Enable lingering
echo ""
echo "[3/6] Enabling lingering for user $USER..."
if loginctl show-user "$USER" --property=Linger | grep -q "yes"; then
    echo "  Lingering already enabled."
else
    echo "  Enabling lingering..."
    sudo loginctl enable-linger "$USER"
fi

# Configure firewall
echo ""
echo "[4/6] Configuring firewall (port 2222/tcp for SSH Git access)..."
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "2222/tcp"; then
        echo "  Port 2222/tcp already allowed."
    else
        echo "  Allowing port 2222/tcp..."
        sudo ufw allow 2222/tcp
    fi
else
    echo "  ufw not installed, skipping firewall config."
fi

# Disable sleep/suspend targets
echo ""
echo "[5/6] Disabling system sleep/suspend targets..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Add local DNS override entries for NAT hairpin workaround
echo ""
echo "[6/6] Adding local DNS overrides to /etc/hosts (NAT hairpin workaround)..."
HOSTS_ENTRIES=(
    "127.0.0.1 git.wmedrano.dev"
    "127.0.0.1 hermes.wmedrano.dev"
    "127.0.0.1 blog.wmedrano.dev"
    "127.0.0.1 wmedrano.dev"
    "127.0.0.1 www.wmedrano.dev"
    "::1 git.wmedrano.dev"
    "::1 hermes.wmedrano.dev"
    "::1 blog.wmedrano.dev"
    "::1 wmedrano.dev"
    "::1 www.wmedrano.dev"
)
for entry in "${HOSTS_ENTRIES[@]}"; do
    if ! grep -qF "$entry" /etc/hosts 2>/dev/null; then
        echo "$entry" | sudo tee -a /etc/hosts > /dev/null
        echo "  Added: $entry"
    else
        echo "  Already present: $entry"
    fi
done

echo ""
echo "=== Prerequisites Complete ==="
echo "Now run ./forgejo-setup.sh to deploy Forgejo."
