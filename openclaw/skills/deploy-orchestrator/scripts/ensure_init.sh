#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

load_env_if_present
require_bin python3

mkdir -p "$RUNTIME_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  cp "$DEFAULT_CONFIG_PATH" "$CONFIG_FILE"
  echo "Initialized config: $CONFIG_FILE"
fi

if [ ! -f "$SKILL_DIR/config/deploy.env" ]; then
  cp "$DEFAULT_ENV_EXAMPLE" "$SKILL_DIR/config/deploy.env"
  echo "Initialized env file: $SKILL_DIR/config/deploy.env"
fi

if [ ! -f "$DB_PATH" ]; then
  python3 "$SCRIPT_DIR/init_db.py" "$DB_PATH" >/dev/null
  echo "Initialized sqlite: $DB_PATH"
fi

echo "OK"
