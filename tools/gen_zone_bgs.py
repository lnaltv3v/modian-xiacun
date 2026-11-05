#!/usr/bin/env python3
"""墨點俠村 野外／秘境戰鬥背景 ×4 — 全新高質（唔綁舊稿／唔抄獵魔村資產）

- 每區 960×540：分層 sky／mid／ground／props + 合成
- 中央戰鬥站位帶留可讀空地；左右／遠景加厚
- 硬邊像素、ART.md 色盤家族

重生：python3 tools/gen_zone_bgs.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace/modian-xiacun")
ART = ROOT / "assets" / "art"
ZONES = ART / "tiles" / "zones"
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
TEAL_POISON = (0x36, 0x78, 0x58, 255)
TEAL_FOG = (0x5A, 0x8A, 0x72, 255)
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
STONE_CRYPT = (0x6A, 0x62, 0x54, 255)
STONE_CRYPT_DK = (0x3A, 0x34, 0x2A, 255)
GRASS = (0x4A, 0x6E, 0x48, 255)
GRASS_LT = (0x5E, 0x82, 0x58, 255)
GRASS_DK = (0x36, 0x52, 0x34, 255)
DRY_GRASS = (0x8A, 0x78, 0x48, 255)
DRY_GRASS_LT = (0xA2, 0x90, 0x58, 255)
SKY = (0xC8, 0xD4, 0xC8, 255)
SKY_DK = (0xA8, 0xB8, 0xB0, 255)
SKY_DUSK = (0xB8, 0xA8, 0x98, 255)
SKY_CRYPT = (0x4A, 0x42, 0x38, 255)
SKY_MIRE = (0x9A, 0xB0, 0xA0, 255)
HILL = (0x3A, 0x5A, 0x4A, 255)
HILL_MID = (0x4A, 0x6A, 0x58, 255)
HILL_FAR = (0x6A, 0x82, 0x72, 255)
HILL_ROCK = (0x5A, 0x52, 0x48, 255)
MUD = (0x4A, 0x3A, 0x28, 255)
MUD_LT = (0x5E, 0x4A, 0x32, 255)
MUD_DK = (0x32, 0x28, 0x1A, 255)
PACK = (0x9A, 0x88, 0x68, 255)
PACK_LT = (0xB0, 0x9E, 0x7A, 255)
PACK_DK = (0x7A, 0x6A, 0x4E, 255)
LEAF = (0x8A, 0x6A, 0x2E, 255)
TRANS = (0, 0, 0, 0)

# All opaque palette colors used (for audit)
PALETTE_LIST = [
    INK, PAPER, VERMILION, TEAL, GOLD,
    INK_SOFT, INK_MID, WOOD, WOOD_LT, WOOD_DK,
    PAPER_DK, PAPER_SH, CREAM,
    TEAL_LT, TEAL_DK, TEAL_POISON, TEAL_FOG,
    VERM_DK, VERM_LT, GOLD_DK, GOLD_LT,
    DIRT, DIRT_DK, DIRT_LT, STONE, STONE_DK, STONE_LT,
    STONE_CRYPT, STONE_CRYPT_DK,
    GRASS, GRASS_LT, GRASS_DK, DRY_GRASS, DRY_GRASS_LT,
    SKY, SKY_DK, SKY_DUSK, SKY_CRYPT, SKY_MIRE,
    HILL, HILL_MID, HILL_FAR, HILL_ROCK,
    MUD, MUD_LT, MUD_DK, PACK, PACK_LT, PACK_DK, LEAF,
]

VW, VH = 960, 540
# Central combat band (clear-ish floor for heroes)
BAND_Y0, BAND_Y1 = 300, 470
BAND_X0, BAND_X1 = 200, 760


def new_img(w: int = VW, h: int = VH) -> Image.Image:
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


def hash2(x: int, y: int, s: int = 0) -> int:
    return (x * 374761393 + y * 668265263 + s * 1274126177) & 0x7FFFFFFF


def dither_dot(img: Image.Image, x0, y0, x1, y1, c, dens=0.12, seed=7) -> None:
    pix = img.load()
    n = seed
    for y in range(max(0, y0), min(img.height, y1 + 1)):
        for x in range(max(0, x0), min(img.width, x1 + 1)):
            n = (n * 1103515245 + 12345 + x * 17 + y * 31) & 0x7FFFFFFF
            if (n % 1000) < int(dens * 1000):
                pix[x, y] = c


def fill_sky(img: Image.Image, top, mid, bot, horizon: int) -> None:
    """Hard-banded sky (no soft gradients)."""
    d = ImageDraw.Draw(img)
    bands = [
        (0, horizon // 3, top),
        (horizon // 3, (2 * horizon) // 3, mid),
        ((2 * horizon) // 3, horizon, bot),
    ]
    for y0, y1, c in bands:
        rect(d, 0, y0, VW - 1, y1 - 1, c)
    # ink cloud dots (宣紙墨點感)
    dither_dot(img, 40, 20, VW - 40, horizon - 10, INK_SOFT, dens=0.018, seed=11)
    dither_dot(img, 80, 10, VW - 80, horizon // 2, PAPER_SH, dens=0.012, seed=22)


def rock(img, cx, cy, w, h, c_fill=STONE, c_dk=STONE_DK, c_lt=STONE_LT) -> None:
    """Hard-edge irregular rock blob (rect blocks)."""
    d = ImageDraw.Draw(img)
    x0, y0 = cx - w // 2, cy - h // 2
    rect(d, x0, y0, x0 + w, y0 + h, c_fill)
    # facets
    rect(d, x0, y0, x0 + w // 3, y0 + h, c_dk)
    rect(d, x0 + (2 * w) // 3, y0, x0 + w, y0 + h // 2, c_lt)
    hard_border(d, x0, y0, x0 + w, y0 + h, INK)
    # crack
    if w > 10:
        vline(d, x0 + w // 2, y0 + 2, y0 + h - 2, INK_SOFT)


def dry_tuft(img, x, y, h=6, c=DRY_GRASS) -> None:
    d = ImageDraw.Draw(img)
    for i, dx in enumerate((-2, 0, 2, -1, 1)):
        hh = h - (i % 3)
        vline(d, x + dx, y - hh, y, c if i % 2 == 0 else DRY_GRASS_LT)
    put(img.load(), VW, VH, x, y, INK_SOFT)


def tree_dead(img, x, y, h=48, trunk=WOOD_DK) -> None:
    """Bare tree silhouette, hard edge."""
    d = ImageDraw.Draw(img)
    tw = max(3, h // 12)
    rect(d, x - tw // 2, y - h, x + tw // 2, y, trunk)
    hard_border(d, x - tw // 2, y - h, x + tw // 2, y, INK)
    # branches
    arms = [
        (x, y - h * 3 // 4, x - h // 3, y - h),
        (x, y - h * 2 // 3, x + h // 3, y - h + 4),
        (x, y - h // 2, x - h // 4, y - h // 2 - 10),
        (x, y - h // 2, x + h // 5, y - h // 2 - 8),
    ]
    for x0, y0, x1, y1 in arms:
        d.line([(x0, y0), (x1, y1)], fill=trunk, width=2)
        d.line([(x0, y0), (x1, y1)], fill=INK, width=1)


def flag_pole(img, x, y, h=36, cloth=VERMILION) -> None:
    d = ImageDraw.Draw(img)
    vline(d, x, y - h, y, WOOD_DK)
    vline(d, x + 1, y - h, y, WOOD)
    # banner
    bw, bh = 14, 10
    rect(d, x + 2, y - h, x + 2 + bw, y - h + bh, cloth)
    hard_border(d, x + 2, y - h, x + 2 + bw, y - h + bh, INK)
    # gold trim tip
    put(img.load(), VW, VH, x, y - h, GOLD)


def save_layers(stem: str, layers: dict[str, Image.Image], composed: Image.Image) -> list[str]:
    ZONES.mkdir(parents=True, exist_ok=True)
    paths = []
    for name, im in layers.items():
        p = ZONES / f"{stem}_{name}.png"
        im.save(p)
        paths.append(str(p.relative_to(ROOT)))
    p = ZONES / f"{stem}.png"
    composed.save(p)
    paths.append(str(p.relative_to(ROOT)))
    return paths


def compose(layers: list[Image.Image]) -> Image.Image:
    out = Image.new("RGBA", (VW, VH), PAPER)
    for L in layers:
        out = Image.alpha_composite(out, L)
    return out


# ===================== ZONE: HILLS =====================

def gen_hills() -> tuple[dict[str, Image.Image], Image.Image]:
    sky = new_img()
    fill_sky(sky, SKY, SKY_DK, PAPER_DK, 200)
    d = ImageDraw.Draw(sky)
    # distant peaks silhouette
    peaks = [
        (0, 200, 80, 140, 160, 200),
        (120, 200, 220, 110, 320, 200),
        (280, 200, 400, 130, 520, 200),
        (500, 200, 620, 100, 740, 200),
        (700, 200, 820, 125, 960, 200),
    ]
    for pts in peaks:
        poly = [(pts[0], pts[1]), (pts[2], pts[3]), (pts[4], pts[5])]
        d.polygon(poly, fill=HILL_FAR)
        d.line(poly + [poly[0]], fill=INK_SOFT)

    mid = new_img()
    dm = ImageDraw.Draw(mid)
    # mid hills
    mid_polys = [
        [(0, 260), (60, 200), (140, 230), (200, 180), (280, 240), (280, 280), (0, 280)],
        [(240, 270), (320, 190), (420, 220), (520, 170), (620, 230), (700, 200), (780, 250), (780, 300), (240, 300)],
        [(720, 280), (800, 210), (880, 240), (960, 200), (960, 300), (720, 300)],
    ]
    for i, poly in enumerate(mid_polys):
        dm.polygon(poly, fill=HILL_MID if i % 2 == 0 else HILL)
        dm.line(poly + [poly[0]], fill=INK)
        # ridge highlight
        for j in range(len(poly) - 1):
            if poly[j][1] < 230:
                dm.line([poly[j], poly[j + 1]], fill=HILL_FAR)

    # rock outcrops on mid
    for cx, cy, w, h in [
        (90, 250, 28, 18), (180, 255, 22, 14), (450, 245, 36, 20),
        (580, 255, 24, 16), (850, 250, 30, 18), (700, 248, 20, 12),
    ]:
        rock(mid, cx, cy, w, h, HILL_ROCK, STONE_DK, STONE)

    ground = new_img()
    dg = ImageDraw.Draw(ground)
    gp = ground.load()
    # base dirt/grass floor — dense slope texture
    for y in range(240, VH):
        for x in range(VW):
            h = hash2(x, y, 3)
            t = (y - 240) / max(1, VH - 240)
            # pebble / grass micro
            if (h % 5) == 0:
                base = DRY_GRASS
            elif (h % 11) == 0:
                base = DIRT_DK
            elif (h % 29) == 0:
                base = STONE_DK
            elif t > 0.55:
                base = DIRT if (h % 3) else DIRT_LT
            else:
                base = GRASS_DK if (h % 4) else (GRASS if (h % 2) else DIRT)
            # diagonal hatch feel (hard)
            if ((x + y * 2) % 9) == 0 and (h % 2) == 0:
                base = DIRT_DK if t > 0.4 else GRASS_DK
            gp[x, y] = base

    # undulating slope stripes (hard bands)
    for y, c in [(270, DIRT_DK), (310, PACK_DK), (360, DIRT), (420, PACK), (480, DIRT_DK)]:
        hline(dg, 0, VW - 1, y, c)
        dither_dot(ground, 0, y - 2, VW - 1, y + 2, INK_SOFT, dens=0.08, seed=y)

    # combat standing ellipse only (no rect band)
    for y in range(BAND_Y0, BAND_Y1):
        for x in range(BAND_X0, BAND_X1):
            nx = (x - 480) / 280
            ny = (y - 385) / 85
            if nx * nx + ny * ny < 1.0:
                h = hash2(x, y, 9)
                c = PACK_LT if (h % 5) else PACK
                if (h % 17) == 0:
                    c = PAPER_SH
                if (h % 31) == 0:
                    c = PACK_DK
                gp[x, y] = c

    # stones / rubble denser at sides
    props = new_img()
    for cx, cy, w, h in [
        (40, 380, 18, 12), (70, 420, 14, 10), (110, 460, 22, 14),
        (150, 340, 16, 10), (880, 360, 20, 12), (920, 420, 18, 14),
        (850, 480, 24, 12), (30, 500, 20, 10),
        (200, 500, 12, 8), (760, 505, 14, 8),
        (480, 500, 10, 6), (250, 360, 14, 9), (700, 365, 16, 10),
        (60, 480, 12, 8), (900, 500, 14, 9), (180, 400, 10, 7),
    ]:
        rock(props, cx, cy, w, h)

    # dry grass tufts (sides denser)
    for x, y in [
        (50, 350), (90, 390), (130, 440), (170, 480),
        (800, 350), (840, 400), (890, 450), (930, 490),
        (220, 330), (740, 335), (250, 490), (710, 495),
        (40, 300), (920, 310), (60, 520), (900, 525),
    ]:
        dry_tuft(props, x, y, h=5 + (hash2(x, y) % 5))

    # distant scrub trees
    for x, y, hh in [(60, 255, 36), (160, 250, 28), (800, 252, 32), (900, 248, 40)]:
        tree_dead(props, x, y, h=hh, trunk=WOOD_DK)

    layers = {"sky": sky, "mid": mid, "ground": ground, "props": props}
    return layers, compose([sky, mid, ground, props])


# ===================== ZONE: MIRE =====================

def gen_mire() -> tuple[dict[str, Image.Image], Image.Image]:
    sky = new_img()
    fill_sky(sky, SKY_MIRE, TEAL_FOG, PAPER_DK, 210)
    # poison fog hard blocks (no blur)
    d = ImageDraw.Draw(sky)
    for x0, y0, w, h in [
        (40, 40, 120, 28), (200, 70, 90, 22), (400, 50, 140, 30),
        (600, 80, 100, 24), (780, 45, 130, 28), (100, 120, 80, 18),
        (500, 110, 110, 20),
    ]:
        rect(d, x0, y0, x0 + w, y0 + h, TEAL_FOG)
        hard_border(d, x0, y0, x0 + w, y0 + h, TEAL_DK)
        dither_dot(sky, x0, y0, x0 + w, y0 + h, TEAL_LT, dens=0.15, seed=x0)

    mid = new_img()
    dm = ImageDraw.Draw(mid)
    # swamp treeline / reed banks
    dm.polygon(
        [(0, 260), (80, 220), (180, 245), (260, 215), (340, 250), (340, 290), (0, 290)],
        fill=TEAL_DK,
    )
    dm.polygon(
        [(620, 280), (700, 230), (800, 250), (900, 220), (960, 250), (960, 300), (620, 300)],
        fill=TEAL_DK,
    )
    hard_border(dm, 0, 220, 340, 290, INK)
    # dead trunks mid
    for x, y, hh in [(50, 270, 55), (120, 265, 42), (220, 275, 48), (750, 270, 50), (880, 268, 58), (920, 275, 40)]:
        tree_dead(mid, x, y, h=hh, trunk=WOOD_DK)

    ground = new_img()
    pix = ground.load()
    for y in range(250, VH):
        for x in range(VW):
            h = hash2(x, y, 5)
            # mud pools
            pool = False
            for cx, cy, rx, ry in [
                (100, 390, 80, 36), (860, 400, 70, 32),
                (280, 500, 55, 24), (670, 505, 60, 22),
                (480, 330, 48, 20), (200, 450, 40, 18), (760, 460, 42, 18),
            ]:
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1.0:
                    pool = True
                    break
            if pool:
                c = TEAL_POISON if (h % 3) else TEAL_DK
                if (h % 11) == 0:
                    c = TEAL_LT
                if ((x + y) % 7) == 0:
                    c = TEAL_FOG
            else:
                c = MUD_DK if (h % 5) else MUD
                if (h % 7) == 0:
                    c = TEAL_DK
                if (h % 13) == 0:
                    c = MUD_LT
                if ((x * 3 + y) % 11) == 0:
                    c = INK_MID
            pix[x, y] = c

    # hard mud ripples
    dg = ImageDraw.Draw(ground)
    for y in (320, 370, 430, 490):
        hline(dg, 0, VW - 1, y, MUD_DK)
        dither_dot(ground, 0, y - 1, VW - 1, y + 1, TEAL_DK, dens=0.14, seed=y)

    # combat ellipse — firmer mud, less toxic
    for y in range(BAND_Y0, BAND_Y1):
        for x in range(BAND_X0, BAND_X1):
            nx = (x - 480) / 270
            ny = (y - 385) / 80
            if nx * nx + ny * ny < 1.0:
                h = hash2(x, y, 13)
                pix[x, y] = PACK_DK if (h % 6) else MUD_LT
                if (h % 21) == 0:
                    pix[x, y] = DIRT

    props = new_img()
    # bones of trees / stumps in sides
    for x, y, hh in [
        (80, 450, 30), (140, 480, 24), (860, 460, 28), (920, 490, 22),
        (40, 400, 36), (180, 420, 20), (820, 410, 26), (940, 440, 32),
    ]:
        tree_dead(props, x, y, h=hh, trunk=INK_MID)
    # poison bubbles (hard squares)
    dp = ImageDraw.Draw(props)
    for x, y, s in [
        (110, 395, 4), (130, 405, 3), (820, 400, 4), (850, 415, 3),
        (300, 495, 3), (660, 500, 4), (480, 335, 3),
        (90, 420, 5), (880, 430, 5), (200, 445, 4), (760, 455, 4),
        (150, 380, 3), (810, 385, 3),
    ]:
        rect(dp, x, y, x + s, y + s, TEAL_LT)
        hard_border(dp, x, y, x + s, y + s, TEAL_DK)
    # reeds dense on banks
    for x, y in [
        (40, 320), (70, 340), (100, 330), (160, 310), (190, 350),
        (790, 315), (830, 340), (900, 330), (940, 350), (870, 300),
    ]:
        for i in range(5):
            vline(dp, x + i * 3, y - 14 - (i % 3) * 3, y, TEAL if i % 2 else TEAL_LT)
    # floating fog chips mid-low sides
    for x0, y0, w, h in [(20, 280, 60, 14), (880, 285, 70, 16), (40, 500, 50, 12), (870, 510, 55, 12)]:
        rect(dp, x0, y0, x0 + w, y0 + h, TEAL_FOG)
        hard_border(dp, x0, y0, x0 + w, y0 + h, TEAL_DK)

    layers = {"sky": sky, "mid": mid, "ground": ground, "props": props}
    return layers, compose([sky, mid, ground, props])


# ===================== ZONE: CRYPT =====================

def gen_crypt() -> tuple[dict[str, Image.Image], Image.Image]:
    sky = new_img()
    # dark chamber "ceiling" bands
    d = ImageDraw.Draw(sky)
    rect(d, 0, 0, VW - 1, 220, SKY_CRYPT)
    rect(d, 0, 0, VW - 1, 80, INK_SOFT)
    rect(d, 0, 80, VW - 1, 140, STONE_CRYPT_DK)
    # vault ribs
    for x in range(60, VW, 120):
        vline(d, x, 0, 200, INK)
        vline(d, x + 1, 0, 200, STONE_CRYPT)
    # hanging gold inlays
    for x in (180, 480, 780):
        rect(d, x - 8, 40, x + 8, 70, GOLD_DK)
        hard_border(d, x - 8, 40, x + 8, 70, GOLD)
        put(sky.load(), VW, VH, x, 55, GOLD_LT)

    mid = new_img()
    dm = ImageDraw.Draw(mid)
    # back wall
    rect(dm, 0, 160, VW - 1, 320, STONE_CRYPT)
    # brick courses
    for y in range(170, 320, 14):
        hline(dm, 0, VW - 1, y, STONE_CRYPT_DK)
        off = 0 if (y // 14) % 2 == 0 else 16
        for x in range(off, VW, 32):
            vline(dm, x, y, min(y + 14, 319), STONE_CRYPT_DK)
    hard_border(dm, 0, 160, VW - 1, 320, INK)

    # niches / arches L/R
    for x0 in (40, 760):
        rect(dm, x0, 180, x0 + 160, 310, STONE_CRYPT_DK)
        hard_border(dm, x0, 180, x0 + 160, 310, INK)
        # arch top
        rect(dm, x0 + 20, 190, x0 + 140, 220, INK_SOFT)
        hard_border(dm, x0 + 20, 190, x0 + 140, 220, GOLD_DK)
        # candle
        cx = x0 + 80
        rect(dm, cx - 2, 250, cx + 2, 290, PAPER_SH)
        rect(dm, cx - 3, 242, cx + 3, 250, GOLD_LT)
        rect(dm, cx - 1, 236, cx + 1, 242, VERMILION)
        hard_border(dm, cx - 3, 242, cx + 3, 290, INK)

    # central stele
    sx0, sy0, sx1, sy1 = 430, 175, 530, 300
    rect(dm, sx0, sy0, sx1, sy1, STONE_LT)
    hard_border(dm, sx0, sy0, sx1, sy1, INK)
    rect(dm, sx0 + 8, sy0 + 12, sx1 - 8, sy1 - 20, STONE)
    hard_border(dm, sx0 + 8, sy0 + 12, sx1 - 8, sy1 - 20, GOLD_DK)
    # inscription dots
    for iy in range(sy0 + 24, sy1 - 30, 10):
        for ix in range(sx0 + 18, sx1 - 18, 8):
            if hash2(ix, iy, 2) % 3 == 0:
                put(mid.load(), VW, VH, ix, iy, INK)

    ground = new_img()
    pix = ground.load()
    for y in range(300, VH):
        for x in range(VW):
            h = hash2(x, y, 7)
            # stone tile grid
            tile = ((x // 24) + (y // 20)) % 2
            c = STONE_CRYPT if tile == 0 else STONE_DK
            if (h % 13) == 0:
                c = INK_MID
            if (h % 37) == 0:
                c = STONE
            pix[x, y] = c

    dg = ImageDraw.Draw(ground)
    # tile seams
    for x in range(0, VW, 24):
        vline(dg, x, 300, VH - 1, INK_SOFT)
    for y in range(300, VH, 20):
        hline(dg, 0, VW - 1, y, INK_SOFT)

    # combat circle — worn smoother
    for y in range(BAND_Y0, BAND_Y1):
        for x in range(BAND_X0, BAND_X1):
            nx = (x - 480) / 270
            ny = (y - 390) / 80
            if nx * nx + ny * ny < 1.0:
                h = hash2(x, y, 17)
                pix[x, y] = PAPER_DK if (h % 8) else STONE_LT

    # gold ring on floor (ritual)
    for a in range(0, 360, 2):
        rad = math.radians(a)
        x = int(480 + math.cos(rad) * 160)
        y = int(390 + math.sin(rad) * 55)
        put(pix, VW, VH, x, y, GOLD_DK)
        put(pix, VW, VH, x + 1, y, GOLD)

    props = new_img()
    dp = ImageDraw.Draw(props)
    # foreground pillars
    for x0 in (20, 900):
        rect(dp, x0, 200, x0 + 40, VH - 10, STONE_CRYPT_DK)
        hard_border(dp, x0, 200, x0 + 40, VH - 10, INK)
        for yy in range(220, VH - 20, 40):
            hline(dp, x0 + 4, x0 + 36, yy, GOLD_DK)
    # urns / jars
    for x, y in [(160, 480), (800, 485), (120, 420), (840, 430)]:
        rect(dp, x - 8, y - 20, x + 8, y, WOOD_DK)
        rect(dp, x - 10, y - 24, x + 10, y - 18, GOLD_DK)
        hard_border(dp, x - 10, y - 24, x + 10, y, INK)
    # bone-ish debris (ink blocks, not gore)
    for x, y, w, h in [(200, 500, 10, 4), (750, 505, 12, 4), (480, 510, 8, 3)]:
        rect(dp, x, y, x + w, y + h, PAPER_SH)
        hard_border(dp, x, y, x + w, y + h, INK)

    # candle glow floor marks (hard vermilion dots near niches)
    for x, y in [(120, 360), (840, 360), (480, 320)]:
        rect(dp, x - 2, y - 2, x + 2, y + 2, VERM_LT)
        hard_border(dp, x - 2, y - 2, x + 2, y + 2, VERMILION)

    layers = {"sky": sky, "mid": mid, "ground": ground, "props": props}
    return layers, compose([sky, mid, ground, props])


# ===================== ZONE: OUTPOST =====================

def gen_outpost() -> tuple[dict[str, Image.Image], Image.Image]:
    sky = new_img()
    fill_sky(sky, SKY_DUSK, SKY_DK, PAPER_DK, 200)
    d = ImageDraw.Draw(sky)
    # sun disc (hard)
    rect(d, 780, 50, 820, 90, GOLD_LT)
    hard_border(d, 780, 50, 820, 90, GOLD_DK)
    # distant hills
    d.polygon([(0, 200), (100, 150), (220, 180), (350, 140), (500, 175), (500, 210), (0, 210)], fill=HILL_FAR)
    d.polygon([(480, 210), (600, 155), (720, 185), (850, 145), (960, 170), (960, 210), (480, 210)], fill=HILL_MID)

    mid = new_img()
    dm = ImageDraw.Draw(mid)
    # watchtower / beacon (right)
    tx0, ty0 = 720, 120
    # tower body
    rect(dm, tx0, ty0 + 40, tx0 + 70, 300, WOOD)
    hard_border(dm, tx0, ty0 + 40, tx0 + 70, 300, INK)
    # wood planks
    for y in range(ty0 + 48, 300, 12):
        hline(dm, tx0 + 2, tx0 + 68, y, WOOD_DK)
    # lookout cabin
    rect(dm, tx0 - 10, ty0, tx0 + 80, ty0 + 50, WOOD_LT)
    hard_border(dm, tx0 - 10, ty0, tx0 + 80, ty0 + 50, INK)
    # roof
    dm.polygon([(tx0 - 16, ty0), (tx0 + 35, ty0 - 28), (tx0 + 86, ty0)], fill=VERM_DK)
    dm.line([(tx0 - 16, ty0), (tx0 + 35, ty0 - 28), (tx0 + 86, ty0)], fill=INK)
    # window
    rect(dm, tx0 + 20, ty0 + 16, tx0 + 40, ty0 + 36, INK_SOFT)
    hard_border(dm, tx0 + 20, ty0 + 16, tx0 + 40, ty0 + 36, GOLD)
    # beacon fire on roof
    rect(dm, tx0 + 28, ty0 - 48, tx0 + 42, ty0 - 28, VERMILION)
    rect(dm, tx0 + 30, ty0 - 56, tx0 + 40, ty0 - 48, GOLD_LT)
    hard_border(dm, tx0 + 28, ty0 - 56, tx0 + 42, ty0 - 28, INK)
    # ladder
    for y in range(ty0 + 55, 295, 8):
        hline(dm, tx0 + 8, tx0 + 28, y, WOOD_DK)
    vline(dm, tx0 + 8, ty0 + 50, 295, INK)
    vline(dm, tx0 + 28, ty0 + 50, 295, INK)

    # left gate posts
    for x0 in (80, 160):
        rect(dm, x0, 180, x0 + 18, 310, WOOD_DK)
        hard_border(dm, x0, 180, x0 + 18, 310, INK)
    # crossbeam
    rect(dm, 80, 180, 178, 198, WOOD)
    hard_border(dm, 80, 180, 178, 198, INK)
    # hanging sign
    rect(dm, 110, 200, 150, 230, PAPER_DK)
    hard_border(dm, 110, 200, 150, 230, GOLD)
    put(mid.load(), VW, VH, 130, 215, VERMILION)

    # flags
    flag_pole(mid, 90, 180, h=50, cloth=VERMILION)
    flag_pole(mid, 170, 180, h=45, cloth=TEAL)
    flag_pole(mid, 755, 120, h=40, cloth=VERMILION)

    ground = new_img()
    pix = ground.load()
    for y in range(250, VH):
        for x in range(VW):
            h = hash2(x, y, 11)
            # dirt road through center
            road = abs(x - 480) < 90 + int(30 * math.sin(y * 0.04))
            if road and y > 280:
                c = PACK if (h % 4) else PACK_LT
                if (h % 15) == 0:
                    c = DIRT_DK
            else:
                c = GRASS_DK if (h % 3) else (GRASS if (h % 5) == 0 else DIRT)
                if (h % 9) == 0:
                    c = DRY_GRASS
                if (h % 17) == 0:
                    c = DIRT_DK
            pix[x, y] = c

    dg = ImageDraw.Draw(ground)
    # road edge lines
    for y in range(290, VH):
        wob = int(20 * math.sin(y * 0.05))
        put(pix, VW, VH, 390 + wob, y, DIRT_DK)
        put(pix, VW, VH, 570 - wob, y, DIRT_DK)

    # combat clearing
    for y in range(BAND_Y0, BAND_Y1):
        for x in range(BAND_X0, BAND_X1):
            nx = (x - 480) / 280
            ny = (y - 385) / 80
            if nx * nx + ny * ny < 1.0:
                h = hash2(x, y, 19)
                pix[x, y] = PACK_LT if (h % 6) else PACK

    props = new_img()
    dp = ImageDraw.Draw(props)
    # wooden palisade L/R
    for base_x, y0 in [(10, 280), (900, 280)]:
        for i in range(8):
            x = base_x + i * 7
            h = 40 + (hash2(x, y0) % 12)
            rect(dp, x, y0, x + 5, y0 + h, WOOD if i % 2 else WOOD_DK)
            # stake tip
            dp.polygon([(x, y0), (x + 2, y0 - 8), (x + 5, y0)], fill=WOOD_DK)
            hard_border(dp, x, y0, x + 5, y0 + h, INK)
        # rail
        hline(dp, base_x, base_x + 56, y0 + 18, WOOD_LT)

    # crates / supply
    for x, y, w, h in [(140, 460, 28, 22), (780, 470, 32, 24), (200, 500, 20, 16)]:
        rect(dp, x, y, x + w, y + h, WOOD)
        hard_border(dp, x, y, x + w, y + h, INK)
        hline(dp, x, x + w, y + h // 2, WOOD_DK)

    # campfire ring near mid-right of band edge
    cx, cy = 700, 400
    for a in range(0, 360, 45):
        rad = math.radians(a)
        rx = int(cx + math.cos(rad) * 16)
        ry = int(cy + math.sin(rad) * 10)
        rock(props, rx, ry, 8, 6, STONE, STONE_DK, STONE_LT)
    rect(dp, cx - 4, cy - 8, cx + 4, cy, VERMILION)
    rect(dp, cx - 2, cy - 14, cx + 2, cy - 8, GOLD_LT)
    hard_border(dp, cx - 4, cy - 14, cx + 4, cy, INK)

    # grass tufts
    for x, y in [(50, 360), (100, 420), (860, 380), (920, 450), (180, 350), (780, 360)]:
        dry_tuft(props, x, y, h=6)

    layers = {"sky": sky, "mid": mid, "ground": ground, "props": props}
    return layers, compose([sky, mid, ground, props])


# ===================== PREVIEW + AUDIT =====================

def make_preview(composed: dict[str, Image.Image]) -> Path:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    order = ["zone_hills", "zone_mire", "zone_crypt", "zone_outpost"]
    # 2x2 grid
    cell_w, cell_h = VW // 2, VH // 2
    strip = Image.new("RGBA", (cell_w * 2, cell_h * 2), INK)
    for i, name in enumerate(order):
        im = composed[name].resize((cell_w, cell_h), Image.Resampling.NEAREST)
        x = (i % 2) * cell_w
        y = (i // 2) * cell_h
        strip.paste(im, (x, y))
        # label bar
        d = ImageDraw.Draw(strip)
        rect(d, x, y, x + 120, y + 14, INK)
        # pixel label via simple blocks — skip font; filename bar only
        hline(d, x, x + cell_w - 1, y + cell_h - 1, GOLD)
        vline(d, x + cell_w - 1, y, y + cell_h - 1, GOLD)
    p = PREVIEW / "zones_strip.png"
    strip.save(p)
    # solo previews (half size)
    for name, im in composed.items():
        half = im.resize((VW // 2, VH // 2), Image.Resampling.NEAREST)
        half.save(PREVIEW / f"{name}_preview.png")
    return p


def audit_colors(images: list[Image.Image]) -> dict:
    """Check every opaque pixel is within ART family (exact match to PALETTE_LIST)."""
    allowed = set(PALETTE_LIST)
    bad = {}
    total = 0
    ok = 0
    for im in images:
        pix = im.load()
        for y in range(im.height):
            for x in range(im.width):
                c = pix[x, y]
                if c[3] == 0:
                    continue
                total += 1
                if c in allowed:
                    ok += 1
                else:
                    key = "#{:02X}{:02X}{:02X}".format(c[0], c[1], c[2])
                    bad[key] = bad.get(key, 0) + 1
    return {"total_opaque": total, "ok": ok, "bad_count": sum(bad.values()), "bad": bad}


def main() -> None:
    ZONES.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)

    gens = {
        "zone_hills": gen_hills,
        "zone_mire": gen_mire,
        "zone_crypt": gen_crypt,
        "zone_outpost": gen_outpost,
    }
    composed_map = {}
    all_files = []
    audit_imgs = []

    for stem, fn in gens.items():
        layers, composed = fn()
        paths = save_layers(stem, layers, composed)
        all_files.extend(paths)
        composed_map[stem] = composed
        audit_imgs.append(composed)
        for L in layers.values():
            audit_imgs.append(L)
        print(f"[ok] {stem}  layers={list(layers)}  composed={VW}x{VH}")

    strip = make_preview(composed_map)
    print(f"[ok] preview {strip.relative_to(ROOT)}")

    # write small MANIFEST
    man = ZONES / "MANIFEST_zones.md"
    lines = [
        "# 野外／秘境戰鬥背景 ×4",
        "",
        "尺寸：每區合成 960×540；分層 sky／mid／ground／props。",
        "重生：`python3 tools/gen_zone_bgs.py`",
        "",
        "| 檔 | 特徵 |",
        "|----|------|",
        "| zone_hills | 亂山坡：遠峰＋碎石枯草＋中央夯土站位 |",
        "| zone_mire | 毒沼：硬色塊毒霧＋泥潭＋枯木青綠 |",
        "| zone_crypt | 古墓：石室碑＋燭火金邊＋陰暗宣紙墨點 |",
        "| zone_outpost | 前哨：木柵烽火台＋旗＋土路 |",
        "",
        "## 檔案",
    ]
    for p in sorted(all_files):
        lines.append(f"- `{p}`")
    lines.append(f"- `{strip.relative_to(ROOT)}`")
    man.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[ok] {man.relative_to(ROOT)}")

    report = audit_colors(audit_imgs)
    print("[audit]", report["total_opaque"], "opaque;", "bad=", report["bad_count"])
    if report["bad"]:
        # show top offenders
        top = sorted(report["bad"].items(), key=lambda kv: -kv[1])[:20]
        for hexv, n in top:
            print(f"  OFF {hexv} x{n}")
    else:
        print("[audit] all opaque pixels in PALETTE_LIST")

    print("DONE")


if __name__ == "__main__":
    main()
