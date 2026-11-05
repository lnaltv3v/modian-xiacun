# 墨點俠村（Ink Hero Village）· v0.4

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
/workspace/tools/godot/godot --headless --path /workspace/modian-xiacun res://scenes/dev/smoke_v03.tscn
```

> **Web／HTML5 export**：而家未裝 Godot export templates，暫時未打出 `export/web/`。裝好 4.3 templates 後可用 `export_presets.cfg`（見下）再出。  
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
- 建築圖示：**128×128** HD；村景 960×540 分層
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
- **v0.4** 放置 UX 打磨＋新手引導＋試玩說明（本版）

私人開發中。勿與 `yinlou-defense`、`wuxia-inn` 混目錄。

## v0.4 循環加深
- 食住醫自動消耗（客棧耗銀／木、醫館耗銀）；短缺暫停恢復
- 飽食／傷勢影響出征成功率（失敗收益大減）
- 練功場：在村閒置攞 XP，滿則升級
- Web：`tools/export_web.sh` → `export/web/`（`python3 -m http.server 8877`）
