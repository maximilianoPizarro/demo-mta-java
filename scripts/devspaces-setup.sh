#!/bin/bash
# Preload the same extensions Dev Spaces installs from .vscode/extensions.json
# and point Developer Lightspeed at the CPU inference server on THIS cluster.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/.konveyor/provider-settings.yaml"
REWRITE="/tmp/mta-provider-settings.yaml"

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

# Resolve the public llama.cpp OpenAI-compatible base URL for this cluster.
resolve_llm_base_url() {
  if [ -n "${MTA_LLM_BASE_URL:-}" ]; then
    printf '%s' "${MTA_LLM_BASE_URL}"
    return
  fi

  host=""
  if command -v oc >/dev/null 2>&1; then
    host="$(oc get route mta-llm -n mta-demo -o jsonpath='{.spec.host}' 2>/dev/null || true)"
  fi

  if [ -z "${host}" ]; then
    # Derive apps.* from the Dev Spaces dashboard URL when oc is unavailable.
    dash="${CHE_DASHBOARD_URL:-${CHE_HOST:-}}"
    if [ -n "${dash}" ]; then
      apps_domain="$(printf '%s' "${dash}" | sed -E 's#https?://##' | sed -E 's#^devspaces\.##' | sed -E 's#/.*##')"
      if [ -n "${apps_domain}" ]; then
        host="mta-llm-mta-demo.${apps_domain}"
      fi
    fi
  fi

  if [ -n "${host}" ]; then
    printf 'https://%s/v1' "${host}"
  fi
}

rewrite_provider_settings() {
  if [ ! -f "${SRC}" ]; then
    echo "No provider settings at ${SRC}"
    return 1
  fi
  cp "${SRC}" "${REWRITE}"
  base_url="$(resolve_llm_base_url || true)"
  if [ -n "${base_url}" ]; then
    # Replace PLACEHOLDER host or any previous mta-llm baseURL with the live Route.
    if command -v python3 >/dev/null 2>&1; then
      python3 - "${REWRITE}" "${base_url}" <<'PY'
import re, sys
path, base = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
text2, n = re.subn(
    r'(baseURL:\s*")[^"]*(")',
    r'\1' + base + r'\2',
    text,
    count=1,
)
if n:
    open(path, "w", encoding="utf-8").write(text2)
    print(f"Rewrote baseURL to {base}")
else:
    print("baseURL key not found; left provider-settings unchanged")
PY
    else
      sed "s|https://mta-llm-mta-demo.PLACEHOLDER/v1|${base_url}|g" "${SRC}" > "${REWRITE}"
      echo "Rewrote baseURL to ${base_url} (sed)"
    fi
  else
    echo "Could not resolve mta-llm Route; leaving PLACEHOLDER in provider-settings"
  fi
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

if ! rewrite_provider_settings; then
  exit 0
fi

copy_settings() {
  dest="$1"
  mkdir -p "$(dirname "${dest}")"
  cp "${REWRITE}" "${dest}"
  echo "Wrote ${dest}"
}

copy_settings "/checode/remote/data/User/globalStorage/redhat.mta-core/settings/provider-settings.yaml"

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
