# 墨點俠村（Ink Hero Village）· v0.17.0

武俠墨點風格村莊經營＋俠客養成。玩法跟足《獵魔村物語》核心循環（建築→養俠→派遣→資源→再升級）。

## 點樣試玩（Desktop）

本機已備 Godot 4.3 CLI：

```bash
# 開視窗玩（推薦）
/workspace/modian-xiacun/tools/play.sh

# 或直接
/workspace/tools/godot/godot --path /workspace/modian-xiacun
```

Headless 煙測（唔開窗）：

```bash
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun --quit-after 2
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun res://scenes/dev/smoke_v06.tscn
```

> **Web／HTML5 試玩**：`tools/export_web.sh` → `cd export/web && python3 -m http.server 8877` → 瀏覽器開 `http://127.0.0.1:8877/`（詳見 `docs/EXPORT.md`）  
> **iOS**：後期里程碑，要 Mac＋Apple 帳先 export。

## 試玩流程（新手 6 步）

畫面頂有引導條（可「跳過」；舊存檔已完成＝唔會重播）：

1. **興建客棧** — 左邊建築列表撳客棧「興建」（銀 50／木 25）
2. **派遣** — 右邊剔選俠客 →「出征亂山坡」
3. **回村** — 等下方倒數完，收資源／睇結果卡
4. **抽卡／興建** — 英雄帖或興建醫館／貨棧／懸賞／書院
5. **秘境** — 剔選俠客 →「秘境」揀難度／波次 → 入秘境
6. **前哨／書院** — 撳「前哨」睇解鎖或難度；有書院可開武學／經世技能樹

之後可自由：

- **放**：自由放置建築（青綠可建區；綠幽靈＝可放、紅＝太近／出界；**右鍵或 Esc 取消**；再撳「放」亦取消）
- 拖移已有建築改位（太近會自動微調）
- 升級鐵匠／醫館／貨棧 → 製作皮甲、傷藥、毛皮梱
- 開「自動再出征」做放置循環
- 存／讀檔（含放置同引導進度）

## 美術

- 綠俠／怪：**64×64**（walk sheet 256×64）
- 建築圖示：**160×160** Pivot R5（八棟再密）；村景 960×540 分層拉開；橙紫／紅 idle／walk／attack 已接
- 稀有階梯（後期）：綠64 → 紫96 → 橙128 → **紅256**

## 目錄

| 路徑 | 說明 |
|------|------|
| `scenes/main/main.tscn` | 開局主場景 |
| `scenes/village/` | 村莊＋自由放置 |
| `scripts/systems/` | 建築／派遣／製作／俠客 |
| `assets/art/` | 俠客／怪／建築／UI／村景 |
| `docs/DESIGN.md` / `docs/ART.md` | 設計同美術規範 |

## 版本

- v0.1 核心循環
- v0.2 製作鏈＋戰鬥結果＋自由放置＋64 art
- v0.4 放置 UX＋新手引導＋食住醫／練功／Web
- v0.5 英雄帖／懸賞／兵器鋪
- v0.6 秘境三波／紫池／師門書院
- v0.7 橙紅池／毒沼／前哨 stub
- **v0.8** 短自動戰鬥／紅階 256 圖／前哨三波（本版）

私人開發中。勿與 `yinlou-defense`、`wuxia-inn` 混目錄。

## v0.4 循環加深
- 食住醫自動消耗（客棧耗銀／木、醫館耗銀）；短缺暫停恢復
- 飽食／傷勢影響出征成功率（失敗收益大減）
- 練功場：在村閒置攞 XP，滿則升級
- Web：`tools/export_web.sh` → `export/web/`（`python3 -m http.server 8877`）

## v0.5 英雄帖／懸賞／兵器鋪
- **英雄帖**：白／綠／藍池抽卡（權重可調）；重覆轉碎片；存檔含碎片
- **懸賞榜**：指定野狼／山賊，出征擊中額外賞
- **兵器鋪**：鐵匠鋪開後可銀購裝；「自動買裝」／「買一次」
- smoke：`res://scenes/dev/smoke_v06.tscn`

## v0.6 秘境／紫池／書院
- **亂山秘境**：剔選最多 5 俠，3 波結算＋簡演出（現有狼／豬／山賊 sprite；末波狼王／山賊頭目放大示意）
- **英雄帖紫池**：權重低；韋小保／胡飛／令狐忠／楊菓／張無記（暫色塊＋兵種標）
- **師門書院**：興建後解鎖 1 個被動技能槽（鐵骨／疾風／沉著／血氣；撳「書院技」輪換）
- smoke：`res://scenes/dev/smoke_v06.tscn`


## v0.9.8
- 師門書院 `academy.png` 160 接入 layout（pivot_r3，拉開錨 280,320）
- 橙／紫 Pivot 高密度 idle／walk／attack 接入（ArtPaths 自動組 attack anim）
- 食住醫狀態列＋俠客成功率短標；秘境／前哨按鈕顯示波次與解鎖條件
- 缺口清單：`docs/NEXT.md`；煙測 `smoke_v098.tscn`


