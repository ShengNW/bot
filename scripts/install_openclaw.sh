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
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.2.26}"
NODE_URL="https://npmmirror.com/mirrors/node/v${NODE_VERSION}/${NODE_DIST}.tar.xz"

echo "[info] installing Node ${NODE_VERSION} and OpenClaw ${OPENCLAW_VERSION}"

sudo apt-get update -y
sudo apt-get install -y curl xz-utils ca-certificates

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

cd "${TMP_DIR}"
curl -fsSLO "${NODE_URL}"
sudo tar -xJf "${NODE_DIST}.tar.xz" -C /usr/local
sudo ln -sf "/usr/local/${NODE_DIST}/bin/node" /usr/local/bin/node
sudo ln -sf "/usr/local/${NODE_DIST}/bin/npm" /usr/local/bin/npm
sudo ln -sf "/usr/local/${NODE_DIST}/bin/npx" /usr/local/bin/npx

node -v
npm -v

npm i -g "openclaw@${OPENCLAW_VERSION}"
openclaw --version

echo "[ok] install complete"
