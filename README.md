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
