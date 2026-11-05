# 墨點俠村 · 美術規範（墨點江湖）

## 風格關鍵詞
宣紙底、墨點色塊、硬邊像素、嚴格色盤、Nearest 過濾（唔好模糊縮放）。

## 色盤（嚴格）
| 名稱 | Hex | 用途 |
|------|-----|------|
| 墨黑 | `#1A1510` | 輪廓、文字、UI 底條 |
| 宣紙 | `#E8DCC8` | 場景底、面板底 |
| 硃紅 | `#C43C2C` 約 | 強調、危險、血／傷 |
| 青綠 | `#2F6B5A` 約 | 安全、藥、山林 |
| 金邊 | `#C9A227` | 標題、稀有、按鈕描邊 |

可微調色階，但主色唔好偏出上述家族。

## 技術
- Godot：`textures/canvas_textures/default_texture_filter = Nearest`（已於 project.godot）
- 精靈建議整數縮放（2× / 3×），避免半像素
- 角色剪影要一眼認得兵種（刀／劍／槍／棍／暗器／拳腳）

## 目錄
- `assets/art/heroes/` 俠客立繪／行走／戰鬥幀
- `assets/art/buildings/` 村莊建築
- `assets/art/ui/` HUD、按鈕、圖示
- `assets/art/monsters/` 敵人／妖物
- `assets/art/tiles/` 地面／村景 tile

## 稀有度視覺階梯
- 白／綠：簡剪影、少飾物
- 藍／紫：多一層飾物同配色識別
- 橙／紅：最華麗——鮮明特徵、細節密度、金邊／硃紅點綴；一眼聯想影射人物（唔抄立繪）

- 技能／攻擊特效：稀有愈高愈誇張（紅階入場＋大招要有明顯演出）

## P1 檔名對照
| hero_id | 美術 stem |
|---------|-----------|
| hero_atie | hero_dao_atie |
| hero_aqing | hero_jian_aqing |
| hero_achang | hero_qiang_achang |
| hero_dali | hero_gun_dali |
| hero_azhen | hero_anqi_azhen |
| hero_aniu | hero_quan_aniu |

Walk sheet：192×48（4×48）。建築錨點見 `data/buildings/layout.json`。

## 解像／密度（Lemon 最高標準）
- 角色原生幀：**最少 64×64**；橙／紅目標 **96×96** 細節密度
- 早期 48×48 只當原型，正式版要升級
- 建築圖示：96×96 或 128×128；村莊底仍 960×540 但紋理加厚
- 顯示整數倍 Nearest；唔用柔邊放大充解像
