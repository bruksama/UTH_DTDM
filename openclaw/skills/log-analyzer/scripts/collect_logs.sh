#!/usr/bin/env bash
set -euo pipefail

LINE_LIMIT=100
CANDIDATE_CONTAINER=""
ACTIVE_CONTAINER=""
NGINX_CONTAINER="nginx"
OUTPUT_DIR="./log-bundle"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --line)
      LINE_LIMIT="$2"
      shift 2
      ;;
    --candidate)
      CANDIDATE_CONTAINER="$2"
      shift 2
      ;;
    --active)
      ACTIVE_CONTAINER="$2"
      shift 2
      ;;
    --nginx)
      NGINX_CONTAINER="$2"
      shift 2
      ;;
    --bundle)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      OUTPUT_DIR="$1"
      shift
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

collect_one() {
  local container="$1"
  local outfile="$2"
  if [ -n "$container" ] && docker ps -a --format '{{.Names}}' | grep -Fxq "$container"; then
    docker logs --tail "$LINE_LIMIT" "$container" > "$outfile" 2>&1 || true
  fi
}

collect_one "$CANDIDATE_CONTAINER" "$OUTPUT_DIR/candidate.log"
collect_one "$ACTIVE_CONTAINER" "$OUTPUT_DIR/active.log"
collect_one "$NGINX_CONTAINER" "$OUTPUT_DIR/nginx.log"

echo "$OUTPUT_DIR"
