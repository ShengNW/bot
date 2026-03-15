#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV="$ROOT_DIR/rust/control-plane/.env"

bash "$ROOT_DIR/scripts/bootstrap_full_stack.sh"

if [[ -f "$APP_ENV" ]]; then
  # shellcheck disable=SC1091
  source "$APP_ENV" || true
fi

if [[ -z "${ROUTER_API_KEY:-}" ]]; then
  echo "[warn] ROUTER_API_KEY is empty in $APP_ENV"
  echo "[warn] Web UI can start, but Router model list and model calls may fail until key is configured."
fi

bash "$ROOT_DIR/scripts/run_full_stack.sh"

echo "[step] runtime status"
bash "$ROOT_DIR/scripts/status_full_stack.sh"

echo "[step] doctor checks"
if ! bash "$ROOT_DIR/scripts/doctor_full_stack.sh"; then
  echo "[warn] doctor reported issues; review output above"
fi

echo "[done] Open in browser: http://${BOT_HUB_BIND_ADDR:-127.0.0.1:3900}/"
