# MANIFEST — 紫階十二人 96×96

生成腳本：`tools/gen_purple_heroes_96.py`
輸出目錄：`assets/art/heroes/purple/`
預覽：`assets/art/_preview/purple_roster96_x1.png`、`purple_roster96_x2.png`

## 規格
- Idle：96×96 RGBA 透明底硬邊
- Walk：384×96（4 幀 × 96）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋梵紫#5A4060 級＋skin/wood/boot/shade/robe 微調
- 解像階梯：紫＝96；Nearest 整數倍顯示
- 華麗度：高於綠64、低於橙128；技能特效今次未做

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
| `purple_weixiaobao` | 韋小保 | 96×96 | 384×96 | 青衣太監帽、多柄匕首、金腰牌 | idle_bad=0 walk_bad=0 opaque=2723 |
| `purple_hufei` | 胡飛 | 96×96 | 384×96 | 少年土褐勁裝、背苗刀、義氣粗眉 | idle_bad=0 walk_bad=0 opaque=2681 |
| `purple_miaorenfeng` | 苗人風 | 96×96 | 384×96 | 壯碩黑甲金邊、半面金紋、硃紅點大刀 | idle_bad=0 walk_bad=0 opaque=3172 |
| `purple_yuanchengzhi` | 袁承智 | 96×96 | 384×96 | 青金勁裝、蛇形波刃短劍、金護腕 | idle_bad=0 walk_bad=0 opaque=2705 |
| `purple_diyun` | 狄芸 | 96×96 | 384×96 | 灰褐破衣樸刀、短亂髮、堅毅眉 | idle_bad=0 walk_bad=0 opaque=2661 |
| `purple_shipotian` | 石破添 | 96×96 | 384×96 | 土黄粗布、巨掌護腕、傻笑 | idle_bad=0 walk_bad=0 opaque=2854 |
| `purple_xuzhu` | 虛竺 | 96×96 | 384×96 | 僧灰袍淡紫帶、光頭念珠、短杖 | idle_bad=0 walk_bad=0 opaque=2628 |
| `purple_limochou` | 李莫秋 | 96×96 | 384×96 | 赤練衣面紗、銀針排、鞭影銀線 | idle_bad=0 walk_bad=0 opaque=2711 |
| `purple_xiaolongnu` | 小龍妞 | 96×96 | 384×96 | 宣紙白衣長白髮、細劍墨邊 | idle_bad=0 walk_bad=0 opaque=2754 |
| `purple_zhaomin` | 趙敏 | 96×96 | 384×96 | 硃紅郡主裝金飾、摺扇＋短刃 | idle_bad=0 walk_bad=0 opaque=2712 |
| `purple_zhouzhiruo` | 周芷偌 | 96×96 | 384×96 | 紫灰峨眉尼袍紫帶、頭巾長劍 | idle_bad=0 walk_bad=0 opaque=2746 |
| `purple_yuebuqun` | 岳不裙 | 96×96 | 384×96 | 白青君子袍冠帶、背長劍、假笑 | idle_bad=0 walk_bad=0 opaque=2842 |

## 自檢
- 尺寸正確；alpha 以 0/255 為主；非透明像素充足
- 十二剪影可辨：太監帽匕首／苗刀少年／金面大刀／蛇劍／破衣樸刀／巨掌／僧念珠／赤練面紗／白衣細劍／摺扇郡主／紫尼頭巾／君子冠帶
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型；全新構圖唔 NN 放大
