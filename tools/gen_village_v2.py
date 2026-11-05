#!/usr/bin/env python3
"""墨點俠村 村景 v2 — 全新高質分層（唔綁舊簡稿／唔抄獵魔村資產）

- 960×540 分層：ground／hills／pad／fg + composed
- 可建空地：中央大片平坦地皮紋，唔再畫死六固定槽
- 建築 128×128 硬陰影微調
- 硬邊、Nearest、ART.md 色盤家族

重生：python3 tools/gen_village_v2.py
"""
from __future__ import annotations

import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace/modian-xiacun")
ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_village_hd"

# —— 色盤（主五色 + 家族微調）——
INK = (0x1A, 0x15, 0x10, 255)
PAPER = (0xE8, 0xDC, 0xC8, 255)
VERMILION = (0xC4, 0x3C, 0x2C, 255)
TEAL = (0x2F, 0x6B, 0x5A, 255)
GOLD = (0xC9, 0xA2, 0x27, 255)

INK_SOFT = (0x2E, 0x26, 0x1C, 255)
INK_MID = (0x3A, 0x30, 0x24, 255)
WOOD = (0x6B, 0x4A, 0x2E, 255)
WOOD_LT = (0x8A, 0x64, 0x3C, 255)
WOOD_DK = (0x4A, 0x32, 0x1E, 255)
PAPER_DK = (0xD4, 0xC4, 0xA8, 255)
PAPER_SH = (0xC8, 0xB8, 0x98, 255)
CREAM = (0xF2, 0xEA, 0xD8, 255)
TEAL_LT = (0x3E, 0x85, 0x70, 255)
TEAL_DK = (0x1E, 0x4A, 0x3E, 255)
VERM_DK = (0x8A, 0x28, 0x1C, 255)
VERM_LT = (0xD8, 0x58, 0x42, 255)
GOLD_DK = (0x9A, 0x78, 0x18, 255)
GOLD_LT = (0xE0, 0xC0, 0x48, 255)
DIRT = (0x7A, 0x5A, 0x3A, 255)
DIRT_DK = (0x5A, 0x42, 0x28, 255)
DIRT_LT = (0x9A, 0x78, 0x52, 255)
STONE = (0x8A, 0x7E, 0x6A, 255)
STONE_DK = (0x5A, 0x52, 0x44, 255)
STONE_LT = (0xA8, 0x9C, 0x88, 255)
GRASS = (0x4A, 0x6E, 0x48, 255)
GRASS_LT = (0x5E, 0x82, 0x58, 255)
GRASS_DK = (0x36, 0x52, 0x34, 255)
SKY = (0xC8, 0xD4, 0xC8, 255)
SKY_DK = (0xA8, 0xB8, 0xB0, 255)
HILL = (0x3A, 0x5A, 0x4A, 255)
HILL_MID = (0x4A, 0x6A, 0x58, 255)
HILL_FAR = (0x6A, 0x82, 0x72, 255)
LEAF = (0x8A, 0x6A, 0x2E, 255)  # fallen leaf (wood/gold family)
PACK = (0x9A, 0x88, 0x68, 255)  # packed earth (stone/dirt family)
PACK_LT = (0xB0, 0x9E, 0x7A, 255)
PACK_DK = (0x7A, 0x6A, 0x4E, 255)
TRANS = (0, 0, 0, 0)

PALETTE = {
    "ink": INK, "paper": PAPER, "vermilion": VERMILION, "teal": TEAL, "gold": GOLD,
    "ink_soft": INK_SOFT, "ink_mid": INK_MID,
    "wood": WOOD, "wood_lt": WOOD_LT, "wood_dk": WOOD_DK,
    "paper_dk": PAPER_DK, "paper_sh": PAPER_SH, "cream": CREAM,
    "teal_lt": TEAL_LT, "teal_dk": TEAL_DK,
    "verm_dk": VERM_DK, "verm_lt": VERM_LT,
    "gold_dk": GOLD_DK, "gold_lt": GOLD_LT,
    "dirt": DIRT, "dirt_dk": DIRT_DK, "dirt_lt": DIRT_LT,
    "stone": STONE, "stone_dk": STONE_DK, "stone_lt": STONE_LT,
    "grass": GRASS, "grass_lt": GRASS_LT, "grass_dk": GRASS_DK,
    "sky": SKY, "sky_dk": SKY_DK,
    "hill": HILL, "hill_mid": HILL_MID, "hill_far": HILL_FAR,
    "leaf": LEAF, "pack": PACK, "pack_lt": PACK_LT, "pack_dk": PACK_DK,
}

VW, VH = 960, 540
HORIZON = 198
ICON = 128

# Preview-only placement (free-place gameplay; anchors are illustrative)
PREVIEW_SLOTS = {
    "manor": (480, 236),
    "inn": (250, 300),
    "forge": (710, 300),
    "clinic": (200, 400),
    "training": (760, 400),
    "bounty": (480, 380),
}


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), TRANS)


def rect(draw, x0, y0, x1, y1, c) -> None:
    draw.rectangle([x0, y0, x1, y1], fill=c)


def hline(draw, x0, x1, y, c) -> None:
    draw.line([(x0, y), (x1, y)], fill=c)


def vline(draw, x, y0, y1, c) -> None:
    draw.line([(x, y0), (x, y1)], fill=c)


def hard_border(draw, x0, y0, x1, y1, c=INK) -> None:
    hline(draw, x0, x1, y0, c)
    hline(draw, x0, x1, y1, c)
    vline(draw, x0, y0, y1, c)
    vline(draw, x1, y0, y1, c)


