# 墨點俠村（Ink Hero Village）

武俠墨點風格村莊經營＋俠客養成。參考《獵魔村物語》核心循環，美術沿用「墨點江湖」（宣紙底、硬邊像素、嚴格色盤）。

## 需求
- **Godot 4.3+**（建議 4.3 stable）
- 本倉庫已用 `config_version=5`（Godot 4）

本機若未裝編輯器，可用：

```bash
/workspace/tools/godot/godot --version
/workspace/tools/godot/godot --path /workspace/modian-xiacun
```

Headless 煙測：

```bash
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun --quit-after 2
```

## 開啟專案
1. Godot 專案管理員 → Import／Scan → 選本目錄 `project.godot`
2. 主場景應自動為 `scenes/main/main.tscn`
3. 按 F5 執行

## 目錄摘要
```
modian-xiacun/
  project.godot
  scenes/main|village|ui|combat/
  scripts/autoload|systems/
  data/heroes|buildings/
  assets/art|audio/
  docs/ART.md  docs/DESIGN.md
```

## Prototype 操作
- **派遣出征**：派一名閒俠，約 3 秒回村加銀／木
- **建／升客棧**：扣銀兩＋木材升級
- **存檔**：寫入 `user://save_slot_0.json`

## 授權／備註
私人開發中。勿與 `yinlou-defense`、`wuxia-inn` 混目錄。
