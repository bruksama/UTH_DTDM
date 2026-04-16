#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

ROLLBACK_COLOR="${1:?usage: rollback.sh <blue|green>}"
load_env_if_present
COMPOSE_FILE="${DEPLOY_COMPOSE_FILE:-$(cfg_get paths.compose_file)}"
BLUE_SERVICE="${DEPLOY_BLUE_SERVICE:-$(cfg_get services.blue)}"
GREEN_SERVICE="${DEPLOY_GREEN_SERVICE:-$(cfg_get services.green)}"

"$SCRIPT_DIR/switch_traffic.sh" "$ROLLBACK_COLOR" >/dev/null

if [ "$ROLLBACK_COLOR" = "blue" ]; then
  docker compose -f "$COMPOSE_FILE" up -d "$BLUE_SERVICE"
  docker compose -f "$COMPOSE_FILE" stop "$GREEN_SERVICE" || true
else
  docker compose -f "$COMPOSE_FILE" up -d "$GREEN_SERVICE"
  docker compose -f "$COMPOSE_FILE" stop "$BLUE_SERVICE" || true
fi

echo "$ROLLBACK_COLOR"
