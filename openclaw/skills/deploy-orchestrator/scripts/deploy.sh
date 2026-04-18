#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

REQUESTED_IMAGE="${1:-latest}"
REQUESTED_BY="${2:-unknown}"
REQUESTED_COMMAND="deploy ${REQUESTED_IMAGE}"

bash "$SCRIPT_DIR/ensure_init.sh" >/dev/null
require_bin python3
load_env_if_present

CONFIG_PATH="$CONFIG_FILE"
SQLITE_PATH="$DB_PATH"
ENVIRONMENT="${DEPLOY_ENVIRONMENT:-$(cfg_get environment)}"
REPO_DIR="$(resolve_deploy_repo_dir)"

DEPLOYMENT_ID="dep-$(date -u +%Y%m%d%H%M%S)-$$"
STARTED_AT="$(now_utc)"
PREVIOUS_COLOR=""
PREVIOUS_TAG=""
CANDIDATE_COLOR=""
RESOLVED_TAG=""
RESOLVED_DIGEST=""
FAIL_STEP="unknown"
SUCCESS=0

if ! acquire_deployment_lock "$SQLITE_PATH" "$ENVIRONMENT" "$REQUESTED_BY" "$DEPLOYMENT_ID" "$STARTED_AT"; then
  echo "Deploy blocked: another deployment is running for environment $ENVIRONMENT" >&2
  exit 1
fi

cleanup_lock() {
  release_deployment_lock "$SQLITE_PATH" "$ENVIRONMENT"
}

handle_failure() {
  local exit_code=$?
  [ "$SUCCESS" = "1" ] && return 0

  local finished_at rollback_status summary rollback_color="${PREVIOUS_COLOR:-}" rollback_tag="${PREVIOUS_TAG:-latest}"
  finished_at="$(now_utc)"

  python3 - "$SQLITE_PATH" "$DEPLOYMENT_ID" "$FAIL_STEP" "$finished_at" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute('UPDATE deployment_history SET status=?, error_summary=?, finished_at=? WHERE deployment_id=?',
            ('failed', f'failed at: {sys.argv[3]}', sys.argv[4], sys.argv[2]))
conn.commit(); conn.close()
PY

  if [ -n "$rollback_color" ] && [ -d "$REPO_DIR" ]; then
    echo "Initiating rollback to $rollback_color with tag $rollback_tag..." >&2
    if (cd "$REPO_DIR" && bash ./scripts/switch.sh "$rollback_color" "$rollback_tag" >/dev/null 2>&1); then
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
    summary="Deploy thất bại ở bước ${FAIL_STEP}, không thể rollback."
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

FAIL_STEP="resolve-image"
RESOLVED_JSON="$(python3 "$SCRIPT_DIR/resolve_image.py" "$REQUESTED_IMAGE")"
RESOLVED_TAG="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["resolved_tag"])' <<<"$RESOLVED_JSON")"
RESOLVED_DIGEST="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("resolved_digest") or "")' <<<"$RESOLVED_JSON")"

FAIL_STEP="read-state"
STATE_JSON="$(bash "$SCRIPT_DIR/status.sh")"
ACTIVE_COLOR="$(python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); print(data.get("active_color") or "")' <<<"$STATE_JSON")"
PREVIOUS_TAG="$(python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); print(data.get("active_image_tag") or "latest")' <<<"$STATE_JSON")"

PREVIOUS_COLOR="$ACTIVE_COLOR"
[ -z "$PREVIOUS_COLOR" ] && PREVIOUS_COLOR="blue"
CANDIDATE_COLOR="$(candidate_from_active "$ACTIVE_COLOR")"

FAIL_STEP="write-pending-state"
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

FAIL_STEP="delegate-to-app-repo"
if [ ! -d "$REPO_DIR" ]; then
  echo "Error: App repository not found at $REPO_DIR. Set DEPLOY_REPO_DIR to override." >&2
  exit 1
fi

cd "$REPO_DIR"
bash ./scripts/switch.sh "$CANDIDATE_COLOR" "$RESOLVED_TAG" >/dev/null

FAIL_STEP="finalize-state"
FINISHED_AT="$(now_utc)"
CONTAINER_NAME="$(service_name_for_color "$CANDIDATE_COLOR")"
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
