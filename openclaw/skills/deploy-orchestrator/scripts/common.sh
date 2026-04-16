#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Thiết lập đường dẫn dựa trên vị trí skill (tự chứa)
RUNTIME_DIR="$SKILL_DIR/runtime"
DB_PATH="$RUNTIME_DIR/deploy.db"
CONFIG_FILE="$SKILL_DIR/config/deploy-config.yaml"

DEFAULT_CONFIG_PATH="$SKILL_DIR/config/deploy-config.example.yaml"
DEFAULT_ENV_EXAMPLE="$SKILL_DIR/config/deploy.env.example"

load_env_if_present() {
  local env_file="${DEPLOY_ENV_FILE:-$SKILL_DIR/config/deploy.env}"
  if [ -f "$env_file" ]; then
    set -a && . "$env_file" && set +a
  fi
}

# Đọc config từ file YAML trong SKILL_DIR
cfg_get() {
  local key="$1"
  python3 - "$CONFIG_FILE" "$key" <<'PY'
import sys, yaml
path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f) or {}
    cur = data
    for part in key.split('.'):
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            print("")
            sys.exit(0)
    print(cur if cur is not None else "")
except FileNotFoundError:
    print("")
PY
}

now_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

require_bin() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required binary: $1" >&2
    exit 1
  }
}

sqlite_query() {
  local db="$DB_PATH"
  shift
  python3 - "$db" "$@" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
sql = sys.argv[2]
params = sys.argv[3:]
cur.execute(sql, params)
rows = cur.fetchall()
for row in rows:
    print("\t".join("" if v is None else str(v) for v in row))
conn.commit()
conn.close()
PY
}
