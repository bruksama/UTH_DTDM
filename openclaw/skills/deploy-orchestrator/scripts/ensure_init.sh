#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

require_bin python3
load_env_if_present

mkdir -p "$(dirname "$CONFIG_FILE")" "$(dirname "$ENV_FILE")"

if [ ! -f "$CONFIG_FILE" ]; then
  cp "$DEFAULT_CONFIG_PATH" "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
  echo "Initialized config: $CONFIG_FILE"
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$DEFAULT_ENV_EXAMPLE" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "Initialized env file: $ENV_FILE"
fi

refresh_runtime_paths
mkdir -p "$RUNTIME_DIR" "$(dirname "$DB_PATH")"

if [ ! -f "$DB_PATH" ]; then
  python3 "$SCRIPT_DIR/init_db.py" "$DB_PATH" >/dev/null
  chmod 600 "$DB_PATH"
  echo "Initialized sqlite: $DB_PATH"
fi

echo "OK"
