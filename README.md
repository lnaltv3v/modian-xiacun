# 墨點俠村（Ink Hero Village）

武俠墨點風格村莊經營＋俠客養成。參考《獵魔村物語》核心循環，美術沿用「墨點江湖」。

## 需求
- **Godot 4.3+**
- CLI（本機）：`/workspace/tools/godot/godot`

```bash
/workspace/tools/godot/godot --path /workspace/modian-xiacun
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun --quit-after 3
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun res://scenes/dev/smoke_v01.tscn
```

## v0.1 點玩
1. 左邊升級建築（客棧提高駐紮／恢復；醫館加速恢復）
2. 右邊剔選俠客（或調人數），按「出征亂山坡」
3. 等倒數回村收銀／毛皮；可勾「自動再出征」
4. 存檔／讀檔；離線期間到期出征會喺讀檔或返回時結算
5. 中間村莊圖可點建築圖示升級（layout.json 錨點）

## 目錄
```
modian-xiacun/
  data/heroes|buildings|zones/
  assets/art/heroes|buildings|monsters|ui|tiles|_preview/
  scenes/main|village|ui|combat/
  scripts/autoload|systems|constants|ui|dev/
```

## 備註
私人開發中。勿與 `yinlou-defense`、`wuxia-inn` 混目錄。目標平台含 **iOS**（後期 export）。
