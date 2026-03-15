#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/rust/control-plane"
APP_ENV="$APP_DIR/.env"

SKIP_OPENCLAW_INSTALL="${SKIP_OPENCLAW_INSTALL:-0}"

echo "[step] bootstrap rust control-plane"
bash "$ROOT_DIR/scripts/bootstrap_rust_control_plane.sh"

if ! command -v openclaw >/dev/null 2>&1; then
  if [[ "$SKIP_OPENCLAW_INSTALL" == "1" ]]; then
    echo "[warn] openclaw missing and SKIP_OPENCLAW_INSTALL=1, skip install"
  else
    echo "[step] install openclaw (node + cli)"
    bash "$ROOT_DIR/scripts/install_openclaw.sh"
  fi
fi

if command -v openclaw >/dev/null 2>&1; then
  echo "[ok] openclaw: $(openclaw --version 2>/dev/null || true)"
else
  echo "[warn] openclaw still missing; WhatsApp/DingTalk instances cannot be started until installed"
fi

if [[ ! -f "$APP_ENV" ]]; then
  cp "$APP_DIR/.env.example" "$APP_ENV"
  echo "[info] created $APP_ENV from template"
fi

if [[ -n "${ROUTER_API_KEY:-}" ]]; then
  if grep -q ^ROUTER_API_KEY= "$APP_ENV"; then
    sed -i "s|^ROUTER_API_KEY=.*$|ROUTER_API_KEY=${ROUTER_API_KEY}|" "$APP_ENV"
  else
    echo "ROUTER_API_KEY=${ROUTER_API_KEY}" >> "$APP_ENV"
  fi
  echo "[ok] injected ROUTER_API_KEY into $APP_ENV from current shell env"
fi

echo "[next] if needed, edit: $APP_ENV"
echo "[next] start full stack: bash $ROOT_DIR/scripts/run_full_stack.sh"
