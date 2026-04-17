#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from typing import Any

requested = sys.argv[1] if len(sys.argv) > 1 else "latest"
provider = os.getenv("DEPLOY_REGISTRY_PROVIDER", "ghcr")
base = os.getenv("DEPLOY_REGISTRY_BASE", "ghcr.io")
repository = os.getenv("DEPLOY_REPOSITORY", "owner/repo")
package = os.getenv("DEPLOY_PACKAGE_NAME", "web-app")
override = os.getenv("DEPLOY_LATEST_TAG")


def emit(resolved_tag: str, source: str, resolved_digest: str | None = None, extra: dict[str, Any] | None = None):
    payload = {
        "requested": requested,
        "resolved_tag": resolved_tag,
        "resolved_digest": resolved_digest,
        "source": source,
    }
    if extra:
        payload.update(extra)
    print(json.dumps(payload))
    sys.exit(0)


def http_json(url: str, headers: dict[str, str] | None = None):
    req = urllib.request.Request(url, headers=headers or {})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode("utf-8"))


def http_head(url: str, headers: dict[str, str] | None = None):
    req = urllib.request.Request(url, headers=headers or {}, method="HEAD")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return dict(resp.headers.items())


def ghcr_image_name() -> str:
    return f"{repository}/{package}".strip("/")


def ghcr_bearer_token(scope_image: str) -> str | None:
    token_url = (
        "https://ghcr.io/token?"
        + urllib.parse.urlencode(
            {
                "scope": f"repository:{scope_image}:pull",
                "service": "ghcr.io",
            }
        )
    )
    try:
        data = http_json(token_url)
        return data.get("token") or data.get("access_token")
    except Exception:
        return None


def semver_key(tag: str):
    m = re.fullmatch(r"v?(\d+)\.(\d+)\.(\d+)(?:[-+].*)?", tag)
    if not m:
        return None
    return tuple(int(x) for x in m.groups())


def choose_best_tag(tags: list[str]) -> str | None:
    if not tags:
        return None

    semver_tags = []
    dated_tags = []
    generic_tags = []

    for tag in tags:
        if tag == "latest":
            generic_tags.append(tag)
            continue
        sk = semver_key(tag)
        if sk is not None:
            semver_tags.append((sk, tag))
            continue
        if re.fullmatch(r"\d{8,14}", tag) or re.fullmatch(r"\d{4}-\d{2}-\d{2}.*", tag):
            dated_tags.append(tag)
            continue
        generic_tags.append(tag)

    if semver_tags:
        semver_tags.sort(key=lambda x: x[0], reverse=True)
        return semver_tags[0][1]

    if dated_tags:
        return sorted(dated_tags, reverse=True)[0]

    if "latest" in tags:
        return "latest"

    return sorted(generic_tags, reverse=True)[0] if generic_tags else None


def resolve_ghcr_latest():
    image = ghcr_image_name()
    token = ghcr_bearer_token(image)
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    tags_url = f"https://ghcr.io/v2/{image}/tags/list"
    try:
        tags_data = http_json(tags_url, headers=headers)
        tags = tags_data.get("tags") or []
    except Exception:
        tags = []

    chosen = choose_best_tag(tags)
    if not chosen:
        if override:
            emit(override, "env-override")
        emit("latest", "ghcr-literal-latest-fallback", extra={"warning": "could-not-read-tags"})

    digest = None
    manifest_url = f"https://ghcr.io/v2/{image}/manifests/{urllib.parse.quote(chosen, safe='')}"
    manifest_headers = {
        **headers,
        "Accept": "application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json",
    }
    try:
        head = http_head(manifest_url, headers=manifest_headers)
        digest = head.get("Docker-Content-Digest")
    except Exception:
        digest = None

    emit(chosen, "ghcr-tags-api", resolved_digest=digest, extra={"tag_count": len(tags)})


if requested != "latest":
    emit(requested, "explicit-tag")

if override:
    emit(override, "env-override")

if provider != "ghcr":
    emit("latest", "fallback-non-ghcr")

resolve_ghcr_latest()
