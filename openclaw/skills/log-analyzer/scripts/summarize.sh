#!/usr/bin/env bash
set -euo pipefail

INPUT_JSON="${1:?usage: summarize.sh <analysis-json-file>}"
python3 - "$INPUT_JSON" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data.get('slack_summary') or data.get('suspected_root_cause') or 'Không đủ dữ liệu để tóm tắt lỗi.')
PY
