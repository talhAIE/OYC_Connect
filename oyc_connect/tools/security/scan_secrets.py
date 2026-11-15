"""Redacted secret scan of tracked files, Flutter config, and Git object history."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

PATTERNS = {
    "onesignal-app-key": re.compile(rb"os_v2_app_[A-Za-z0-9_-]{20,}"),
    "onesignal-org-key": re.compile(rb"os_v2_org_[A-Za-z0-9_-]{20,}"),
    "stripe-secret-key": re.compile(rb"sk_(?:live|test)_[A-Za-z0-9]{16,}"),
    "supabase-secret-key": re.compile(rb"sb_secret_[A-Za-z0-9_-]{16,}"),
}
SERVER_FIELDS = re.compile(
    rb"(?im)^\s*(ONESIGNAL_(?:REST_)?API_KEY|ONESIGNAL_ORG_API_KEY|"
    rb"SUPABASE_SERVICE_ROLE_KEY|STRIPE_SECRET_KEY)\s*=\s*([^\r\n]*)"
)


def git(repo: Path, *args: str, input: bytes | None = None) -> bytes:
    return subprocess.run(
        ["git", "-C", str(repo), *args], input=input, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, check=True,
    ).stdout


def matches(content: bytes, path: str, reference: str) -> list[dict]:
    found = []
    for kind, pattern in PATTERNS.items():
        for match in pattern.finditer(content):
            found.append({
                "kind": kind, "path": path, "reference": reference,
                "fingerprint": hashlib.sha256(match.group()).hexdigest()[:12],
            })
    # Also detect JWT-shaped Supabase service-role keys without printing them.
    for token in re.findall(rb"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+", content):
        try:
            import base64
            payload = token.split(b".")[1]
            claims = json.loads(base64.urlsafe_b64decode(payload + b"=" * (-len(payload) % 4)))
            if isinstance(claims, dict) and claims.get("role") == "service_role":
                found.append({"kind": "supabase-service-jwt", "path": path,
                              "reference": reference, "fingerprint": hashlib.sha256(token).hexdigest()[:12]})
        except (ValueError, TypeError, KeyError):
            pass
    return found


def scan(repo: Path, history: bool = False) -> dict:
    findings = []
    tracked_env = []
    bare = git(repo, "rev-parse", "--is-bare-repository").strip() == b"true"
    if not bare:
        paths = git(repo, "ls-files", "-z").decode().split("\0")
        for relative in filter(None, paths):
            path = repo / relative
            if path.is_file():
                findings += matches(path.read_bytes(), relative, "working-tree")
            if Path(relative).name in (".env", "env") or (
                Path(relative).name.startswith(".env.") and not relative.endswith(".example")
            ):
                tracked_env.append(relative)
        # Include untracked new source, excluding ignored tooling/dependencies.
        extra = git(repo, "ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")
        for relative in filter(None, extra):
            path = repo / relative
            if path.is_file():
                findings += matches(path.read_bytes(), relative, "untracked-working-tree")
        # Flutter .env is deliberately ignored but shipped, so inspect it too.
        client = repo / "oyc_connect/assets/.env"
        if client.is_file():
            content = client.read_bytes()
            findings += matches(content, "oyc_connect/assets/.env", "bundled-client-config")
            for field in SERVER_FIELDS.finditer(content):
                if field.group(2).strip().strip(b"'\""):
                    findings.append({"kind": "server-field-in-client-assets", "path": "oyc_connect/assets/.env",
                                     "reference": "bundled-client-config", "field": field.group(1).decode()})
    if history:
        records = git(repo, "rev-list", "--objects", "--all", "--reflog").decode().splitlines()
        paths_by_oid = {}
        for line in records:
            oid, _, path = line.partition(" ")
            if path and (Path(path).suffix.lower() in {".sql", ".md", ".ts", ".dart", ".yaml", ".yml", ".json", ".txt", ".py", ".ps1"}
                         or Path(path).name in {"env", ".env"} or Path(path).name.startswith(".env.")):
                paths_by_oid.setdefault(oid, path)
        if paths_by_oid:
            response = git(repo, "cat-file", "--batch", input=("\n".join(paths_by_oid) + "\n").encode())
            offset = 0
            for oid, path in paths_by_oid.items():
                end = response.index(b"\n", offset)
                header = response[offset:end].split()
                size = int(header[2])
                content = response[end + 1:end + 1 + size]
                offset = end + 1 + size + 1
                if header[1] == b"blob":
                    findings += matches(content, path, "git-blob:" + oid)
    # Deterministic output; never output raw credentials or matching lines.
    dedup = {json.dumps(f, sort_keys=True): f for f in findings}
    return {"history_scanned": history, "findings": list(dedup.values()), "tracked_environment_files": tracked_env}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument("--history", action="store_true")
    args = parser.parse_args()
    result = scan(args.repo.resolve(), args.history)
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if result["findings"] or result["tracked_environment_files"] else 0)
