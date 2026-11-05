# MANIFEST — 紅階六人 256×256

生成腳本：`tools/gen_red_heroes_256.py`
輸出目錄：`assets/art/heroes/red/`
預覽：`assets/art/_preview/red_roster256_x1.png`、`red_roster256_x2.png`

## 規格
- Idle：256×256 RGBA 透明底硬邊
- Walk：1024×256（4 幀 × 256）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋skin/wood/boot/shade/robe 微調
- 解像階梯：紅＝256；Nearest 整數倍顯示
- 技能特效：今次未做（可後補）

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
| `red_zhangwuji` | 張無記 | 256×256 | 1024×256 | 白衣黑邊半束髮、雙掌淡金氣暈、藥囊 | idle_bad=0 walk_bad=0 |
| `red_dongfang` | 東方唔敗 | 256×256 | 1024×256 | 硃紅繡袍長髮、銀針扇、繡箍飄帶 | idle_bad=0 walk_bad=0 |
| `red_dugu` | 獨孤求拜 | 256×256 | 1024×256 | 青袍負木劍、清瘦密褶、劍氣淡白 | idle_bad=0 walk_bad=0 |
| `red_saodi` | 掃地僧 | 256×256 | 1024×256 | 灰僧衣補丁光頭、竹掃把、念珠落葉 | idle_bad=0 walk_bad=0 |
| `red_wangchongyang` | 王重揚 | 256×256 | 1024×256 | 道冠長鬚寬袖、玉牌、中正雙拳青氣 | idle_bad=0 walk_bad=0 |
| `red_huangshang` | 黃裳 | 256×256 | 1024×256 | 墨褐文袍書卷、袖弩鐵蓮、墨指痕 | idle_bad=0 walk_bad=0 |

## 自檢
- 尺寸正確；alpha 以 0/255 為主
- 六人並排剪影可辨：白掌／紅針／木劍／掃把／道鬚／書卷袖弩
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型
