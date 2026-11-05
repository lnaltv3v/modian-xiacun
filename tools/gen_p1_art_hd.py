#!/usr/bin/env python3
"""墨點俠村 P1.1 HD — 升密度／最高質感重出
村莊分層維持 960×540；建築圖示 128×128；HUD／按鈕／資源 icon 紋理加厚。
硬邊、Nearest、嚴格色盤；唔抄獵魔村。
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace/modian-xiacun")
ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
UI = ART / "ui"
PREVIEW = ART / "_preview"

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
TRANS = (0, 0, 0, 0)

PALETTE_HEX = {
    "ink": "#1A1510",
    "paper": "#E8DCC8",
    "vermilion": "#C43C2C",
    "teal": "#2F6B5A",
    "gold": "#C9A227",
    "ink_soft": "#2E261C",
    "ink_mid": "#3A3024",
    "wood": "#6B4A2E",
    "wood_lt": "#8A643C",
    "wood_dk": "#4A321E",
    "paper_dk": "#D4C4A8",
    "paper_sh": "#C8B898",
    "cream": "#F2EAD8",
    "teal_lt": "#3E8570",
    "teal_dk": "#1E4A3E",
    "verm_dk": "#8A281C",
    "verm_lt": "#D85842",
    "gold_dk": "#9A7818",
    "gold_lt": "#E0C048",
    "dirt": "#7A5A3A",
    "dirt_dk": "#5A4228",
    "dirt_lt": "#9A7852",
    "stone": "#8A7E6A",
    "stone_dk": "#5A5244",
    "stone_lt": "#A89C88",
    "grass": "#4A6E48",
    "grass_lt": "#5E8258",
    "grass_dk": "#365234",
    "sky": "#C8D4C8",
    "sky_dk": "#A8B8B0",
    "hill": "#3A5A4A",
    "hill_mid": "#4A6A58",
    "hill_far": "#6A8272",
}

VW, VH = 960, 540
ICON = 128  # building icon size

BUILDING_SLOTS = {
    "manor": (480, 210),
    "inn": (220, 280),
    "forge": (740, 280),
    "clinic": (160, 380),
    "training": (800, 380),
    "bounty": (480, 360),
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


def dither_dot(img: Image.Image, x0, y0, x1, y1, c, dens=0.12, seed=7) -> None:
    pix = img.load()
    n = seed
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                n = (n * 1103515245 + 12345 + x * 17 + y * 31) & 0x7FFFFFFF
                if (n % 1000) < int(dens * 1000):
                    pix[x, y] = c


def put(pix, w, h, x, y, c) -> None:
    if 0 <= x < w and 0 <= y < h:
        pix[x, y] = c


# ===================== VILLAGE GROUND (HD density) =====================

def gen_village_ground() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()
    horizon = 200

    # Base grass band
    rect(d, 0, horizon, VW - 1, VH - 1, GRASS)

    # Dense grass striping + micro-noise (Fortias-readable, not throng)
    for y in range(horizon, VH):
        band = (y // 4) % 4
        base = [GRASS, GRASS_LT, GRASS, GRASS_DK][band]
        for x in range(VW):
            n = (x * 37 + y * 91 + 13) & 0xFF
            if n < 40:
                pix[x, y] = GRASS_LT if base != GRASS_LT else GRASS
            elif n > 220:
                pix[x, y] = GRASS_DK
            else:
                pix[x, y] = base
            # sparse teal blades
            if (x * 13 + y * 7) % 47 == 0:
                pix[x, y] = TEAL if (x + y) % 2 == 0 else TEAL_DK

    # Dirt patches (readable clumps)
    for cx, cy, r in [
        (60, 360, 28), (100, 480, 22), (880, 350, 26), (900, 490, 24),
        (200, 520, 18), (760, 520, 20), (40, 280, 16), (920, 260, 14),
    ]:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy * 2 < r * r:
                    x, y = cx + dx, cy + dy
                    if y >= horizon and 0 <= x < VW and 0 <= y < VH:
                        t = (dx + dy) % 3
                        pix[x, y] = [DIRT, DIRT_DK, DIRT_LT][t]

    # Stone path — denser brick seams (winding)
    path_pts = []
    for i in range(80):
        t = i / 79
        y = 210 + int(t * 310)
        x = 480 + int(22 * math.sin(t * math.pi * 2.2))
        path_pts.append((x, y))

    for i, (cx, cy) in enumerate(path_pts):
        half = 26 + (i // 12)
        for dy in range(-5, 6):
            for dx in range(-half, half + 1):
                x, y = cx + dx, cy + dy
                if not (0 <= x < VW and 0 <= y < VH and y >= horizon):
                    continue
                # brick cell 5×4 with mortar
                bx, by = x // 5, y // 4
                mortar = (x % 5 == 0) or (y % 4 == 0)
                if mortar:
                    pix[x, y] = INK_MID if (bx + by) % 2 == 0 else INK_SOFT
                else:
                    tile = (bx + by * 3) % 4
                    pix[x, y] = [STONE, STONE_LT, STONE, STONE_DK][tile]
                # highlight top of brick
                if (y % 4 == 1) and (x % 5 != 0) and (x % 5 < 4):
                    if pix[x, y][:3] in (STONE[:3], STONE_DK[:3]):
                        pix[x, y] = STONE_LT

    # Dirt shoulders along path
    for i, (cx, cy) in enumerate(path_pts):
        half = 26 + (i // 12)
        for side in (-1, 1):
            for dy in range(-3, 4):
                for dx in range(0, 8):
                    x = cx + side * (half + dx)
                    y = cy + dy
                    if 0 <= x < VW and 0 <= y < VH and y >= horizon:
                        pix[x, y] = DIRT if dx < 4 else DIRT_LT

    # Extra brick cross-seams for density
    for y in range(horizon, VH, 8):
        for x in range(420, 540):
            if pix[x, y][:3] in (STONE[:3], STONE_LT[:3], STONE_DK[:3]):
                if x % 10 == 0:
                    pix[x, y] = INK_SOFT

    # Scattered pebbles
    dither_dot(img, 80, horizon + 30, 400, VH - 10, STONE_DK, dens=0.022, seed=99)
    dither_dot(img, 560, horizon + 30, 880, VH - 10, STONE_DK, dens=0.022, seed=101)
    dither_dot(img, 80, horizon + 30, 400, VH - 10, STONE_LT, dens=0.01, seed=55)

    # Grass tufts (readable clusters)
    tufts = [
        (90, 320), (115, 335), (130, 450), (145, 465),
        (850, 340), (870, 355), (880, 470), (900, 485),
        (300, 500), (320, 510), (640, 505), (660, 515),
        (50, 400), (910, 410), (180, 300), (780, 310),
        (250, 470), (700, 480), (400, 530), (560, 530),
    ]
    for gx, gy in tufts:
        for dy in range(-4, 5):
            for dx in range(-6, 7):
                if abs(dx) + abs(dy) < 7:
                    x, y = gx + dx, gy + dy
                    if 0 <= x < VW and 0 <= y < VH and y >= horizon:
                        pix[x, y] = TEAL if (dx + dy) % 2 == 0 else TEAL_DK
                        if abs(dx) + abs(dy) == 6:
                            pix[x, y] = GRASS_DK

    # Tiny flower accents (vermilion/gold sparse)
    for fx, fy in [(110, 380), (860, 390), (310, 490), (650, 495), (200, 440), (760, 450)]:
        if 0 <= fx < VW and horizon <= fy < VH:
            pix[fx, fy] = VERMILION
            pix[fx + 1, fy] = VERM_LT
            pix[fx, fy + 1] = TEAL_DK

    return img


def gen_village_hills() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # Sky hard bands (no soft AA)
    bands = [
        (0, 35, SKY),
        (35, 55, SKY),
        (55, 75, SKY_DK),
        (75, 100, PAPER_DK),
        (100, 130, PAPER_SH),
        (130, 160, PAPER_DK),
        (160, 200, PAPER_SH),
    ]
    for y0, y1, c in bands:
        rect(d, 0, y0, VW - 1, y1 - 1, c)

    # Sparse cloud blocks (hard rectangles)
    for cx, cy, w, h in [(80, 28, 40, 8), (200, 20, 50, 10), (500, 24, 36, 8), (700, 18, 44, 10), (860, 30, 30, 8)]:
        rect(d, cx, cy, cx + w, cy + h, CREAM)
        hard_border(d, cx, cy, cx + w, cy + h, PAPER_DK)

    def mountain_band(base_y, peaks, color, mid_color, ridge=INK):
        pts = [(0, base_y)]
        for px_, h in peaks:
            pts.append((px_ - 50, base_y))
            pts.append((px_ - 20, base_y - h // 2))
            pts.append((px_, base_y - h))
            pts.append((px_ + 20, base_y - h // 2))
            pts.append((px_ + 50, base_y))
        pts.append((VW - 1, base_y))
        pts.append((VW - 1, 199))
        pts.append((0, 199))
        d.polygon(pts, fill=color)
        for px_, h in peaks:
            d.line(
                [(px_ - 50, base_y), (px_ - 20, base_y - h // 2), (px_, base_y - h),
                 (px_ + 20, base_y - h // 2), (px_ + 50, base_y)],
                fill=ridge, width=1,
            )
            # ridge shadow hatch
            for i in range(0, h, 4):
                yy = base_y - h + i
                xx0 = px_ - max(2, 18 - i // 3)
                xx1 = px_ - 2
                hline(d, xx0, xx1, yy, mid_color)
            # mid belly
            rect(d, px_ - 18, base_y - h // 3, px_ + 10, base_y - 2, mid_color)

    mountain_band(
        155,
        [(100, 75), (250, 100), (420, 65), (580, 105), (740, 80), (900, 60)],
        HILL_FAR, HILL_MID,
    )
    mountain_band(
        178,
        [(60, 55), (200, 75), (360, 50), (520, 85), (680, 60), (840, 70), (940, 45)],
        HILL_MID, HILL,
    )
    mountain_band(
        198,
        [(120, 42), (300, 58), (480, 38), (650, 62), (820, 45), (930, 35)],
        HILL, TEAL_DK,
    )

    # Dense foothill tree silhouettes
    for tx in range(0, VW, 12):
        by = 192 + ((tx * 7) % 8)
        h = 10 + ((tx * 3) % 8)
        for dy in range(0, h):
            w = max(1, 5 - dy // 3)
            for dx in range(-w, w + 1):
                x, y = tx + dx, by - dy
                if 0 <= x < VW and 0 <= y < VH:
                    pix[x, y] = INK if dy > h - 3 else TEAL_DK
        # trunk
        for dy in range(0, 4):
            put(pix, VW, VH, tx, by + dy, WOOD_DK)

    # Extra ink dots on far ridges for texture
    dither_dot(img, 0, 80, VW - 1, 160, INK_SOFT, dens=0.02, seed=77)
    dither_dot(img, 0, 100, VW - 1, 180, TEAL_DK, dens=0.015, seed=88)

    return img


def gen_village_buildings_pad() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()
    pw, ph = 120, 80

    for key, (cx, cy) in BUILDING_SLOTS.items():
        x0, y0 = cx - pw // 2, cy - ph // 2
        x1, y1 = x0 + pw - 1, y0 + ph - 1
        # hard shadow
        rect(d, x0 + 4, y0 + 4, x1 + 4, y1 + 4, INK_SOFT)
        # wood deck
        rect(d, x0, y0, x1, y1, WOOD)
        # top planks
        rect(d, x0 + 2, y0 + 2, x1 - 2, y1 - 12, PAPER_DK)
        for yy in range(y0 + 3, y1 - 12, 3):
            c = WOOD_DK if (yy // 3) % 2 == 0 else WOOD_LT
            hline(d, x0 + 3, x1 - 3, yy, c)
            # knot dots
            if (yy + hash(key)) % 9 == 0:
                kx = x0 + 10 + ((yy * 5) % (pw - 24))
                rect(d, kx, yy - 1, kx + 2, yy + 1, WOOD_DK)
        # stone footing denser
        rect(d, x0, y1 - 10, x1, y1, STONE)
        for xx in range(x0, x1, 6):
            vline(d, xx, y1 - 10, y1, STONE_DK)
            # brick horizontal
            hline(d, x0, x1, y1 - 5, INK_MID)
        for xx in range(x0 + 3, x1, 6):
            put(pix, VW, VH, xx, y1 - 7, STONE_LT)
        hard_border(d, x0, y0, x1, y1, INK)
        # gold corner markers
        for ox, oy in [(2, 2), (pw - 7, 2), (2, ph - 14), (pw - 7, ph - 14)]:
            rect(d, x0 + ox, y0 + oy, x0 + ox + 4, y0 + oy + 4, GOLD)
            hard_border(d, x0 + ox, y0 + oy, x0 + ox + 4, y0 + oy + 4, GOLD_DK)
        # center anchor
        ax, ay = cx, cy - 4
        rect(d, ax - 4, ay - 4, ax + 4, ay + 4, TEAL)
        hard_border(d, ax - 4, ay - 4, ax + 4, ay + 4, INK)
        rect(d, ax - 1, ay - 1, ax + 1, ay + 1, GOLD)
        dither_dot(img, x0 + 4, y1 - 8, x1 - 4, y1 - 2, STONE_DK, dens=0.25, seed=abs(hash(key)) % 1000)

    return img


def gen_village_fg() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    def tree(tx, ty, h=80):
        # trunk with bark lines
        rect(d, tx - 4, ty - h // 2, tx + 4, ty + 22, WOOD_DK)
        hard_border(d, tx - 4, ty - h // 2, tx + 4, ty + 22, INK)
        for yy in range(ty - h // 2 + 2, ty + 20, 4):
            hline(d, tx - 3, tx + 3, yy, WOOD)
        # layered leaf diamonds
        layers = [(-22, -h // 2, 26), (14, -h // 2 - 6, 24), (-4, -h // 2 - 22, 22),
                  (-14, -h // 2 - 10, 18), (10, -h // 2 - 16, 16)]
        for i, (ox, oy, r) in enumerate(layers):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if abs(dx) + abs(dy) < r:
                        x, y = tx + ox + dx, ty + oy + dy
                        if 0 <= x < VW and 0 <= y < VH:
                            c = [TEAL, TEAL_DK, TEAL_LT, TEAL, GRASS_DK][(dx + dy + i) % 5]
                            pix[x, y] = c
            for a in range(0, 360, 15):
                x = tx + ox + int(r * 0.92 * math.cos(a * math.pi / 180))
                y = ty + oy + int(r * 0.92 * math.sin(a * math.pi / 180))
                put(pix, VW, VH, x, y, INK)

    tree(40, 420, 95)
    tree(28, 300, 75)
    tree(55, 500, 60)
    tree(920, 400, 90)
    tree(935, 280, 70)
    tree(900, 490, 55)

    # Bottom fence denser posts + rails
    for x in range(0, VW, 12):
        bx = x + 2
        rect(d, bx, VH - 40, bx + 5, VH - 3, WOOD)
        hard_border(d, bx, VH - 40, bx + 5, VH - 3, INK)
        vline(d, bx + 2, VH - 38, VH - 5, WOOD_DK)
        if x + 12 < VW:
            rect(d, bx, VH - 32, x + 12, VH - 29, WOOD_LT)
            rect(d, bx, VH - 20, x + 12, VH - 17, WOOD_LT)
            hline(d, bx, x + 12, VH - 30, WOOD_DK)
            hline(d, bx, x + 12, VH - 18, WOOD_DK)

    def lantern(lx, ly):
        vline(d, lx, ly - 34, ly - 2, INK)
        # tassel hook
        rect(d, lx - 2, ly - 36, lx + 2, ly - 34, GOLD)
        rect(d, lx - 10, ly - 2, lx + 10, ly + 22, VERMILION)
        rect(d, lx - 8, ly, lx + 8, ly + 18, VERM_LT)
        # vertical folds
        for fx in (lx - 4, lx, lx + 4):
            vline(d, fx, ly, ly + 18, VERM_DK)
        hard_border(d, lx - 10, ly - 2, lx + 10, ly + 22, INK)
        rect(d, lx - 11, ly - 5, lx + 11, ly - 2, GOLD)
        rect(d, lx - 11, ly + 22, lx + 11, ly + 25, GOLD)
        hard_border(d, lx - 11, ly - 5, lx + 11, ly - 2, GOLD_DK)
        vline(d, lx, ly + 25, ly + 34, VERM_DK)
        rect(d, lx - 2, ly + 34, lx + 2, ly + 36, VERMILION)

    lantern(70, 200)
    lantern(890, 200)
    lantern(50, 260)
    lantern(910, 260)

    # Corner grass / rock fg
    for gx in [18, 45, 70, 890, 915, 940]:
        for dy in range(0, 18):
            for dx in range(-10, 11):
                if abs(dx) < 10 - dy // 2:
                    x, y = gx + dx, VH - 44 - dy
                    if 0 <= x < VW and 0 <= y < VH:
                        pix[x, y] = GRASS_DK if dx % 2 == 0 else TEAL

    # Small rocks at fence
    for rx, ry in [(100, VH - 28), (300, VH - 26), (600, VH - 28), (800, VH - 26)]:
        rect(d, rx, ry, rx + 8, ry + 5, STONE)
        hard_border(d, rx, ry, rx + 8, ry + 5, INK)
        put(pix, VW, VH, rx + 2, ry + 1, STONE_LT)

    return img


# ===================== BUILDING ICONS 128×128 =====================

def foot_shadow(d, x0, y0, x1, y1, ox=4, oy=4):
    rect(d, x0 + ox, y0 + oy, x1 + ox, y1 + oy, INK_SOFT)


def roof_tiles(d, x0, y0, x1, y1, c1=VERMILION, c2=VERM_DK):
    """Hard-edge tile rows on a roof band."""
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
    # inner panes
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
    # stone terrace
    rect(d, 18, 92, 108, 116, STONE)
    for xx in range(18, 108, 7):
        vline(d, xx, 92, 116, STONE_DK)
    hline(d, 18, 108, 104, INK_MID)
    hard_border(d, 18, 92, 108, 116, INK)
    # steps
    rect(d, 48, 108, 78, 118, STONE_LT)
    hard_border(d, 48, 108, 78, 118, INK)
    # main hall
    rect(d, 26, 48, 100, 96, PAPER)
    hard_border(d, 26, 48, 100, 96, INK)
    # wood pillars
    for px in (30, 52, 72, 94):
        rect(d, px, 50, px + 5, 94, WOOD)
        hard_border(d, px, 50, px + 5, 94, INK)
        vline(d, px + 2, 52, 92, WOOD_DK)
    # door
    rect(d, 54, 64, 72, 96, WOOD_DK)
    hard_border(d, 54, 64, 72, 96, INK)
    vline(d, 63, 66, 94, INK)
    rect(d, 60, 76, 66, 82, GOLD)  # knocker plate
    rect(d, 62, 78, 64, 80, GOLD_LT)
    # windows with lattice
    window_lattice(d, 34, 62, 48, 78)
    window_lattice(d, 78, 62, 92, 78)
    # eaves vermilion triangle + tiles
    d.polygon([(20, 54), (64, 22), (108, 54)], fill=VERMILION)
    d.line([(20, 54), (64, 22), (108, 54)], fill=INK)
    roof_tiles(d, 28, 40, 100, 52)
    rect(d, 22, 50, 106, 56, VERM_DK)
    hard_border(d, 22, 50, 106, 56, INK)
    # ridge ornament
    rect(d, 60, 18, 68, 26, GOLD)
    hard_border(d, 60, 18, 68, 26, GOLD_DK)
    rect(d, 62, 14, 66, 18, VERMILION)
    # side wing hints
    rect(d, 14, 70, 26, 96, PAPER_DK)
    hard_border(d, 14, 70, 26, 96, INK)
    rect(d, 100, 70, 112, 96, PAPER_DK)
    hard_border(d, 100, 70, 112, 96, INK)
    return img


def icon_inn() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 22, 52, 106, 110)
    # two-storey body
    rect(d, 22, 52, 106, 110, PAPER_DK)
    hard_border(d, 22, 52, 106, 110, INK)
    # floor split
    hline(d, 24, 104, 78, WOOD)
    rect(d, 24, 74, 104, 82, WOOD)
    for xx in range(28, 100, 8):
        vline(d, xx, 74, 82, WOOD_DK)
    # upper windows
    window_lattice(d, 30, 58, 44, 70, TEAL_DK)
    window_lattice(d, 56, 58, 70, 70, TEAL_DK)
    window_lattice(d, 82, 58, 96, 70, TEAL_DK)
    # roof
    d.polygon([(16, 58), (64, 28), (112, 58)], fill=WOOD)
    d.line([(16, 58), (64, 28), (112, 58)], fill=INK)
    roof_tiles(d, 28, 44, 100, 56, WOOD_LT, WOOD_DK)
    rect(d, 18, 54, 110, 60, WOOD_DK)
    hard_border(d, 18, 54, 110, 60, INK)
    # hanging shop sign
    rect(d, 96, 34, 118, 70, VERMILION)
    hard_border(d, 96, 34, 118, 70, INK)
    rect(d, 100, 40, 114, 46, CREAM)
    rect(d, 100, 50, 114, 56, CREAM)
    rect(d, 100, 60, 114, 64, GOLD)
    vline(d, 107, 28, 34, INK)
    # curtain door
    rect(d, 48, 84, 80, 110, VERM_LT)
    for cx in range(50, 80, 6):
        vline(d, cx, 84, 110, VERMILION)
    hard_border(d, 48, 84, 80, 110, INK)
    # lantern by door
    rect(d, 30, 88, 42, 102, VERMILION)
    hard_border(d, 30, 88, 42, 102, INK)
    rect(d, 29, 86, 43, 88, GOLD)
    return img


def icon_forge() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 20, 64, 108, 112)
    # shed
    rect(d, 20, 64, 108, 112, WOOD)
    for yy in range(68, 108, 5):
        hline(d, 22, 106, yy, WOOD_DK if (yy // 5) % 2 == 0 else WOOD_LT)
    hard_border(d, 20, 64, 108, 112, INK)
    # open front posts
    rect(d, 28, 64, 34, 112, WOOD_DK)
    rect(d, 94, 64, 100, 112, WOOD_DK)
    hard_border(d, 28, 64, 34, 112, INK)
    hard_border(d, 94, 64, 100, 112, INK)
    # roof
    d.polygon([(14, 70), (64, 34), (114, 70)], fill=INK_MID)
    d.line([(14, 70), (64, 34), (114, 70)], fill=INK)
    roof_tiles(d, 30, 48, 98, 66, STONE, STONE_DK)
    rect(d, 16, 66, 112, 72, INK_SOFT)
    # forge furnace
    rect(d, 36, 76, 64, 108, INK)
    hard_border(d, 36, 76, 64, 108, INK)
    rect(d, 40, 82, 60, 104, VERM_DK)
    rect(d, 44, 88, 56, 100, VERMILION)
    rect(d, 48, 92, 52, 96, GOLD_LT)  # fire core
    # sparks
    for sx, sy in [(42, 80), (58, 78), (50, 76), (46, 84)]:
        rect(d, sx, sy, sx + 2, sy + 2, GOLD)
    # anvil
    rect(d, 72, 88, 100, 100, STONE_DK)
    hard_border(d, 72, 88, 100, 100, INK)
    rect(d, 78, 78, 94, 88, STONE)
    hard_border(d, 78, 78, 94, 88, INK)
    rect(d, 82, 100, 90, 110, STONE_DK)
    hard_border(d, 82, 100, 90, 110, INK)
    hline(d, 74, 98, 90, STONE_LT)
    # hammer on anvil
    rect(d, 84, 74, 96, 78, INK_MID)
    rect(d, 88, 70, 92, 74, WOOD)
    # smoke puffs
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
    # teal roof (medicine)
    d.polygon([(22, 62), (64, 30), (106, 62)], fill=TEAL)
    d.line([(22, 62), (64, 30), (106, 62)], fill=INK)
    roof_tiles(d, 34, 44, 94, 58, TEAL_LT, TEAL_DK)
    rect(d, 24, 58, 104, 64, TEAL_DK)
    hard_border(d, 24, 58, 104, 64, INK)
    # door
    rect(d, 52, 76, 76, 110, WOOD)
    hard_border(d, 52, 76, 76, 110, INK)
    rect(d, 60, 90, 64, 94, GOLD)
    # herb gourd (detailed)
    rect(d, 34, 78, 48, 86, TEAL_LT)  # upper bulb
    hard_border(d, 34, 78, 48, 86, INK)
    rect(d, 32, 86, 50, 104, TEAL)
    hard_border(d, 32, 86, 50, 104, INK)
    hline(d, 32, 50, 86, INK)
    rect(d, 38, 74, 44, 78, GOLD)  # stopper
    hard_border(d, 38, 74, 44, 78, GOLD_DK)
    # gourd sash
    hline(d, 34, 48, 92, VERMILION)
    # window
    window_lattice(d, 80, 78, 94, 96, TEAL_DK)
    # medicine flag
    vline(d, 92, 34, 58, INK)
    rect(d, 92, 34, 114, 52, VERMILION)
    hard_border(d, 92, 34, 114, 52, INK)
    # 十 cross mark
    hline(d, 98, 108, 42, CREAM)
    vline(d, 103, 38, 48, CREAM)
    # side herb pots
    rect(d, 34, 104, 42, 110, TEAL_DK)
    rect(d, 44, 104, 50, 110, GRASS)
    return img


def icon_training() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 14, 80, 114, 116)
    # packed earth yard
    rect(d, 14, 80, 114, 116, DIRT)
    for y in range(84, 114, 3):
        hline(d, 16, 112, y, DIRT_DK if (y // 3) % 2 == 0 else DIRT_LT)
    dither_dot(img, 16, 84, 112, 112, DIRT_DK, dens=0.08, seed=33)
    hard_border(d, 14, 80, 114, 116, INK)
    # fence posts
    for x in (18, 36, 54, 72, 90, 106):
        rect(d, x, 62, x + 4, 84, WOOD)
        hard_border(d, x, 62, x + 4, 84, INK)
    hline(d, 18, 110, 68, WOOD_LT)
    hline(d, 18, 110, 76, WOOD_LT)
    # wooden dummy (detailed)
    # base
    rect(d, 52, 100, 76, 112, WOOD_DK)
    hard_border(d, 52, 100, 76, 112, INK)
    # torso
    rect(d, 56, 48, 72, 100, WOOD)
    hard_border(d, 56, 48, 72, 100, INK)
    for yy in range(52, 96, 6):
        hline(d, 58, 70, yy, WOOD_DK)
    # head
    rect(d, 52, 28, 76, 50, WOOD_LT)
    hard_border(d, 52, 28, 76, 50, INK)
    # face marks
    rect(d, 58, 36, 62, 40, INK)
    rect(d, 66, 36, 70, 40, INK)
    # arms
    rect(d, 32, 56, 56, 64, WOOD)
    hard_border(d, 32, 56, 56, 64, INK)
    rect(d, 72, 56, 96, 64, WOOD)
    hard_border(d, 72, 56, 96, 64, INK)
    # vermilion target dots
    for tx, ty in [(62, 58), (40, 58), (88, 58), (64, 78)]:
        rect(d, tx, ty, tx + 4, ty + 4, VERMILION)
        hard_border(d, tx, ty, tx + 4, ty + 4, VERM_DK)
    # weapon rack hint
    rect(d, 100, 70, 108, 100, WOOD_DK)
    hard_border(d, 100, 70, 108, 100, INK)
    vline(d, 104, 48, 70, INK)  # spear
    rect(d, 102, 44, 106, 50, STONE)
    return img


def icon_bounty() -> Image.Image:
    img = new_img(ICON, ICON)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 22, 36, 106, 116)
    # posts
    rect(d, 34, 24, 44, 116, WOOD_DK)
    rect(d, 84, 24, 94, 116, WOOD_DK)
    hard_border(d, 34, 24, 44, 116, INK)
    hard_border(d, 84, 24, 94, 116, INK)
    for yy in range(28, 112, 8):
        hline(d, 36, 42, yy, WOOD)
        hline(d, 86, 92, yy, WOOD)
    # board
    rect(d, 22, 36, 106, 96, PAPER)
    hard_border(d, 22, 36, 106, 96, INK)
    # gold inner frame (double)
    hard_border(d, 26, 40, 102, 92, GOLD)
    hard_border(d, 28, 42, 100, 90, GOLD_DK)
    # notice strips with texture
    rect(d, 34, 48, 94, 58, VERMILION)
    hard_border(d, 34, 48, 94, 58, INK)
    for xx in range(38, 90, 6):
        vline(d, xx, 50, 56, VERM_DK)
    rect(d, 34, 62, 94, 68, INK_MID)
    hard_border(d, 34, 62, 94, 68, INK)
    rect(d, 34, 72, 80, 78, INK_SOFT)
    hard_border(d, 34, 72, 80, 78, INK)
    rect(d, 34, 82, 70, 86, PAPER_SH)
    # seals
    rect(d, 86, 72, 96, 82, VERMILION)
    hard_border(d, 86, 72, 96, 82, VERM_DK)
    # top beam
    rect(d, 18, 20, 110, 32, WOOD)
    hard_border(d, 18, 20, 110, 32, INK)
    for xx in range(22, 106, 10):
        vline(d, xx, 22, 30, WOOD_DK)
    # nails
    rect(d, 38, 24, 42, 28, GOLD)
    rect(d, 86, 24, 90, 28, GOLD)
    # hanging tassels
    vline(d, 28, 96, 110, VERM_DK)
    vline(d, 100, 96, 110, VERM_DK)
    rect(d, 26, 110, 30, 114, VERMILION)
    rect(d, 98, 110, 102, 114, VERMILION)
    return img


# ===================== UI HD =====================

def gen_hud_panel() -> Image.Image:
    w, h = 320, 64
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    # outer ink
    rect(d, 0, 0, w - 1, h - 1, INK)
    # gold rim
    rect(d, 2, 2, w - 3, h - 3, GOLD)
    # paper fill
    rect(d, 4, 4, w - 5, h - 5, PAPER)
    hard_border(d, 4, 4, w - 5, h - 5, INK)
    # inner double line
    hard_border(d, 6, 6, w - 7, h - 7, PAPER_DK)
    hard_border(d, 7, 7, w - 8, h - 8, INK_SOFT)
    # top cream highlight + bottom shade
    hline(d, 8, w - 9, 8, CREAM)
    hline(d, 8, w - 9, 9, PAPER_DK)
    hline(d, 8, w - 9, h - 9, PAPER_SH)
    hline(d, 8, w - 9, h - 8, INK_SOFT)
    # resource slot dividers with bevel
    for x in (64, 128, 192, 256):
        vline(d, x, 12, h - 13, PAPER_DK)
        vline(d, x + 1, 12, h - 13, CREAM)
        vline(d, x + 2, 12, h - 13, PAPER_SH)
        # tiny gold tick
        rect(d, x - 1, 10, x + 3, 12, GOLD_DK)
        rect(d, x - 1, h - 13, x + 3, h - 11, GOLD_DK)
    # corner ornaments denser
    for cx, cy in [(9, 9), (w - 15, 9), (9, h - 15), (w - 15, h - 15)]:
        rect(d, cx, cy, cx + 5, cy + 5, GOLD)
        hard_border(d, cx, cy, cx + 5, cy + 5, GOLD_DK)
        rect(d, cx + 2, cy + 2, cx + 3, cy + 3, GOLD_LT)
    # subtle paper grain
    dither_dot(img, 10, 14, w - 11, h - 15, PAPER_DK, dens=0.04, seed=42)
    return img


def _blit_pixel_font(draw, text_key, ox, oy, color=INK):
    glyphs = {
        "派": [
            "###.#",
            "#.#.#",
            "#####",
            "..#..",
            ".###.",
            "#.#.#",
            "#...#",
        ],
        "遣": [
            "##.##",
            "#.#.#",
            "#####",
            "#...#",
            "#####",
            "..#.#",
            "##..#",
        ],
        "建": [
            ".###.",
            "#.#.#",
            ".###.",
            "#####",
            "..#..",
            ".###.",
            "#.#.#",
        ],
        "造": [
            "..#..",
            ".###.",
            "#.#.#",
            "#####",
            "#...#",
            ".###.",
            "#...#",
        ],
    }
    g = glyphs.get(text_key)
    if not g:
        return
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            if ch == "#":
                rect(draw, ox + x * 2, oy + y * 2, ox + x * 2 + 1, oy + y * 2 + 1, color)


def gen_btn(label_chars, accent) -> Image.Image:
    w, h = 128, 40
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    # shadow
    rect(d, 3, 3, w - 1, h - 1, INK_SOFT)
    # outer ink
    rect(d, 0, 0, w - 4, h - 4, INK)
    # gold rim
    rect(d, 2, 2, w - 6, h - 6, GOLD)
    # accent fill
    rect(d, 4, 4, w - 8, h - 8, accent)
    # inner paper band
    rect(d, 8, 8, w - 12, h - 12, PAPER)
    hard_border(d, 8, 8, w - 12, h - 12, INK)
    # double inner
    hard_border(d, 10, 10, w - 14, h - 14, PAPER_DK)
    # highlight / shade
    hline(d, 11, w - 15, 11, CREAM)
    hline(d, 11, w - 15, h - 15, PAPER_SH)
    # accent micro-stripes in margins
    for yy in (5, 6):
        hline(d, 5, w - 9, yy, GOLD_LT if accent == VERMILION else TEAL_LT)
    # glyphs
    gap = 28
    start_x = (w - 4 - gap * (len(label_chars) - 1) - 14) // 2
    for i, ch in enumerate(label_chars):
        _blit_pixel_font(d, ch, start_x + i * gap, 12, INK)
    # corner gold ticks
    for cx, cy in [(5, 5), (w - 11, 5), (5, h - 11), (w - 11, h - 11)]:
        rect(d, cx, cy, cx + 2, cy + 2, GOLD_DK)
    return img


def gen_btn_dispatch() -> Image.Image:
    return gen_btn(["派", "遣"], VERMILION)


def gen_btn_build() -> Image.Image:
    return gen_btn(["建", "造"], TEAL)


def icon_silver() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 10, 16, 24, 28, INK_SOFT)
    # ingot body
    d.polygon([(5, 18), (10, 8), (22, 8), (27, 18), (22, 26), (10, 26)], fill=STONE_LT)
    d.line([(5, 18), (10, 8), (22, 8), (27, 18), (22, 26), (10, 26), (5, 18)], fill=INK)
    # top facet
    d.polygon([(10, 8), (22, 8), (20, 14), (12, 14)], fill=CREAM)
    d.line([(10, 8), (22, 8), (20, 14), (12, 14), (10, 8)], fill=INK)
    # gold seal
    rect(d, 13, 11, 19, 15, GOLD)
    hard_border(d, 13, 11, 19, 15, GOLD_DK)
    # side shade
    hline(d, 11, 21, 20, STONE)
    hline(d, 11, 21, 24, STONE_DK)
    return img


def icon_wood() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 14, 28, 30, INK_SOFT)
    for i, y in enumerate((6, 13, 20)):
        c = [WOOD_DK, WOOD, WOOD_LT][i]
        rect(d, 5, y, 27, y + 7, c)
        hard_border(d, 5, y, 27, y + 7, INK)
        # end grain rings
        rect(d, 5, y + 1, 10, y + 6, WOOD_DK if i != 0 else INK_MID)
        rect(d, 7, y + 2, 9, y + 4, PAPER_DK)
        # bark notch
        put(img.load(), 32, 32, 16, y + 3, WOOD_DK)
        put(img.load(), 32, 32, 20, y + 5, WOOD_DK)
    return img


def icon_hide() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 12, 26, 28, INK_SOFT)
    # rolled hide outer
    d.ellipse([5, 6, 27, 28], fill=WOOD_LT)
    d.ellipse([5, 6, 27, 28], outline=INK)
    d.ellipse([9, 10, 23, 24], fill=WOOD)
    d.ellipse([9, 10, 23, 24], outline=INK)
    d.ellipse([13, 14, 19, 20], fill=DIRT)
    d.ellipse([13, 14, 19, 20], outline=INK)
    # fur ticks
    for p in [(8, 10), (22, 9), (10, 22), (20, 20), (7, 16), (24, 16)]:
        rect(d, p[0], p[1], p[0] + 1, p[1] + 1, DIRT_DK)
    return img


def icon_iron() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 14, 26, 28, INK_SOFT)
    # bar
    rect(d, 5, 10, 27, 24, STONE_DK)
    hard_border(d, 5, 10, 27, 24, INK)
    # facets
    rect(d, 7, 12, 25, 14, STONE)
    rect(d, 7, 16, 25, 18, INK)
    rect(d, 7, 20, 25, 22, INK_MID)
    hline(d, 7, 15, 12, STONE_LT)
    # stamp
    rect(d, 12, 15, 20, 19, GOLD_DK)
    hard_border(d, 12, 15, 20, 19, GOLD)
    return img


def icon_herb() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    # stem
    rect(d, 14, 16, 18, 30, TEAL_DK)
    hard_border(d, 14, 16, 18, 30, INK)
    # leaves
    d.polygon([(16, 2), (4, 16), (16, 13)], fill=TEAL)
    d.polygon([(16, 2), (28, 16), (16, 13)], fill=TEAL_LT)
    d.line([(16, 2), (4, 16), (16, 13), (16, 2)], fill=INK)
    d.line([(16, 2), (28, 16), (16, 13)], fill=INK)
    # leaf veins
    d.line([(16, 4), (8, 14)], fill=TEAL_DK)
    d.line([(16, 4), (24, 14)], fill=TEAL_DK)
    # bud
    rect(d, 13, 0, 19, 6, VERMILION)
    hard_border(d, 13, 0, 19, 6, INK)
    rect(d, 15, 2, 17, 4, VERM_LT)
    return img


# ===================== MAIN =====================

def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(f"  wrote {path.relative_to(ROOT)}  {img.size[0]}×{img.size[1]}")


def audit_colors(img: Image.Image, name: str, allowed_rgb: set) -> list:
    pix = img.load()
    bad = {}
    for y in range(img.height):
        for x in range(img.width):
            p = pix[x, y]
            if p[3] < 128:
                continue
            rgb = p[:3]
            if rgb not in allowed_rgb:
                bad[rgb] = bad.get(rgb, 0) + 1
    if bad:
        top = sorted(bad.items(), key=lambda kv: -kv[1])[:8]
        print(f"  [audit] {name}: off-palette {len(bad)} colors, top={top}")
    else:
        print(f"  [audit] {name}: OK (in-palette)")
    return list(bad.keys())


def main() -> None:
    print("=== 墨點俠村 P1.1 HD art gen ===")
    PREVIEW.mkdir(parents=True, exist_ok=True)

    print("-- tiles --")
    ground = gen_village_ground()
    hills = gen_village_hills()
    pads = gen_village_buildings_pad()
    fg = gen_village_fg()
    save(ground, TILES / "village_ground.png")
    save(hills, TILES / "village_hills.png")
    save(pads, TILES / "village_buildings_pad.png")
    save(fg, TILES / "village_fg.png")

    building_imgs = {
        "manor": icon_manor(),
        "inn": icon_inn(),
        "forge": icon_forge(),
        "clinic": icon_clinic(),
        "training": icon_training(),
        "bounty": icon_bounty(),
    }

    composed = new_img(VW, VH)
    d = ImageDraw.Draw(composed)
    rect(d, 0, 0, VW - 1, VH - 1, PAPER)
    for layer in (ground, hills, pads, fg):
        composed = Image.alpha_composite(composed, layer)
    # 128 icon anchor: (cx-64, cy-72)
    for key, icon in building_imgs.items():
        cx, cy = BUILDING_SLOTS[key]
        composed.alpha_composite(icon, (cx - 64, cy - 72))
    save(composed, TILES / "village_composed.png")
    save(composed, PREVIEW / "village_composed.png")

    print("-- buildings 128×128 --")
    for key, fn in [
        ("manor", icon_manor),
        ("inn", icon_inn),
        ("forge", icon_forge),
        ("clinic", icon_clinic),
        ("training", icon_training),
        ("bounty", icon_bounty),
    ]:
        save(fn(), BUILDINGS / f"{key}.png")

    print("-- ui --")
    save(gen_hud_panel(), UI / "hud_panel.png")
    save(gen_btn_dispatch(), UI / "btn_dispatch.png")
    save(gen_btn_build(), UI / "btn_build.png")
    save(icon_silver(), UI / "icon_silver.png")
    save(icon_wood(), UI / "icon_wood.png")
    save(icon_hide(), UI / "icon_hide.png")
    save(icon_iron(), UI / "icon_iron.png")
    save(icon_herb(), UI / "icon_herb.png")

    # UI strip
    strip = new_img(640, 120)
    sd = ImageDraw.Draw(strip)
    rect(sd, 0, 0, 639, 119, PAPER_DK)
    strip.alpha_composite(gen_hud_panel(), (8, 8))
    strip.alpha_composite(gen_btn_dispatch(), (8, 80))
    strip.alpha_composite(gen_btn_build(), (150, 80))
    x = 300
    for fn in (icon_silver, icon_wood, icon_hide, icon_iron, icon_herb):
        strip.alpha_composite(fn(), (x, 78))
        x += 40
    save(strip, PREVIEW / "ui_strip.png")

    # buildings row (128 each)
    brow = new_img(800, 140)
    bd = ImageDraw.Draw(brow)
    rect(bd, 0, 0, 799, 139, PAPER_SH)
    bx = 8
    for key in ("manor", "inn", "forge", "clinic", "training", "bounty"):
        brow.alpha_composite(building_imgs[key], (bx, 6))
        bx += 132
    save(brow, PREVIEW / "buildings_row.png")

    # Color audit
    allowed = set()
    for hx in PALETTE_HEX.values():
        r = int(hx[1:3], 16)
        g = int(hx[3:5], 16)
        b = int(hx[5:7], 16)
        allowed.add((r, g, b))
    print("-- audit --")
    off_total = 0
    for p in sorted(list(TILES.glob("village_*.png")) + list(BUILDINGS.glob("*.png")) + list(UI.glob("*.png"))):
        if p.name == ".gitkeep":
            continue
        im = Image.open(p).convert("RGBA")
        bad = audit_colors(im, p.name, allowed)
        off_total += len(bad)

    print("\n=== DONE P1.1 HD ===")
    print("BUILDING_SLOTS (cx,cy) + icon top-left (cx-64, cy-72):")
    for k, (cx, cy) in BUILDING_SLOTS.items():
        print(f"  {k}: center={cx},{cy}  blit=({cx-64},{cy-72})")
    print(f"off-palette color kinds across files: {off_total}")
    print("Regen: python3 tools/gen_p1_art_hd.py")


if __name__ == "__main__":
    main()
