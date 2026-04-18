#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

require_bin python3
load_env_if_present

SQLITE_PATH="$DB_PATH"
ENVIRONMENT="${DEPLOY_ENVIRONMENT:-$(cfg_get environment)}"

python3 - "$SQLITE_PATH" "$ENVIRONMENT" <<'PY'
import sqlite3, sys, json
conn = sqlite3.connect(sys.argv[1])
conn.row_factory = sqlite3.Row
cur = conn.cursor()
cur.execute("SELECT * FROM deployment_state WHERE environment = ?", (sys.argv[2],))
row = cur.fetchone()
print(json.dumps(dict(row) if row else {"environment": sys.argv[2], "status": "uninitialized"}))
conn.close()
PY
