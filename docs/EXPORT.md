# Export 說明

## Desktop
```bash
/workspace/modian-xiacun/tools/play.sh
```

## Web（HTML5）— 一鍵試玩
Export templates：`~/.local/share/godot/export_templates/4.3.stable/`（需含 `web_*.zip`）。

```bash
# 一鍵（會寫 export/web/；缺 preset 時從 docs/export_presets.example.cfg 複製）
/workspace/modian-xiacun/tools/export_web.sh

# 本機伺服
cd /workspace/modian-xiacun/export/web && python3 -m http.server 8877
# 瀏覽器開 http://127.0.0.1:8877/
```

等價手動指令：
```bash
mkdir -p /workspace/modian-xiacun/export/web
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun \
  --export-release "Web" /workspace/modian-xiacun/export/web/index.html
```

產物：`index.html` / `index.js` / `index.wasm` / `index.pck`（`export/` 已 gitignore，本機生成即可）。

## iOS
後期；需要 macOS、Xcode、Apple Developer。
