#!/usr/bin/env bash
# Publish local mta-output/*/static-report into docs/ for GitHub Pages.
# Deduplicates identical Konveyor UI assets, sanitizes absolute file:// URIs,
# and regenerates the comparison summaries.json.
#
# Usage:
#   bash scripts/mta-cli-analyze.sh all   # optional refresh
#   bash scripts/publish-mta-reports.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

SRC_ROOT="${MTA_OUTPUT_ROOT:-mta-output}"
DEST_ROOT="${MTA_PAGES_ROOT:-docs/mta-reports}"
TARGETS=(openjdk11 openjdk17 openjdk21 cloud-readiness bc4j)

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

missing=0
for t in "${TARGETS[@]}"; do
  if [[ ! -f "${SRC_ROOT}/${t}/static-report/output.js" ]]; then
    echo "Missing ${SRC_ROOT}/${t}/static-report/output.js — run: bash scripts/mta-cli-analyze.sh ${t}" >&2
    missing=1
  fi
done
if [[ "${missing}" -eq 1 ]]; then
  exit 1
fi

echo "Publishing MTA static reports → ${DEST_ROOT}"
rm -rf "${DEST_ROOT}"
mkdir -p "${DEST_ROOT}/shared"

# Shared Konveyor UI (identical across targets for a given CLI version)
cp -a "${SRC_ROOT}/openjdk11/static-report/assets" "${DEST_ROOT}/shared/"
for f in theme.js version.js favicon.ico logo192.png logo512.png manifest.json robots.txt; do
  cp -a "${SRC_ROOT}/openjdk11/static-report/${f}" "${DEST_ROOT}/shared/"
done
if [[ -d "${SRC_ROOT}/openjdk11/static-report/api" ]]; then
  cp -a "${SRC_ROOT}/openjdk11/static-report/api" "${DEST_ROOT}/shared/"
fi

# Jekyll on GitHub Pages ignores folders starting with _; force raw static serving.
touch docs/.nojekyll

sanitize_and_copy() {
  local target="$1"
  local src="${SRC_ROOT}/${target}/static-report"
  local dest="${DEST_ROOT}/${target}"
  mkdir -p "${dest}"

  # Point the SPA shell at shared assets (one copy for all five reports).
  sed \
    -e 's|href="./favicon.ico"|href="../shared/favicon.ico"|g' \
    -e 's|href="./logo192.png"|href="../shared/logo192.png"|g' \
    -e 's|src="./theme.js"|src="../shared/theme.js"|g' \
    -e 's|src="./version.js"|src="../shared/version.js"|g' \
    -e 's|src="./assets/|src="../shared/assets/|g' \
    "${src}/index.html" > "${dest}/index.html"

  # Keep output.js next to index.html; rewrite absolute file:// paths to portable paths.
  python3 - "${src}/output.js" "${dest}/output.js" <<'PY'
import re, sys
from pathlib import Path

src, dest = Path(sys.argv[1]), Path(sys.argv[2])
text = src.read_text(encoding="utf-8")

# sample-app source hits (Windows / POSIX file URIs and bare absolute paths)
replacements = [
    (re.compile(r'file:///[A-Za-z]:/[^"\\]*?/sample-app/', re.I), "sample-app/"),
    (re.compile(r'file:///[^"\\]*?/sample-app/'), "sample-app/"),
    (re.compile(r'file://[^"\\]*?/sample-app/'), "sample-app/"),
    (re.compile(r'[A-Za-z]:\\\\[^"\\]*?\\\\sample-app\\\\', re.I), "sample-app/"),
    (re.compile(r'[A-Za-z]:/[^"\\]*?/sample-app/', re.I), "sample-app/"),
    # Maven local-repo coordinates embedded by analyzer
    (re.compile(r'file:///[A-Za-z]:/[^"\\]*?/\.m2/repository/', re.I), ".m2/repository/"),
    (re.compile(r'file:///[^"\\]*?/\.m2/repository/'), ".m2/repository/"),
    (re.compile(r'file://[^"\\]*?/\.m2/repository/'), ".m2/repository/"),
]
for pat, repl in replacements:
    text = pat.sub(repl, text)

text = text.replace("sample-app\\\\", "sample-app/")
dest.write_text(text, encoding="utf-8")
print(f"  sanitized {dest}")
PY
}

for t in "${TARGETS[@]}"; do
  echo "- ${t}"
  sanitize_and_copy "${t}"
done

# Comparison hub + machine-readable summaries
cp -a "${ROOT}/scripts/mta-reports-index.html" "${DEST_ROOT}/index.html"
python3 "${ROOT}/scripts/summarize-mta-reports.py" --reports-root "${DEST_ROOT}"

# Landing page at docs/ so GitHub Pages root is useful
cat > docs/index.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="refresh" content="0; url=mta-reports/" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>demo-mta-java reports</title>
    <link rel="canonical" href="mta-reports/" />
  </head>
  <body>
    <p>Redirecting to <a href="mta-reports/">MTA report comparison</a>…</p>
  </body>
</html>
EOF

echo
echo "Done. Local preview:"
echo "  python3 -m http.server 8765 --directory docs"
echo "  open http://127.0.0.1:8765/mta-reports/"
echo "GitHub Pages (after push + enable /docs):"
echo "  https://maximilianopizarro.github.io/demo-mta-java/mta-reports/"
