#!/bin/bash
# Preload the same extensions Dev Spaces installs from .vscode/extensions.json
# and point Developer Lightspeed at the CPU inference server.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/.konveyor/provider-settings.yaml"

download_vsix() {
  meta="$1"
  out="$2"
  url="$(curl -fsSL "${meta}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["files"]["download"])')"
  echo "Downloading ${url}"
  curl -fL --retry 3 --retry-delay 2 -o "${out}.partial" "${url}"
  mv "${out}.partial" "${out}"
}

install_vsix() {
  vsix="$1"
  code=""
  if command -v code-oss >/dev/null 2>&1; then
    code="$(command -v code-oss)"
  else
    for candidate in \
      /checode/checode-linux-libc/ubi8/bin/remote-cli/code-oss \
      /checode/checode-linux-libc/ubi9/bin/remote-cli/code-oss \
      /checode/checode-linux-libc/ubi8/bin/che-code \
      /checode/checode-linux-libc/ubi9/bin/che-code
    do
      if [ -x "${candidate}" ]; then
        code="${candidate}"
        break
      fi
    done
  fi
  if [ -z "${code}" ]; then
    echo "code-oss not ready; Che Code should install ${vsix} from the devfile attribute"
    return 0
  fi
  export LD_LIBRARY_PATH="/checode/checode-linux-libc/ubi8/ld_libs:/checode/checode-linux-libc/ubi9/ld_libs:${LD_LIBRARY_PATH:-}"
  echo "Installing ${vsix}"
  "${code}" --install-extension "${vsix}" --force || echo "Install of ${vsix} deferred"
}

sock=""
for _ in $(seq 1 30); do
  sock="$(ls /tmp/vscode-ipc-*.sock 2>/dev/null | head -1 || true)"
  [ -n "${sock}" ] && break
  sleep 2
done
if [ -n "${sock}" ]; then
  export VSCODE_IPC_HOOK_CLI="${sock}"
fi

download_vsix "https://open-vsx.org/api/redhat/java/linux-x64/latest" /tmp/redhat.java.vsix
download_vsix "https://open-vsx.org/api/vscjava/vscode-maven/latest" /tmp/vscode-maven.vsix
download_vsix "https://open-vsx.org/api/redhat/mta-vscode-extension/latest" /tmp/mta.vsix
install_vsix /tmp/redhat.java.vsix
install_vsix /tmp/vscode-maven.vsix
install_vsix /tmp/mta.vsix

if [ ! -f "${SRC}" ]; then
  echo "No provider settings at ${SRC}"
  exit 0
fi

copy_settings() {
  dest="$1"
  mkdir -p "$(dirname "${dest}")"
  cp "${SRC}" "${dest}"
  echo "Wrote ${dest}"
}

for id in redhat.mta-core redhat.mta-vscode-extension konveyor.konveyor; do
  for base in \
    "${HOME}/.vscode-server/data/User/globalStorage" \
    "${HOME}/.vscode-remote/data/User/globalStorage" \
    "${HOME}/.config/Code/User/globalStorage" \
    "${HOME}/.local/share/code-server/User/globalStorage"
  do
    copy_settings "${base}/${id}/settings/provider-settings.yaml"
  done
done
