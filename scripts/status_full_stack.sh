#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENV="$ROOT_DIR/rust/control-plane/.env"
PID_FILE="$ROOT_DIR/runtime/control-plane/control-plane.pid"
LOG_FILE="$ROOT_DIR/runtime/control-plane/logs/control-plane.out.log"
BIND="127.0.0.1:3900"

if [[ -f "$APP_ENV" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$APP_ENV"
  set +a
  BIND="${BOT_HUB_BIND_ADDR:-$BIND}"
fi

echo "[info] bind=$BIND"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" || true)"
  if [[ -n "${PID:-}" ]] && kill -0 "$PID" 2>/dev/null; then
    echo "[ok] running pid=$PID"
  else
    echo "[warn] pid file exists but process not alive"
  fi
else
  echo "[warn] pid file not found"
fi

ss -lntp | grep "${BIND##*:}" || true

echo "[info] health:"
curl -sS "http://$BIND/api/v1/public/health" || true

echo
if [[ -f "$LOG_FILE" ]]; then
  echo "[info] tail log:"
  tail -n 20 "$LOG_FILE"
fi
