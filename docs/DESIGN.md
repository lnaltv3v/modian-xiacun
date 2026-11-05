# 墨點俠村 · 設計重點（短版）

完整計劃書另見 Cursor Page。此處對齊 **v0.1 核心循環**。

## 核心循環（獵魔村式）
建築服務俠客 → 俠客變強 → 派遣出征帶回資源 → 升級村莊 → 再開建築。

## 開局
- 六綠俠：刀客阿鐵、劍客阿青、槍客阿長、棍僧大力、暗衛阿針、拳師阿牛
- 建築：村長府、客棧、鐵匠鋪、醫館、練功場、懸賞榜
- 獵場：亂山坡（`data/zones/core.json`）

## v0.1 規則摘要
- 資源：銀兩／木材／毛皮
- 俠客：體力、飽食、傷勢；出征狀態 `hunting`，在村 `idle`
- 客棧提高駐紮上限與飽食恢復；醫館加快體力／傷勢恢復；鐵匠鋪加戰力；懸賞榜加收益倍率
- 派遣：剔選 1–多隻 → 亂山坡 → 倒數（unix `return_at`，支援離線結算）→ 回村加銀／毛皮／木，扣體／飽，機率受傷
- 自動再出征：勾選後在村且狀態允許會自動派（最多同時 2 隊）
- 存檔：`user://save_slot_0.json`，`version: 2`

## 美術／場景
- 俠客 idle／walk（48×48；walk 192×48 sheet）→ `ArtPaths` + `HeroPortrait` SpriteFrames
- 建築錨點：`data/buildings/layout.json`（設計 960×540；圖示錨 cx-48, cy-56）
- 分層 z：ground→hills→buildings_pad→建築→fg
- 怪物圖預留戰鬥結果卡

## 技術
- 引擎：**Godot 4.3+**
- 主場景：`res://scenes/main/main.tscn`
- Autoload：`GameState`、`SaveManager`
- 系統：`BuildingSystem` / `HeroSystem` / `DispatchSystem` / `ResourceLoop`
- 後期：Android／**iOS** export

## 煙測
```bash
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun res://scenes/dev/smoke_v01.tscn
```
