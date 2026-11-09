#!/usr/bin/env python3
"""後製開局六綠俠高密度（獵魔村 Pivot）— 只處理 starter，唔生白綠藍池。"""
from __future__ import annotations
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("/workspace/modian-xiacun/assets/art")
HEROES = ROOT / "heroes"
RAW = HEROES / "_gen_raw_lowtier"
GREEN = HEROES / "green"
PREV = ROOT / "_preview"
MANIFEST = Path("/workspace/modian-xiacun/tools/MANIFEST_lowtier_heroes.md")

sys.path.insert(0, str(Path("/workspace/modian-xiacun/tools")))
from postprocess_mhs_sprites import process_idle, process_strip  # noqa
from synth_anim_from_idle import bob_walk, bob_attack  # noqa

SIZE = 64
STARTERS = [
    ("hero_dao_atie", "刀客阿鐵", "忠厚"),
    ("hero_jian_aqing", "劍客阿青", "冷靜"),
    ("hero_qiang_achang", "槍客阿長", "豪邁"),
    ("hero_gun_dali", "棍僧大力", "慈悲"),
    ("hero_anqi_azhen", "暗衛阿針", "機敏"),
    ("hero_quan_aniu", "拳師阿牛", "直率"),
]


def frame_variance(sheet: Image.Image, size: int, n: int = 4) -> float:
    """Mean pairwise L1 between consecutive frames (opaque only). Higher = more motion."""
    arr = np.array(sheet.convert("RGBA"), dtype=np.float32)
    frames = [arr[:, i * size : (i + 1) * size] for i in range(n)]
    diffs = []
    for a, b in zip(frames, frames[1:]):
        mask = (a[:, :, 3] > 16) | (b[:, :, 3] > 16)
        if mask.sum() == 0:
            continue
        d = np.abs(a[:, :, :3] - b[:, :, :3])[mask].mean()
        diffs.append(float(d))
    return float(np.mean(diffs)) if diffs else 0.0


def save_both(stem: str, kind: str, im: Image.Image):
    """Write to heroes/ root (game path) and heroes/green/."""
    name = f"{stem}_{kind}.png"
    dst_root = HEROES / name
    dst_green = GREEN / name
    GREEN.mkdir(parents=True, exist_ok=True)
    im.save(dst_root)
    im.save(dst_green)
    return dst_root, dst_green


def process_one(stem: str):
    idle_src = RAW / f"{stem}_idle_raw.png"
    walk_src = RAW / f"{stem}_walk_raw.png"
    atk_src = RAW / f"{stem}_attack_raw.png"
    assert idle_src.exists(), idle_src
    assert walk_src.exists(), walk_src
    assert atk_src.exists(), atk_src

    idle_tmp = RAW / f"_tmp_{stem}_idle.png"
    walk_tmp = RAW / f"_tmp_{stem}_walk.png"
    atk_tmp = RAW / f"_tmp_{stem}_attack.png"

    process_idle(idle_src, idle_tmp, SIZE)
    process_strip(walk_src, walk_tmp, SIZE, n=4)
    process_strip(atk_src, atk_tmp, SIZE, n=4)

    idle = Image.open(idle_tmp).convert("RGBA")
    walk = Image.open(walk_tmp).convert("RGBA")
    atk = Image.open(atk_tmp).convert("RGBA")

    # If walk strip almost static, replace with synth from idle
    wv = frame_variance(walk, SIZE)
    notes = []
    if wv < 2.5:
        walk = bob_walk(idle, SIZE)
        notes.append(f"walk_synth(var={wv:.2f})")
    else:
        notes.append(f"walk_ai(var={wv:.2f})")

    av = frame_variance(atk, SIZE)
    if av < 2.5:
        atk = bob_attack(idle, SIZE)
        notes.append(f"atk_synth(var={av:.2f})")
    else:
        notes.append(f"atk_ai(var={av:.2f})")

    assert idle.size == (SIZE, SIZE), idle.size
    assert walk.size == (SIZE * 4, SIZE), walk.size
    assert atk.size == (SIZE * 4, SIZE), atk.size

    save_both(stem, "idle", idle)
    save_both(stem, "walk", walk)
    save_both(stem, "attack", atk)
    return notes


