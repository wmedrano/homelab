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

## BuildBarn RBE

Self-hosted Remote Build Execution cluster for Chromium builds using Siso. Runs via rootless Podman Quadlet with no authentication (insecure mode) — access is controlled via SSH tunnel.

### Architecture

| Service | Container | Ports | Purpose |
|---------|-----------|-------|---------|
| Frontend | `buildbarn-frontend` | 8980 | RBE API endpoint (CAS, Action Cache, Execution) |
| Storage | `buildbarn-storage` | 8981 | CAS/action-cache/FsAC backend storage |
| Scheduler | `buildbarn-scheduler` | 8982, 8983, 8984, 7982 | Dispatches actions to workers |
| Worker | `buildbarn-worker` | — | Pulls actions from scheduler, manages execution |
| Runner | `buildbarn-runner` | — | Executes build actions in siso-chromium environment |
| Installer | `buildbarn-runner-installer` | — | Ephemeral: copies `bb_runner` binary to shared volume |

All containers communicate via the `buildbarn` Podman network. The runner uses the `siso-chromium` image from Google's RBE infrastructure, providing the full Chromium build toolchain (clang, ninja, etc.).

### Deploy

```bash
bash buildbarn-setup.sh
```

This script:
1. Creates Podman named volumes for persistent storage
2. Copies JSONnet configs into the `buildbarn-config` volume
3. Installs Quadlet files to `~/.config/containers/systemd/`
4. Starts all services in dependency order

### Connect via SSH Tunnel

Since the RBE endpoint has no authentication, access is via SSH port forwarding:

```bash
# Forward the RBE endpoint to your local machine
ssh -L 8980:localhost:8980 <server-host>

# Then build Chromium with Siso using the tunnel
autoninja -C out/Default --reapi-address=localhost:8980
```

For persistent tunnels, add to `~/.ssh/config`:

```
Host buildbarn
    HostName <server-host>
    LocalForward 8980 localhost:8980
```

### Siso Configuration

The `rbe/backend.star` file configures Siso to use your BuildBarn cluster. Copy it to your Chromium source:

```bash
cp rbe/backend.star /path/to/chromium/src/build/config/siso/backend_config/backend.star
```

Build with remote execution:

```bash
autoninja -C out/Default --reapi-address=localhost:8980
```

### Manage

```bash
# Check all BuildBarn services
systemctl --user status 'buildbarn-*'

# View logs
podman logs buildbarn-storage
podman logs buildbarn-scheduler
podman logs buildbarn-worker
podman logs buildbarn-runner

# Restart all services (in order)
systemctl --user restart buildbarn-storage
systemctl --user restart buildbarn-frontend
systemctl --user restart buildbarn-scheduler
systemctl --user restart buildbarn-worker buildbarn-runner

# Stop all services
systemctl --user stop buildbarn-runner buildbarn-worker buildbarn-scheduler buildbarn-frontend buildbarn-storage

# Scheduler metrics/admin UI
curl http://localhost:7982/
```

### Configuration Files

JSONnet configs are stored in the `buildbarn-config` Podman volume. To update:

```bash
# Edit configs in the repo, then re-copy to the volume
podman run --rm \
    -v buildbarn-config:/config:Z \
    -v ./rbe/config:/src:ro \
    docker.io/alpine:latest \
    sh -c "cp /src/*.jsonnet /src/*.libsonnet /config/"

# Restart affected services
systemctl --user restart buildbarn-storage buildbarn-scheduler buildbarn-worker buildbarn-runner
```

### Troubleshooting

- **Worker not connecting**: Check that the worker can reach `buildbarn-scheduler:8983` on the `buildbarn` network. Run `podman network inspect buildbarn`.
- **Runner not starting**: Verify the runner-installer has completed (`podman logs buildbarn-runner-installer`). The runner waits for `/bb/installed` to exist.
- **Storage errors**: Check volume permissions. Rootless Podman may need `--userns=keep-id` for volume writes. The worker container already includes this flag.
- **Large build failures**: Increase `maximumMessageSizeBytes` in `common.libsonnet` (default: 64 MiB) and `defaultExecutionTimeout` in `scheduler.jsonnet`.

## Networking

IPv4 connectivity from the host to its own public services can break due to **NAT hairpin failure** — the host cannot reach its own public IPv4 address through the router's NAT. The fix is local DNS overrides in `/etc/hosts` that point each domain to `127.0.0.1` (and `::1` for IPv6 loopback), bypassing the broken hairpin route.

- The `/etc/hosts` entries are installed idempotently by `init-prerequisites.sh` (step 6).
- The Forgejo runner uses **host networking** (`network: "host"`, PR #21) so job containers share the host network stack and benefit from the same `/etc/hosts` overrides.

Validate after running `init-prerequisites.sh`:

```bash
curl -4 --connect-timeout 5 -s -o /dev/null -w "%{http_code}\n" https://git.wmedrano.dev/
```