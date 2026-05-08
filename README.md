# Server Config

## Overview

Manages self-hosted services using rootless Podman with systemd Quadlet files.

### Forgejo

Git hosting service with:
- SQLite as database backend
- Port 2222 for SSH (Git access)
- Port 2223 for web hosting (proxied by Caddy)
- Domain: git.wmedrano.dev
## Prerequisites

- **Podman**: For Arch-based systems: `sudo pacman -S podman`; for other Linux distributions, install via your package manager (e.g., `sudo apt install podman` on Debian/Ubuntu)
- **Subuid/Subgid**: Already configured for user `bill` (100000:65536)
- **Lingering**: Enabled via `loginctl enable-linger $USER`

## Quadlet Files

Quadlet is a Podman feature that lets you manage containers as native systemd services using simple configuration files. For rootless (user-level) Podman:

- Quadlet files use the `.container` extension (e.g., `forgejo.container` in this repo)
- Place them in `~/.config/containers/systemd/` to auto-generate systemd user services
- After changes, run `systemctl --user daemon-reload` to apply updates
- Systemd creates a matching `.service` file (e.g., `forgejo.service` from `forgejo.container`)

This replaces manual `podman run` commands with integrated systemd management for automatic restarts, logging, and dependency handling.

## Services

### Forgejo

### Hermes

Runs as a rootless Podman container managed by systemd via Quadlet.

- **Configuration**: `forgejo.container` (Podman quadlet)
- **Data**: Stored in Podman volume `forgejo-data`
- **Service**: `systemctl --user status forgejo`
- **Caddy**: Proxies `git.wmedrano.dev` → `localhost:2223`

### Hermes

A container for logging in and installing software, exposing port 9112.

- **Configuration**: `hermes.container` (Podman quadlet)
- **Container Name**: `hermes`
- **Service**: `systemctl --user status hermes`
- **Ports**:
  - Host Port 9112 → Container Port 9112
- **Access**: `podman exec -it hermes /bin/bash`

For reproducible deployment, run `init-preprequisites.sh` (sudo required) then either `forgejo-setup.sh` or `hermes-setup.sh` (user-level).

#### Port Reference
| Purpose | Host Port | Container Port |
|---------|-----------|----------------|
| SSH (Git) | 2222 | 2222 |
| HTTP (Web) | 2223 | 3000 |
| Hermes Service | 9112 | 9112 |

#### Git Clone URLs
**SSH:**
```bash
git clone ssh://git@git.wmedrano.dev:2222/username/repository.git
```

**HTTPS:**
```bash
git clone https://git.wmedrano.dev/username/repository.git
```

#### Useful Commands
```bash
# Check container status
systemctl --user status forgejo
systemctl --user status hermes

# View logs
podman logs forgejo
podman logs hermes

# Execute commands in container
podman exec -it forgejo /bin/bash
podman exec -it hermes /bin/bash

# Access Forgejo CLI
podman exec -it forgejo forgejo admin --help

# Restart container
systemctl --user restart forgejo
systemctl --user restart hermes
```
