# MANIFEST — 橙階十二人 128×128

生成腳本：`tools/gen_orange_heroes_128.py`
輸出目錄：`assets/art/heroes/orange/`
預覽：`assets/art/_preview/orange_roster128_x1.png`、`orange_roster128_x2.png`

## 規格
- Idle：128×128 RGBA 透明底硬邊
- Walk：512×128（4 幀 × 128）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋梵紫#5A4060 級＋skin/wood/boot/shade/robe 微調
- 解像階梯：橙＝128；Nearest 整數倍顯示
- 華麗度：高於綠64、低於紅256；技能特效今次未做

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
| `orange_yangguo` | 楊菓 | 128×128 | 512×128 | 黑衣披風硃紅裏、右義肢護臂、左掌、玉蜂囊 | idle_bad=0 walk_bad=0 opaque=4960 |
| `orange_guojing` | 郭靚 | 128×128 | 512×128 | 壯碩土褐勁裝、雙拳護腕、銅扣寬腰帶 | idle_bad=0 walk_bad=0 opaque=5376 |
| `orange_linghuzhong` | 令狐忠 | 128×128 | 512×128 | 青衫散髮負劍、酒葫蘆、衣襟鬆開 | idle_bad=0 walk_bad=0 opaque=5221 |
| `orange_qiaofeng` | 喬風 | 128×128 | 512×128 | 高大短褐龍抓手、綠布袋、骨項飾 | idle_bad=0 walk_bad=0 opaque=5416 |
| `orange_zhangsanfeng` | 張三風 | 128×128 | 512×128 | 道袍白髮長鬚、太極胸圖、拂塵圓轉姿 | idle_bad=0 walk_bad=0 opaque=5798 |
| `orange_fengqingyang` | 風青羊 | 128×128 | 512×128 | 灰青袍白髮、鞘中長劍、崖風披肩草鞋 | idle_bad=0 walk_bad=0 opaque=4918 |
| `orange_huangyaoshi` | 黃藥獅 | 128×128 | 512×128 | 青綠衫執玉簫、袖藏棋子、克制桃花點 | idle_bad=0 walk_bad=0 opaque=5010 |
| `orange_ouyangfeng` | 歐陽峰 | 128×128 | 512×128 | 白衣披髮蛇杖、毒囊梵紫、詭異眼 | idle_bad=0 walk_bad=0 opaque=6060 |
| `orange_hongqigong` | 洪喫公 | 128×128 | 512×128 | 老丐打狗棒綠袋破衣、雞腿待機彩蛋 | idle_bad=0 walk_bad=0 opaque=5188 |
| `orange_yideng` | 一登大師 | 128×128 | 512×128 | 金紅袈裟光頭念珠、指尖暖金光 | idle_bad=0 walk_bad=0 opaque=4984 |
| `orange_zhoubotong` | 周伯同 | 128×128 | 512×128 | 白髮童顏雙臂異動、嬉笑無兵器殘影 | idle_bad=0 walk_bad=0 opaque=4958 |
| `orange_miejueshitai` | 滅絕師態 | 128×128 | 512×128 | 青灰尼袍頭巾長劍、硃砂戒疤嚴峻 | idle_bad=0 walk_bad=0 opaque=5066 |

## 自檢
- 尺寸正確；alpha 以 0/255 為主；非透明像素充足
- 十二剪影可辨：披風義肢／雙拳褐／青衫葫蘆／龍抓／道鬚太極／灰袍鞘劍／執簫／蛇杖／打狗棒雞腿／袈裟指光／雙臂異動／尼袍戒疤
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型；全新構圖唔 NN 放大
