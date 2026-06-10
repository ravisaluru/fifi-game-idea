#!/bin/sh
# Run once after cloning: sh scripts/setup-hooks.sh
# Installs a pre-push hook that runs tests + a production build before every push.

HOOK_DIR="$(git rev-parse --git-dir)/hooks"

cat > "$HOOK_DIR/pre-push" << 'EOF'
#!/bin/sh
# Pre-push hook: runs the test suite and a production build.
# To skip in an emergency: git push --no-verify

set -e

echo "→ npm test"
npm test

echo "→ npm run build"
npm run build

echo "✓ All checks passed"
EOF

chmod +x "$HOOK_DIR/pre-push"
echo "✓ pre-push hook installed at $HOOK_DIR/pre-push"
echo "  Runs automatically before every 'git push'."
echo "  Skip with: git push --no-verify  (use sparingly)"
