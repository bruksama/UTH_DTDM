#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

if len(sys.argv) != 2:
    print("usage: analyze_logs.py <log-bundle-dir>", file=sys.stderr)
    sys.exit(1)

bundle = Path(sys.argv[1])
if not bundle.exists() or not bundle.is_dir():
    print("bundle directory not found", file=sys.stderr)
    sys.exit(1)

files = {
    "candidate": bundle / "candidate.log",
    "active": bundle / "active.log",
    "nginx": bundle / "nginx.log",
}

texts = {}
for key, path in files.items():
    texts[key] = path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""

combined = "\n".join(texts.values())
combined_lower = combined.lower()

rules = [
    (
        "image_pull_failure",
        ["pull access denied", "manifest unknown", "not found"],
        "Không pull được image từ registry.",
        "Kiểm tra tên image, tag, quyền truy cập registry hoặc package visibility.",
        "high",
    ),
    (
        "port_conflict",
        ["address already in use", "port is already allocated"],
        "Container mới không bind được port vì conflict.",
        "Kiểm tra container/tiến trình đang chiếm port hoặc compose mapping.",
        "high",
    ),
    (
        "missing_env_or_config",
        ["environment variable", "not set", "missing", "keyerror", "config"],
        "App có thể thiếu biến môi trường hoặc config runtime.",
        "Kiểm tra env file, secret, và config được mount vào container.",
        "medium",
    ),
    (
        "application_crash",
        ["traceback", "exception", "panic", "segmentation fault", "fatal"],
        "App có dấu hiệu crash khi khởi động hoặc khi nhận request.",
        "Đọc candidate logs chi tiết hơn để xác định stack trace hoặc lỗi runtime gốc.",
        "medium",
    ),
    (
        "health_check_failure",
        ["500 internal server error", "502 bad gateway", "503 service unavailable", "health check failed"],
        "Health check thất bại sau khi container khởi động.",
        "Kiểm tra candidate app response ở route public và dependency runtime của app.",
        "medium",
    ),
    (
        "nginx_failure",
        ["host not found in upstream", "connect() failed", "no live upstreams"],
        "Nginx hoặc reverse proxy không route được tới upstream mong đợi.",
        "Kiểm tra nginx upstream config, service name và trạng thái container đích.",
        "high",
    ),
]

incident_type = "insufficient_evidence"
suspected_root_cause = "Chưa đủ evidence để kết luận nguyên nhân chính."
recommended_operator_action = "Kiểm tra candidate logs và nginx logs với phạm vi rộng hơn."
confidence = "low"
matched = []

for incident, keywords, message, action, level in rules:
    hit_lines = []
    for line in combined.splitlines():
        l = line.lower()
        if any(k in l for k in keywords):
            hit_lines.append(line.strip())
    if hit_lines:
        incident_type = incident
        suspected_root_cause = message
        recommended_operator_action = action
        confidence = level
        matched = hit_lines[:5]
        break

if incident_type == "insufficient_evidence":
    if texts["candidate"].strip() == "" and texts["nginx"].strip() == "":
        suspected_root_cause = "Không có log bundle đủ để phân tích."
        recommended_operator_action = "Chạy lại bước collect logs với candidate/nginx container thật."
    elif re.search(r"(error|failed|failure)", combined_lower):
        suspected_root_cause = "Có dấu hiệu lỗi trong logs nhưng chưa đủ cụ thể để phân loại chắc chắn."
        recommended_operator_action = "Tăng line limit và kiểm tra log của candidate container trước."
        confidence = "low"
        matched = [line.strip() for line in combined.splitlines() if re.search(r"(error|failed|failure)", line.lower())][:5]

slack_summary = {
    "image_pull_failure": "Deploy fail: không pull được image từ registry.",
    "port_conflict": "Deploy fail: candidate không bind được port do conflict.",
    "missing_env_or_config": "Deploy fail: app có thể thiếu env/config runtime.",
    "application_crash": "Deploy fail: app có dấu hiệu crash khi chạy.",
    "health_check_failure": "Deploy fail: health check không pass.",
    "nginx_failure": "Deploy fail: Nginx không route được tới upstream mới.",
    "insufficient_evidence": "Deploy fail: chưa đủ evidence để kết luận chắc nguyên nhân.",
}.get(incident_type, suspected_root_cause)

result = {
    "incident_type": incident_type,
    "suspected_root_cause": suspected_root_cause,
    "confidence": confidence,
    "evidence_snippets": matched,
    "affected_container_or_color": None,
    "recommended_operator_action": recommended_operator_action,
    "slack_summary": slack_summary,
}

print(json.dumps(result, ensure_ascii=False, indent=2))