def put(pix, w, h, x, y, c) -> None:
    if 0 <= x < w and 0 <= y < h:
        pix[x, y] = c


def dither_dot(img: Image.Image, x0, y0, x1, y1, c, dens=0.12, seed=7) -> None:
    pix = img.load()
    n = seed
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                n = (n * 1103515245 + 12345 + x * 17 + y * 31) & 0x7FFFFFFF
                if (n % 1000) < int(dens * 1000):
                    pix[x, y] = c


def hash2(x: int, y: int, s: int = 0) -> int:
    return (x * 374761393 + y * 668265263 + s * 1274126177) & 0x7FFFFFFF


# ===================== GROUND v2 =====================

def gen_village_ground() -> Image.Image:
    """Dense grass / stone path / mud / leaves + clear central buildable plateau."""
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # --- base grass with micro variance ---
    for y in range(HORIZON, VH):
        for x in range(VW):
            n = hash2(x, y, 3)
            band = (y // 3) % 5
            base = [GRASS, GRASS_LT, GRASS, GRASS_DK, GRASS][band]
            r = n % 100
            if r < 12:
                pix[x, y] = GRASS_LT
            elif r > 88:
                pix[x, y] = GRASS_DK
            elif r < 18:
                pix[x, y] = TEAL if (x + y) % 3 else TEAL_DK
            else:
                pix[x, y] = base

    # --- central buildable plateau (packed earth, large + clear) ---
    # Ellipse-ish plateau covering most mid-village: ~x 140..820, y 230..500
    for y in range(220, VH - 30):
        for x in range(120, 840):
            # soft hard-edge ellipse (no AA): inside = pack, rim = dirt
            nx = (x - 480) / 340.0
            ny = (y - 370) / 150.0
            rr = nx * nx + ny * ny
            if rr <= 1.0:
                n = hash2(x, y, 11) % 100
                if rr > 0.88:
                    # rim dirt ring (readable edge of buildable zone)
                    pix[x, y] = DIRT if n < 55 else DIRT_DK
                elif rr > 0.72:
                    pix[x, y] = PACK_DK if n < 40 else DIRT_LT
                else:
                    # flat pack with subtle brick-ish grit
                    if (x % 6 == 0) or (y % 5 == 0):
                        pix[x, y] = PACK_DK if ((x // 6) + (y // 5)) % 2 else PACK
                    elif n < 8:
                        pix[x, y] = PACK_LT
                    elif n > 93:
                        pix[x, y] = DIRT
                    else:
                        pix[x, y] = PACK

    # plateau corner stakes (very subtle markers, not slots)
    for sx, sy in [(160, 250), (800, 250), (160, 480), (800, 480)]:
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                if abs(dx) == 2 or abs(dy) == 2:
                    put(pix, VW, VH, sx + dx, sy + dy, INK_SOFT)
                else:
                    put(pix, VW, VH, sx + dx, sy + dy, GOLD_DK)

    # --- winding stone path (not binding layout; just village feel) ---
    path_pts = []
    for i in range(100):
        t = i / 99
        y = 205 + int(t * 300)
        x = 480 + int(28 * math.sin(t * math.pi * 2.4) + 10 * math.sin(t * math.pi * 5))
        path_pts.append((x, y))

    for i, (cx, cy) in enumerate(path_pts):
        half = 18 + (i // 20)
        for dy in range(-4, 5):
            for dx in range(-half, half + 1):
                x, y = cx + dx, cy + dy
                if not (0 <= x < VW and HORIZON <= y < VH):
                    continue
                # keep path readable even over plateau
                bx, by = x // 5, y // 4
                mortar = (x % 5 == 0) or (y % 4 == 0)
                if mortar:
                    pix[x, y] = INK_MID if (bx + by) % 2 == 0 else INK_SOFT
                else:
                    tile = (bx + by * 3) % 4
                    pix[x, y] = [STONE, STONE_LT, STONE, STONE_DK][tile]
                if (y % 4 == 1) and (x % 5 not in (0, 4)):
                    if pix[x, y][:3] in (STONE[:3], STONE_DK[:3]):
                        pix[x, y] = STONE_LT

    # dirt shoulders
    for i, (cx, cy) in enumerate(path_pts):
        half = 18 + (i // 20)
        for side in (-1, 1):
            for dy in range(-2, 3):
                for dx in range(0, 6):
                    x = cx + side * (half + dx)
                    y = cy + dy
                    if 0 <= x < VW and HORIZON <= y < VH:
                        # don't erase plateau core too aggressively
                        nx = (x - 480) / 340.0
                        ny = (y - 370) / 150.0
                        if nx * nx + ny * ny < 0.55:
                            continue
                        pix[x, y] = DIRT if dx < 3 else DIRT_LT

    # --- mud / dirt patches outside plateau ---
    muds = [
        (70, 340, 22), (95, 470, 18), (50, 280, 14),
        (890, 330, 24), (910, 480, 20), (860, 260, 12),
        (300, 520, 16), (660, 520, 16), (480, 520, 14),
        (140, 520, 12), (820, 520, 12),
    ]
    for cx, cy, r in muds:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy * 2 < r * r:
                    x, y = cx + dx, cy + dy
                    if HORIZON <= y < VH and 0 <= x < VW:
                        t = (dx + dy + hash2(x, y, 5)) % 3
                        pix[x, y] = [DIRT, DIRT_DK, DIRT_LT][t]

    # --- grass tufts (readable clusters, denser near edges) ---
    tufts = []
    for i in range(48):
        # edge-biased
        if i % 2 == 0:
            gx = 30 + (i * 37) % 140
        else:
            gx = 820 + (i * 41) % 120
        gy = 240 + (i * 53) % 280
        tufts.append((gx, gy))
    # a few mid-side tufts (avoid plateau core)
    tufts += [
        (180, 260), (200, 500), (760, 260), (780, 500),
        (120, 400), (840, 400), (100, 320), (860, 320),
        (250, 520), (710, 520), (40, 440), (920, 440),
    ]
    for gx, gy in tufts:
        for dy in range(-5, 6):
            for dx in range(-7, 8):
                if abs(dx) + abs(dy) < 8:
                    x, y = gx + dx, gy + dy
                    if 0 <= x < VW and HORIZON <= y < VH:
                        # skip deep plateau
                        nx = (x - 480) / 340.0
                        ny = (y - 370) / 150.0
                        if nx * nx + ny * ny < 0.5:
                            continue
                        if abs(dx) + abs(dy) >= 7:
                            pix[x, y] = GRASS_DK
                        else:
                            pix[x, y] = TEAL if (dx + dy) % 2 == 0 else TEAL_DK

    # --- fallen leaf dots ---
    for i in range(120):
        lx = (hash2(i, 9, 21) % (VW - 40)) + 20
        ly = HORIZON + 20 + (hash2(i, 11, 33) % (VH - HORIZON - 40))
        nx = (lx - 480) / 340.0
        ny = (ly - 370) / 150.0
        # denser outside plateau, sparse inside
        if nx * nx + ny * ny < 0.45 and (i % 5):
            continue
        put(pix, VW, VH, lx, ly, LEAF if i % 3 else GOLD_DK)
        if i % 4 == 0:
            put(pix, VW, VH, lx + 1, ly, WOOD)

    # --- pebbles ---
    dither_dot(img, 40, HORIZON + 20, 200, VH - 10, STONE_DK, dens=0.028, seed=91)
    dither_dot(img, 760, HORIZON + 20, 920, VH - 10, STONE_DK, dens=0.028, seed=92)
    dither_dot(img, 200, 480, 760, VH - 8, STONE_LT, dens=0.012, seed=93)

    # tiny flower accents
    for fx, fy in [(95, 360), (870, 370), (130, 500), (830, 505), (60, 420), (900, 430)]:
        put(pix, VW, VH, fx, fy, VERMILION)
        put(pix, VW, VH, fx + 1, fy, VERM_LT)
        put(pix, VW, VH, fx, fy + 1, TEAL_DK)

    return img


# ===================== HILLS v2 =====================

def gen_village_hills() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # Sky hard bands
    bands = [
        (0, 28, SKY),
        (28, 48, SKY),
        (48, 68, SKY_DK),
        (68, 95, PAPER_DK),
        (95, 125, PAPER_SH),
        (125, 155, PAPER_DK),
        (155, HORIZON, PAPER_SH),
    ]
    for y0, y1, c in bands:
        rect(d, 0, y0, VW - 1, y1 - 1, c)

    # Cloud blocks
    for cx, cy, w, h in [
        (60, 22, 48, 9), (180, 16, 56, 11), (360, 26, 40, 8),
        (520, 18, 50, 10), (700, 14, 46, 11), (850, 24, 36, 9),
        (280, 36, 30, 7), (620, 34, 28, 7),
    ]:
        rect(d, cx, cy, cx + w, cy + h, CREAM)
        hard_border(d, cx, cy, cx + w, cy + h, PAPER_DK)
        # under shade strip
        hline(d, cx + 2, cx + w - 2, cy + h - 1, PAPER_SH)

    def mountain_band(base_y, peaks, color, mid_color, ridge=INK):
        pts = [(0, base_y)]
        for px_, h in peaks:
            pts.append((px_ - 55, base_y))
            pts.append((px_ - 22, base_y - h // 2))
            pts.append((px_, base_y - h))
            pts.append((px_ + 22, base_y - h // 2))
            pts.append((px_ + 55, base_y))
        pts += [(VW - 1, base_y), (VW - 1, HORIZON), (0, HORIZON)]
        d.polygon(pts, fill=color)
        for px_, h in peaks:
            d.line(
                [(px_ - 55, base_y), (px_ - 22, base_y - h // 2), (px_, base_y - h),
                 (px_ + 22, base_y - h // 2), (px_ + 55, base_y)],
                fill=ridge, width=1,
            )
            for i in range(0, h, 3):
                yy = base_y - h + i
                xx0 = px_ - max(2, 20 - i // 3)
                hline(d, xx0, px_ - 1, yy, mid_color)
            # belly shade
            rect(d, px_ - 16, base_y - h // 3, px_ + 12, base_y - 2, mid_color)
            # ink ridge ticks
            for i in range(0, h, 8):
                put(pix, VW, VH, px_ - 2, base_y - h + i, INK_SOFT)

    # Far / mid / near — more layers
    mountain_band(
        148,
        [(80, 70), (220, 95), (380, 60), (540, 100), (700, 75), (860, 55), (940, 45)],
        HILL_FAR, HILL_MID,
    )
    mountain_band(
        170,
        [(40, 50), (160, 72), (300, 48), (450, 82), (600, 58), (760, 78), (900, 50)],
        HILL_MID, HILL,
    )
    mountain_band(
        190,
        [(100, 40), (260, 55), (420, 36), (580, 60), (740, 42), (880, 50), (950, 30)],
        HILL, TEAL_DK,
    )
    # Closest foothill lip
    mountain_band(
        HORIZON - 2,
        [(60, 22), (200, 28), (360, 18), (520, 30), (680, 20), (840, 26), (940, 16)],
        TEAL_DK, INK_SOFT,
    )

    # Dense foothill trees
    for tx in range(0, VW, 10):
        by = 186 + ((tx * 7) % 10)
        h = 9 + ((tx * 3) % 10)
        for dy in range(0, h):
            w = max(1, 5 - dy // 3)
            for dx in range(-w, w + 1):
                x, y = tx + dx, by - dy
                if 0 <= x < VW and 0 <= y < VH:
                    pix[x, y] = INK if dy > h - 3 else (TEAL_DK if dx % 2 == 0 else TEAL)
        for dy in range(0, 4):
            put(pix, VW, VH, tx, by + dy, WOOD_DK)

    # texture stipple
    dither_dot(img, 0, 70, VW - 1, 150, INK_SOFT, dens=0.018, seed=71)
    dither_dot(img, 0, 100, VW - 1, 185, TEAL_DK, dens=0.014, seed=72)
    dither_dot(img, 0, 40, VW - 1, 90, PAPER_DK, dens=0.01, seed=73)

    # distant temple/pagoda silhouette hint (original, not IP)
    px, py = 620, 120
    rect(d, px - 4, py, px + 4, py + 40, INK_SOFT)
    for ry, rw in [(py + 4, 18), (py + 16, 14), (py + 28, 10)]:
        rect(d, px - rw // 2, ry, px + rw // 2, ry + 3, INK_MID)
        hard_border(d, px - rw // 2, ry, px + rw // 2, ry + 3, INK)
    rect(d, px - 2, py - 6, px + 2, py, VERM_DK)

    return img


# ===================== PAD v2 (hint only) =====================

def gen_village_buildings_pad() -> Image.Image:
    """Lightweight buildable-zone hint — NO fixed six slots.
    Sparse ground grain + optional ultra-faint dashed preview cells.
    """
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # Sparse pack grain over plateau (alpha-ish via sparse dots — still opaque palette)
    for y in range(240, 490):
        for x in range(160, 800):
            nx = (x - 480) / 300.0
            ny = (y - 365) / 130.0
            rr = nx * nx + ny * ny
            if rr > 0.95:
                continue
            n = hash2(x, y, 41) % 1000
            if n < 18:
                # faint wood-grain / pack flecks
                pix[x, y] = (*PACK_DK[:3], 255) if n < 9 else (*WOOD_DK[:3], 255)
            elif n < 28 and ((x + y) % 7 == 0):
                pix[x, y] = (*INK_SOFT[:3], 255)

    # Ultra-faint dashed preview cells (optional guide; NOT gameplay slots)
    # 3×2 ghost grid, very sparse dashes in gold_dk / ink_soft
    cell_w, cell_h = 140, 90
    origins = [
        (480 - cell_w // 2, 250),
        (250 - cell_w // 2, 310),
        (710 - cell_w // 2, 310),
        (200 - cell_w // 2, 410),
        (760 - cell_w // 2, 410),
        (480 - cell_w // 2, 390),
    ]
    for ox, oy in origins:
        # dashed border every 6 px, 2 on / 4 off
        for t in range(0, cell_w, 6):
            if (t // 6) % 2 == 0:
                put(pix, VW, VH, ox + t, oy, GOLD_DK)
                put(pix, VW, VH, ox + t, oy + cell_h, GOLD_DK)
        for t in range(0, cell_h, 6):
            if (t // 6) % 2 == 0:
                put(pix, VW, VH, ox, oy + t, GOLD_DK)
                put(pix, VW, VH, ox + cell_w, oy + t, GOLD_DK)
        # tiny center cross (preview only)
        cx, cy = ox + cell_w // 2, oy + cell_h // 2
        for dx in range(-3, 4):
            put(pix, VW, VH, cx + dx, cy, INK_SOFT)
        for dy in range(-3, 4):
            put(pix, VW, VH, cx, cy + dy, INK_SOFT)

    # Corner stamps of buildable zone
    for sx, sy in [(150, 235), (810, 235), (150, 490), (810, 490)]:
        rect(d, sx - 3, sy - 3, sx + 3, sy + 3, TEAL_DK)
        hard_border(d, sx - 3, sy - 3, sx + 3, sy + 3, INK)
        rect(d, sx - 1, sy - 1, sx + 1, sy + 1, GOLD)

    return img


# ===================== FG v2 =====================

def gen_village_fg() -> Image.Image:
    """Side trees / lanterns / bottom fence — keep central build zone clear."""
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    def tree(tx, ty, h=80):
        rect(d, tx - 5, ty - h // 2, tx + 5, ty + 24, WOOD_DK)
        hard_border(d, tx - 5, ty - h // 2, tx + 5, ty + 24, INK)
        for yy in range(ty - h // 2 + 2, ty + 22, 3):
            hline(d, tx - 4, tx + 4, yy, WOOD)
            if (yy // 3) % 2 == 0:
                put(pix, VW, VH, tx - 2, yy + 1, WOOD_LT)
        layers = [
            (-24, -h // 2, 28), (16, -h // 2 - 8, 26), (-6, -h // 2 - 26, 24),
            (-16, -h // 2 - 12, 20), (12, -h // 2 - 18, 18), (0, -h // 2 - 36, 16),
        ]
        for i, (ox, oy, r) in enumerate(layers):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if abs(dx) + abs(dy) < r:
                        x, y = tx + ox + dx, ty + oy + dy
                        if 0 <= x < VW and 0 <= y < VH:
                            pix[x, y] = [TEAL, TEAL_DK, TEAL_LT, TEAL, GRASS_DK][(dx + dy + i) % 5]
            for a in range(0, 360, 12):
                x = tx + ox + int(r * 0.92 * math.cos(a * math.pi / 180))
                y = ty + oy + int(r * 0.92 * math.sin(a * math.pi / 180))
                put(pix, VW, VH, x, y, INK)

    # Left / right only — never into central 200..760 build strip
    tree(36, 410, 100)
    tree(22, 290, 78)
    tree(50, 500, 62)
    tree(70, 350, 55)
    tree(924, 400, 95)
    tree(940, 280, 72)
    tree(905, 490, 58)
    tree(888, 340, 50)

    # Bottom fence
    for x in range(0, VW, 11):
        bx = x + 2
        rect(d, bx, VH - 42, bx + 5, VH - 2, WOOD)
        hard_border(d, bx, VH - 42, bx + 5, VH - 2, INK)
        vline(d, bx + 2, VH - 40, VH - 4, WOOD_DK)
        if x + 11 < VW:
            rect(d, bx, VH - 34, x + 11, VH - 30, WOOD_LT)
            rect(d, bx, VH - 22, x + 11, VH - 18, WOOD_LT)
            hline(d, bx, x + 11, VH - 32, WOOD_DK)
            hline(d, bx, x + 11, VH - 20, WOOD_DK)

    def lantern(lx, ly):
        vline(d, lx, ly - 36, ly - 2, INK)
        rect(d, lx - 2, ly - 38, lx + 2, ly - 36, GOLD)
        rect(d, lx - 11, ly - 2, lx + 11, ly + 24, VERMILION)
        rect(d, lx - 9, ly, lx + 9, ly + 20, VERM_LT)
        for fx in (lx - 5, lx, lx + 5):
            vline(d, fx, ly, ly + 20, VERM_DK)
        hard_border(d, lx - 11, ly - 2, lx + 11, ly + 24, INK)
        rect(d, lx - 12, ly - 6, lx + 12, ly - 2, GOLD)
        rect(d, lx - 12, ly + 24, lx + 12, ly + 28, GOLD)
        hard_border(d, lx - 12, ly - 6, lx + 12, ly - 2, GOLD_DK)
        vline(d, lx, ly + 28, ly + 38, VERM_DK)
        rect(d, lx - 2, ly + 38, lx + 2, ly + 40, VERMILION)

    lantern(68, 195)
    lantern(892, 195)
    lantern(48, 255)
    lantern(912, 255)

    # Corner grass / rocks
    for gx in [16, 42, 68, 892, 918, 942]:
        for dy in range(0, 20):
            for dx in range(-11, 12):
                if abs(dx) < 11 - dy // 2:
                    x, y = gx + dx, VH - 46 - dy
                    if 0 <= x < VW and 0 <= y < VH:
                        pix[x, y] = GRASS_DK if dx % 2 == 0 else TEAL

    for rx, ry in [(110, VH - 30), (280, VH - 28), (480, VH - 30), (680, VH - 28), (850, VH - 30)]:
        rect(d, rx, ry, rx + 10, ry + 6, STONE)
        hard_border(d, rx, ry, rx + 10, ry + 6, INK)
        put(pix, VW, VH, rx + 2, ry + 1, STONE_LT)
        put(pix, VW, VH, rx + 6, ry + 3, STONE_DK)

    # Side hedge strips (not into center)
    for side_x0, side_x1 in [(0, 95), (865, 959)]:
        for y in range(220, 480, 3):
            for x in range(side_x0, side_x1):
                if hash2(x, y, 8) % 100 < 22:
                    pix[x, y] = TEAL_DK if (x + y) % 2 else GRASS_DK

    return img


# ===================== BUILDINGS 128 — shadow tweak =====================

def foot_shadow(d, x0, y0, x1, y1, ox=5, oy=5):
    """Harder, slightly larger foot shadow for readability."""
    rect(d, x0 + ox, y0 + oy, x1 + ox, y1 + oy, INK_SOFT)
    # second deeper lip
    rect(d, x0 + ox + 2, y0 + oy + 2, x1 + ox + 1, y1 + oy + 1, INK_MID)


def roof_tiles(d, x0, y0, x1, y1, c1=VERMILION, c2=VERM_DK):
    for y in range(y0, y1 + 1, 3):
        hline(d, x0, x1, y, c2 if ((y - y0) // 3) % 2 == 0 else c1)
        for x in range(x0, x1, 5):
            vline(d, x + ((y - y0) // 3) % 2 * 2, y, min(y + 2, y1), INK_SOFT)


def window_lattice(d, x0, y0, x1, y1, fill=TEAL_DK):
    rect(d, x0, y0, x1, y1, fill)
    hard_border(d, x0, y0, x1, y1, INK)
    mx = (x0 + x1) // 2
    my = (y0 + y1) // 2
    vline(d, mx, y0, y1, WOOD)
    hline(d, x0, x1, my, WOOD)
    for qx0, qy0, qx1, qy1 in [
        (x0 + 1, y0 + 1, mx - 1, my - 1),
        (mx + 1, y0 + 1, x1 - 1, my - 1),
        (x0 + 1, my + 1, mx - 1, y1 - 1),
        (mx + 1, my + 1, x1 - 1, y1 - 1),
    ]:
        if qx1 > qx0 and qy1 > qy0:
            hard_border(d, qx0, qy0, qx1, qy1, INK_SOFT)


def icon_manor() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 18, 92, 108, 116)
    rect(d, 18, 92, 108, 116, STONE)
    for xx in range(18, 108, 7):
        vline(d, xx, 92, 116, STONE_DK)
    hline(d, 18, 108, 104, INK_MID)
    hard_border(d, 18, 92, 108, 116, INK)
    rect(d, 48, 108, 78, 118, STONE_LT)
    hard_border(d, 48, 108, 78, 118, INK)
    rect(d, 26, 48, 100, 96, PAPER)
    hard_border(d, 26, 48, 100, 96, INK)
    for px in (30, 52, 72, 94):
        rect(d, px, 50, px + 5, 94, WOOD)
        hard_border(d, px, 50, px + 5, 94, INK)
        vline(d, px + 2, 52, 92, WOOD_DK)
    rect(d, 54, 64, 72, 96, WOOD_DK)
    hard_border(d, 54, 64, 72, 96, INK)
    vline(d, 63, 66, 94, INK)
    rect(d, 60, 76, 66, 82, GOLD)
    rect(d, 62, 78, 64, 80, GOLD_LT)
    window_lattice(d, 34, 62, 48, 78)
    window_lattice(d, 78, 62, 92, 78)
    d.polygon([(20, 54), (64, 22), (108, 54)], fill=VERMILION)
    d.line([(20, 54), (64, 22), (108, 54)], fill=INK)
    roof_tiles(d, 28, 40, 100, 52)
    rect(d, 22, 50, 106, 56, VERM_DK)
    hard_border(d, 22, 50, 106, 56, INK)
    rect(d, 60, 18, 68, 26, GOLD)
    hard_border(d, 60, 18, 68, 26, GOLD_DK)
    rect(d, 62, 14, 66, 18, VERMILION)
    rect(d, 14, 70, 26, 96, PAPER_DK)
    hard_border(d, 14, 70, 26, 96, INK)
    rect(d, 100, 70, 112, 96, PAPER_DK)
    hard_border(d, 100, 70, 112, 96, INK)
    return img


def icon_inn() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 22, 52, 106, 110)
    rect(d, 22, 52, 106, 110, PAPER_DK)
    hard_border(d, 22, 52, 106, 110, INK)
    hline(d, 24, 104, 78, WOOD)
    rect(d, 24, 74, 104, 82, WOOD)
    for xx in range(28, 100, 8):
        vline(d, xx, 74, 82, WOOD_DK)
    window_lattice(d, 30, 58, 44, 70, TEAL_DK)
    window_lattice(d, 56, 58, 70, 70, TEAL_DK)
    window_lattice(d, 82, 58, 96, 70, TEAL_DK)
    d.polygon([(16, 58), (64, 28), (112, 58)], fill=WOOD)
    d.line([(16, 58), (64, 28), (112, 58)], fill=INK)
    roof_tiles(d, 28, 44, 100, 56, WOOD_LT, WOOD_DK)
    rect(d, 18, 54, 110, 60, WOOD_DK)
    hard_border(d, 18, 54, 110, 60, INK)
    rect(d, 96, 34, 118, 70, VERMILION)
    hard_border(d, 96, 34, 118, 70, INK)
    rect(d, 100, 40, 114, 46, CREAM)
    rect(d, 100, 50, 114, 56, CREAM)
    rect(d, 100, 60, 114, 64, GOLD)
    vline(d, 107, 28, 34, INK)
    rect(d, 48, 84, 80, 110, VERM_LT)
    for cx in range(50, 80, 6):
        vline(d, cx, 84, 110, VERMILION)
    hard_border(d, 48, 84, 80, 110, INK)
    rect(d, 30, 88, 42, 102, VERMILION)
    hard_border(d, 30, 88, 42, 102, INK)
    rect(d, 29, 86, 43, 88, GOLD)
    return img


def icon_forge() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 20, 64, 108, 112)
    rect(d, 20, 64, 108, 112, WOOD)
    for yy in range(68, 108, 5):
        hline(d, 22, 106, yy, WOOD_DK if (yy // 5) % 2 == 0 else WOOD_LT)
    hard_border(d, 20, 64, 108, 112, INK)
    rect(d, 28, 64, 34, 112, WOOD_DK)
    rect(d, 94, 64, 100, 112, WOOD_DK)
    hard_border(d, 28, 64, 34, 112, INK)
    hard_border(d, 94, 64, 100, 112, INK)
    d.polygon([(14, 70), (64, 34), (114, 70)], fill=INK_MID)
    d.line([(14, 70), (64, 34), (114, 70)], fill=INK)
    roof_tiles(d, 30, 48, 98, 66, STONE, STONE_DK)
    rect(d, 16, 66, 112, 72, INK_SOFT)
    rect(d, 36, 76, 64, 108, INK)
    hard_border(d, 36, 76, 64, 108, INK)
    rect(d, 40, 82, 60, 104, VERM_DK)
    rect(d, 44, 88, 56, 100, VERMILION)
    rect(d, 48, 92, 52, 96, GOLD_LT)
    for sx, sy in [(42, 80), (58, 78), (50, 76), (46, 84)]:
        rect(d, sx, sy, sx + 2, sy + 2, GOLD)
    rect(d, 72, 88, 100, 100, STONE_DK)
    hard_border(d, 72, 88, 100, 100, INK)
    rect(d, 78, 78, 94, 88, STONE)
    hard_border(d, 78, 78, 94, 88, INK)
    rect(d, 82, 100, 90, 110, STONE_DK)
    hard_border(d, 82, 100, 90, 110, INK)
    hline(d, 74, 98, 90, STONE_LT)
    rect(d, 84, 74, 96, 78, INK_MID)
    rect(d, 88, 70, 92, 74, WOOD)
    for sx, sy in [(48, 56), (54, 46), (46, 40), (58, 52)]:
        rect(d, sx, sy, sx + 6, sy + 5, PAPER_SH)
        hard_border(d, sx, sy, sx + 6, sy + 5, PAPER_DK)
    return img


def icon_clinic() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 28, 56, 100, 110)
    rect(d, 28, 56, 100, 110, PAPER)
    hard_border(d, 28, 56, 100, 110, INK)
    d.polygon([(22, 62), (64, 30), (106, 62)], fill=TEAL)
    d.line([(22, 62), (64, 30), (106, 62)], fill=INK)
    roof_tiles(d, 34, 44, 94, 58, TEAL_LT, TEAL_DK)
    rect(d, 24, 58, 104, 64, TEAL_DK)
    hard_border(d, 24, 58, 104, 64, INK)
    rect(d, 52, 76, 76, 110, WOOD)
    hard_border(d, 52, 76, 76, 110, INK)
    rect(d, 60, 90, 64, 94, GOLD)
    rect(d, 34, 78, 48, 86, TEAL_LT)
    hard_border(d, 34, 78, 48, 86, INK)
    rect(d, 32, 86, 50, 104, TEAL)
    hard_border(d, 32, 86, 50, 104, INK)
    hline(d, 32, 50, 86, INK)
    rect(d, 38, 74, 44, 78, GOLD)
    hard_border(d, 38, 74, 44, 78, GOLD_DK)
    hline(d, 34, 48, 92, VERMILION)
    window_lattice(d, 80, 78, 94, 96, TEAL_DK)
    vline(d, 92, 34, 58, INK)
    rect(d, 92, 34, 114, 52, VERMILION)
    hard_border(d, 92, 34, 114, 52, INK)
    hline(d, 98, 108, 42, CREAM)
    vline(d, 103, 38, 48, CREAM)
    rect(d, 34, 104, 42, 110, TEAL_DK)
    rect(d, 44, 104, 50, 110, GRASS)
    return img


def icon_training() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 14, 80, 114, 116)
    rect(d, 14, 80, 114, 116, DIRT)
    for y in range(84, 114, 3):
        hline(d, 16, 112, y, DIRT_DK if (y // 3) % 2 == 0 else DIRT_LT)
    dither_dot(img, 16, 84, 112, 112, DIRT_DK, dens=0.08, seed=33)
    hard_border(d, 14, 80, 114, 116, INK)
    for x in (18, 36, 54, 72, 90, 106):
        rect(d, x, 62, x + 4, 84, WOOD)
        hard_border(d, x, 62, x + 4, 84, INK)
    hline(d, 18, 110, 68, WOOD_LT)
    hline(d, 18, 110, 76, WOOD_LT)
    rect(d, 52, 100, 76, 112, WOOD_DK)
    hard_border(d, 52, 100, 76, 112, INK)
    rect(d, 56, 48, 72, 100, WOOD)
    hard_border(d, 56, 48, 72, 100, INK)
    for yy in range(52, 96, 6):
        hline(d, 58, 70, yy, WOOD_DK)
    rect(d, 52, 28, 76, 50, WOOD_LT)
    hard_border(d, 52, 28, 76, 50, INK)
    rect(d, 58, 36, 62, 40, INK)
    rect(d, 66, 36, 70, 40, INK)
    rect(d, 32, 56, 56, 64, WOOD)
    hard_border(d, 32, 56, 56, 64, INK)
    rect(d, 72, 56, 96, 64, WOOD)
    hard_border(d, 72, 56, 96, 64, INK)
    for tx, ty in [(62, 58), (40, 58), (88, 58), (64, 78)]:
        rect(d, tx, ty, tx + 4, ty + 4, VERMILION)
        hard_border(d, tx, ty, tx + 4, ty + 4, VERM_DK)
    rect(d, 100, 70, 108, 100, WOOD_DK)
    hard_border(d, 100, 70, 108, 100, INK)
    vline(d, 104, 48, 70, INK)
    rect(d, 102, 44, 106, 50, STONE)
    return img


def icon_bounty() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 22, 36, 106, 116)
    rect(d, 34, 24, 44, 116, WOOD_DK)
    rect(d, 84, 24, 94, 116, WOOD_DK)
    hard_border(d, 34, 24, 44, 116, INK)
    hard_border(d, 84, 24, 94, 116, INK)
    for yy in range(28, 112, 8):
        hline(d, 36, 42, yy, WOOD)
        hline(d, 86, 92, yy, WOOD)
    rect(d, 22, 36, 106, 96, PAPER)
    hard_border(d, 22, 36, 106, 96, INK)
    hard_border(d, 26, 40, 102, 92, GOLD)
    hard_border(d, 28, 42, 100, 90, GOLD_DK)
    rect(d, 34, 48, 94, 58, VERMILION)
    hard_border(d, 34, 48, 94, 58, INK)
    for xx in range(38, 90, 6):
        vline(d, xx, 50, 56, VERM_DK)
    rect(d, 34, 62, 94, 68, INK_MID)
    hard_border(d, 34, 62, 94, 68, INK)
    rect(d, 34, 72, 80, 78, INK_SOFT)
    hard_border(d, 34, 72, 80, 78, INK)
    rect(d, 34, 82, 70, 86, PAPER_SH)
    rect(d, 86, 72, 96, 82, VERMILION)
    hard_border(d, 86, 72, 96, 82, VERM_DK)
    rect(d, 18, 20, 110, 32, WOOD)
    hard_border(d, 18, 20, 110, 32, INK)
    for xx in range(22, 106, 10):
        vline(d, xx, 22, 30, WOOD_DK)
    rect(d, 38, 24, 42, 28, GOLD)
    rect(d, 86, 24, 90, 28, GOLD)
    vline(d, 28, 96, 110, VERM_DK)
    vline(d, 100, 96, 110, VERM_DK)
    rect(d, 26, 110, 30, 114, VERMILION)
    rect(d, 98, 110, 102, 114, VERMILION)
    return img


# ===================== COMPOSE + AUDIT =====================

def compose(ground, hills, pad, fg, buildings: dict[str, Image.Image] | None = None) -> Image.Image:
    out = Image.new("RGBA", (VW, VH), PAPER)
    out.alpha_composite(hills)
    out.alpha_composite(ground)
    out.alpha_composite(pad)
    if buildings:
        for key, (cx, cy) in PREVIEW_SLOTS.items():
            b = buildings.get(key)
            if not b:
                continue
            x = cx - b.width // 2
            y = cy - b.height // 2
            out.alpha_composite(b, (x, y))
    out.alpha_composite(fg)
    return out


def audit_colors(*imgs: Image.Image) -> list[str]:
    allowed = {c[:3] for c in PALETTE.values()}
    # also allow fully transparent
    offenders: dict[tuple, int] = {}
    for im in imgs:
        pix = im.load()
        w, h = im.size
        for y in range(h):
            for x in range(w):
                p = pix[x, y]
                if p[3] == 0:
                    continue
                rgb = p[:3]
                if rgb not in allowed:
                    offenders[rgb] = offenders.get(rgb, 0) + 1
    # report top offenders
    items = sorted(offenders.items(), key=lambda kv: -kv[1])[:20]
    return [f"#{r:02X}{g:02X}{b:02X}×{n}" for (r, g, b), n in items]


def nearest_palette(rgb: tuple[int, int, int]) -> tuple[int, int, int, int]:
    best = None
    best_d = 1e18
    for c in PALETTE.values():
        d = (c[0] - rgb[0]) ** 2 + (c[1] - rgb[1]) ** 2 + (c[2] - rgb[2]) ** 2
        if d < best_d:
            best_d = d
            best = c
    return best


def clamp_to_palette(img: Image.Image) -> Image.Image:
    """Safety: snap any stray RGBA to nearest palette color (hard, no blend)."""
    pix = img.load()
    allowed = {c[:3]: c for c in PALETTE.values()}
    w, h = img.size
    for y in range(h):
        for x in range(w):
            p = pix[x, y]
            if p[3] == 0:
                continue
            if p[:3] not in allowed:
                pix[x, y] = nearest_palette(p[:3])
    return img


def main() -> None:
    TILES.mkdir(parents=True, exist_ok=True)
    BUILDINGS.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)

    print("gen ground…")
    ground = clamp_to_palette(gen_village_ground())
    print("gen hills…")
    hills = clamp_to_palette(gen_village_hills())
    print("gen pad…")
    pad = clamp_to_palette(gen_village_buildings_pad())
    print("gen fg…")
    fg = clamp_to_palette(gen_village_fg())

    print("gen buildings…")
    bmap = {
        "manor": clamp_to_palette(icon_manor()),
        "inn": clamp_to_palette(icon_inn()),
        "forge": clamp_to_palette(icon_forge()),
        "clinic": clamp_to_palette(icon_clinic()),
        "training": clamp_to_palette(icon_training()),
        "bounty": clamp_to_palette(icon_bounty()),
    }

    composed = compose(ground, hills, pad, fg, bmap)
    composed_bare = compose(ground, hills, pad, fg, None)

    # write tiles (formal overwrite)
    ground.save(TILES / "village_ground.png")
    hills.save(TILES / "village_hills.png")
    pad.save(TILES / "village_buildings_pad.png")
    fg.save(TILES / "village_fg.png")
    composed.save(TILES / "village_composed.png")

    # preview
    composed.save(PREVIEW / "village_v2_composed.png")
    composed_bare.save(PREVIEW / "village_v2_layers_only.png")
    shutil.copy(TILES / "village_composed.png", PREVIEW / "village_composed.png")

    for k, im in bmap.items():
        im.save(BUILDINGS / f"{k}.png")

    # sizes
    paths = [
        TILES / "village_ground.png",
        TILES / "village_hills.png",
        TILES / "village_buildings_pad.png",
        TILES / "village_fg.png",
        TILES / "village_composed.png",
        PREVIEW / "village_v2_composed.png",
        PREVIEW / "village_v2_layers_only.png",
    ]
    for k in bmap:
        paths.append(BUILDINGS / f"{k}.png")

    print("\n=== PATHS ===")
    for p in paths:
        im = Image.open(p)
        print(f"{p.relative_to(ROOT)}  {im.size[0]}×{im.size[1]}  {im.mode}")

    print("\n=== COLOR AUDIT (off-palette) ===")
    offs = audit_colors(ground, hills, pad, fg, *bmap.values())
    if offs:
        print("OFF:", ", ".join(offs))
    else:
        print("OK: all opaque pixels in palette family")

    print("\nformal = assets/art/tiles/ (overwritten v2)")
    print("backup = assets/art/_prev_village_hd/")
    print("DONE")


if __name__ == "__main__":
    main()
