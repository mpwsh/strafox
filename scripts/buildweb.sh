#!/bin/bash
set -e

GAME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="${GAME_DIR}/web"
TEMP_DIR=$(mktemp -d)

# Copy only game files to a clean temp directory
cd "$GAME_DIR"
cp -r *.lua "$TEMP_DIR/"
cp -r moonshine "$TEMP_DIR/"
cp -r assets "$TEMP_DIR/"
cp conf.lua "$TEMP_DIR/" 2>/dev/null || true

rm -rf "$WEB_DIR"
mkdir -p "$WEB_DIR"

npx love.js --title Strafox -c "$TEMP_DIR" "$WEB_DIR"
cp "$GAME_DIR/site/index.html" "$WEB_DIR/"
cp "$GAME_DIR/site/js/"* "$WEB_DIR/"
cp "$GAME_DIR/scripts/globalizeFS.js" "$WEB_DIR/"
cp "$GAME_DIR/scripts/consolewrapper.js" "$WEB_DIR/"
cp "$GAME_DIR/scripts/webdb.js" "$WEB_DIR/"
cp -r "$GAME_DIR/assets" "$WEB_DIR/assets"
cd "$WEB_DIR" && node globalizeFS.js

rm -rf "$TEMP_DIR"

echo "Build complete: $WEB_DIR"
echo "Run: cd web && python3 -m http.server 8000"
