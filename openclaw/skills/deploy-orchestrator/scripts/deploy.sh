#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

REQUESTED_IMAGE="${1:-latest}"
REQUESTED_BY="${2:-unknown}"
REQUESTED_COMMAND="deploy ${REQUESTED_IMAGE}"

"$SCRIPT_DIR/ensure_init.sh" >/dev/null
load_env_if_present

require_bin docker
require_bin python3
require_bin curl

CONFIG_PATH="${DEPLOY_CONFIG_PATH:-$SKILL_DIR/config/deploy-config.yaml}"
SQLITE_PATH="$DB_PATH"
COMPOSE_FILE="${DEPLOY_COMPOSE_FILE:-$(cfg_get paths.compose_file)}"
ENVIRONMENT="${DEPLOY_ENVIRONMENT:-$(cfg_get environment)}"
BLUE_SERVICE="${DEPLOY_BLUE_SERVICE:-$(cfg_get services.blue)}"
GREEN_SERVICE="${DEPLOY_GREEN_SERVICE:-$(cfg_get services.green)}"
PUBLIC_BASE_URL="${DEPLOY_PUBLIC_BASE_URL:-$(cfg_get health.public_base_url)}"
HEALTH_ROUTE="${DEPLOY_HEALTH_ROUTE:-$(cfg_get health.route)}"
EDGE_SERVICE="${DEPLOY_EDGE_SERVICE:-$(cfg_get services.edge)}"

export DEPLOY_CONFIG_PATH="$CONFIG_PATH"
export DEPLOY_SQLITE_PATH="$SQLITE_PATH"
export DEPLOY_COMPOSE_FILE="$COMPOSE_FILE"
export DEPLOY_ENVIRONMENT="$ENVIRONMENT"
export DEPLOY_BLUE_SERVICE="$BLUE_SERVICE"
export DEPLOY_GREEN_SERVICE="$GREEN_SERVICE"
export DEPLOY_PUBLIC_BASE_URL="$PUBLIC_BASE_URL"
export DEPLOY_HEALTH_ROUTE="$HEALTH_ROUTE"
export DEPLOY_EDGE_SERVICE="$EDGE_SERVICE"

DEPLOYMENT_ID="dep-$(date -u +%Y%m%d%H%M%S)-$$"
STARTED_AT="$(now_utc)"
PREVIOUS_COLOR=""
CANDIDATE_COLOR=""
CANDIDATE_SERVICE=""
RESOLVED_TAG=""
RESOLVED_DIGEST=""
FAIL_STEP="unknown"
SUCCESS=0

LOCK_EXISTS="$(python3 - "$SQLITE_PATH" "$ENVIRONMENT" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM deployment_lock WHERE environment = ?', (sys.argv[2],))
print(cur.fetchone()[0])
conn.close()
PY
)"
if [ "$LOCK_EXISTS" != "0" ]; then
  echo "Deploy blocked: another deployment is running for environment $ENVIRONMENT" >&2
  exit 1
fi

python3 - "$SQLITE_PATH" "$ENVIRONMENT" "$REQUESTED_BY" "$DEPLOYMENT_ID" "$STARTED_AT" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('INSERT OR REPLACE INTO deployment_lock(environment, locked_by, deployment_id, lock_reason, locked_at, expires_at) VALUES (?, ?, ?, ?, ?, ?)',
            (sys.argv[2], sys.argv[3], sys.argv[4], 'deploy-running', sys.argv[5], None))
conn.commit(); conn.close()
PY

cleanup_lock() {
  python3 - "$SQLITE_PATH" "$ENVIRONMENT" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('DELETE FROM deployment_lock WHERE environment = ?', (sys.argv[2],))
conn.commit(); conn.close()
PY
}

