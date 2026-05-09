# Homelab

Self-hosted services via rootless Podman + systemd Quadlet.

## Forgejo

Git hosting at `git.wmedrano.dev`.

### Deploy

`bash init-prerequisites.sh` (sudo), then `bash forgejo-setup.sh`

| Purpose    | Host Port |
|------------|-----------|
| SSH (Git)  | 2222      |
| HTTP (Web) | 2223      |

**Clone:**
- SSH: `git clone ssh://git@git.wmedrano.dev:2222/user/repo.git`
- HTTPS: `git clone https://git.wmedrano.dev/user/repo.git`

### Manage

```bash
systemctl --user status forgejo   # status
podman logs forgejo               # logs
systemctl --user restart forgejo  # restart
```

## Hermes

AI agent gateway running on port 8642.

### Deploy

`bash init-prerequisites.sh` (sudo, if not already done), then `bash hermes-setup.sh`

The setup script runs an interactive wizard on first install, then starts the persistent gateway service.

| Purpose | Host Port |
|---------|-----------|
| Gateway | 8642      |

### Shell Access

```bash
podman exec -it hermes .venv/bin/hermes   # hermes CLI
podman exec -it hermes bash               # bash shell
```

### Manage

```bash
systemctl --user status hermes   # status
podman logs hermes               # logs
systemctl --user restart hermes  # restart
```

### Reset

To redo the setup wizard from scratch:

```bash
systemctl --user stop hermes
podman volume rm hermes-data
bash hermes-setup.sh
```
