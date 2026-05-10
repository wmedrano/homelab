# Homelab

Self-hosted services via rootless Podman + systemd Quadlet.

## Caddy

Reverse proxy at `git.wmedrano.dev` and `hermes.wmedrano.dev`, static site at `blog.wmedrano.dev`.

### Deploy

```bash
sudo pacman -S caddy --noconfirm
sudo cp Caddyfile /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
```

**Sites:**

| Domain | Purpose |
|--------|---------|
| `blog.wmedrano.dev` / `www.wmedrano.dev` / `wmedrano.dev` | Static files (`/var/www/wmedrano.dev`) |
| `git.wmedrano.dev` | Forgejo reverse proxy |
| `hermes.wmedrano.dev` | Hermes agent (basicauth protected) |

### Manage

```bash
sudo systemctl status caddy    # status
sudo systemctl restart caddy   # restart
caddy validate --config /etc/caddy/Caddyfile  # validate config
```

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