handle_failure() {
  local exit_code=$?
  [ "$SUCCESS" = "1" ] && return 0

  local finished_at rollback_status summary rollback_color="${PREVIOUS_COLOR:-}"
  finished_at="$(now_utc)"

  python3 - "$SQLITE_PATH" "$DEPLOYMENT_ID" "$FAIL_STEP" "$finished_at" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_history SET status=?, error_summary=?, finished_at=? WHERE deployment_id=?',
            ('failed', f'failed at: {sys.argv[3]}', sys.argv[4], sys.argv[2]))
conn.commit(); conn.close()
PY

  if [ -n "$rollback_color" ]; then
    if "$SCRIPT_DIR/rollback.sh" "$rollback_color" >/dev/null 2>&1; then
      rollback_status="rolled_back"
      summary="Deploy thất bại ở bước ${FAIL_STEP}, đã rollback về ${rollback_color}."
      python3 - "$SQLITE_PATH" "$ENVIRONMENT" "$rollback_color" "$DEPLOYMENT_ID" "$finished_at" "$summary" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_state SET active_color=?, status=?, updated_at=?, notes=?, last_deployment_id=? WHERE environment=?',
            (sys.argv[3], 'active', sys.argv[5], sys.argv[6], sys.argv[4], sys.argv[2]))
cur.execute('UPDATE deployment_history SET final_active_color=?, rollback_occurred=1, status=?, operator_summary=?, finished_at=? WHERE deployment_id=?',
            (sys.argv[3], 'rolled_back', sys.argv[6], sys.argv[5], sys.argv[4]))
conn.commit(); conn.close()
PY
    else
      rollback_status="rollback_failed"
      summary="Deploy thất bại ở bước ${FAIL_STEP}, rollback cũng thất bại."
      python3 - "$SQLITE_PATH" "$ENVIRONMENT" "$DEPLOYMENT_ID" "$finished_at" "$summary" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_state SET status=?, updated_at=?, notes=?, last_deployment_id=? WHERE environment=?',
            ('error', sys.argv[4], sys.argv[5], sys.argv[3], sys.argv[2]))
cur.execute('UPDATE deployment_history SET rollback_occurred=1, status=?, operator_summary=?, finished_at=? WHERE deployment_id=?',
            ('rollback_failed', sys.argv[5], sys.argv[4], sys.argv[3]))
conn.commit(); conn.close()
PY
    fi
  else
    summary="Deploy thất bại ở bước ${FAIL_STEP}, không có previous color để rollback."
    python3 - "$SQLITE_PATH" "$ENVIRONMENT" "$DEPLOYMENT_ID" "$finished_at" "$summary" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_state SET status=?, updated_at=?, notes=?, last_deployment_id=? WHERE environment=?',
            ('error', sys.argv[4], sys.argv[5], sys.argv[3], sys.argv[2]))
cur.execute('UPDATE deployment_history SET rollback_occurred=0, status=?, operator_summary=?, finished_at=? WHERE deployment_id=?',
            ('failed', sys.argv[5], sys.argv[4], sys.argv[3]))
conn.commit(); conn.close()
PY
  fi

  echo "$summary" >&2
  exit "$exit_code"
}
trap cleanup_lock EXIT
trap handle_failure ERR

RESOLVED_JSON="$(DEPLOY_CONFIG_PATH="$CONFIG_PATH" python3 "$SCRIPT_DIR/resolve_image.py" "$REQUESTED_IMAGE")"
RESOLVED_TAG="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["resolved_tag"])' <<<"$RESOLVED_JSON")"
RESOLVED_DIGEST="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("resolved_digest") or "")' <<<"$RESOLVED_JSON")"

STATE_JSON="$("$SCRIPT_DIR/status.sh")"
ACTIVE_COLOR="$(python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); print(data.get("active_color") or "")' <<<"$STATE_JSON")"
CANDIDATE_COLOR="$(candidate_from_active "$ACTIVE_COLOR")"
CANDIDATE_SERVICE="$GREEN_SERVICE"
PREVIOUS_COLOR="$ACTIVE_COLOR"
if [ "$CANDIDATE_COLOR" = "blue" ]; then
  CANDIDATE_SERVICE="$BLUE_SERVICE"
