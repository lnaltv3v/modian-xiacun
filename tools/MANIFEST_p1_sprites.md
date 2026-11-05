# 墨點俠村 P1 精靈 MANIFEST

- 統一幀尺寸：`64×64`（綠稀有正式標準；舊 48 備份於 `heroes/_prev_48/`、`monsters/_prev_48/`）
- Walk sheet：`4` 幀橫向（256×64）
- 風格：硬邊 putpixel／box，Nearest；透明底 PNG；衣褶／腰帶／武器邊緣／硬邊陰影加厚
- 色盤：墨黑 #1A1510／宣紙 #E8DCC8／硃紅 #C43C2C／青綠 #2F6B5A／金邊 #C9A227 + skin/wood/boot/shade/stone 家族微調
- 面向：右／¾ 右

## 解像階梯（Lemon）
- 白／綠 → **64×64**（本批）
- 藍／紫 → **96×96**
- 橙 → **128×128**
- 紅 → **256×256**
- 顯示：整數倍 Nearest；唔用柔邊放大充解像

## Heroes
- **刀客阿鐵** `hero_dao_atie_idle.png` / `hero_dao_atie_walk.png`（4f，64×64）
- **劍客阿青** `hero_jian_aqing_idle.png` / `hero_jian_aqing_walk.png`（4f，64×64）
- **槍客阿長** `hero_qiang_achang_idle.png` / `hero_qiang_achang_walk.png`（4f，64×64）
- **棍僧大力** `hero_gun_dali_idle.png` / `hero_gun_dali_walk.png`（4f，64×64）
- **暗衛阿針** `hero_anqi_azhen_idle.png` / `hero_anqi_azhen_walk.png`（4f，64×64）
- **拳師阿牛** `hero_quan_aniu_idle.png` / `hero_quan_aniu_walk.png`（4f，64×64）

## Monsters
- **狼** `monster_wolf_idle.png` / `monster_wolf_attack.png`（64×64）
- **野豬** `monster_boar_idle.png` / `monster_boar_attack.png`（64×64）
- **山賊** `monster_bandit_idle.png` / `monster_bandit_attack.png`（64×64）

## 相對舊 48 加厚重點
- 臉 16×14、軀幹衣褶豎／橫線、金腰帶扣＋綠稀有珠
- 靴底雙硬邊；武器刃口／中脊／護手／穗珠
- 怪：肋褶、鬃刺、獠牙層次、破刀缺口

## 自檢
- hero_dao_atie_idle: 64×64 px=1634 palette_ok=True
- hero_dao_atie_walk: 4f 256×64 px=6604
- hero_jian_aqing_idle: 64×64 px=1497 palette_ok=True
- hero_jian_aqing_walk: 4f 256×64 px=6000
- hero_qiang_achang_idle: 64×64 px=1589 palette_ok=True
- hero_qiang_achang_walk: 4f 256×64 px=6310
- hero_gun_dali_idle: 64×64 px=1572 palette_ok=True
- hero_gun_dali_walk: 4f 256×64 px=6256
- hero_anqi_azhen_idle: 64×64 px=1584 palette_ok=True
- hero_anqi_azhen_walk: 4f 256×64 px=6300
- hero_quan_aniu_idle: 64×64 px=1655 palette_ok=True
- hero_quan_aniu_walk: 4f 256×64 px=6676
- monster_wolf_idle: 64×64 px=1365 palette_ok=True
- monster_wolf_attack: px=1444
- monster_boar_idle: 64×64 px=1516 palette_ok=True
- monster_boar_attack: px=1572
- monster_bandit_idle: 64×64 px=1385 palette_ok=True
- monster_bandit_attack: px=1389

腳本：`tools/gen_p1_sprites_64.py`
預覽：`assets/art/_preview/p1_roster64_x3.png`、`p1_roster_x4.png`
