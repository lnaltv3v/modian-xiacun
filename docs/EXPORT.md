# Export 說明

## Desktop（而家可用）
```bash
/workspace/modian-xiacun/tools/play.sh
```

## Web（HTML5）— 要 export templates
1. 下載 Godot 4.3 export templates：
   https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
2. 解壓到 `~/.local/share/godot/export_templates/4.3.stable/`
3. 複製 `docs/export_presets.example.cfg` → 專案根 `export_presets.cfg`
4. 執行：
```bash
mkdir -p /workspace/modian-xiacun/export/web
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun \
  --export-release "Web" /workspace/modian-xiacun/export/web/index.html
```

## iOS
後期；需要 macOS、Xcode、Apple Developer。
