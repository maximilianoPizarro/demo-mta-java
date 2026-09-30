#!/bin/bash
# Install mta-cli (Red Hat) or kantra (upstream) into .tools/ for Dev Spaces / local use.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${ROOT}/.tools"
BIN="${TOOLS}/bin"
mkdir -p "${BIN}"

if command -v mta-cli >/dev/null 2>&1; then
  echo "mta-cli already on PATH: $(command -v mta-cli)"
  exit 0
fi
if [ -x "${BIN}/mta-cli" ]; then
  echo "mta-cli already at ${BIN}/mta-cli"
  exit 0
fi
if [ -x "${BIN}/kantra" ]; then
  ln -sfn "${BIN}/kantra" "${BIN}/mta-cli"
  echo "Linked ${BIN}/kantra -> ${BIN}/mta-cli"
  exit 0
fi

# Optional: point at a Red Hat mta-cli tarball/zip URL (requires RH login cookie in some cases).
# Example:
#   export MTA_CLI_URL='https://developers.redhat.com/content-gateway/file/.../mta-cli-linux.zip'
if [ -n "${MTA_CLI_URL:-}" ]; then
  tmp="$(mktemp -d)"
  archive="${tmp}/mta-cli-archive"
  echo "Downloading MTA CLI from MTA_CLI_URL..."
  curl -fL --retry 3 -o "${archive}" "${MTA_CLI_URL}"
  case "${MTA_CLI_URL}" in
    *.zip) (cd "${tmp}" && unzip -q "${archive}") ;;
    *.tar.gz|*.tgz) (cd "${tmp}" && tar -xzf "${archive}") ;;
    *) echo "Unsupported archive type in MTA_CLI_URL"; exit 1 ;;
  esac
  found="$(find "${tmp}" -type f \( -name mta-cli -o -name kantra \) | head -1)"
  if [ -z "${found}" ]; then
    echo "No mta-cli/kantra binary inside archive"
    exit 1
  fi
  cp "${found}" "${BIN}/mta-cli"
  chmod 0755 "${BIN}/mta-cli"
  echo "Installed ${BIN}/mta-cli"
  echo "Add to PATH: export PATH=\"${BIN}:\$PATH\""
  exit 0
fi

# Fallback: upstream Kantra (same analyze UX as MTA CLI for this demo).
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
echo "Add to PATH: export PATH=\"${BIN}:\$PATH\""
