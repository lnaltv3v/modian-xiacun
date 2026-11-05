# Export 說明

## Desktop
```bash
/workspace/modian-xiacun/tools/play.sh
```

## Web（HTML5）— 已驗證
Export templates 裝喺 `~/.local/share/godot/export_templates/4.3.stable/`。

```bash
mkdir -p /workspace/modian-xiacun/export/web
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun \
  --export-release "Web" /workspace/modian-xiacun/export/web/index.html

cd /workspace/modian-xiacun/export/web
python3 -m http.server 8765
# 瀏覽器開 http://127.0.0.1:8765/
```

產物：`index.html` / `index.js` / `index.wasm` / `index.pck`

## iOS
後期；需要 macOS、Xcode、Apple Developer。
