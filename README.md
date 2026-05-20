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

## Forgejo Actions Runner

CI/CD runner for Forgejo Actions, using the Podman socket (no DinD).

### Deploy

1. Go to **Site Administration → Actions → Runners** on `git.wmedrano.dev` and create a new runner
2. Copy the registration token and UUID
3. Run: `bash runner-setup.sh <TOKEN> <UUID>`

The token and UUID are written into `runner-config.yml` in the data volume via the v12 `server.connections` block — no separate `register` step needed.

### Manage

```bash
systemctl --user status forgejo_actions_runner   # status
podman logs forgejo_actions_runner               # logs
systemctl --user restart forgejo_actions_runner  # restart
```

## Networking

IPv4 connectivity from the host to its own public services can break due to **NAT hairpin failure** — the host cannot reach its own public IPv4 address through the router's NAT. The fix is local DNS overrides in `/etc/hosts` that point each domain to `127.0.0.1` (and `::1` for IPv6 loopback), bypassing the broken hairpin route.

- The `/etc/hosts` entries are installed idempotently by `init-prerequisites.sh` (step 6).
- The Forgejo runner uses **host networking** (`network: "host"`, PR #21) so job containers share the host network stack and benefit from the same `/etc/hosts` overrides.

Validate after running `init-prerequisites.sh`:

```bash
curl -4 --connect-timeout 5 -s -o /dev/null -w "%{http_code}\n" https://git.wmedrano.dev/
```
