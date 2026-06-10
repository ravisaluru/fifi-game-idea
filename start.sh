#!/bin/bash
# start.sh — start Fifi's World Adventures dev server in the background.

PID_FILE=.dev-server.pid

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️ Dev server is already running (PID: $PID)."
    echo "Play at http://localhost:8080"
    exit 0
  else
    echo "Cleaned up stale $PID_FILE file."
    rm "$PID_FILE"
  fi
fi

if [ ! -d node_modules ]; then
  echo "📦 Installing dependencies first..."
  npm install
fi

echo "🚀 Starting Fifi's World Adventures..."
npx vite --port 8080 --host localhost > dev-server.log 2>&1 &
DEV_PID=$!
echo $DEV_PID > "$PID_FILE"

sleep 2

if ps -p $DEV_PID > /dev/null 2>&1; then
  echo "✅ Dev server started!"
  echo "• PID: $DEV_PID"
  echo "• URL: http://localhost:8080"
  echo "• Log: tail -f dev-server.log"
  echo ""
  echo "Open http://localhost:8080 in your browser to play! 🎉"
else
  echo "❌ Failed to start. Check dev-server.log for details."
  rm -f "$PID_FILE"
  exit 1
fi
