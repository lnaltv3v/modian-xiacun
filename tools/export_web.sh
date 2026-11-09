#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/workspace/tools/godot/godot}"
PRESET_SRC="$ROOT/docs/export_presets.example.cfg"
PRESET_DST="$ROOT/export_presets.cfg"
OUT="$ROOT/export/web/index.html"
if [[ ! -x "$GODOT" ]]; then
  echo "找不到 Godot：$GODOT" >&2
  exit 1
fi
if [[ ! -f "$PRESET_DST" ]]; then
  cp "$PRESET_SRC" "$PRESET_DST"
fi
mkdir -p "$ROOT/export/web"
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT"
echo "Web export → $ROOT/export/web/"
echo "試玩：cd $ROOT/export/web && python3 -m http.server 8877"
echo "瀏覽器開 http://127.0.0.1:8877/"
