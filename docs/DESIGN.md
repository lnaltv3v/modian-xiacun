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
- 建築錨點：`data/buildings/layout.json`（設計 960×540；圖示錨 cx-80, cy-88（160×160））
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

## v0.3-playable
- 自由放置 UX：可建區提示、幽靈預覽（綠可／紅不可）、最短間隔防疊、Esc／右鍵取消
- 新手 6 步：興建客棧 → 派遣 → 回村 → 抽卡／興建 → 秘境選擇 → 前哨／書院（可跳過；存檔 `tutorial_step`；0＝完成唔重播）
- 試玩入口：`tools/play.sh`；煙測 `smoke_v03.tscn`
- 存檔 version **4**
- Web export 待 templates（見 `docs/EXPORT.md`）

## v0.4 食住醫／練功
- **食**：客棧 Lv≥1，閒置俠客耗銀回飽食；自然饑餓持續
- **住**：客棧或村長府，耗木回體力
- **醫**：醫館 Lv≥1，耗銀療傷
- **成功率**：`UpkeepSystem.party_success_chance` 由飽／傷／體綜合；失敗≈30% 收益＋額外受傷
- **練功場**：閒置 XP／秒隨等級；出征成功額外 XP

## v0.5
- 英雄帖（白綠藍池＋碎片）
- 懸賞指定狼／山賊
- 兵器鋪自動買裝


## v0.9.1 打磨
- 出征：亂山坡 14s／毒沼 20s；power_bonus 略收；建築升級 `1.45^lv × (1+0.06lv)`
- UI：稀有色邊；資源列圖示＋獨立數字唔裁切
- 紫階 12 人 96×96：`assets/art/heroes/purple/` + ArtPaths；pool `art_stem`、`placeholder:false`
- 煙測：`smoke_v091.tscn`；試玩清單：`docs/PLAYTEST.md`

## v0.9.5 比武台／製作裝備
- **比武台**：依附練功場；剔 2 俠切磋；戰力＋亂數結算；自動戰鬥演出（對手用俠客精靈）；日限 12；連勝微 XP；存檔欄 `arena_*`
- **製作→裝備**：庫存列可裝／用／賣；換裝舊件回庫；`TrainingSystem.apply_xp_to_hero`
- 存檔 SaveManager **11**；煙測 `smoke_v095.tscn`


## v0.9.9
- 建築全數 160（含書院）；HUD 食住醫／秘境前哨釐清；橙紫 attack 見 v0.9.8
- HUD：食住醫狀態／已選成功率；秘境·N波／前哨·N波 按鈕文案
- 對齊 EHT 缺口見 `docs/NEXT.md`


## v0.13 外派駐守
- 多前哨營地：亂山前哨／官道哨卡；`OutpostSystem.station`／`recall`／`tick_camps`
- 俠客 `status=camped`；存檔 `camp_stations`＋`camp_pick_id`；Save **14**
