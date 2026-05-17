#!/bin/sh
# Run once after cloning: sh scripts/setup-hooks.sh
# Installs a pre-push hook that runs analyze + tests locally before every push.

HOOK_DIR="$(git rev-parse --git-dir)/hooks"

cat > "$HOOK_DIR/pre-push" << 'EOF'
#!/bin/sh
# Pre-push hook: runs flutter analyze and flutter test.
# To skip in an emergency: git push --no-verify

set -e

echo "→ flutter analyze"
flutter analyze --fatal-infos

echo "→ flutter test"
flutter test

echo "✓ All checks passed"
EOF

chmod +x "$HOOK_DIR/pre-push"
echo "✓ pre-push hook installed at $HOOK_DIR/pre-push"
echo "  Runs automatically before every 'git push'."
echo "  Skip with: git push --no-verify  (use sparingly)"
