# MANIFEST — 精英怪四隻（獵魔村密度）

腳本：`tools/gen_elite_monsters.py`
Raw：`assets/art/monsters/_gen_raw/`
輸出：`assets/art/monsters/`
預覽：`assets/art/_preview/elite_monsters_x2.png`

## 規格
- 風格：對齊《獵魔村物語》高密度像素；唔用舊墨點簡陋風
- Idle：正方形 RGBA
- Attack：4 幀橫向 sheet（寬＝幀尺寸×4）

## 清單
| id | 名 | idle | attack | 備註 |
|----|----|------|--------|------|
| `monster_snake` | 毒蛇 | 64×64 | 256×64 | 綠黑鱗、噴毒 |
| `monster_python` | 巨蟒 | 96×96 | 384×96 | Boss；厚身菱紋 |
| `monster_wolf_king` | 狼王 | 96×96 | 384×96 | Boss；明顯強過 `monster_wolf` |
| `monster_bandit_chief` | 山賊頭目 | 96×96 | 384×96 | Boss；明顯強過 `monster_bandit` |

## 自檢
- 尺寸正確；idle／attack 齊
- Boss 剪影／飾物明顯強過舊普通怪
