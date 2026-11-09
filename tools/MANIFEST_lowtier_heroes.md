# MANIFEST — 開局六綠俠 64（獵魔村密度・Pivot）

腳本：`tools/gen_lowtier_heroes_hd.py`
Raw：`assets/art/heroes/_gen_raw_lowtier/`
舊墨點備份：`assets/art/heroes/_prev_inkdot_green/`
輸出（雙寫）：
- `assets/art/heroes/hero_*_{idle,walk,attack}.png`（遊戲慣用路徑）
- `assets/art/heroes/green/hero_*_{idle,walk,attack}.png`
預覽：`assets/art/_preview/green_starter_roster_x2.png`

## 規格
- Idle：64×64 RGBA
- Walk／Attack：256×64（4 幀橫 sheet）
- 風格：對齊紅六人 Pivot／《獵魔村物語》高密度；唔用舊墨點簡陋風
- 顯示：整數倍 Nearest

## 清單
| id | 名 | 個性 | idle | walk | attack | 備註 |
|----|----|------|------|------|--------|------|
| `hero_dao_atie` | 刀客阿鐵 | 忠厚 | 64×64 | 256×64 | 256×64 | walk_ai(var=19.71); atk_ai(var=41.22) |
| `hero_jian_aqing` | 劍客阿青 | 冷靜 | 64×64 | 256×64 | 256×64 | walk_ai(var=6.39); atk_ai(var=51.84) |
| `hero_qiang_achang` | 槍客阿長 | 豪邁 | 64×64 | 256×64 | 256×64 | walk_ai(var=15.99); atk_ai(var=36.80) |
| `hero_gun_dali` | 棍僧大力 | 慈悲 | 64×64 | 256×64 | 256×64 | walk_ai(var=8.28); atk_ai(var=38.83) |
| `hero_anqi_azhen` | 暗衛阿針 | 機敏 | 64×64 | 256×64 | 256×64 | walk_ai(var=8.79); atk_ai(var=34.91) |
| `hero_quan_aniu` | 拳師阿牛 | 直率 | 64×64 | 256×64 | 256×64 | walk_ai(var=4.85); atk_ai(var=43.50) |

## 押後／取消
- 白／綠池／藍卡池（`white/`／`green_*` 青衫／`blue/`）整批取消，唔再開 GenerateImage。
- 預覽 `white_green_blue_roster_x2.png` **未做**。

## 自檢
- 六人 idle／walk／attack 齊；尺寸正確
- 每人獨立五官／體型／武器剪影可辨
