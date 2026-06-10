#!/bin/bash
# stop.sh — stop the background dev server.

PID_FILE=.dev-server.pid

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  echo "🛑 Stopping Fifi's World Adventures (PID: $PID)..."

  if kill "$PID" > /dev/null 2>&1; then
    pkill -P "$PID" > /dev/null 2>&1
    rm -f "$PID_FILE"
    echo "✅ Stopped successfully!"
  else
    echo "⚠️ Process $PID was not running, or failed to terminate."
    rm -f "$PID_FILE"
  fi
else
  echo "ℹ️ No running dev server found (no $PID_FILE file present)."
fi
