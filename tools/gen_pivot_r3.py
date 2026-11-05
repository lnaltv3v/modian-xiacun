#!/usr/bin/env python3
"""墨點俠村 · Pivot R3（師門書院 academy）

Lemon：拉開版 R2 OK；跟紅六人 Pivot 同款高密度細緻度。
獵魔村式可讀密度；暫時放寬墨點硬邊／5 色盤；武俠題材；唔抄資產。

本輪：academy 160×160＋預覽；可選村景拉開佈局加書院。
備份舊 128 academy → assets/art/_prev_pivot_r2/buildings/

重生：python3 tools/gen_pivot_r3.py
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace/modian-xiacun")
sys.path.insert(0, str(ROOT / "tools"))

import gen_pivot_r1 as r1  # noqa: E402
import gen_pivot_r2 as r2  # noqa: E402

ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_pivot_r2"

VW, VH = r1.VW, r1.VH
ICON = r1.ICON  # 160
TRANS = r1.TRANS

C = r1.C
INK, INK2, INK3 = r1.INK, r1.INK2, r1.INK3
SHADOW = r1.SHADOW
WOOD, WOOD_LAC = r1.WOOD, r1.WOOD_LAC
WALL, WALL_SH = r1.WALL, r1.WALL_SH
ROOF_R, ROOF_SL, ROOF_BK = r1.ROOF_R, r1.ROOF_SL, r1.ROOF_BK
GOLD, IRON, FIRE = r1.GOLD, r1.IRON, r1.FIRE
TEAL, VERM, CREAM = r1.TEAL, r1.VERM, r1.CREAM
STONE, MORTAR, DIRT, PACK, PATH = r1.STONE, r1.MORTAR, r1.DIRT, r1.PACK, r1.PATH
SKY1 = r1.SKY1

HERB = r2.HERB
PAPER = r2.PAPER
JADE = r2.JADE
CLOTH_BL = r2.CLOTH_BL
CLOTH_PU = r2.CLOTH_PU
ROPE = r2.ROPE

new_img = r1.new_img
put = r1.put
blend = r1.blend
hash2 = r1.hash2
noise = r1.noise
rect = r1.rect
ellipse_shadow = r1.ellipse_shadow
fill_disk = r1.fill_disk
wood_plank_v = r1.wood_plank_v
wood_plank_h = r1.wood_plank_h
plaster_wall = r1.plaster_wall
stone_bricks = r1.stone_bricks
draw_curved_roof = r1.draw_curved_roof
lattice_window = r1.lattice_window
hanging_lantern = r1.hanging_lantern

micro_grain = r2.micro_grain
ink_outline_rect = r2.ink_outline_rect
gold_studs = r2.gold_studs
tile_dither_extra = r2.tile_dither_extra
preview_row = r2.preview_row
compose = r2.compose


# 書院專用：墨瓦／竹／書卷色
INK_TILE = [
    C("2A3038"), C("3A4450"), C("1A2028"), C("4A5460"),
    C("0E141A"), C("5A6470"), C("6A7480"),
]
BAMBOO = [C("6A8A40"), C("8AAA58"), C("4A6A28"), C("A0C068"), C("3A5020")]
SCROLL_RED = [C("8A2030"), C("A04050"), C("6A1020"), C("C06070")]


def scroll_roll(pix, w, h, cx, cy, length=18, vert=True):
    """Rolled scroll tube + trailing paper."""
    if vert:
        for y in range(cy, cy + length):
            n = noise(cx, y, 800)
            put(pix, w, h, cx, y, WOOD[int(n * 3)])
            put(pix, w, h, cx + 1, y, WOOD[2])
            put(pix, w, h, cx - 1, y, WOOD[4])
        put(pix, w, h, cx, cy - 1, GOLD[0])
        put(pix, w, h, cx, cy + length, GOLD[2])
        # dangling paper strip
        for dy in range(0, 10):
            for dx in range(0, 6):
                put(pix, w, h, cx + 3 + dx, cy + 4 + dy, PAPER[dx % 2])
            if dy % 3 == 1:
                put(pix, w, h, cx + 5, cy + 4 + dy, INK3)
    else:
        for x in range(cx, cx + length):
            n = noise(x, cy, 801)
            put(pix, w, h, x, cy, WOOD[int(n * 3)])
            put(pix, w, h, x, cy + 1, WOOD[2])
        for dy in range(0, 8):
            for dx in range(0, length - 2):
                put(pix, w, h, cx + 1 + dx, cy + 3 + dy, PAPER[0 if dy < 4 else 1])
            if dy % 2 == 0:
                put(pix, w, h, cx + length // 2, cy + 3 + dy, INK3)


def sword_on_rack(pix, w, h, hx, y0, y1, gold_guard=True):
    for y in range(y0, y1):
        put(pix, w, h, hx, y, IRON[1])
        put(pix, w, h, hx + 1, y, IRON[3])
    # tip
    put(pix, w, h, hx, y0 - 1, IRON[0])
    put(pix, w, h, hx + 1, y0 - 2, IRON[0])
    # guard
    if gold_guard:
        for dx in range(-3, 5):
            put(pix, w, h, hx + dx, y0 + (y1 - y0) // 3, GOLD[0])
            put(pix, w, h, hx + dx, y0 + (y1 - y0) // 3 + 1, GOLD[2])
    # grip wrap
    for y in range(y0 + (y1 - y0) * 2 // 3, y1 - 2):
        put(pix, w, h, hx, y, WOOD_LAC[1] if y % 2 else WOOD_LAC[0])
        put(pix, w, h, hx + 1, y, WOOD_LAC[2])
    # pommel
    put(pix, w, h, hx, y1 - 1, GOLD[1])
    put(pix, w, h, hx + 1, y1, GOLD[0])


def open_book(pix, w, h, x0, y0, x1, y1):
    mid = (x0 + x1) // 2
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            n = noise(x, y, 810)
            put(pix, w, h, x, y, PAPER[int(n * (len(PAPER) - 1))])
    # spine crease
    for y in range(y0, y1 + 1):
        put(pix, w, h, mid, y, PAPER[2])
        put(pix, w, h, mid - 1, y, INK3)
    # text lines left/right
    for ly in range(y0 + 2, y1 - 1, 3):
        for lx in range(x0 + 2, mid - 2):
            if noise(lx, ly, 811) > 0.4:
                put(pix, w, h, lx, ly, INK2 if (lx + ly) % 3 else INK)
        for lx in range(mid + 2, x1 - 1):
            if noise(lx, ly, 812) > 0.4:
                put(pix, w, h, lx, ly, INK2 if (lx + ly) % 3 else INK)
    ink_outline_rect(pix, w, h, x0, y0, x1, y1, WOOD[6])


def bamboo_clump(pix, w, h, bx, y0, y1, seed=820):
    for i, ox in enumerate((-2, 2, 6, 0)):
        for y in range(y0, y1 + 1):
            n = noise(bx + ox, y, seed + i)
            c = BAMBOO[int(n * 3)]
            if (y - y0) % 9 == 0:
                c = BAMBOO[2]
            put(pix, w, h, bx + ox, y, c)
            put(pix, w, h, bx + ox + 1, y, BAMBOO[1] if n > 0.5 else BAMBOO[3])
            put(pix, w, h, bx + ox - 1, y, BAMBOO[2])
        # leaf tuft top
        for dy in range(0, 8):
            for dx in range(-4, 5):
                if abs(dx) <= 4 - dy // 2 and noise(bx + ox + dx, y0 - dy, seed + 10) < 0.7:
                    put(pix, w, h, bx + ox + dx, y0 - dy,
                        BAMBOO[3] if (dx + dy) % 2 else BAMBOO[1])


def icon_academy() -> Image.Image:
    """師門書院 — 匾額、飛檐墨瓦、石階、書卷／劍架、燈籠、層次陰影。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 62, 12, SHADOW, 0.74)

    # courtyard packed earth + moss grit
    for y in range(128, 154):
        for x in range(10, 150):
            n = noise(x, y, 900)
            put(pix, w, h, x, y, DIRT[int(n * (len(DIRT) - 1))])
            if noise(x, y, 901) < 0.06:
                put(pix, w, h, x, y, HERB[2])
            if noise(x, y, 902) < 0.03:
                put(pix, w, h, x, y, STONE[int(n * 2)])

    # stone terrace + steps
    stone_bricks(pix, w, h, 24, 116, 136, 142, bw=8, bh=5, seed=903)
    micro_grain(pix, w, h, 24, 116, 136, 142, STONE, 0.06, 904)
    for i, (sx0, sx1, sy) in enumerate([(58, 102, 136), (62, 98, 140), (66, 94, 144), (70, 90, 148)]):
        for x in range(sx0, sx1 + 1):
            for yy in range(sy, sy + 3):
                put(pix, w, h, x, yy, STONE[(i + 1) % len(STONE)])
            put(pix, w, h, x, sy, MORTAR)
            # soft step shadow
            put(pix, w, h, x, sy + 2, blend(STONE[2], INK, 0.25))

    # soft ground contact shadow under terrace
    for y in range(142, 150):
        for x in range(28, 132):
            cur = pix[x, y]
            if cur[3]:
                pix[x, y] = blend(cur, SHADOW, 0.18 + 0.04 * ((y - 142) / 8))

    # main plaster hall body
    plaster_wall(pix, w, h, 30, 54, 130, 120, seed=905, shade_right=True)
    micro_grain(pix, w, h, 30, 54, 130, 120, WALL, 0.05, 906)
    # soft left rim light / right shade polish
    for y in range(54, 121):
        put(pix, w, h, 30, y, WALL[0])
        put(pix, w, h, 31, y, blend(WALL[1], CREAM, 0.3))
        put(pix, w, h, 129, y, WALL_SH)
        put(pix, w, h, 130, y, blend(WALL_SH, INK2, 0.3))

    # timber columns (5)
    for cx in (36, 56, 80, 104, 124):
        wood_plank_v(pix, w, h, cx - 3, 52, cx + 3, 120, seed=907 + cx)
        for y in range(52, 121):
            put(pix, w, h, cx - 4, y, INK2)
            put(pix, w, h, cx + 4, y, INK)
        # iron band + gold stud
        for by in (70, 100):
            for dx in range(-3, 4):
                put(pix, w, h, cx + dx, by, IRON[0])
                put(pix, w, h, cx + dx, by + 1, IRON[2])
            put(pix, w, h, cx, by + 1, GOLD[1])

    # beam under eaves + gold trim
    wood_plank_h(pix, w, h, 26, 48, 134, 56, seed=908)
    for x in range(26, 135):
        put(pix, w, h, x, 48, GOLD[2])
        put(pix, w, h, x, 56, INK)
        if x % 7 == 0:
            put(pix, w, h, x, 49, GOLD[0])
            put(pix, w, h, x, 50, GOLD[1])

    # open central door — bookshelves visible
    for y in range(72, 118):
        for x in range(66, 94):
            put(pix, w, h, x, y, WOOD[3])
    # shelf rows + book spines
    for row in range(5):
        sy = 74 + row * 8
        for x in range(68, 93):
            put(pix, w, h, x, sy, WOOD[1])
            put(pix, w, h, x, sy + 1, WOOD[6])
        for col in range(6):
            bx = 69 + col * 4
            spine = [CLOTH_BL[0], CLOTH_PU[0], VERM[2], TEAL[0], WOOD_LAC[0], JADE[0]][col]
            for yy in range(sy + 2, sy + 7):
                put(pix, w, h, bx, yy, spine)
                put(pix, w, h, bx + 1, yy, blend(spine, PAPER[0], 0.35))
                put(pix, w, h, bx + 2, yy, blend(spine, INK, 0.2))
            put(pix, w, h, bx + 1, sy + 3, GOLD[2] if col % 2 == 0 else PAPER[0])

    # door frames
    wood_plank_v(pix, w, h, 62, 70, 66, 120, seed=909)
    wood_plank_v(pix, w, h, 94, 70, 98, 120, seed=910)
    # threshold
    wood_plank_h(pix, w, h, 62, 118, 98, 122, seed=911)

    # lattice windows with warm paper panes (study light)
    lattice_window(img, 38, 68, 54, 92, pane=PAPER[1])
    lattice_window(img, 106, 68, 122, 92, pane=PAPER[1])
    # extra lattice density
    for wx0, wx1 in [(38, 54), (106, 122)]:
        for yy in range(68, 93, 4):
            for xx in range(wx0, wx1 + 1):
                put(pix, w, h, xx, yy, WOOD[1])
        for xx in range(wx0, wx1 + 1, 4):
            for yy in range(68, 93):
                put(pix, w, h, xx, yy, WOOD[0])

    # rail across porch
    for x in range(34, 126):
        put(pix, w, h, x, 108, WOOD[1])
        put(pix, w, h, x, 109, WOOD[6])
        if x % 5 == 0:
            for y in range(100, 110):
                put(pix, w, h, x, y, WOOD[0])

    # 匾額 「師門書院」 style plaque
    rect(d, 50, 56, 110, 70, WOOD_LAC[0])
    for x in range(50, 111):
        put(pix, w, h, x, 56, GOLD[0])
        put(pix, w, h, x, 57, GOLD[1])
        put(pix, w, h, x, 70, GOLD[2])
        put(pix, w, h, x, 69, GOLD[3] if x % 2 else GOLD[2])
    for y in range(56, 71):
        put(pix, w, h, 50, y, GOLD[0])
        put(pix, w, h, 110, y, GOLD[0])
        put(pix, w, h, 51, y, GOLD[2])
        put(pix, w, h, 109, y, GOLD[2])
    # four glyph blocks
    for i, xx in enumerate((56, 68, 80, 92)):
        rect(d, xx, 59, xx + 9, 67, CREAM if i % 2 == 0 else PAPER[0])
        # micro ink strokes (glyph hint)
        put(pix, w, h, xx + 2, 61, INK)
        put(pix, w, h, xx + 3, 62, INK)
        put(pix, w, h, xx + 4, 63, INK2)
        put(pix, w, h, xx + 5, 62, INK)
        put(pix, w, h, xx + 6, 61, INK)
        put(pix, w, h, xx + 4, 64, INK)
        put(pix, w, h, xx + 4, 65, INK2)
        if i == 1:
            put(pix, w, h, xx + 3, 65, VERM[0])  # seal hint
    gold_studs(pix, w, h, [(52, 58), (52, 66), (106, 58), (106, 66)])

    # hanging scrolls under eaves (left / right of plaque)
    scroll_roll(pix, w, h, 44, 58, length=22, vert=True)
    scroll_roll(pix, w, h, 116, 58, length=22, vert=True)
    # horizontal scroll on porch table later

    # sword rack right porch
    wood_plank_v(pix, w, h, 128, 78, 132, 128, seed=912)
    wood_plank_v(pix, w, h, 144, 78, 148, 128, seed=913)
    wood_plank_h(pix, w, h, 126, 84, 150, 90, seed=914)
    wood_plank_h(pix, w, h, 126, 108, 150, 114, seed=915)
    for i, hx in enumerate((130, 136, 142)):
        sword_on_rack(pix, w, h, hx, 62, 120, gold_guard=(i != 1))

    # reading desk left porch + open book + inkstone
    wood_plank_h(pix, w, h, 12, 112, 42, 118, seed=916)
    wood_plank_v(pix, w, h, 14, 118, 16, 132, seed=917)
    wood_plank_v(pix, w, h, 38, 118, 40, 132, seed=918)
    open_book(pix, w, h, 16, 104, 36, 114)
    # inkstone
    for dy in range(0, 6):
        for dx in range(0, 8):
            put(pix, w, h, 18 + dx, 116 + dy, STONE[1] if dy < 4 else STONE[0])
    put(pix, w, h, 21, 117, INK)  # ink pool
    put(pix, w, h, 22, 117, INK2)
    # brush
    for y in range(100, 116):
        put(pix, w, h, 34, y, WOOD[0])
    put(pix, w, h, 34, 99, INK)
    put(pix, w, h, 34, 98, INK2)

    # stacked scrolls on desk side
    scroll_roll(pix, w, h, 40, 100, length=12, vert=False)

    # bamboo left accent
    bamboo_clump(pix, w, h, 14, 70, 128, seed=920)

    # ink-tile curved roof (scholar black/blue-grey) with flying eaves feel
    draw_curved_roof(
        img,
        apex=(80, 12),
        left=(10, 48),
        right=(150, 48),
        base_y=54,
        cols=INK_TILE,
        eave_drop=11,
        seed=930,
    )
    tile_dither_extra(pix, w, h, 10, 12, 150, 54, INK_TILE, 931)
    # ridge beam
    for x in range(40, 120):
        put(pix, w, h, x, 14 + int(0.012 * (x - 80) ** 2), ROOF_BK[0])
        put(pix, w, h, x, 15 + int(0.012 * (x - 80) ** 2), INK)
    # ridge ornaments + chiwen hint
    for ox in (-8, -4, 0, 4, 8):
        put(pix, w, h, 80 + ox, 11, GOLD[0])
        put(pix, w, h, 80 + ox, 10, GOLD[1])
    put(pix, w, h, 80, 8, JADE[3])
    put(pix, w, h, 80, 7, GOLD[3])
    put(pix, w, h, 80, 6, VERM[0])
    # eave tip upturn (飛檐) — extra tiles at corners
    for t in range(0, 10):
        put(pix, w, h, 12 + t, 46 - t // 2, INK_TILE[1])
        put(pix, w, h, 13 + t, 45 - t // 2, INK_TILE[0])
        put(pix, w, h, 148 - t, 46 - t // 2, INK_TILE[1])
        put(pix, w, h, 147 - t, 45 - t // 2, INK_TILE[0])
        if t % 2 == 0:
            put(pix, w, h, 12 + t, 44 - t // 2, GOLD[2])
            put(pix, w, h, 148 - t, 44 - t // 2, GOLD[2])

    # hanging lanterns
    hanging_lantern(img, 58, 62)
    hanging_lantern(img, 102, 62)
    # extra porch lantern posts
    wood_plank_v(pix, w, h, 48, 100, 50, 130, seed=940)
    wood_plank_v(pix, w, h, 110, 100, 112, 130, seed=941)
    hanging_lantern(img, 49, 96)
    hanging_lantern(img, 111, 96)

    # stone lion / guardian orbs flanking steps (readable blobs)
    for cx in (52, 108):
        fill_disk(pix, w, h, cx, 130, 6, STONE, seed=942 + cx)
        put(pix, w, h, cx - 1, 127, STONE[3])
        put(pix, w, h, cx + 1, 127, STONE[3])
        put(pix, w, h, cx, 126, GOLD[2])  # forehead jewel
        # soft contact shadow
        for dx in range(-5, 6):
            put(pix, w, h, cx + dx, 136, blend(DIRT[2], SHADOW, 0.4))

    # vermilion couplet boards flanking door
    for sx in (58, 100):
        for y in range(74, 106):
            put(pix, w, h, sx, y, VERM[1])
            put(pix, w, h, sx + 1, y, VERM[0])
            put(pix, w, h, sx + 2, y, VERM[2])
            if (y - 74) % 5 == 2:
                put(pix, w, h, sx + 1, y, GOLD[1])
                put(pix, w, h, sx + 1, y + 1, PAPER[0])
        put(pix, w, h, sx, 73, GOLD[0])
        put(pix, w, h, sx + 2, 73, GOLD[0])
        put(pix, w, h, sx, 106, GOLD[2])
        put(pix, w, h, sx + 2, 106, GOLD[2])

    # fallen leaves near bamboo
    for fx, fy in [(20, 134), (24, 138), (18, 140), (28, 136)]:
        put(pix, w, h, fx, fy, HERB[3] if fx % 2 else VERM[3])

    return img


def ensure_backup():
    PREV.mkdir(parents=True, exist_ok=True)
    (PREV / "buildings").mkdir(exist_ok=True)
    src = BUILDINGS / "academy.png"
    dst = PREV / "buildings" / "academy.png"
    if src.exists():
        # always keep first (old 128) backup; if already there, also snapshot current if different size
        if not dst.exists():
            shutil.copy2(src, dst)
        else:
            try:
                old = Image.open(dst)
                cur = Image.open(src)
                if old.size != cur.size and cur.size == (128, 128):
                    shutil.copy2(src, dst)
            except Exception:
                pass


def load_building(name: str) -> Image.Image:
    p = BUILDINGS / f"{name}.png"
    if not p.exists():
        raise FileNotFoundError(p)
    im = Image.open(p).convert("RGBA")
    if im.size != (ICON, ICON):
        raise ValueError(f"{p} size {im.size}, expected {ICON}×{ICON}")
    return im


def academy_solo_preview(academy: Image.Image) -> Image.Image:
    """Single academy magnified ×2 and ×3 side by side on checker."""
    pad = 16
    a2 = academy.resize((ICON * 2, ICON * 2), Image.NEAREST)
    a3 = academy.resize((ICON * 3, ICON * 3), Image.NEAREST)
    w = pad + a2.width + pad + a3.width + pad
    h = pad + max(a2.height, a3.height) + pad
    img = Image.new("RGBA", (w, h), C("1A1814"))
    pix = img.load()
    for y in range(h):
        for x in range(w):
            if ((x // 10) + (y // 10)) % 2 == 0:
                pix[x, y] = C("2A2620")
            else:
                pix[x, y] = C("22201A")
    img.alpha_composite(a2, (pad, pad + (a3.height - a2.height) // 2))
    img.alpha_composite(a3, (pad + a2.width + pad, pad))
    return img


def main():
    ensure_backup()
    PREVIEW.mkdir(parents=True, exist_ok=True)
    BUILDINGS.mkdir(parents=True, exist_ok=True)

    print("Generating academy 160×160…")
    academy = icon_academy()
    academy.save(BUILDINGS / "academy.png")

    # load all current 160 buildings
    names = ["manor", "inn", "forge", "clinic", "training", "bounty", "warehouse", "academy"]
    buildings = {}
    for n in names:
        if n == "academy":
            buildings[n] = academy
        else:
            buildings[n] = load_building(n)

    # previews
    solo = academy_solo_preview(academy)
    solo.save(PREVIEW / "pivot_r3_academy.png")

    row_all = preview_row([(buildings[n], n) for n in names])
    row_all.save(PREVIEW / "pivot_r3_all_buildings.png")
    row_all.resize((row_all.width * 2, row_all.height * 2), Image.NEAREST).save(
        PREVIEW / "pivot_r3_all_buildings_x2.png"
    )

    # optional village compose — spaced layout + academy in free mid-plateau slot
    print("Composing village preview with academy (spaced)…")
    ground = Image.open(TILES / "village_ground.png").convert("RGBA")
    hills = Image.open(TILES / "village_hills.png").convert("RGBA")
    pad = Image.open(TILES / "village_buildings_pad.png").convert("RGBA")
    fg = Image.open(TILES / "village_fg.png").convert("RGBA")

    slots = {
        "manor": (480, 225),
        "warehouse": (100, 295),
        "forge": (860, 295),
        "inn": (140, 505),
        "training": (840, 505),
        "clinic": (340, 518),
        "bounty": (620, 518),
        "academy": (300, 360),  # mid-west plateau — 拉開空位，唔貼其他
    }
    composed = compose(ground, hills, pad, fg, buildings, slots)
    composed.save(PREVIEW / "pivot_r3_village.png")
    # also refresh composed preview alias (do NOT overwrite tiles/village_composed until confirmed)
    composed.save(PREVIEW / "village_composed.png")

    # report
    print("OK")
    p = BUILDINGS / "academy.png"
    im = Image.open(p)
    print(f"  academy: {im.size[0]}×{im.size[1]}  {p}")
    print(f"  backup:  {PREV / 'buildings' / 'academy.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r3_academy.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r3_all_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r3_village.png'}")
    for n in names:
        bp = BUILDINGS / f"{n}.png"
        bim = Image.open(bp)
        print(f"  buildings/{n}.png: {bim.size[0]}×{bim.size[1]}")
    print("重生：python3 tools/gen_pivot_r3.py")
    print("已停等確認")


if __name__ == "__main__":
    main()