## v0.9.9
- 師門書院 `academy.png` 160 接入 layout（pivot_r4 加厚八棟，錨 280,320，拉開）
- 食住醫狀態列＋俠客成功率短標；秘境／前哨按鈕顯示波次與解鎖條件
- 缺口清單：`docs/NEXT.md`；煙測 `smoke_v099.tscn`
- （v0.9.8 已接橙紫高密度 idle／walk／attack）

## v0.10.0
- 秘境／前哨結果卡：波次 ✓✗ 清單、掉落摘要、解鎖／下一步提示（EHT 式清晰）
- 村莊「維護」小面板：食／住／醫等級、日耗預覽、短缺紅點（`UpkeepSystem.describe_panel`）
- 煙測：`res://scenes/dev/smoke_v010.tscn`





## v0.17.0
- **工程收尾**：舊煙測版本 pin 改為 ≥（`SmokeUtil`）；`smoke_v110`–`v160` 可喺 HEAD 一齊過
- **存檔兼容**：`SaveManager.migrate_state` 補 `academy_unlocked_nodes`／`camp_stations`／`tutorial_step`；讀檔後 `AcademySystem.reload`
- **綠階 WIP attack**：`ArtPaths.hero_attack` 只認紅／橙／紫；`load_tex` 唔對未 import 裸檔 `load()`（減噪音，唔接入綠 roster）
- 煙測：`res://scenes/dev/smoke_v170.tscn`；SAVE 仍 14

## v0.16.0
- **營地手感平衡**：駐守飽食不再疊村莊饑餓（`UpkeepSystem` 對 `camped` 跳過）；只走營地耗
- **糧餉舒適**：繳足銀＝`comfort_drain_mult` 減耗＋微補乾糧；欠餉加重；面板標「舒適／欠餉」
- **Web 試玩**：`tools/export_web.sh` 一鍵 export；`cd export/web && python3 -m http.server 8877`
- 煙測：`res://scenes/dev/smoke_v160.tscn`；SAVE 仍 14

## v0.15.0
- **書院技能樹擴充**：武學／經世兩專精（保留舊 7 節點 id，存檔兼容）；新增破招／卸力／剛猛／鐵壁被動與村賬／礦脈／秘藏／營帳／前哨／心訣／要略等全村節點
- **效果接線**：暴擊／招架進自動戰鬥；出征毛皮鐵、秘境銀碎片、駐守涓滴、前哨銀獎、日耗銀乘算；武學心訣被動槽＋1
- **書院 UI**：按 row／col 網格、專精色、碎片消耗提示、解鎖閃光
- 煙測：`res://scenes/dev/smoke_v150.tscn`；SAVE 仍 14

## v0.14.0
- **戰鬥手感**：入場淡入 pose → 逼近；受擊閃紅／微擊退＋飄字；約 20% 招架（「招架」飄字＋青閃）；暴擊微震 Arena 1～2px（鏡頭細震）
- **區底圖分層**：sky／mid／ground／props 疊層強調景深（缺層回退合成圖）
- 煙測：`res://scenes/dev/smoke_v140.tscn`；SAVE 仍 14

## v0.13.0
- **外派駐守 stub**：解鎖前哨後可派俠長期駐「亂山前哨」「官道哨卡」（官道需一次前哨全勝）
- 駐守中不可派遣／秘境／一波防衛；被動涓滴銀／毛皮／鐵＋週期小戰摘要；耗體／飽＋少量銀維持；疲憊自動召回
- 前哨面板：難度守點＋營地揀選／駐守／召回；存檔 `camp_stations`（Save **14**）
- 煙測：`res://scenes/dev/smoke_v130.tscn`

## v0.12.0
- **新手引導**：④ 後接 ⑤秘境選擇／⑥前哨解鎖提示＋書院技能樹；舊存檔 `tutorial_step=0` 唔重播
- **HUD 資訊密度**：頂欄下 chip 帶（食／住／醫圖示＋派遣就緒／秘境／前哨狀態）；重用 Pivot R6 `hud_panel`／icons／btn art
- 煙測：`res://scenes/dev/smoke_v120.tscn`

## v0.11.0
- **亂山秘境**：入場可揀難度（普通／困難／絕境）同波次組（一波試探／雙波／三波全破）；敵力／獎／耗體按倍率；全破解鎖下一階
- **前哨防衛**：同樣難度階（敵／獎倍率）；全勝累計解鎖
- **師門書院技能樹 stub**：碎片解鎖節點、預覽被動／全村效果（村賬精算日耗銀、貨棧要訣出征銀）；授徒限已解鎖被動
- 煙測：`res://scenes/dev/smoke_v110.tscn`

## v0.10.4

- 師門書院 `academy.png` 接入 Lemon 批核之 Pivot R3 交付（160×160；其餘建築／村景仍 Pivot R5）
- 煙測：`res://scenes/dev/smoke_v104.tscn`

## v0.10.3

- Pivot R6 UI drop-in：`hud_panel`／`btn_dispatch`／`btn_build`／resource icons 接入主介面（尺寸維持 320×64／128×40／32×32）。

## v0.10.2
- Pivot R5 八棟＋村景分層 tiles 接入（`art_revision: pivot_r5`；pad 透明；拉開 free-place）
- 預覽 `assets/art/_preview/pivot_r5_*`；備份 `_prev_pivot_r4/`；`tools/gen_pivot_r5.py`
- 煙測：`res://scenes/dev/smoke_v010.tscn`
