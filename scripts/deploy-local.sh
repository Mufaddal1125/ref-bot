#!/usr/bin/env bash
# Build the client for the room and bring the whole stack up on this machine.
#
#   scripts/deploy-local.sh                  # http://<this machine's LAN IP>
#   PORT=8080 scripts/deploy-local.sh        # if something already owns 80
#   HOST_IP=192.168.1.20 scripts/deploy-local.sh
#   SKIP_BUILD=1 scripts/deploy-local.sh     # backend-only change

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
port="${PORT:-80}"

# The client is compiled against one address, so it has to be the address the
# room types — not localhost.
host_ip="${HOST_IP:-}"
if [ -z "$host_ip" ]; then
    if command -v ipconfig >/dev/null 2>&1 && [ "$(uname -s)" = "Darwin" ]; then
        host_ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
    else
        host_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    fi
fi
if [ -z "$host_ip" ]; then
    echo "Could not work out this machine's LAN address. Set HOST_IP=<ip>." >&2
    exit 1
fi

if [ "$port" = "80" ]; then origin="http://$host_ip"; else origin="http://$host_ip:$port"; fi

env_file="$root/.env.deploy"
if [ ! -f "$env_file" ]; then
    cp "$root/.env.deploy.example" "$env_file"
    secret="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 50)"
    sed -i.bak "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=$secret|" "$env_file" && rm -f "$env_file.bak"
    echo "Created .env.deploy with a fresh secret key."
    echo "Put REFEREE_API_KEY in it before phase 3 matters."
fi

if [ -z "${SKIP_BUILD:-}" ]; then
    echo "Building the client against $origin ..."
    (cd "$root/app" && flutter build web --release --dart-define=API_BASE_URL="$origin")
fi

HTTP_PORT="$port" CSRF_TRUSTED_ORIGINS="$origin" \
    docker compose --project-directory "$root" \
        -f "$root/docker-compose.deploy.yml" \
        --env-file "$env_file" \
        up -d --build

echo
echo "RefBot is on $origin"
echo "  admin      $origin/admin/"
echo "  job queue  $origin/django-rq/"
echo "  logs       docker compose -f docker-compose.deploy.yml logs -f backend worker"
echo "  stop       docker compose -f docker-compose.deploy.yml down"