def make_preview():
    PREV.mkdir(parents=True, exist_ok=True)
    cell = 64
    pad = 6
    cols = 6
    # rows: idle | walk f1 | walk f3 | attack f3
    rows = 4
    W = cols * (cell + pad) + pad
    H = rows * (cell + pad) + pad + 18
    board = Image.new("RGBA", (W, H), (28, 24, 22, 255))
    draw = ImageDraw.Draw(board)
    labels = ["idle", "walk0", "walk2", "atk2"]
    for i, (stem, name, pers) in enumerate(STARTERS):
        idle = Image.open(HEROES / f"{stem}_idle.png").convert("RGBA")
        walk = Image.open(HEROES / f"{stem}_walk.png").convert("RGBA")
        atk = Image.open(HEROES / f"{stem}_attack.png").convert("RGBA")
        w0 = walk.crop((0, 0, cell, cell))
        w2 = walk.crop((cell * 2, 0, cell * 3, cell))
        a2 = atk.crop((cell * 2, 0, cell * 3, cell))
        x = pad + i * (cell + pad)
        for r, im in enumerate([idle, w0, w2, a2]):
            y = pad + r * (cell + pad)
            board.paste(im, (x, y), im)
        # tiny name under last row
        draw.text((x, H - 16), name[-2:], fill=(200, 190, 170, 255))
    out1 = PREV / "green_starter_roster_x2.png"
    # also include labeled bigger board with x2
    x2 = board.resize((board.width * 2, board.height * 2), Image.Resampling.NEAREST)
    # add row labels on x2
    d2 = ImageDraw.Draw(x2)
    for r, lab in enumerate(labels):
        d2.text((2, pad * 2 + r * (cell + pad) * 2), lab, fill=(180, 170, 150, 255))
    x2.save(out1)
    # 1x also
    board.save(PREV / "green_starter_roster.png")
    return out1


def write_manifest(notes_map: dict):
    lines = [
        "# MANIFEST — 開局六綠俠 64（獵魔村密度・Pivot）",
        "",
        "腳本：`tools/gen_lowtier_heroes_hd.py`",
        "Raw：`assets/art/heroes/_gen_raw_lowtier/`",
        "舊墨點備份：`assets/art/heroes/_prev_inkdot_green/`",
        "輸出（雙寫）：",
        "- `assets/art/heroes/hero_*_{idle,walk,attack}.png`（遊戲慣用路徑）",
        "- `assets/art/heroes/green/hero_*_{idle,walk,attack}.png`",
        "預覽：`assets/art/_preview/green_starter_roster_x2.png`",
        "",
        "## 規格",
        "- Idle：64×64 RGBA",
        "- Walk／Attack：256×64（4 幀橫 sheet）",
        "- 風格：對齊紅六人 Pivot／《獵魔村物語》高密度；唔用舊墨點簡陋風",
        "- 顯示：整數倍 Nearest",
        "",
        "## 清單",
        "| id | 名 | 個性 | idle | walk | attack | 備註 |",
        "|----|----|------|------|------|--------|------|",
    ]
    for stem, name, pers in STARTERS:
        note = "; ".join(notes_map.get(stem, []))
        lines.append(
            f"| `{stem}` | {name} | {pers} | 64×64 | 256×64 | 256×64 | {note} |"
        )
    lines += [
        "",
        "## 押後／取消",
        "- 白／綠池／藍卡池（`white/`／`green_*` 青衫／`blue/`）整批取消，唔再開 GenerateImage。",
        "- 預覽 `white_green_blue_roster_x2.png` **未做**。",
        "",
        "## 自檢",
        "- 六人 idle／walk／attack 齊；尺寸正確",
        "- 每人獨立五官／體型／武器剪影可辨",
        "",
    ]
    MANIFEST.write_text("\n".join(lines), encoding="utf-8")
    return MANIFEST


def main():
    GREEN.mkdir(parents=True, exist_ok=True)
    notes_map = {}
    for stem, name, pers in STARTERS:
        print(f"== {stem} {name}")
        notes = process_one(stem)
        notes_map[stem] = notes
        print("  ", notes)
    prev = make_preview()
    man = write_manifest(notes_map)
    print("preview", prev)
    print("manifest", man)
    # cleanup tmp
    for p in RAW.glob("_tmp_*"):
        p.unlink()


if __name__ == "__main__":
    main()
