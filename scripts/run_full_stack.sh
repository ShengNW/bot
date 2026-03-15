#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/rust/control-plane"
RUNTIME_DIR="$ROOT_DIR/runtime/control-plane"
LOG_DIR="$RUNTIME_DIR/logs"
PID_FILE="$RUNTIME_DIR/control-plane.pid"
BIN="$APP_DIR/target/debug/bot-hub-control-plane"

mkdir -p "$LOG_DIR"

if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
fi

if [[ ! -x "$BIN" || "$APP_DIR/src/main.rs" -nt "$BIN" || "$APP_DIR/Cargo.toml" -nt "$BIN" || "$APP_DIR/web/index.html" -nt "$BIN" ]]; then
  echo "[info] building control-plane binary..."
  cd "$APP_DIR"
  cargo build
fi

if [[ -f "$APP_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$APP_DIR/.env"
  set +a
fi

BIND="${BOT_HUB_BIND_ADDR:-127.0.0.1:3900}"
PORT="${BIND##*:}"

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" || true)"
  if [[ -n "${OLD_PID:-}" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[ok] already running, pid=$OLD_PID"
    exit 0
  fi
fi

EXISTING_PID="$(pgrep -af "bot-hub-control-plane" | awk "{print \$1; exit}" || true)"
if [[ -n "${EXISTING_PID:-}" ]] && kill -0 "$EXISTING_PID" 2>/dev/null; then
  echo "$EXISTING_PID" > "$PID_FILE"
  echo "[ok] already running, recovered pid=$EXISTING_PID bind=$BIND"
  echo "[url] http://$BIND/"
  exit 0
fi

if ss -lnt | awk "{print \$4}" | grep -E "[:.]$PORT$" >/dev/null 2>&1; then
  echo "[error] port $PORT is already in use; set BOT_HUB_BIND_ADDR to a free port or stop the conflicting process" >&2
  exit 1
fi

nohup "$BIN" > "$LOG_DIR/control-plane.out.log" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

sleep 1
if kill -0 "$PID" 2>/dev/null; then
  echo "[ok] bot-hub started: pid=$PID bind=$BIND"
  echo "[url] http://$BIND/"
else
  echo "[error] start failed, see log: $LOG_DIR/control-plane.out.log" >&2
  exit 1
fi
