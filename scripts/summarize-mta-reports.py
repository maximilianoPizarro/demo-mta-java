#!/usr/bin/env python3
"""Build summaries.json from published (or local) MTA static-report output.js files."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

TARGETS = (
    "openjdk11",
    "openjdk17",
    "openjdk21",
    "cloud-readiness",
    "bc4j",
)

LABELS = {
    "openjdk11": {
        "title": "OpenJDK 11",
        "subtitle": "Java 8 → 11 (APIs removidas / cambiadas)",
    },
    "openjdk17": {
        "title": "OpenJDK 17",
        "subtitle": "Java 8 → 17 (deprecaciones y remociones)",
    },
    "openjdk21": {
        "title": "OpenJDK 21",
        "subtitle": "Java 8 → 21 (APIs modernas vs legacy)",
    },
    "cloud-readiness": {
        "title": "Cloud readiness",
        "subtitle": "Filesystem, localhost, logs → contenedores",
    },
    "bc4j": {
        "title": "BC4J / ADF",
        "subtitle": "Certificar ADF en JDK + WebLogic contenedorizado",
    },
}


def load_apps(path: Path) -> list:
    text = path.read_text(encoding="utf-8")
    match = re.search(r'window\s*\[\s*["\']apps["\']\s*\]\s*=\s*', text)
    if not match:
        raise ValueError(f"No window['apps'] assignment in {path}")
    blob = text[match.end() :].strip().rstrip(";")
    return json.loads(blob)


def summarize_target(target: str, output_js: Path) -> dict:
    apps = load_apps(output_js)
    app = apps[0]
    incidents = 0
    story = 0
    by_cat: Counter[str] = Counter()
    violations: list[dict] = []

    for ruleset in app.get("rulesets") or []:
        viol = ruleset.get("violations") or {}
        if not isinstance(viol, dict):
            continue
        for rule_id, detail in viol.items():
            if not isinstance(detail, dict):
                continue
            incs = detail.get("incidents") or []
            n = len(incs)
            if n == 0:
                continue
            effort = int(detail.get("effort") or 0)
            category = detail.get("category") or "unknown"
            incidents += n
            story += effort * n
            by_cat[category] += n
            files = sorted(
                {
                    (i.get("uri") or "").replace("\\", "/").split("sample-app/", 1)[-1]
                    if "sample-app/" in (i.get("uri") or "").replace("\\", "/")
                    else (i.get("uri") or "")
                    for i in incs
                }
            )
            violations.append(
                {
                    "rule": rule_id,
                    "category": category,
                    "effort": effort,
                    "incidents": n,
                    "description": (detail.get("description") or "").strip(),
                    "files": [f for f in files if f][:12],
                }
            )

    violations.sort(key=lambda v: (-v["incidents"], -v["effort"], v["rule"]))
    meta = LABELS.get(target, {"title": target, "subtitle": ""})
    return {
        "target": target,
        "title": meta["title"],
        "subtitle": meta["subtitle"],
        "application": app.get("name"),
        "incidents": incidents,
        "storyPoints": story,
        "categories": dict(sorted(by_cat.items())),
        "rulesetsWithHits": sum(
            1 for rs in (app.get("rulesets") or []) if rs.get("violations")
        ),
        "topViolations": violations[:20],
        "reportPath": f"{target}/",
    }


def read_version(shared_version: Path | None) -> str | None:
    if not shared_version or not shared_version.is_file():
        return None
    text = shared_version.read_text(encoding="utf-8")
    # version.js typically: window["version"] = "x.y.z";
    m = re.search(r'["\']([^"\']+)["\']', text)
    return m.group(1) if m else text.strip()[:80]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reports-root",
        type=Path,
        default=Path("docs/mta-reports"),
        help="Published reports root (default: docs/mta-reports)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output summaries.json (default: <reports-root>/summaries.json)",
    )
    args = parser.parse_args()
    root: Path = args.reports_root
    out = args.out or (root / "summaries.json")

    reports = []
    missing = []
    for target in TARGETS:
        path = root / target / "output.js"
        if not path.is_file():
            missing.append(str(path))
            continue
        reports.append(summarize_target(target, path))

    if missing:
        print("Missing report data:", *missing, sep="\n  ", file=sys.stderr)
        if not reports:
            return 1

    payload = {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "input": "sample-app (Java 8)",
        "mode": "source-only",
        "cliVersion": read_version(root / "shared" / "version.js"),
        "reports": reports,
        "totals": {
            "incidents": sum(r["incidents"] for r in reports),
            "storyPoints": sum(r["storyPoints"] for r in reports),
        },
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {out} ({len(reports)} reports)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
