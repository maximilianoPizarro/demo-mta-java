#!/bin/bash
# Run MTA / Kantra analyze for one report target (or all).
# Intended for Dev Spaces terminal and local CLI use.
#
# Usage:
#   bash scripts/install-mta-cli.sh          # once
#   export PATH="$PWD/.tools/bin:$PATH"
#   bash scripts/mta-cli-analyze.sh openjdk11
#   bash scripts/mta-cli-analyze.sh all
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

TARGET="${1:-}"
INPUT="${MTA_INPUT:-sample-app}"
OUT_ROOT="${MTA_OUTPUT_ROOT:-mta-output}"
MODE="${MTA_MODE:-source-only}"
RULES_BC4J="${MTA_RULES_BC4J:-rules/bc4j}"

# Absolute paths: the mta-cli wrapper cds into .tools/mta-cli for jdtls/rulesets.
INPUT_ABS="$(cd "${INPUT}" 2>/dev/null && pwd || true)"
if [ -z "${INPUT_ABS}" ]; then
  INPUT_ABS="${ROOT}/${INPUT}"
fi
OUT_ROOT_ABS="${ROOT}/${OUT_ROOT}"
RULES_BC4J_ABS="${ROOT}/${RULES_BC4J}"

usage() {
  cat <<'EOF'
Usage: bash scripts/mta-cli-analyze.sh <target>

Targets (one HTML report each under mta-output/<target>/static-report/):
  openjdk11        OpenJDK 8 → 11
  openjdk17        OpenJDK 8 → 17
  openjdk21        OpenJDK 8 → 21
  cloud-readiness  Aptitud a contenedores / OpenShift
  bc4j             Certificación ADF/BC4J (reglas custom; WebLogic se queda)
  all              Corre los cinco reportes

Env:
  MTA_CLI          Path to mta-cli or kantra (default: search PATH and .tools/bin)
  MTA_INPUT        App path (default: sample-app)
  MTA_OUTPUT_ROOT  Output root (default: mta-output)
  MTA_MODE         source-only|full (default: source-only)
EOF
}

resolve_cli() {
  if [ -n "${MTA_CLI:-}" ]; then
    printf '%s' "${MTA_CLI}"
    return
  fi
  if [ -x "${ROOT}/.tools/bin/mta-cli" ]; then
    printf '%s' "${ROOT}/.tools/bin/mta-cli"
    return
  fi
  if [ -x "${ROOT}/.tools/mta-cli/windows-mta-cli.exe" ]; then
    # Late-bind wrapper if the zip was extracted manually.
    bash "${ROOT}/scripts/install-mta-cli.sh" >/dev/null
    printf '%s' "${ROOT}/.tools/bin/mta-cli"
    return
  fi
  if command -v mta-cli >/dev/null 2>&1; then
    command -v mta-cli
    return
  fi
  if command -v kantra >/dev/null 2>&1; then
    command -v kantra
    return
  fi
  if [ -x "${ROOT}/.tools/bin/kantra" ]; then
    printf '%s' "${ROOT}/.tools/bin/kantra"
    return
  fi
  echo "mta-cli not found. Run: bash scripts/install-mta-cli.sh /path/to/mta-*-cli-*.zip" >&2
  exit 1
}

analyze_one() {
  local target="$1"
  local out="${OUT_ROOT_ABS}/${target}"
  local cli
  cli="$(resolve_cli)"
  mkdir -p "${OUT_ROOT_ABS}"
  rm -rf "${out}"
  mkdir -p "${out}"

  echo "=== MTA analyze target=${target} input=${INPUT_ABS} out=${out} mode=${MODE} ==="
  case "${target}" in
    openjdk11|openjdk17|openjdk21|cloud-readiness)
      "${cli}" analyze \
        --input "${INPUT_ABS}" \
        --output "${out}" \
        --target "${target}" \
        --mode "${MODE}" \
        --overwrite
      ;;
    bc4j)
      "${cli}" analyze \
        --input "${INPUT_ABS}" \
        --output "${out}" \
        --target bc4j \
        --rules "${RULES_BC4J_ABS}" \
        --mode "${MODE}" \
        --overwrite
      ;;
    *)
      echo "Unknown target: ${target}" >&2
      usage >&2
      exit 1
      ;;
  esac

  report="${out}/static-report/index.html"
  if [ -f "${report}" ]; then
    echo "Report: ${report}"
  else
    echo "Analysis finished. Look under ${out}/ for static-report/"
    ls -la "${out}" || true
  fi
}

if [ -z "${TARGET}" ] || [ "${TARGET}" = "-h" ] || [ "${TARGET}" = "--help" ]; then
  usage
  exit 0
fi

if [ ! -d "${INPUT_ABS}" ]; then
  echo "Input not found: ${INPUT_ABS}" >&2
  exit 1
fi

if [ "${TARGET}" = "all" ]; then
  for t in openjdk11 openjdk17 openjdk21 cloud-readiness bc4j; do
    analyze_one "${t}"
  done
  echo "All reports under ${OUT_ROOT_ABS}/"
  exit 0
fi

analyze_one "${TARGET}"
