# 墨點俠村（Ink Hero Village）· v0.9.7

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

> **Web／HTML5**：`tools/export_web.sh` → `export/web/`（`python3 -m http.server 8877`）  
> **iOS**：後期里程碑，要 Mac＋Apple 帳先 export。

## 試玩流程（新手 3 步）

畫面頂有引導條（可「跳過」）：

1. **興建客棧** — 左邊建築列表撳客棧「興建」（銀 50／木 25）
2. **派遣** — 右邊剔選俠客 →「出征亂山坡」
3. **回村** — 等下方倒數完，收資源／睇結果卡

之後可自由：

- **放**：自由放置建築（青綠可建區；綠幽靈＝可放、紅＝太近／出界；**右鍵或 Esc 取消**；再撳「放」亦取消）
- 拖移已有建築改位（太近會自動微調）
- 升級鐵匠／醫館／貨棧 → 製作皮甲、傷藥、毛皮梱
- 開「自動再出征」做放置循環
- 存／讀檔（含放置同引導進度）

## 美術

- 綠俠／怪：**64×64**（walk sheet 256×64）
- 建築圖示：**160×160** Pivot R2（七棟核心；academy 暫 128）；村景 960×540 分層拉開預設
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
