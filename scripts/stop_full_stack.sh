#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/runtime/control-plane/control-plane.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "[ok] no pid file, already stopped"
  exit 0
fi

PID="$(cat "$PID_FILE" || true)"
if [[ -n "${PID:-}" ]] && kill -0 "$PID" 2>/dev/null; then
  kill "$PID" || true
  sleep 1
  if kill -0 "$PID" 2>/dev/null; then
    kill -9 "$PID" || true
  fi
  echo "[ok] stopped pid=$PID"
else
  echo "[ok] process already gone"
fi

rm -f "$PID_FILE"
