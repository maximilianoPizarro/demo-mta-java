#!/bin/bash
# Preload the same extensions Dev Spaces installs from .vscode/extensions.json
# and point Developer Lightspeed at the CPU inference server.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/.konveyor/provider-settings.yaml"

install_ext() {
  id="$1"
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
    echo "code-oss not ready; ${id} stays in .vscode/extensions.json"
    return 0
  fi
  export LD_LIBRARY_PATH="/checode/checode-linux-libc/ubi8/ld_libs:/checode/checode-linux-libc/ubi9/ld_libs:${LD_LIBRARY_PATH:-}"
  echo "Installing ${id}"
  "${code}" --install-extension "${id}" --force || echo "Install of ${id} deferred to extensions.json"
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

install_ext redhat.java
install_ext vscjava.vscode-maven
install_ext redhat.mta-vscode-extension

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
