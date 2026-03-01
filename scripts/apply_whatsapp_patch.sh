#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_FILE="${REPO_DIR}/versions.lock"
if [[ -f "${LOCK_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${LOCK_FILE}"
fi

NODE_VERSION="${NODE_VERSION:-22.22.0}"
NODE_DIST="${NODE_DIST:-node-v${NODE_VERSION}-linux-x64}"
ROOT="/usr/local/${NODE_DIST}/lib/node_modules/openclaw/dist"
PLUGIN_ROOT="/usr/local/${NODE_DIST}/lib/node_modules/openclaw/dist/plugin-sdk"

OLD='browser: ["openclaw", "cli", VERSION]'
NEW='browser: ["Ubuntu", "Chrome", "122.0.0.0"]'

TARGETS=(
  "${ROOT}/session-Dugoy7rd.js"
  "${ROOT}/session-C_T4icrY.js"
  "${ROOT}/session-CmithsSM.js"
  "${ROOT}/session-B5tdmbsr.js"
  "${PLUGIN_ROOT}/session-DNHC6iPh.js"
)

patched=0
for f in "${TARGETS[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "[fail] target missing: ${f}" >&2
    exit 2
  fi

  if grep -Fq "${NEW}" "${f}"; then
    echo "[skip] already patched: ${f}"
    continue
  fi

  if grep -Fq "${OLD}" "${f}"; then
    sudo cp "${f}" "${f}.bak.$(date +%Y%m%d%H%M%S)"
    sudo sed -i "s/${OLD//\//\/}/${NEW//\//\/}/g" "${f}"
    echo "[ok] patched: ${f}"
    patched=$((patched + 1))
  else
    echo "[fail] pattern not found in ${f}" >&2
    exit 3
  fi

done

echo "[info] verify patches"
grep -RIn 'browser: \["Ubuntu", "Chrome", "122.0.0.0"\]' "${ROOT}"/session-*.js "${PLUGIN_ROOT}"/session-*.js

echo "[ok] patch done, changed files=${patched}"
