# MANIFEST — 紅階六人 256×256（facefix／腳形修正）

生成腳本：`tools/gen_red_heroes_256.py`
輸出目錄：`assets/art/heroes/red/`
備份：`assets/art/heroes/red/_prev_facefix/`
預覽：`assets/art/_preview/red_roster256_x1.png`、`red_roster256_x2.png`
臉對照：`assets/art/_preview/red_faces_compare.png`（上＝舊／下＝新）、`red_faces_closeup.png`

## 規格
- Idle：256×256 RGBA 透明底硬邊
- Walk：1024×256（4 幀 × 256）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋skin/wood/boot/shade/robe 微調
- 解像階梯：紅＝256；Nearest 整數倍顯示
- **facefix**：六人獨立五官／神態（唔共用同一 face 模板）
- **腳形修正**：靴底平貼 sole_y=236，陰影 y=238；idle 雙腳對稱踩實；walk 抬腳 6px
- 技能特效：今次未做（可後補）

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
| `red_zhangwuji` | 張無記 | 256×256 | 1024×256 | facefix溫厚圓目微抿＋腳踩實；白衣黑邊半束髮、雙掌淡金、藥囊 | idle_bad=0 walk_bad=0 |
| `red_dongfang` | 東方唔敗 | 256×256 | 1024×256 | facefix鳳眼戲謔嘴＋腳踩實；硃紅繡袍長髮、銀針、飄帶 | idle_bad=0 walk_bad=0 |
| `red_dugu` | 獨孤求拜 | 256×256 | 1024×256 | facefix細目薄唇清瘦＋腳踩實；青袍負木劍、密褶 | idle_bad=0 walk_bad=0 |
| `red_saodi` | 掃地僧 | 256×256 | 1024×256 | facefix老年皺紋慈眉＋腳踩實；灰僧衣補丁、掃把念珠 | idle_bad=0 walk_bad=0 |
| `red_wangchongyang` | 王重揚 | 256×256 | 1024×256 | facefix劍眉長鬚剛毅＋腳踩實；道冠寬袖、玉牌雙拳 | idle_bad=0 walk_bad=0 |
| `red_huangshang` | 黃裳 | 256×256 | 1024×256 | facefix文士細目墨頰＋腳踩實；墨褐袍書卷、袖弩鐵蓮 | idle_bad=0 walk_bad=0 |

## 自檢
- 尺寸正確；alpha 以 0/255 為主
- 六人並排剪影可辨：白掌／紅針／木劍／掃把／道鬚／書卷袖弩
- 臉：溫厚圓目／鳳眼戲謔／細目淡漠／老年慈眉／劍眉長鬚／文士墨頰
- 腳：唔懸空、唔外八歪斜
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型
