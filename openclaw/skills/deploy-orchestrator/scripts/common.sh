#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DEFAULT_RUNTIME_DIR="$SKILL_DIR/runtime"
DEFAULT_CONFIG_FILE="$SKILL_DIR/config/deploy-config.yaml"
DEFAULT_ENV_FILE="$SKILL_DIR/config/deploy.env"
DEFAULT_CONFIG_PATH="$SKILL_DIR/config/deploy-config.example.yaml"
DEFAULT_ENV_EXAMPLE="$SKILL_DIR/config/deploy.env.example"
DEFAULT_DEPLOY_REPO_DIR="${HOME:?HOME is required}/.openclaw/workspace/deploy_runtime"

CONFIG_FILE="$DEFAULT_CONFIG_FILE"
ENV_FILE="$DEFAULT_ENV_FILE"
RUNTIME_DIR="$DEFAULT_RUNTIME_DIR"
DB_PATH="$DEFAULT_RUNTIME_DIR/deploy.db"

cfg_get() {
  local key="$1"
  local config_file="${CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
  python3 - "$config_file" "$key" <<'PY'
import pathlib, sys
root, stack = {}, [(-1, {})]
stack[0] = (-1, root)
try:
    lines = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
except FileNotFoundError:
    print("")
    raise SystemExit
for raw in lines:
    if not raw.strip() or raw.lstrip().startswith("#"):
        continue
    indent = len(raw) - len(raw.lstrip(" "))
    key, sep, value = raw.strip().partition(":")
    if not sep:
        continue
    while indent <= stack[-1][0]:
        stack.pop()
    parent = stack[-1][1]
    key, value = key.strip(), value.strip()
    if value:
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        parent[key] = value
        continue
    node = {}
    parent[key] = node
    stack.append((indent, node))
cur = root
for part in sys.argv[2].split("."):
    if not isinstance(cur, dict) or part not in cur:
        print("")
        raise SystemExit
    cur = cur[part]
print("" if cur is None else cur)
PY
}

resolve_runtime_dir() {
  [ -n "${DEPLOY_RUNTIME_DIR:-}" ] && printf '%s\n' "$DEPLOY_RUNTIME_DIR" && return 0
  local runtime_dir="$(cfg_get paths.runtime_dir)"
  [ -n "$runtime_dir" ] && printf '%s\n' "$runtime_dir" || printf '%s\n' "$DEFAULT_RUNTIME_DIR"
}

resolve_db_path() {
  [ -n "${DEPLOY_SQLITE_PATH:-}" ] && printf '%s\n' "$DEPLOY_SQLITE_PATH" && return 0
  [ -n "${DEPLOY_RUNTIME_DIR:-}" ] && printf '%s/deploy.db\n' "$DEPLOY_RUNTIME_DIR" && return 0
  local sqlite_path="$(cfg_get paths.sqlite_db)"
  [ -n "$sqlite_path" ] && printf '%s\n' "$sqlite_path" || printf '%s/deploy.db\n' "$RUNTIME_DIR"
}

refresh_runtime_paths() {
  CONFIG_FILE="${DEPLOY_CONFIG_PATH:-$DEFAULT_CONFIG_FILE}"
  ENV_FILE="${DEPLOY_ENV_FILE:-$DEFAULT_ENV_FILE}"
  RUNTIME_DIR="$(resolve_runtime_dir)"
  DB_PATH="$(resolve_db_path)"
  export CONFIG_FILE ENV_FILE RUNTIME_DIR DB_PATH
}

load_env_if_present() {
  local env_file="${DEPLOY_ENV_FILE:-$DEFAULT_ENV_FILE}"
  [ -f "$env_file" ] || { refresh_runtime_paths; return 0; }
  while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    [[ -v $key ]] && continue
    printf -v "$key" '%s' "$value"
    export "$key"
  done < <(python3 - "$env_file" <<'PY'
import ast, pathlib, re, sys
for i, raw in enumerate(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines(), start=1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("export "):
        line = line[7:].lstrip()
    key, sep, value = line.partition("=")
    if not sep:
        raise SystemExit(f"Invalid env line {i}: expected KEY=VALUE")
    key, value = key.strip(), value.strip()
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
        raise SystemExit(f"Invalid env key on line {i}: {key}")
    if value[:1] in {"'", '"'}:
        if len(value) < 2 or value[-1] != value[0]:
            raise SystemExit(f"Invalid quoted env value on line {i}")
        value = ast.literal_eval(value)
    print(key, end="\0")
    print(value if isinstance(value, str) else str(value), end="\0")
PY
)
  refresh_runtime_paths
}

candidate_from_active() {
  case "${1:-}" in blue) printf 'green\n' ;; green) printf 'blue\n' ;; *) printf 'blue\n' ;; esac
}

service_name_for_color() {
  local color="$1"
  local service_name="$(cfg_get "services.${color}")"
  [ -n "$service_name" ] && printf '%s\n' "$service_name" || printf 'app-%s\n' "$color"
}

resolve_deploy_repo_dir() {
  [ -n "${DEPLOY_REPO_DIR:-}" ] && printf '%s\n' "$DEPLOY_REPO_DIR" || printf '%s\n' "$DEFAULT_DEPLOY_REPO_DIR"
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

require_bin() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required binary: $1" >&2; exit 1; }
}

sqlite_query() {
  local db="$DB_PATH"
  shift
  python3 - "$db" "$@" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute(sys.argv[2], sys.argv[3:])
for row in cur.fetchall():
    print("\t".join("" if v is None else str(v) for v in row))
conn.commit()
conn.close()
PY
}

acquire_deployment_lock() {
  python3 - "$1" "$2" "$3" "$4" "$5" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1], timeout=5)
cur = conn.cursor()
try:
    cur.execute(
        "INSERT INTO deployment_lock(environment, locked_by, deployment_id, lock_reason, locked_at, expires_at) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (sys.argv[2], sys.argv[3], sys.argv[4], "deploy-running", sys.argv[5], None),
    )
    conn.commit()
except sqlite3.IntegrityError:
    sys.exit(1)
finally:
    conn.close()
PY
}

release_deployment_lock() {
  python3 - "$1" "$2" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1], timeout=5)
cur = conn.cursor()
cur.execute("DELETE FROM deployment_lock WHERE environment = ?", (sys.argv[2],))
conn.commit()
conn.close()
PY
}
