#!/usr/bin/env python3
"""墨點俠村 · Pivot R2（獵魔村式高密度，對齊紅六人細緻度）

Lemon 確認新密度方向 OK；追加：建築／村景細節層次對齊紅六人
（瓦片／木紋／飾件／陰影層要夠密，唔停留簡陋色塊）。

本輪：clinic／training／bounty／warehouse 160×160＋村景再密。
保留 R1 manor／inn／forge；舊 128 簡陋檔汰換。
備份 R1 村景＋將改建築 → assets/art/_prev_pivot_r1/

重生：python3 tools/gen_pivot_r2.py
"""
from __future__ import annotations

import math
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace/modian-xiacun")
sys.path.insert(0, str(ROOT / "tools"))

import gen_pivot_r1 as r1  # noqa: E402

ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_pivot_r1"  # R1 backup — do NOT touch _prev_before_density_pivot

VW, VH = r1.VW, r1.VH
ICON = r1.ICON  # 160
HORIZON = r1.HORIZON
TRANS = r1.TRANS

# re-export palette helpers
C = r1.C
INK, INK2, INK3 = r1.INK, r1.INK2, r1.INK3
SHADOW = r1.SHADOW
WOOD, WOOD_LAC = r1.WOOD, r1.WOOD_LAC
WALL, WALL_SH = r1.WALL, r1.WALL_SH
ROOF_R, ROOF_SL, ROOF_BK = r1.ROOF_R, r1.ROOF_SL, r1.ROOF_BK
GOLD, IRON, FIRE = r1.GOLD, r1.IRON, r1.FIRE
TEAL, VERM, CREAM = r1.TEAL, r1.VERM, r1.CREAM
STONE, MORTAR, DIRT, PACK, PATH = r1.STONE, r1.MORTAR, r1.DIRT, r1.PACK, r1.PATH
GRASS = r1.GRASS
LEAF, LEAF_LT, LEAF_DK, LEAF_Y = r1.LEAF, r1.LEAF_LT, r1.LEAF_DK, r1.LEAF_Y
PINE, PINE_LT, PINE_DK = r1.PINE, r1.PINE_LT, r1.PINE_DK
HILL_FAR, HILL_MID, HILL_NEAR, HILL_EDGE = r1.HILL_FAR, r1.HILL_MID, r1.HILL_NEAR, r1.HILL_EDGE
SKY0, SKY1, SKY2, SKY3 = r1.SKY0, r1.SKY1, r1.SKY2, r1.SKY3
CLOUD, CLOUD_DK = r1.CLOUD, r1.CLOUD_DK
BANNER, BANNER_DK = r1.BANNER, r1.BANNER_DK

# extra clinic / herb / paper accents (beyond strict 5-color)
HERB = [C("3E8A48"), C("5AAA58"), C("2A6A30"), C("8AC868"), C("1A4A20"), C("A8D878")]
HERB_DRY = [C("8A7A40"), C("A09050"), C("6A5A28"), C("C0B068")]
PAPER = [C("F4E8D0"), C("E8D8B8"), C("D8C8A0"), C("FFF4DC")]
JADE = [C("3A8A6A"), C("50A888"), C("2A6A4A"), C("70C8A0"), C("1A4A32")]
CLOTH_BL = [C("3A5A8A"), C("4A6AA0"), C("2A3A5A"), C("6A8AC0")]
CLOTH_PU = [C("5A4060"), C("6A5080"), C("3A2840"), C("8A70A0")]
SAND = [C("C8B890"), C("B8A878"), C("D8C8A0"), C("A89868"), C("E8D8B0")]
ROPE = [C("8A6A38"), C("A08048"), C("6A4A28")]

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
roof_tile_band = r1.roof_tile_band
draw_curved_roof = r1.draw_curved_roof
lattice_window = r1.lattice_window
hanging_lantern = r1.hanging_lantern


# —— denser micro helpers (red-hero density) ——

def micro_grain(pix, w, h, x0, y0, x1, y1, cols, density=0.12, seed=200):
    """Scatter micro pixels for material grit (silk/wood/stone feel)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            if noise(x, y, seed) < density:
                pix[x, y] = cols[hash2(x, y, seed + 1) % len(cols)]


def ink_outline_rect(pix, w, h, x0, y0, x1, y1, col=None):
    if col is None:
        col = INK
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y0, col)
        put(pix, w, h, x, y1, col)
    for y in range(y0, y1 + 1):
        put(pix, w, h, x0, y, col)
        put(pix, w, h, x1, y, col)


def gold_studs(pix, w, h, pts):
    for x, y in pts:
        put(pix, w, h, x, y, GOLD[1])
        put(pix, w, h, x, y + 1, GOLD[2])
        put(pix, w, h, x + 1, y, GOLD[0])


def draw_crate(pix, w, h, x0, y0, x1, y1, seed=210):
    wood_plank_h(pix, w, h, x0, y0, x1, y1, seed=seed)
    ink_outline_rect(pix, w, h, x0, y0, x1, y1)
    # cross braces
    for t in range(0, max(1, x1 - x0)):
        put(pix, w, h, x0 + t, y0 + t * (y1 - y0) // max(1, x1 - x0), WOOD[6])
        put(pix, w, h, x1 - t, y0 + t * (y1 - y0) // max(1, x1 - x0), WOOD[6])
    # metal corners
    for cx, cy in [(x0, y0), (x1 - 2, y0), (x0, y1 - 2), (x1 - 2, y1 - 2)]:
        for dy in range(3):
            for dx in range(3):
                put(pix, w, h, cx + dx, cy + dy, IRON[1])


def herb_jar(pix, w, h, cx, cy, col_body):
    for dy in range(0, 14):
        for dx in range(-5, 6):
            if abs(dx) <= 5 - dy // 7:
                n = noise(cx + dx, cy + dy, 220)
                c = col_body if n > 0.4 else blend(col_body, INK2, 0.25)
                if abs(dx) > 3:
                    c = blend(c, INK, 0.2)
                put(pix, w, h, cx + dx, cy + dy, c)
    # lid
    for dx in range(-4, 5):
        put(pix, w, h, cx + dx, cy - 1, WOOD[1])
        put(pix, w, h, cx + dx, cy - 2, WOOD[0])
    put(pix, w, h, cx, cy - 3, WOOD[3])
    # label strip
    for dx in range(-3, 4):
        put(pix, w, h, cx + dx, cy + 5, PAPER[0])
        put(pix, w, h, cx + dx, cy + 6, PAPER[1])


def hanging_herb(pix, w, h, cx, cy):
    """Dried herb bundle."""
    for y in range(cy - 10, cy):
        put(pix, w, h, cx, y, ROPE[1])
    for i, (ox, oy) in enumerate([(-3, 0), (0, 2), (3, 0), (-2, 4), (2, 5), (0, 7)]):
        for dy in range(0, 8):
            for dx in range(-2, 3):
                if abs(dx) <= 2 - dy // 4:
                    put(pix, w, h, cx + ox + dx, cy + oy + dy,
                        HERB_DRY[hash2(cx + ox, cy + oy + dy, 221 + i) % len(HERB_DRY)])


def bamboo_post(pix, w, h, x, y0, y1, seed=230):
    for y in range(y0, y1 + 1):
        n = noise(x, y, seed)
        c = HERB[1] if n > 0.5 else HERB[0]
        if (y - y0) % 10 == 0:
            c = HERB[2]
        put(pix, w, h, x, y, c)
        put(pix, w, h, x + 1, y, HERB[3] if n > 0.6 else HERB[1])
        put(pix, w, h, x - 1, y, HERB[2])
        put(pix, w, h, x + 2, y, INK2)


def tile_dither_extra(pix, w, h, x0, y0, x1, y1, cols, seed=240):
    """Extra scallop / highlight pass over an existing roof region."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            # only touch roof-ish reds/slates
            if noise(x, y, seed) < 0.08:
                pix[x, y] = cols[hash2(x, y, seed + 2) % len(cols)]
            # single-pixel specular
            if ((x + y * 3) % 11) == 0 and noise(x, y, seed + 3) > 0.7:
                pix[x, y] = cols[0]


