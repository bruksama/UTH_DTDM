#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

TARGET_COLOR="${1:?usage: switch_traffic.sh <blue|green>}"
load_env_if_present

NGINX_CONF="${DEPLOY_NGINX_CONF:-$(cfg_get paths.nginx_conf)}"
COMPOSE_FILE="${DEPLOY_COMPOSE_FILE:-$(cfg_get paths.compose_file)}"
BLUE_SERVICE="${DEPLOY_BLUE_SERVICE:-$(cfg_get services.blue)}"
GREEN_SERVICE="${DEPLOY_GREEN_SERVICE:-$(cfg_get services.green)}"
EDGE_SERVICE="${DEPLOY_EDGE_SERVICE:-$(cfg_get services.edge)}"

[ -f "$NGINX_CONF" ] || { echo "nginx.conf not found: $NGINX_CONF" >&2; exit 1; }

if [ "$TARGET_COLOR" = "blue" ]; then
  sed -i "s/# server ${BLUE_SERVICE}:80;/server ${BLUE_SERVICE}:80;/g" "$NGINX_CONF" || true
  sed -i "s/server ${GREEN_SERVICE}:80;/# server ${GREEN_SERVICE}:80;/g" "$NGINX_CONF" || true
else
  sed -i "s/# server ${GREEN_SERVICE}:80;/server ${GREEN_SERVICE}:80;/g" "$NGINX_CONF" || true
  sed -i "s/server ${BLUE_SERVICE}:80;/# server ${BLUE_SERVICE}:80;/g" "$NGINX_CONF" || true
fi

if docker compose -f "$COMPOSE_FILE" exec -T "$EDGE_SERVICE" nginx -s reload >/dev/null 2>&1; then
  echo "reloaded"
else
  docker compose -f "$COMPOSE_FILE" restart "$EDGE_SERVICE" >/dev/null
  echo "restarted"
fi
