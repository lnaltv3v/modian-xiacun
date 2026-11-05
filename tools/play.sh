#!/usr/bin/env bash
# Desktop 試玩啟動（Godot 4.3）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/workspace/tools/godot/godot}"
if [[ ! -x "$GODOT" ]]; then
  echo "找不到 Godot：$GODOT" >&2
  exit 1
fi
exec "$GODOT" --path "$ROOT" "$@"