# ===================== BUILDINGS 160 (R2) =====================

def icon_clinic() -> Image.Image:
    """醫館 — 青瓦白牆、藥櫃、藥幌、掛草藥、石獅級細節密度。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 60, 11, SHADOW, 0.72)

    # packed earth + herb garden patch
    for y in range(134, 154):
        for x in range(18, 142):
            n = noise(x, y, 300)
            put(pix, w, h, x, y, DIRT[int(n * (len(DIRT) - 1))])
    # herb garden left
    for y in range(128, 148):
        for x in range(12, 40):
            n = noise(x, y, 301)
            if n < 0.55:
                put(pix, w, h, x, y, HERB[int(n * 4)])
            elif n < 0.75:
                put(pix, w, h, x, y, DIRT[1])
            else:
                put(pix, w, h, x, y, HERB_DRY[int(n * 3) % 4])
    # tiny flower dots
    for fx, fy in [(16, 132), (22, 136), (28, 130), (34, 138), (20, 142)]:
        put(pix, w, h, fx, fy, VERM[3])
        put(pix, w, h, fx + 1, fy, PAPER[0])

    # stone terrace
    stone_bricks(pix, w, h, 28, 118, 140, 144, bw=8, bh=5, seed=302)
    micro_grain(pix, w, h, 28, 118, 140, 144, STONE, 0.05, 303)
    # steps
    for i, (sx0, sx1, sy) in enumerate([(60, 100, 138), (64, 96, 142), (68, 92, 146)]):
        for x in range(sx0, sx1 + 1):
            for yy in range(sy, sy + 3):
                put(pix, w, h, x, yy, STONE[1 + i % 3])
            put(pix, w, h, x, sy, MORTAR)

    # main plaster body
    plaster_wall(pix, w, h, 32, 58, 128, 122, seed=304, shade_right=True)
    micro_grain(pix, w, h, 32, 58, 128, 122, WALL, 0.04, 305)
    # wood columns
    for cx in (38, 58, 80, 102, 122):
        wood_plank_v(pix, w, h, cx - 3, 60, cx + 3, 120, seed=306 + cx)
        for y in range(60, 121):
            put(pix, w, h, cx - 4, y, INK2)
            put(pix, w, h, cx + 4, y, INK)

    # beam + gold trim
    wood_plank_h(pix, w, h, 30, 54, 130, 62, seed=307)
    for x in range(30, 131):
        put(pix, w, h, x, 54, GOLD[2])
        put(pix, w, h, x, 62, INK)
        if x % 8 == 0:
            put(pix, w, h, x, 55, GOLD[0])

    # medicine cabinet visible through open door (dense drawers)
    for y in range(78, 118):
        for x in range(66, 94):
            put(pix, w, h, x, y, WOOD[2])
    for row in range(4):
        for col in range(3):
            dx0 = 68 + col * 8
            dy0 = 80 + row * 9
            rect(d, dx0, dy0, dx0 + 6, dy0 + 7, WOOD[1])
            ink_outline_rect(pix, w, h, dx0, dy0, dx0 + 6, dy0 + 7, WOOD[6])
            put(pix, w, h, dx0 + 3, dy0 + 4, GOLD[2])  # knob
            # label paper
            put(pix, w, h, dx0 + 2, dy0 + 2, PAPER[0])
            put(pix, w, h, dx0 + 3, dy0 + 2, PAPER[1])

    # door frames
    wood_plank_v(pix, w, h, 64, 76, 66, 120, seed=308)
    wood_plank_v(pix, w, h, 94, 76, 96, 120, seed=309)

    # lattice windows with teal panes
    lattice_window(img, 40, 72, 54, 92, pane=TEAL[2])
    lattice_window(img, 106, 72, 120, 92, pane=TEAL[2])
    # inner cross lattice extra
    for wx0, wx1 in [(40, 54), (106, 120)]:
        for yy in range(72, 93, 4):
            for xx in range(wx0, wx1 + 1):
                put(pix, w, h, xx, yy, WOOD[1])

    # hanging herbs under eaves
    hanging_herb(pix, w, h, 48, 64)
    hanging_herb(pix, w, h, 112, 64)
    hanging_herb(pix, w, h, 80, 58)

    # jars on porch
    herb_jar(pix, w, h, 44, 110, TEAL[0])
    herb_jar(pix, w, h, 54, 112, VERM[2])
    herb_jar(pix, w, h, 116, 110, JADE[0])

    # clinic signboard (teal + gold)
    rect(d, 56, 64, 104, 74, TEAL[2])
    for x in range(56, 105):
        put(pix, w, h, x, 64, GOLD[0])
        put(pix, w, h, x, 74, GOLD[2])
    for y in range(64, 75):
        put(pix, w, h, 56, y, GOLD[0])
        put(pix, w, h, 104, y, GOLD[0])
    for i, xx in enumerate((62, 72, 82, 92)):
        rect(d, xx, 66, xx + 6, 72, PAPER[0] if i % 2 == 0 else GOLD[1])

    # hanging medicine banner (left)
    for y in range(40, 100):
        put(pix, w, h, 18, y, WOOD[0])
        put(pix, w, h, 19, y, WOOD[2])
    for dy in range(0, 48):
        for dx in range(0, 18):
            c = TEAL[0] if dx < 15 else TEAL[2]
            if dy < 3 or dy > 44:
                c = GOLD[0]
            if 5 <= dx <= 12 and 8 <= dy <= 40:
                if ((dy - 8) // 7) % 2 == 0:
                    c = PAPER[0]
            put(pix, w, h, 22 + dx, 44 + dy, c)
    for dx in range(0, 18, 2):
        put(pix, w, h, 22 + dx, 92, TEAL[2])

    # teal slate roof (clinic identity)
    draw_curved_roof(
        img,
        apex=(80, 18),
        left=(16, 52),
        right=(144, 52),
        base_y=58,
        cols=[TEAL[1], TEAL[0], TEAL[3], TEAL[2], C("1E4A3E"), C("0A2A22"), TEAL[0]],
        eave_drop=10,
        seed=310,
    )
    tile_dither_extra(pix, w, h, 16, 18, 144, 58, [TEAL[3], TEAL[1], TEAL[0]], 311)
    # ridge ornaments
    for ox in (-5, 0, 5):
        put(pix, w, h, 80 + ox, 16, GOLD[0])
        put(pix, w, h, 80 + ox, 15, GOLD[1])
    put(pix, w, h, 80, 13, JADE[3])
    put(pix, w, h, 80, 12, GOLD[3])

    # lanterns
    hanging_lantern(img, 60, 68)
    hanging_lantern(img, 100, 68)

    # mortar & pestle hint on right porch
    for y in range(120, 132):
        for x in range(124, 138):
            put(pix, w, h, x, y, STONE[2])
    fill_disk(pix, w, h, 131, 122, 5, STONE, seed=312)
    put(pix, w, h, 131, 118, WOOD[0])  # pestle
    put(pix, w, h, 131, 117, WOOD[2])
    put(pix, w, h, 131, 116, WOOD[1])

    # edge polish
    for y in range(58, 122):
        put(pix, w, h, 32, y, WALL[5])
        put(pix, w, h, 128, y, WALL_SH)

    return img


def icon_training() -> Image.Image:
    """練功場 — 沙地擂台、密木亭、木人樁、兵器架、鼓、旗、圍繩（紅六人級密度）。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 64, 12, SHADOW, 0.75)

    # dense sand / packed dirt arena floor with grit
    for y in range(96, 154):
        for x in range(8, 152):
            n = noise(x, y, 400)
            n2 = noise(x // 2, y // 2, 401)
            idx = int((n * 0.55 + n2 * 0.45) * (len(SAND) - 1))
            put(pix, w, h, x, y, SAND[idx])
            if noise(x, y, 402) < 0.07:
                put(pix, w, h, x, y, DIRT[int(n * 3)])
            if noise(x, y, 4022) < 0.03:
                put(pix, w, h, x, y, STONE[int(n * 2)])

    # raised stone ring (thicker)
    for a in range(0, 360, 1):
        rad = math.radians(a)
        for rr in (50, 51, 52, 53, 54, 55):
            x = int(80 + rr * math.cos(rad) * 1.18)
            y = int(124 + rr * math.sin(rad) * 0.58)
            if 0 <= x < w and 0 <= y < h:
                c = STONE[hash2(x, y, 403) % len(STONE)]
                if rr in (50, 55):
                    c = MORTAR if (a // 6) % 2 == 0 else STONE[0]
                put(pix, w, h, x, y, c)

    # inner wood platform — denser plank grain
    for y in range(106, 142):
        for x in range(38, 122):
            nx = (x - 80) / 42.0
            ny = (y - 124) / 20.0
            if nx * nx + ny * ny > 1.0:
                continue
            n = noise(x, y // 2, 404)
            put(pix, w, h, x, y, WOOD[int(n * (len(WOOD) - 1))])
            if (y - 106) % 3 == 0:
                put(pix, w, h, x, y, WOOD[6])
            if noise(x, y, 4044) < 0.05:
                put(pix, w, h, x, y, WOOD[4])

    # back pavilion — fuller timber hall (not tiny shed)
    plaster_wall(pix, w, h, 22, 48, 110, 88, seed=440, shade_right=True)
    micro_grain(pix, w, h, 22, 48, 110, 88, WALL, 0.05, 441)
    for cx in (28, 48, 68, 88, 104):
        wood_plank_v(pix, w, h, cx - 3, 46, cx + 3, 96, seed=442 + cx)
        for y in range(46, 97):
            put(pix, w, h, cx - 4, y, INK2)
            put(pix, w, h, cx + 4, y, INK)
    wood_plank_h(pix, w, h, 20, 44, 112, 52, seed=443)
    for x in range(20, 113):
        put(pix, w, h, x, 44, GOLD[2])
        put(pix, w, h, x, 52, INK)
    # rail across pavilion front
    for x in range(30, 104):
        put(pix, w, h, x, 78, WOOD[1])
        if x % 4 == 0:
            for y in range(72, 79):
                put(pix, w, h, x, y, WOOD[0])
    # lattice windows in pavilion
    lattice_window(img, 36, 56, 50, 70)
    lattice_window(img, 74, 56, 88, 70)
    # hanging weapons inside pavilion
    for hx in (40, 58, 82):
        for y in range(54, 72):
            put(pix, w, h, hx, y, IRON[1])
            put(pix, w, h, hx + 1, y, IRON[3])
        for dx in range(-3, 4):
            put(pix, w, h, hx + dx, 58, GOLD[0])

    # curved slate roof over pavilion
    draw_curved_roof(
        img,
        apex=(66, 14),
        left=(10, 44),
        right=(122, 44),
        base_y=50,
        cols=ROOF_SL,
        eave_drop=9,
        seed=415,
    )
    tile_dither_extra(pix, w, h, 10, 14, 122, 50, ROOF_SL, 416)
    for x in range(36, 96):
        put(pix, w, h, x, 16 + int(0.015 * (x - 66) ** 2), ROOF_BK[0])
    for ox in (-4, 0, 4):
        put(pix, w, h, 66 + ox, 12, GOLD[0])
    put(pix, w, h, 66, 10, GOLD[1])

    # corner posts with gold caps + rope
    for px, py in [(32, 102), (128, 102), (24, 140), (136, 140)]:
        wood_plank_v(pix, w, h, px - 3, py - 34, px + 3, py + 8, seed=405 + px)
        for y in range(py - 34, py + 9):
            put(pix, w, h, px - 4, y, INK2)
            put(pix, w, h, px + 4, y, INK)
        for dx in range(-4, 5):
            put(pix, w, h, px + dx, py - 35, GOLD[0])
            put(pix, w, h, px + dx, py - 36, GOLD[1])
        # iron band
        for dx in range(-3, 4):
            put(pix, w, h, px + dx, py - 10, IRON[0])

    def rope_line(x0, y0, x1, y1):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for s in range(steps + 1):
            x = x0 + (x1 - x0) * s // steps
            y = y0 + (y1 - y0) * s // steps
            mid = s / steps
            sag = int(5 * math.sin(mid * math.pi))
            put(pix, w, h, x, y + sag, ROPE[1])
            put(pix, w, h, x, y + sag + 1, ROPE[0])
            if s % 4 == 0:
                put(pix, w, h, x, y + sag - 1, ROPE[2])

    rope_line(32, 82, 128, 82)
    rope_line(32, 90, 128, 90)
    rope_line(24, 122, 32, 82)
    rope_line(136, 122, 128, 82)

    # wooden dummy (dense) center-left
    wood_plank_v(pix, w, h, 56, 68, 66, 132, seed=406)
    for y in range(68, 133):
        put(pix, w, h, 55, y, INK2)
        put(pix, w, h, 67, y, INK)
    wood_plank_h(pix, w, h, 42, 86, 80, 94, seed=407)
    wood_plank_h(pix, w, h, 46, 100, 76, 106, seed=408)
    wood_plank_h(pix, w, h, 48, 114, 74, 118, seed=4081)
    # head block with grain
    for y in range(58, 74):
        for x in range(52, 70):
            n = noise(x, y, 409)
            put(pix, w, h, x, y, WOOD[int(n * 5)])
    ink_outline_rect(pix, w, h, 52, 58, 69, 73)
    put(pix, w, h, 56, 64, INK)
    put(pix, w, h, 64, 64, INK)
    put(pix, w, h, 60, 68, INK2)
    # impact marks
    for mx, my in [(50, 90), (78, 92), (48, 104)]:
        put(pix, w, h, mx, my, WOOD[4])
        put(pix, w, h, mx + 1, my, DIRT[3])

    # weapon rack right (thicker)
    wood_plank_v(pix, w, h, 116, 58, 122, 134, seed=410)
    wood_plank_v(pix, w, h, 140, 58, 146, 134, seed=411)
    wood_plank_h(pix, w, h, 114, 64, 148, 70, seed=412)
    wood_plank_h(pix, w, h, 114, 96, 148, 102, seed=413)
    wood_plank_h(pix, w, h, 114, 124, 148, 128, seed=4131)
    for i, hx in enumerate((120, 128, 136, 144)):
        for y in range(40, 110):
            c0 = IRON[1] if i % 2 == 0 else WOOD[3]
            c1 = IRON[3] if i % 2 == 0 else WOOD[1]
            put(pix, w, h, hx, y, c0)
            put(pix, w, h, hx + 1, y, c1)
        put(pix, w, h, hx, 38, IRON[0])
        put(pix, w, h, hx + 1, 37, GOLD[2])
        for dx in range(-3, 4):
            put(pix, w, h, hx + dx, 74, GOLD[0])

    # war drum left foreground
    for y in range(118, 140):
        for x in range(10, 34):
            nx = (x - 22) / 12.0
            ny = (y - 129) / 11.0
            if nx * nx + ny * ny <= 1:
                n = noise(x, y, 450)
                put(pix, w, h, x, y, WOOD_LAC[int(n * 3)])
    for x in range(12, 32):
        put(pix, w, h, x, 120, GOLD[0])
        put(pix, w, h, x, 136, GOLD[2])
    # drum skin
    for y in range(122, 134):
        for x in range(14, 30):
            if ((x - 22) / 8) ** 2 + ((y - 128) / 6) ** 2 < 1:
                put(pix, w, h, x, y, PAPER[1] if noise(x, y, 451) > 0.4 else PAPER[0])
    # drumsticks
    for y in range(110, 122):
        put(pix, w, h, 18, y, WOOD[0])
        put(pix, w, h, 28, y, WOOD[1])

    # training flags
    for bx, by, col in [(40, 28, VERM), (96, 24, TEAL)]:
        for y in range(by, by + 40):
            put(pix, w, h, bx, y, WOOD[0])
            put(pix, w, h, bx + 1, y, WOOD[2])
        for dy in range(0, 32):
            for dx in range(0, 18):
                c = col[0] if dx < 15 else col[2]
                if dy < 2 or dy > 29:
                    c = GOLD[0]
                if 4 <= dx <= 13 and 6 <= dy <= 26:
                    if ((dy - 6) // 5) % 2 == 0:
                        c = PAPER[0]
                put(pix, w, h, bx + 3 + dx, by + 2 + dy, c)
        for dx in range(0, 18, 2):
            put(pix, w, h, bx + 3 + dx, by + 34, col[2])

    # stone water basin
    for y in range(134, 148):
        for x in range(148 - 22, 148):
            put(pix, w, h, x, y, STONE[1])
    for y in range(136, 146):
        for x in range(148 - 20, 146):
            put(pix, w, h, x, y, TEAL[2] if noise(x, y, 417) > 0.3 else TEAL[1])
            if noise(x, y, 4171) < 0.1:
                put(pix, w, h, x, y, SKY1)

    # footprints + scuff marks
    for fx, fy in [(70, 134), (78, 136), (86, 133), (94, 137), (74, 140), (88, 140)]:
        put(pix, w, h, fx, fy, DIRT[3])
        put(pix, w, h, fx + 1, fy + 1, DIRT[2])

    # lanterns on pavilion
    hanging_lantern(img, 34, 52)
    hanging_lantern(img, 98, 52)

    return img


def icon_bounty() -> Image.Image:
    """懸賞榜 — 大木榜、告示紙、封印、簷頂、石台、燈籠。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 58, 11, SHADOW, 0.7)

    # stone base
    stone_bricks(pix, w, h, 30, 122, 130, 150, bw=9, bh=5, seed=500)
    micro_grain(pix, w, h, 30, 122, 130, 150, STONE, 0.06, 501)
    for i, (sx0, sx1, sy) in enumerate([(55, 105, 140), (60, 100, 144), (65, 95, 148)]):
        for x in range(sx0, sx1 + 1):
            for yy in range(sy, sy + 3):
                put(pix, w, h, x, yy, STONE[(i + 1) % len(STONE)])

    # heavy posts
    for cx in (40, 120):
        wood_plank_v(pix, w, h, cx - 5, 36, cx + 5, 128, seed=502 + cx)
        for y in range(36, 129):
            put(pix, w, h, cx - 6, y, INK2)
            put(pix, w, h, cx + 6, y, INK)
        # iron bands
        for by in (50, 80, 110):
            for dx in range(-6, 7):
                put(pix, w, h, cx + dx, by, IRON[0])
                put(pix, w, h, cx + dx, by + 1, IRON[1])
                put(pix, w, h, cx + dx, by + 2, IRON[2])

    # cross beams
    wood_plank_h(pix, w, h, 34, 40, 126, 50, seed=503)
    wood_plank_h(pix, w, h, 36, 118, 124, 126, seed=504)
    for x in range(34, 127):
        put(pix, w, h, x, 40, GOLD[2])
        put(pix, w, h, x, 50, INK)

    # main board back
    wood_plank_v(pix, w, h, 48, 52, 112, 118, seed=505)
    micro_grain(pix, w, h, 48, 52, 112, 118, WOOD, 0.08, 506)
    ink_outline_rect(pix, w, h, 48, 52, 112, 118)

    # notice papers (layered, dense)
    papers = [
        (52, 56, 74, 78, 0),
        (78, 58, 108, 82, 1),
        (54, 82, 80, 108, 2),
        (82, 84, 110, 112, 3),
        (64, 70, 96, 98, 4),  # center overlay
    ]
    for x0, y0, x1, y1, s in papers:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                n = noise(x, y, 510 + s)
                c = PAPER[int(n * (len(PAPER) - 1))]
                # aged stain
                if n < 0.08:
                    c = PAPER[2]
                put(pix, w, h, x, y, c)
        ink_outline_rect(pix, w, h, x0, y0, x1, y1, WOOD[6])
        # text lines (blocks)
        for ly in range(y0 + 4, y1 - 3, 4):
            for lx in range(x0 + 3, x1 - 2):
                if noise(lx, ly, 520 + s) > 0.35:
                    put(pix, w, h, lx, ly, INK2 if (lx + ly) % 3 else INK)
        # vermilion seal stamp
        sx = x1 - 8
        sy = y1 - 10
        for dy in range(0, 7):
            for dx in range(0, 7):
                if abs(dx - 3) + abs(dy - 3) < 5:
                    put(pix, w, h, sx + dx, sy + dy, VERM[0] if noise(sx + dx, sy + dy, 530) > 0.3 else VERM[1])
        # nail / pin
        put(pix, w, h, (x0 + x1) // 2, y0 + 1, IRON[0])
        put(pix, w, h, (x0 + x1) // 2, y0, IRON[3])

    # top plaque 「懸賞」
    rect(d, 58, 28, 102, 42, WOOD_LAC[0])
    for x in range(58, 103):
        put(pix, w, h, x, 28, GOLD[0])
        put(pix, w, h, x, 42, GOLD[2])
    for y in range(28, 43):
        put(pix, w, h, 58, y, GOLD[0])
        put(pix, w, h, 102, y, GOLD[0])
    for i, xx in enumerate((64, 76, 88)):
        rect(d, xx, 31, xx + 8, 39, CREAM if i != 1 else GOLD[1])
        # micro stroke
        put(pix, w, h, xx + 2, 33, INK)
        put(pix, w, h, xx + 5, 36, INK2)

    # small curved roof over board
    draw_curved_roof(
        img,
        apex=(80, 8),
        left=(24, 32),
        right=(136, 32),
        base_y=38,
        cols=ROOF_R,
        eave_drop=7,
        seed=540,
    )
    tile_dither_extra(pix, w, h, 24, 8, 136, 38, ROOF_R, 541)
    for ox in (-4, 0, 4):
        put(pix, w, h, 80 + ox, 7, GOLD[0])
    put(pix, w, h, 80, 5, VERM[0])
    put(pix, w, h, 80, 4, GOLD[3])

    # lanterns
    hanging_lantern(img, 48, 48)
    hanging_lantern(img, 112, 48)

    # wanted silhouette sketch on center paper (readable figure)
    for dy in range(0, 16):
        for dx in range(-4, 5):
            if abs(dx) <= 4 - dy // 6:
                put(pix, w, h, 80 + dx, 76 + dy, INK3 if dy < 4 else INK2)
    put(pix, w, h, 80, 74, INK)  # head

    # side scroll tubes
    for sx in (34, 126):
        for y in range(60, 110):
            n = noise(sx, y, 550)
            put(pix, w, h, sx, y, WOOD[int(n * 3)])
            put(pix, w, h, sx + 1, y, WOOD[2])
            put(pix, w, h, sx - 1, y, WOOD[4])
        put(pix, w, h, sx, 58, GOLD[0])
        put(pix, w, h, sx, 110, GOLD[2])

    return img


def icon_warehouse() -> Image.Image:
    """貨棧 — 木倉、貨箱堆、麻袋、簷頂、吊索、帳本台。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 62, 12, SHADOW, 0.72)

    # dirt yard
    for y in range(128, 154):
        for x in range(12, 150):
            n = noise(x, y, 600)
            put(pix, w, h, x, y, DIRT[int(n * (len(DIRT) - 1))])

    # stone foundation
    stone_bricks(pix, w, h, 20, 116, 140, 138, bw=8, bh=5, seed=601)
    micro_grain(pix, w, h, 20, 116, 140, 138, STONE, 0.05, 602)

    # main timber warehouse body (horizontal siding denser)
    for y in range(58, 120):
        for x in range(28, 132):
            n = noise(x, y // 2, 603)
            base = WOOD[int(n * (len(WOOD) - 1))]
            if (y - 58) % 5 == 0:
                base = WOOD[6]
            if noise(x, y, 604) < 0.06:
                base = WOOD[4]  # knot
            # shade right
            t = (x - 28) / 104
            if t > 0.7:
                base = blend(base, INK2, (t - 0.7) * 0.5)
            put(pix, w, h, x, y, base)
    # vertical posts
    for cx in (32, 56, 80, 104, 128):
        wood_plank_v(pix, w, h, cx - 3, 56, cx + 3, 120, seed=605 + cx)
        for y in range(56, 121):
            put(pix, w, h, cx - 4, y, INK2)
            put(pix, w, h, cx + 4, y, INK)
        # iron bolts
        for by in (70, 90, 110):
            put(pix, w, h, cx, by, IRON[1])
            put(pix, w, h, cx, by + 1, IRON[0])

    # big sliding door
    wood_plank_v(pix, w, h, 62, 78, 98, 120, seed=606)
    for y in range(78, 121):
        put(pix, w, h, 80, y, WOOD[6])
    # door metal braces
    for by in (86, 100, 114):
        for x in range(62, 99):
            put(pix, w, h, x, by, IRON[0])
            put(pix, w, h, x, by + 1, IRON[2])
    # handles
    put(pix, w, h, 74, 100, IRON[3])
    put(pix, w, h, 86, 100, IRON[3])
    gold_studs(pix, w, h, [(68, 88), (68, 108), (92, 88), (92, 108)])

    # loft window
    lattice_window(img, 70, 60, 90, 74, pane=INK3)
    # side windows
    lattice_window(img, 38, 80, 52, 98)
    lattice_window(img, 108, 80, 122, 98)

    # beam under eaves + gold
    wood_plank_h(pix, w, h, 24, 50, 136, 58, seed=607)
    for x in range(24, 137):
        put(pix, w, h, x, 50, GOLD[2])
        put(pix, w, h, x, 58, INK)

    # slate roof
    draw_curved_roof(
        img,
        apex=(80, 16),
        left=(12, 50),
        right=(148, 50),
        base_y=56,
        cols=ROOF_SL,
        eave_drop=10,
        seed=608,
    )
    tile_dither_extra(pix, w, h, 12, 16, 148, 56, ROOF_SL, 609)
    for ox in (-6, -2, 2, 6):
        put(pix, w, h, 80 + ox, 14, IRON[1])
    put(pix, w, h, 80, 11, GOLD[0])
    put(pix, w, h, 80, 10, GOLD[1])

    # hanging hoist beam + rope + hook
    wood_plank_h(pix, w, h, 100, 44, 150, 50, seed=610)
    for y in range(50, 90):
        put(pix, w, h, 140, y, ROPE[1])
        if y % 3 == 0:
            put(pix, w, h, 141, y, ROPE[0])
    # hook
    put(pix, w, h, 140, 90, IRON[0])
    put(pix, w, h, 139, 91, IRON[1])
    put(pix, w, h, 141, 91, IRON[1])
    put(pix, w, h, 138, 92, IRON[3])
    put(pix, w, h, 142, 92, IRON[3])

    # cargo crates pile (left + front)
    draw_crate(pix, w, h, 14, 108, 36, 128, seed=611)
    draw_crate(pix, w, h, 20, 96, 40, 112, seed=612)
    draw_crate(pix, w, h, 100, 112, 124, 132, seed=613)
    draw_crate(pix, w, h, 118, 104, 142, 124, seed=614)

    # sacks
    for cx, cy in [(48, 124), (56, 128), (44, 132)]:
        for dy in range(0, 12):
            for dx in range(-7, 8):
                if (dx * dx) / 49 + (dy - 6) ** 2 / 40 <= 1:
                    n = noise(cx + dx, cy + dy, 620)
                    put(pix, w, h, cx + dx, cy + dy, SAND[int(n * 3)])
        # tie
        for dx in range(-3, 4):
            put(pix, w, h, cx + dx, cy + 2, ROPE[0])

    # ledger desk right porch
    wood_plank_h(pix, w, h, 128, 118, 148, 124, seed=621)
    wood_plank_v(pix, w, h, 130, 124, 132, 136, seed=622)
    wood_plank_v(pix, w, h, 144, 124, 146, 136, seed=623)
    # open book
    for y in range(114, 120):
        for x in range(132, 146):
            put(pix, w, h, x, y, PAPER[0])
    put(pix, w, h, 139, 114, INK2)  # spine
    for ly in (116, 118):
        for lx in range(133, 138):
            put(pix, w, h, lx, ly, INK3)
        for lx in range(140, 145):
            put(pix, w, h, lx, ly, INK3)

    # warehouse plaque
    rect(d, 60, 64, 100, 74, WOOD[0])
    for x in range(60, 101):
        put(pix, w, h, x, 64, GOLD[0])
        put(pix, w, h, x, 74, GOLD[2])
    for i, xx in enumerate((66, 78, 90)):
        rect(d, xx, 66, xx + 7, 72, CREAM if i != 1 else GOLD[1])

    # lanterns
    hanging_lantern(img, 52, 66)
    hanging_lantern(img, 108, 66)

    # edge polish
    for y in range(58, 120):
        put(pix, w, h, 28, y, WOOD[6])
        put(pix, w, h, 132, y, INK2)

    return img


# ===================== DENSEN VILLAGE =====================

def gen_ground_r2() -> Image.Image:
    """R1 ground + denser grit, flowers, puddles, path wear, rim shrubs."""
    img = r1.gen_ground()
    pix = img.load()

    # extra micro grass blades
    for i in range(400):
        x = hash2(i, 1, 700) % VW
        y = HORIZON + (hash2(i, 2, 701) % (VH - HORIZON))
        if noise(x, y, 702) < 0.55:
            put(pix, VW, VH, x, y, LEAF if i % 2 == 0 else LEAF_LT)
            put(pix, VW, VH, x, y - 1, LEAF_DK if i % 3 == 0 else LEAF)

    # flower clusters near plateau rim
    for i in range(60):
        tx = 170 + (hash2(i, 3, 703) % 620)
        ty = 250 + (hash2(i, 4, 704) % 220)
        nx = (tx - 480) / 320.0
        ny = (ty - 360) / 140.0
        rr = nx * nx + ny * ny
        if 0.65 < rr < 1.1:
            cols = [VERM[3], PAPER[0], GOLD[3], CLOTH_PU[3], HERB[3]]
            for k in range(5):
                put(pix, VW, VH, tx + (k % 3) - 1, ty + (k // 3), cols[k % len(cols)])
                put(pix, VW, VH, tx, ty + 1, HERB[2])

    # shallow puddles on packed earth
    for cx, cy, r in [(420, 400, 14), (560, 370, 10), (300, 420, 8), (700, 430, 9)]:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.45) < 1:
                    x, y = cx + dx, cy + dy
                    if 0 <= x < VW and 0 <= y < VH:
                        cur = pix[x, y]
                        pix[x, y] = blend(cur, TEAL[2], 0.35)
                        if noise(x, y, 705) < 0.15:
                            pix[x, y] = blend(cur, SKY1, 0.4)

    # cart wheel ruts on path
    for i in range(80):
        t = i / 79
        y = 220 + int(t * 280)
        x = 480 + int(28 * math.sin(t * math.pi * 2.4)) - 10
        for dx in range(-2, 3):
            put(pix, VW, VH, x + dx, y, DIRT[3])
            put(pix, VW, VH, x + 18 + dx, y, DIRT[2])

    # stone pebbles scatter
    for i in range(150):
        x = 160 + (hash2(i, 5, 706) % 640)
        y = 250 + (hash2(i, 6, 707) % 230)
        if noise(x, y, 708) < 0.4:
            put(pix, VW, VH, x, y, STONE[hash2(i, 7, 709) % len(STONE)])
            put(pix, VW, VH, x + 1, y, STONE[0])

    return img


def gen_hills_r2() -> Image.Image:
    img = r1.gen_hills()
    pix = img.load()

    # extra mid-ground tree clumps
    for i in range(16):
        tx = 40 + i * 58 + (hash2(i, 0, 710) % 24)
        ty = 155 + (hash2(i, 1, 711) % 28)
        hgt = 14 + (hash2(i, 2, 712) % 16)
        for dy in range(0, hgt):
            half = max(1, 5 - dy // 4)
            for dx in range(-half, half + 1):
                put(pix, VW, VH, tx + dx, ty - dy, PINE if dx % 2 else PINE_LT)
        put(pix, VW, VH, tx, ty + 1, WOOD[4])

    # birds (tiny V)
    for bx, by in [(200, 60), (450, 40), (700, 55), (820, 35)]:
        put(pix, VW, VH, bx, by, INK2)
        put(pix, VW, VH, bx - 1, by - 1, INK3)
        put(pix, VW, VH, bx + 1, by - 1, INK3)

    # distant village smoke wisps
    for cx, cy, r in [(640, 88, 5), (648, 80, 4), (300, 120, 3)]:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r and noise(cx + dx, cy + dy, 713) < 0.6:
                    put(pix, VW, VH, cx + dx, cy + dy, blend(CLOUD_DK, SKY2, 0.5))

    # ridge rock outcrops
    for rx, ry, rr in [(180, 160, 7), (520, 148, 6), (780, 155, 8)]:
        fill_disk(pix, VW, VH, rx, ry, rr, STONE, seed=714)
        put(pix, VW, VH, rx - 2, ry - 2, STONE[3])

    return img


def gen_pad_r2() -> Image.Image:
    img = r1.gen_pad()
    pix = img.load()

    # denser grain + subtle flagstone hints inside cells
    cell_w, cell_h = 150, 96
    origins = [
        (480 - cell_w // 2, 248),
        (250 - cell_w // 2, 310),
        (710 - cell_w // 2, 310),
        (210 - cell_w // 2, 410),
        (750 - cell_w // 2, 410),
        (480 - cell_w // 2, 390),
    ]
    for ox, oy in origins:
        for y in range(oy + 4, oy + cell_h - 3):
            for x in range(ox + 4, ox + cell_w - 3):
                if noise(x, y, 720) < 0.025:
                    pix[x, y] = blend(PACK[1], STONE[2], 0.4)
                # tiny center mark
        cx, cy = ox + cell_w // 2, oy + cell_h // 2
        for dx in range(-2, 3):
            put(pix, VW, VH, cx + dx, cy, GOLD[2])
            put(pix, VW, VH, cx, cy + dx, GOLD[2])

    return img


def gen_fg_r2() -> Image.Image:
    img = r1.gen_fg()
    pix = img.load()

    # extra mid shrubs (still keep center clear)
    for sx, sy in [(95, 360), (110, 440), (850, 370), (865, 450), (75, 280), (880, 290)]:
        for dy in range(0, 28):
            for dx in range(-14, 15):
                if abs(dx) < 14 - dy // 2 and noise(sx + dx, sy - dy, 730) < 0.7:
                    put(pix, VW, VH, sx + dx, sy - dy,
                        LEAF_DK if (dx + dy) % 2 == 0 else PINE_LT)

    # fallen leaves denser near fence
    for i in range(100):
        x = hash2(i, 1, 731) % VW
        y = VH - 60 + (hash2(i, 2, 732) % 50)
        put(pix, VW, VH, x, y, LEAF_Y if i % 3 else VERM[3])

    # extra lanterns mid-side
    hanging_lantern(img, 90, 230)
    hanging_lantern(img, 870, 230)

    # bamboo clusters sides
    for bx in (25, 45, 935, 915):
        bamboo_post(pix, VW, VH, bx, 320, 420, seed=733 + bx)
        bamboo_post(pix, VW, VH, bx + 6, 340, 430, seed=734 + bx)

    # mushrooms / rocks near fence
    for mx, my in [(140, VH - 40), (820, VH - 38), (400, VH - 36)]:
        fill_disk(pix, VW, VH, mx, my, 4, STONE, seed=735)
        put(pix, VW, VH, mx, my - 3, VERM[1])
        put(pix, VW, VH, mx, my - 4, VERM[0])

    return img


def compose(ground, hills, pad, fg, buildings=None, slots=None) -> Image.Image:
    return r1.compose(ground, hills, pad, fg, buildings, slots)


def preview_row(items, bg_dark=True) -> Image.Image:
    """items: list of (Image, name)."""
    pad = 14
    n = len(items)
    w = ICON * n + pad * (n + 1)
    h = ICON + pad * 2
    img = Image.new("RGBA", (w, h), C("1A1814"))
    pix = img.load()
    for y in range(h):
        for x in range(w):
            if ((x // 8) + (y // 8)) % 2 == 0:
                pix[x, y] = C("2A2620")
            else:
                pix[x, y] = C("22201A")
    for i, (im, _name) in enumerate(items):
        x = pad + i * (ICON + pad)
        y = pad
        ellipse_shadow(img, x + ICON // 2, y + ICON - 4, 50, 10, SHADOW, 0.5)
        img.alpha_composite(im, (x, y))
    return img


def ensure_backup_r1():
    """Backup current R1 village tiles + buildings we will replace (128 leftovers)."""
    PREV.mkdir(parents=True, exist_ok=True)
    (PREV / "buildings").mkdir(exist_ok=True)
    (PREV / "tiles").mkdir(exist_ok=True)

    # backup R1 village layers once
    for name in (
        "village_ground.png", "village_hills.png", "village_buildings_pad.png",
        "village_fg.png", "village_composed.png",
    ):
        src = TILES / name
        dst = PREV / "tiles" / name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)

    # backup buildings being replaced (old 128 or any existing)
    for name in ("clinic.png", "training.png", "bounty.png", "warehouse.png"):
        src = BUILDINGS / name
        dst = PREV / "buildings" / name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)

    # also snapshot R1 manor/inn/forge for reference (do not overwrite later)
    for name in ("manor.png", "inn.png", "forge.png"):
        src = BUILDINGS / name
        dst = PREV / "buildings" / name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)


def load_r1_buildings():
    out = {}
    for name in ("manor", "inn", "forge"):
        p = BUILDINGS / f"{name}.png"
        if not p.exists():
            raise FileNotFoundError(f"R1 building missing: {p}")
        im = Image.open(p).convert("RGBA")
        if im.size != (ICON, ICON):
            raise ValueError(f"{p} size {im.size}, expected {ICON}×{ICON}")
        out[name] = im
    return out


def main():
    ensure_backup_r1()
    PREVIEW.mkdir(parents=True, exist_ok=True)
    TILES.mkdir(parents=True, exist_ok=True)
    BUILDINGS.mkdir(parents=True, exist_ok=True)

    print("Loading R1 manor/inn/forge…")
    r1b = load_r1_buildings()

    print("Generating R2 buildings 160×160 (clinic/training/bounty/warehouse)…")
    clinic = icon_clinic()
    training = icon_training()
    bounty = icon_bounty()
    warehouse = icon_warehouse()
    clinic.save(BUILDINGS / "clinic.png")
    training.save(BUILDINGS / "training.png")
    bounty.save(BUILDINGS / "bounty.png")
    warehouse.save(BUILDINGS / "warehouse.png")

    print("Generating denser village layers 960×540…")
    ground = gen_ground_r2()
    hills = gen_hills_r2()
    pad = gen_pad_r2()
    fg = gen_fg_r2()
    ground.save(TILES / "village_ground.png")
    hills.save(TILES / "village_hills.png")
    pad.save(TILES / "village_buildings_pad.png")
    fg.save(TILES / "village_fg.png")

    # 自由放置；預覽錨須拉開 — 建築散喺可建高原邊緣／角落，中央大片空
    # slots = (cx, cy) 腳底錨；compose: x=cx-w/2, y=cy-h+12（唔好圍成一團／貼埋）
    slots = {
        "manor": (480, 225),      # 北緣遠景地標
        "warehouse": (100, 295),  # 西緣上
        "forge": (860, 295),      # 東緣上
        "inn": (140, 505),        # 西南角
        "training": (840, 505),   # 東南角
        "clinic": (340, 518),     # 南緣偏左
        "bounty": (620, 518),     # 南緣偏右
    }
    buildings = {
        "manor": r1b["manor"],
        "inn": r1b["inn"],
        "forge": r1b["forge"],
        "clinic": clinic,
        "training": training,
        "bounty": bounty,
        "warehouse": warehouse,
    }
    composed = compose(ground, hills, pad, fg, buildings, slots)
    composed.save(TILES / "village_composed.png")

    # previews
    row_new = preview_row([
        (clinic, "clinic"),
        (training, "training"),
        (bounty, "bounty"),
        (warehouse, "warehouse"),
    ])
    row_new.resize((row_new.width * 2, row_new.height * 2), Image.NEAREST).save(
        PREVIEW / "pivot_r2_buildings.png"
    )

    row_all = preview_row([
        (r1b["manor"], "manor"),
        (r1b["inn"], "inn"),
        (r1b["forge"], "forge"),
        (clinic, "clinic"),
        (training, "training"),
        (bounty, "bounty"),
        (warehouse, "warehouse"),
    ])
    # all-seven may be wide — save x1 and x2
    row_all.save(PREVIEW / "pivot_r2_all_buildings.png")
    row_all.resize((row_all.width * 2, row_all.height * 2), Image.NEAREST).save(
        PREVIEW / "pivot_r2_all_buildings_x2.png"
    )

    composed.save(PREVIEW / "pivot_r2_village.png")
    composed.save(PREVIEW / "village_composed.png")

    layers_only = compose(ground, hills, pad, fg)
    layers_only.save(PREVIEW / "pivot_r2_layers_only.png")

    # size report
    print("OK")
    for name in ("clinic", "training", "bounty", "warehouse"):
        p = BUILDINGS / f"{name}.png"
        im = Image.open(p)
        print(f"  {name}: {im.size[0]}×{im.size[1]}  {p}")
    for name in ("manor", "inn", "forge"):
        p = BUILDINGS / f"{name}.png"
        im = Image.open(p)
        print(f"  {name} (R1 kept): {im.size[0]}×{im.size[1]}")
    for name in (
        "village_ground.png", "village_hills.png", "village_buildings_pad.png",
        "village_fg.png", "village_composed.png",
    ):
        p = TILES / name
        im = Image.open(p)
        print(f"  tiles/{name}: {im.size[0]}×{im.size[1]}")
    print(f"  preview: {PREVIEW / 'pivot_r2_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r2_all_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r2_village.png'}")
    print(f"  backup: {PREV}")
    print("  warehouse: core.json 已有貨棧 id；本輪出 160×160 木倉＋貨箱／麻袋／吊索")
    print("  academy: 留下一輪")
    print("重生：python3 tools/gen_pivot_r2.py")
    print("已停等預覽確認")


if __name__ == "__main__":
    main()
