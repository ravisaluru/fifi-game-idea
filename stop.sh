#!/bin/bash
# stop.sh
# A script to stop the background Flutter application.

if [ -f flutter.pid ]; then
  PID=$(cat flutter.pid)
  echo "🛑 Stopping Fifi's World Adventures (PID: $PID)..."
  
  if kill $PID > /dev/null 2>&1; then
    # Also kill any child processes spawned by flutter run
    pkill -P $PID > /dev/null 2>&1
    rm -f flutter.pid
    echo "✅ Stopped successfully!"
  else
    echo "⚠️ Process $PID was not running, or failed to terminate."
    rm -f flutter.pid
  fi
else
  echo "ℹ️ No running application found (no flutter.pid file present)."
fi
