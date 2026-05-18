#!/bin/bash
# start.sh
# A script to start Fifi's World Adventures in the background.

if [ -f flutter.pid ]; then
  PID=$(cat flutter.pid)
  if ps -p $PID > /dev/null 2>&1; then
    echo "⚠️ Flutter application is already running (PID: $PID)."
    echo "Play online at http://localhost:8080"
    exit 0
  else
    echo "Cleaned up stale flutter.pid file."
    rm flutter.pid
  fi
fi

echo "🚀 Starting Fifi's World Adventures..."
echo "Running in background on http://localhost:8080..."

# Start flutter web-server
flutter run -d web-server --web-port=8080 --web-hostname=localhost > flutter_run.log 2>&1 &
FLUTTER_PID=$!
echo $FLUTTER_PID > flutter.pid

# Wait a couple of seconds to make sure it didn't immediately fail
sleep 2

if ps -p $FLUTTER_PID > /dev/null 2>&1; then
  echo "✅ Application started successfully!"
  echo "• PID: $FLUTTER_PID"
  echo "• URL: http://localhost:8080"
  echo "• Log: tail -f flutter_run.log"
  echo ""
  echo "Open http://localhost:8080 in your browser to play! 🎉"
else
  echo "❌ Failed to start the application. Check flutter_run.log for details."
  rm -f flutter.pid
  exit 1
fi
