#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/common.sh"

load_env_if_present
require_bin python3

RUNTIME_DIR="${DEPLOY_RUNTIME_DIR:-$(cfg_get paths.runtime_dir)}"
SQLITE_PATH="${DEPLOY_SQLITE_PATH:-$(cfg_get paths.sqlite_db)}"
CONFIG_TARGET="${DEPLOY_CONFIG_PATH:-$SKILL_DIR/config/deploy-config.yaml}"
ENV_TARGET="${DEPLOY_ENV_FILE:-$SKILL_DIR/config/deploy.env}"

mkdir -p "$RUNTIME_DIR"
mkdir -p "$(dirname "$SQLITE_PATH")"
mkdir -p "$(dirname "$CONFIG_TARGET")"

if [ ! -f "$CONFIG_TARGET" ]; then
  cp "$DEFAULT_CONFIG_PATH" "$CONFIG_TARGET"
  echo "Initialized config: $CONFIG_TARGET"
fi

if [ ! -f "$ENV_TARGET" ]; then
  cp "$DEFAULT_ENV_EXAMPLE" "$ENV_TARGET"
  echo "Initialized env file: $ENV_TARGET"
fi

if [ ! -f "$SQLITE_PATH" ]; then
  python3 "$SCRIPT_DIR/init_db.py" "$SQLITE_PATH" >/dev/null
  echo "Initialized sqlite: $SQLITE_PATH"
else
  python3 "$SCRIPT_DIR/init_db.py" "$SQLITE_PATH" >/dev/null
fi

echo "OK"
