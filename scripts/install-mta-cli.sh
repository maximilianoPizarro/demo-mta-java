#!/usr/bin/env bash
# Install / wire mta-cli into .tools/ for Dev Spaces and local use.
#
# Preferred (Windows local, already downloaded):
#   bash scripts/install-mta-cli.sh "C:/Users/Max/Downloads/mta-8.3.0-cli-windows-amd64.zip"
# Or extract once to .tools/mta-cli/ and re-run this script with no args.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${ROOT}/.tools"
BUNDLE="${TOOLS}/mta-cli"
BIN="${TOOLS}/bin"
mkdir -p "${BIN}" "${BUNDLE}"

write_wrapper() {
  cat > "${BIN}/mta-cli" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="${ROOT}/.tools/mta-cli"
EXE=""
if [ -x "${BUNDLE}/windows-mta-cli.exe" ]; then
  EXE="${BUNDLE}/windows-mta-cli.exe"
elif [ -x "${BUNDLE}/linux-mta-cli" ]; then
  EXE="${BUNDLE}/linux-mta-cli"
elif [ -x "${BUNDLE}/darwin-mta-cli" ]; then
  EXE="${BUNDLE}/darwin-mta-cli"
elif [ -x "${BUNDLE}/mta-cli" ]; then
  EXE="${BUNDLE}/mta-cli"
else
  echo "No MTA CLI binary under ${BUNDLE}" >&2
  exit 1
fi
# Must run from the bundle so jdtls/rulesets/static-report resolve.
cd "${BUNDLE}"
exec "${EXE}" "$@"
EOF
  chmod 0755 "${BIN}/mta-cli"
  echo "Wrapper: ${BIN}/mta-cli"
}

extract_zip() {
  local zip="$1"
  if [ ! -f "${zip}" ]; then
    echo "Zip not found: ${zip}" >&2
    exit 1
  fi
  echo "Extracting ${zip} → ${BUNDLE}"
  mkdir -p "${BUNDLE}"
  # Quiet extract; large archive (~750 MiB).
  unzip -o -q "${zip}" -d "${BUNDLE}"
}

# Arg 1: optional path to Red Hat mta-*-cli-*.zip
ZIP_ARG="${1:-${MTA_CLI_ZIP:-}}"
if [ -n "${ZIP_ARG}" ]; then
  extract_zip "${ZIP_ARG}"
fi

# Already extracted?
if [ -x "${BUNDLE}/windows-mta-cli.exe" ] || [ -x "${BUNDLE}/linux-mta-cli" ] || [ -x "${BUNDLE}/darwin-mta-cli" ] || [ -x "${BUNDLE}/mta-cli" ]; then
  write_wrapper
  export PATH="${BIN}:${PATH}"
  echo "Configured Red Hat MTA CLI bundle at ${BUNDLE}"
  "${BIN}/mta-cli" version || true
  echo "Add to PATH: export PATH=\"${BIN}:\$PATH\""
  exit 0
fi

# Optional download URL
if [ -n "${MTA_CLI_URL:-}" ]; then
  tmp="$(mktemp -d)"
  archive="${tmp}/mta-cli-archive"
  echo "Downloading MTA CLI from MTA_CLI_URL..."
  curl -fL --retry 3 -o "${archive}" "${MTA_CLI_URL}"
  case "${MTA_CLI_URL}" in
    *.zip)
      extract_zip "${archive}"
      ;;
    *.tar.gz|*.tgz)
      (cd "${BUNDLE}" && tar -xzf "${archive}")
      ;;
    *)
      echo "Unsupported archive type in MTA_CLI_URL" >&2
      exit 1
      ;;
  esac
  write_wrapper
  "${BIN}/mta-cli" version || true
  echo "Add to PATH: export PATH=\"${BIN}:\$PATH\""
  exit 0
fi

# Fallback: upstream Kantra (smaller; not the full Red Hat bundle).
if command -v mta-cli >/dev/null 2>&1; then
  echo "mta-cli already on PATH: $(command -v mta-cli)"
  exit 0
fi

KANTRA_VERSION="${KANTRA_VERSION:-v0.10.0-beta.1}"
ARCH="$(uname -m)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "${ARCH}" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac
case "${OS}" in
  linux|darwin) ;;
  msys*|mingw*|cygwin*) OS=windows ;;
  *) echo "Unsupported OS: ${OS}"; exit 1 ;;
esac

asset="kantra.${OS}.${ARCH}.zip"
url="https://github.com/konveyor/kantra/releases/download/${KANTRA_VERSION}/${asset}"
tmp="$(mktemp -d)"
echo "Downloading ${url}"
curl -fL --retry 3 -o "${tmp}/${asset}" "${url}"
(cd "${tmp}" && unzip -q "${asset}")
found="$(find "${tmp}" -type f -name 'kantra*' ! -name '*.zip' | head -1)"
cp "${found}" "${BIN}/kantra"
chmod 0755 "${BIN}/kantra"
ln -sfn "${BIN}/kantra" "${BIN}/mta-cli" 2>/dev/null || cp "${BIN}/kantra" "${BIN}/mta-cli"
echo "Installed ${BIN}/mta-cli (kantra ${KANTRA_VERSION})"
echo "Prefer the Red Hat zip: bash scripts/install-mta-cli.sh /path/to/mta-*-cli-*.zip"
echo "Add to PATH: export PATH=\"${BIN}:\$PATH\""
