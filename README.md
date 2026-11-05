# 墨點俠村（Ink Hero Village）

武俠墨點風格村莊經營＋俠客養成。參考《獵魔村物語》核心循環，美術沿用「墨點江湖」。

## 需求
- **Godot 4.3+**
- CLI（本機）：`/workspace/tools/godot/godot`

```bash
/workspace/tools/godot/godot --path /workspace/modian-xiacun
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun --quit-after 3
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun res://scenes/dev/smoke_v02.tscn
```

## v0.2 點玩
1. 左邊興建／升級建築；「放」＝自由放置（點村莊地面），亦可拖建築改位
2. 貨棧／鐵匠／醫館解鎖後可製作（皮甲、傷藥、鐵刃、毛皮梱）
3. 點俠客名作製作目標；裝備加戰力
4. 出征亂山坡 → 回村有狼／野豬／山賊結果卡
5. 存檔含資源、庫存、建築放置

## 美術
- 綠俠／怪：**64×64**（walk 256×64）；舊 48 在 `_prev_48/`
- 建築圖示：**128×128** HD
- 稀有階梯：綠64 → 紫96 → 橙128 → 紅256

## 備註
私人開發中。勿與 `yinlou-defense`、`wuxia-inn` 混目錄。目標平台含 **iOS**（後期 export）。
