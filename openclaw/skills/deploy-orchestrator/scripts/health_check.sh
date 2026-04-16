#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:?usage: health_check.sh <url>}"
RETRIES="${DEPLOY_HEALTH_RETRIES:-3}"
TIMEOUT="${DEPLOY_HEALTH_TIMEOUT:-10}"
SLEEP_SEC="${DEPLOY_HEALTH_SLEEP:-2}"
USE_COMPOSE_EXEC="${USE_COMPOSE_EXEC:-0}"
EDGE_SERVICE="${DEPLOY_EDGE_SERVICE:-nginx}"
COMPOSE_FILE="${DEPLOY_COMPOSE_FILE:-docker-compose.yml}"

for i in $(seq 1 "$RETRIES"); do
  if [ "$USE_COMPOSE_EXEC" = "1" ]; then
    if docker compose -f "$COMPOSE_FILE" exec -T "$EDGE_SERVICE" sh -c "wget -T $TIMEOUT -q -O /dev/null '$TARGET_URL'"; then
      echo "passed:$i"
      exit 0
    fi
  else
    if curl -fsS --max-time "$TIMEOUT" "$TARGET_URL" >/dev/null; then
      echo "passed:$i"
      exit 0
    fi
  fi
  echo "retry:$i"
  sleep "$SLEEP_SEC"
done

echo "failed"
exit 1
