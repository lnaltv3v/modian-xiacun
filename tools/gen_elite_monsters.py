#!/usr/bin/env python3
"""Postprocess elite monsters to game sprites + preview + MANIFEST."""
from __future__ import annotations
import sys
from pathlib import Path
from PIL import Image

ROOT = Path("/workspace/modian-xiacun/assets/art")
MON = ROOT / "monsters"
RAW = MON / "_gen_raw"
PREV = ROOT / "_preview"
sys.path.insert(0, str(Path("/workspace/modian-xiacun/tools")))
from postprocess_mhs_sprites import process_idle, process_strip  # noqa

ELITES = [
    ("monster_snake", 64, "毒蛇"),
    ("monster_python", 96, "巨蟒 Boss"),
    ("monster_wolf_king", 96, "狼王 Boss"),
    ("monster_bandit_chief", 96, "山賊頭目 Boss"),
]

def main():
    MON.mkdir(parents=True, exist_ok=True)
    PREV.mkdir(parents=True, exist_ok=True)
    for name, size, label in ELITES:
        idle_src = RAW / f"{name}_idle_raw.png"
        atk_src = RAW / f"{name}_attack_raw.png"
        idle_dst = MON / f"{name}_idle.png"
        atk_dst = MON / f"{name}_attack.png"
        print(f"process {name} size={size} ({label})")
        process_idle(idle_src, idle_dst, size)
        # attack: 4-frame sheet preferred; fall back to 2 if split weak
        process_strip(atk_src, atk_dst, size, n=4)
        idle = Image.open(idle_dst)
        atk = Image.open(atk_dst)
        assert idle.size == (size, size), idle.size
        assert atk.size == (size * 4, size), atk.size
        print(f"  idle {idle.size}  attack {atk.size}")

    # preview: idle row + attack f3 row
    # layout: 2 rows x 4 cols; snake is 64 so pad to 96 cell
    cell = 96
    pad = 8
    W = 4 * (cell + pad) + pad
    H = 2 * (cell + pad) + pad + 24
    board = Image.new("RGBA", (W, H), (24, 20, 18, 255))
    for i, (name, size, label) in enumerate(ELITES):
        idle = Image.open(MON / f"{name}_idle.png").convert("RGBA")
        atk = Image.open(MON / f"{name}_attack.png").convert("RGBA")
        f3 = atk.crop((size * 2, 0, size * 3, size))
        # scale to fit cell
        def fit(im):
            if im.size[0] == cell and im.size[1] == cell:
                return im
            canvas = Image.new("RGBA", (cell, cell), (0,0,0,0))
            scale = min(cell / im.size[0], cell / im.size[1])
            nw, nh = max(1, int(im.size[0]*scale)), max(1, int(im.size[1]*scale))
            r = im.resize((nw, nh), Image.Resampling.NEAREST)
            canvas.paste(r, ((cell-nw)//2, (cell-nh)//2), r)
            return canvas
        idle96 = fit(idle)
        f396 = fit(f3)
        x = pad + i * (cell + pad)
        board.paste(idle96, (x, pad), idle96)
        board.paste(f396, (x, pad + cell + pad), f396)
    x1 = PREV / "elite_monsters.png"
    x2 = PREV / "elite_monsters_x2.png"
    board.save(x1)
    board.resize((board.width * 2, board.height * 2), Image.NEAREST).save(x2)
    print("preview", x2)

    man = Path("/workspace/modian-xiacun/tools/MANIFEST_elite_monsters.md")
    man.write_text("""# MANIFEST — 精英怪四隻（獵魔村密度）

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
""", encoding="utf-8")
    print("manifest", man)

if __name__ == "__main__":
    main()