fi

python3 - "$SQLITE_PATH" "$DEPLOYMENT_ID" "$ENVIRONMENT" "$REQUESTED_BY" "$REQUESTED_COMMAND" "$REQUESTED_IMAGE" "$RESOLVED_TAG" "$RESOLVED_DIGEST" "$PREVIOUS_COLOR" "$CANDIDATE_COLOR" "$STARTED_AT" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('INSERT INTO deployment_history(deployment_id, environment, requested_by, requested_command, requested_image, resolved_image_tag, resolved_image_digest, previous_active_color, candidate_color, status, started_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            (sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8] or None, sys.argv[9] or None, sys.argv[10], 'running', sys.argv[11]))
cur.execute('INSERT INTO deployment_state(environment, active_color, active_image_tag, active_image_digest, active_container_name, previous_color, previous_image_tag, previous_image_digest, last_deployment_id, status, updated_at, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(environment) DO UPDATE SET last_deployment_id=excluded.last_deployment_id, status=excluded.status, updated_at=excluded.updated_at',
            (sys.argv[3], sys.argv[9] or 'blue', '', '', '', sys.argv[9] or None, None, None, sys.argv[2], 'deploying', sys.argv[11], 'deployment in progress'))
conn.commit(); conn.close()
PY

IMAGE_REF="$REQUESTED_IMAGE"
if [ "$REQUESTED_IMAGE" = "latest" ]; then
  IMAGE_REF="$RESOLVED_TAG"
fi

FAIL_STEP="pull-image"
docker pull "$IMAGE_REF" >/dev/null 2>&1

FAIL_STEP="start-candidate"
docker compose -f "$COMPOSE_FILE" up -d "$CANDIDATE_SERVICE"

FAIL_STEP="pre-switch-health-check"
USE_COMPOSE_EXEC=1 DEPLOY_EDGE_SERVICE="$EDGE_SERVICE" DEPLOY_COMPOSE_FILE="$COMPOSE_FILE" \
  "$SCRIPT_DIR/health_check.sh" "http://${CANDIDATE_SERVICE}:80${HEALTH_ROUTE}" >/dev/null

FAIL_STEP="switch-traffic"
"$SCRIPT_DIR/switch_traffic.sh" "$CANDIDATE_COLOR" >/dev/null

FAIL_STEP="post-switch-health-check"
"$SCRIPT_DIR/health_check.sh" "${PUBLIC_BASE_URL}${HEALTH_ROUTE}" >/dev/null

FINISHED_AT="$(now_utc)"
CONTAINER_NAME="$CANDIDATE_SERVICE"
SUMMARY="Deploy thành công: ${RESOLVED_TAG} lên ${CANDIDATE_COLOR}, health check pass, traffic đã chuyển."

python3 - "$SQLITE_PATH" "$ENVIRONMENT" "$CANDIDATE_COLOR" "$RESOLVED_TAG" "$RESOLVED_DIGEST" "$CONTAINER_NAME" "$PREVIOUS_COLOR" "$DEPLOYMENT_ID" "$FINISHED_AT" "$SUMMARY" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_state SET active_color=?, active_image_tag=?, active_image_digest=?, active_container_name=?, previous_color=?, last_deployment_id=?, status=?, updated_at=?, notes=? WHERE environment=?',
            (sys.argv[3], sys.argv[4], sys.argv[5] or None, sys.argv[6], sys.argv[7] or None, sys.argv[8], 'active', sys.argv[9], sys.argv[10], sys.argv[2]))
cur.execute('UPDATE deployment_history SET final_active_color=?, health_check_url=?, health_check_passed=1, rollback_occurred=0, status=?, operator_summary=?, finished_at=? WHERE deployment_id=?',
            (sys.argv[3], '/', 'succeeded', sys.argv[10], sys.argv[9], sys.argv[8]))
conn.commit(); conn.close()
PY

SUCCESS=1
echo "$SUMMARY"
