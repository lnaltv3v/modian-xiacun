#!/usr/bin/env python3
"""墨點俠村 · Pivot R4（統一加厚打磨）

Lemon（經總開發）：書院 R3 已批可接入；繼續補齊／打磨建築同村景
（高密度、拉開）；預覽交總開發即可。

本輪：全部 8 棟 160 覆寫加厚（瓦紋／木紋／石磚／燈籠／匾額／門檻／陰影／微粒）
＋村景再密（路面石縫、草叢、籬笆、遠山層次、前景道具；中央可建空地淨）。
備份 R3 → assets/art/_prev_pivot_r3/

重生：python3 tools/gen_pivot_r4.py
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
import gen_pivot_r2 as r2  # noqa: E402
import gen_pivot_r3 as r3  # noqa: E402

ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_pivot_r3"

VW, VH = r1.VW, r1.VH
ICON = r1.ICON  # 160
HORIZON = r1.HORIZON
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
GRASS = r1.GRASS
LEAF, LEAF_LT, LEAF_DK, LEAF_Y = r1.LEAF, r1.LEAF_LT, r1.LEAF_DK, r1.LEAF_Y
PINE, PINE_LT, PINE_DK = r1.PINE, r1.PINE_LT, r1.PINE_DK
HILL_FAR, HILL_MID, HILL_NEAR, HILL_EDGE = r1.HILL_FAR, r1.HILL_MID, r1.HILL_NEAR, r1.HILL_EDGE
SKY0, SKY1, SKY2, SKY3 = r1.SKY0, r1.SKY1, r1.SKY2, r1.SKY3
CLOUD, CLOUD_DK = r1.CLOUD, r1.CLOUD_DK
BANNER, BANNER_DK = r1.BANNER, r1.BANNER_DK

HERB = r2.HERB
HERB_DRY = r2.HERB_DRY
PAPER = r2.PAPER
JADE = r2.JADE
CLOTH_BL = r2.CLOTH_BL
CLOTH_PU = r2.CLOTH_PU
SAND = r2.SAND
ROPE = r2.ROPE

INK_TILE = r3.INK_TILE
BAMBOO = r3.BAMBOO
SCROLL_RED = r3.SCROLL_RED

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
draw_crate = r2.draw_crate
herb_jar = r2.herb_jar
hanging_herb = r2.hanging_herb
bamboo_post = r2.bamboo_post
tile_dither_extra = r2.tile_dither_extra
preview_row = r2.preview_row
compose = r2.compose

scroll_roll = r3.scroll_roll
sword_on_rack = r3.sword_on_rack
open_book = r3.open_book
bamboo_clump = r3.bamboo_clump


# ===================== R4 polish helpers =====================

def eave_soft_shadow(pix, w, h, x0, y0, x1, y1, strength=0.28, seed=1000):
    """Soft contact shade under eaves / beams."""
    for y in range(y0, y1 + 1):
        t = (y - y0) / max(1, y1 - y0)
        a = strength * (1.0 - t)
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            pix[x, y] = blend(cur, SHADOW, a * (0.7 + 0.3 * noise(x, y, seed)))


def particle_speck(pix, w, h, x0, y0, x1, y1, density=0.04, seed=1010):
    """Fine dust / grit speckles (non-transparent pixels only)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            n = noise(x, y, seed)
            if n < density * 0.5:
                pix[x, y] = blend(cur, INK2, 0.18)
            elif n > 1.0 - density * 0.5:
                pix[x, y] = blend(cur, CREAM, 0.12)


def vermilion_couplet(pix, w, h, sx, y0, y1):
    """Narrow 硃紅對聯板 with gold glyph hints."""
    for y in range(y0, y1 + 1):
        put(pix, w, h, sx, y, VERM[1])
        put(pix, w, h, sx + 1, y, VERM[0])
        put(pix, w, h, sx + 2, y, VERM[2])
        if (y - y0) % 5 == 2:
            put(pix, w, h, sx + 1, y, GOLD[1])
            put(pix, w, h, sx + 1, y + 1, PAPER[0])
    put(pix, w, h, sx, y0 - 1, GOLD[0])
    put(pix, w, h, sx + 2, y0 - 1, GOLD[0])
    put(pix, w, h, sx, y1 + 1, GOLD[2])
    put(pix, w, h, sx + 2, y1 + 1, GOLD[2])


def fancy_plaque(pix, d, w, h, x0, y0, x1, y1, n_glyphs=4, lacquer=True):
    """Lacquered plaque with gold rim + glyph blocks + studs."""
    body = WOOD_LAC[0] if lacquer else WOOD[0]
    rect(d, x0, y0, x1, y1, body)
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y0, GOLD[0])
        put(pix, w, h, x, y0 + 1, GOLD[1])
        put(pix, w, h, x, y1, GOLD[2])
        put(pix, w, h, x, y1 - 1, GOLD[3] if x % 2 else GOLD[2])
    for y in range(y0, y1 + 1):
        put(pix, w, h, x0, y, GOLD[0])
        put(pix, w, h, x1, y, GOLD[0])
        put(pix, w, h, x0 + 1, y, GOLD[2])
        put(pix, w, h, x1 - 1, y, GOLD[2])
    gw = max(5, (x1 - x0 - 8) // n_glyphs)
    for i in range(n_glyphs):
        xx = x0 + 4 + i * gw
        rect(d, xx, y0 + 3, xx + gw - 3, y1 - 3, CREAM if i % 2 == 0 else PAPER[0])
        put(pix, w, h, xx + 1, y0 + 5, INK)
        put(pix, w, h, xx + 2, y0 + 6, INK)
        put(pix, w, h, xx + 3, y0 + 7, INK2)
        put(pix, w, h, xx + 2, y0 + 8, INK)
        if i == 1:
            put(pix, w, h, xx + 2, y1 - 5, VERM[0])
    gold_studs(pix, w, h, [(x0 + 2, y0 + 2), (x0 + 2, y1 - 3), (x1 - 3, y0 + 2), (x1 - 3, y1 - 3)])


def threshold_bar(pix, w, h, x0, y, x1, thick=3):
    wood_plank_h(pix, w, h, x0, y, x1, y + thick, seed=1100 + y)
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y, GOLD[2] if x % 5 == 0 else WOOD[1])
        put(pix, w, h, x, y + thick, INK)


def iron_band_h(pix, w, h, x0, y, x1):
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y, IRON[0])
        put(pix, w, h, x, y + 1, IRON[2])
        if x % 6 == 0:
            put(pix, w, h, x, y + 1, GOLD[1])


def flying_eave_tips(pix, w, h, lx, rx, by, cols, gold=True):
    """飛檐 tip upturn at left/right eaves."""
    for t in range(0, 10):
        put(pix, w, h, lx + t, by - t // 2, cols[1 % len(cols)])
        put(pix, w, h, lx + 1 + t, by - 1 - t // 2, cols[0])
        put(pix, w, h, rx - t, by - t // 2, cols[1 % len(cols)])
        put(pix, w, h, rx - 1 - t, by - 1 - t // 2, cols[0])
        if gold and t % 2 == 0:
            put(pix, w, h, lx + t, by - 2 - t // 2, GOLD[2])
            put(pix, w, h, rx - t, by - 2 - t // 2, GOLD[2])


def ridge_ornaments(pix, w, h, cx, cy, span=8):
    for ox in range(-span, span + 1, 4):
        put(pix, w, h, cx + ox, cy, GOLD[0])
        put(pix, w, h, cx + ox, cy - 1, GOLD[1])
    put(pix, w, h, cx, cy - 3, VERM[0])
    put(pix, w, h, cx, cy - 4, GOLD[3])
    put(pix, w, h, cx, cy - 5, JADE[3] if len(JADE) > 3 else GOLD[0])


def polish_universal(img: Image.Image, seed: int = 1200) -> Image.Image:
    """Pass over finished icon: grain, speck, slight edge darken."""
    pix = img.load()
    w = h = ICON
    # micro grit on opaque pixels
    particle_speck(pix, w, h, 0, 0, w - 1, h - 1, density=0.035, seed=seed)
    # soft silhouette rim darken
    for y in range(h):
        for x in range(w):
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            # edge if neighbor transparent
            edge = False
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or pix[nx, ny][3] == 0:
                    edge = True
                    break
            if edge and noise(x, y, seed + 5) > 0.35:
                pix[x, y] = blend(cur, INK, 0.22)
    return img


# ===================== BUILDINGS R4 (rewrite denser) =====================

def icon_manor_r4() -> Image.Image:
    """村長府 — R1 base + R4 加厚：雙層瓦紋、對聯、燈籠柱、門檻、石獅金飾。"""
    img = r1.icon_manor()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    # denser roof tile dither both roofs
    tile_dither_extra(pix, w, h, 18, 10, 142, 60, ROOF_R, 1301)
    tile_dither_extra(pix, w, h, 44, 8, 116, 36, ROOF_R, 1302)
    flying_eave_tips(pix, w, h, 18, 142, 54, ROOF_R)
    flying_eave_tips(pix, w, h, 44, 116, 32, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 8, span=10)

    # wall / wood grain
    micro_grain(pix, w, h, 30, 62, 130, 122, WALL, 0.07, 1303)
    micro_grain(pix, w, h, 30, 62, 130, 122, WOOD, 0.03, 1304)
    stone_bricks(pix, w, h, 18, 118, 142, 148, bw=9, bh=6, seed=1305)  # refresh terrace grit
    micro_grain(pix, w, h, 18, 118, 142, 148, STONE, 0.08, 1306)

    # eave shadow under lower roof beam
    eave_soft_shadow(pix, w, h, 28, 66, 132, 78, strength=0.32, seed=1307)

    # fancy plaque overwrite
    fancy_plaque(pix, d, w, h, 54, 66, 106, 80, n_glyphs=4)

    # vermilion couplets flanking door
    vermilion_couplet(pix, w, h, 62, 86, 116)
    vermilion_couplet(pix, w, h, 94, 86, 116)

    # threshold
    threshold_bar(pix, w, h, 66, 120, 94, thick=3)

    # extra lanterns on posts
    wood_plank_v(pix, w, h, 44, 100, 46, 132, seed=1308)
    wood_plank_v(pix, w, h, 114, 100, 116, 132, seed=1309)
    hanging_lantern(img, 45, 96)
    hanging_lantern(img, 115, 96)
    hanging_lantern(img, 48, 68)
    hanging_lantern(img, 112, 68)

    # iron bands on columns
    for cx in (36, 56, 78, 100, 122):
        iron_band_h(pix, w, h, cx - 3, 78, cx + 3)
        iron_band_h(pix, w, h, cx - 3, 108, cx + 3)

    # stone lions jewel + shadow
    for lx in (48, 108):
        fill_disk(pix, w, h, lx, 132, 6, STONE, seed=1310 + lx)
        put(pix, w, h, lx, 126, GOLD[2])
        put(pix, w, h, lx - 1, 128, STONE[3])
        put(pix, w, h, lx + 1, 128, STONE[3])
        for dx in range(-5, 6):
            put(pix, w, h, lx + dx, 138, blend(STONE[2], SHADOW, 0.45))

    # courtyard grit
    for y in range(148, 156):
        for x in range(20, 140):
            if noise(x, y, 1311) < 0.3:
                put(pix, w, h, x, y, DIRT[int(noise(x, y, 1312) * 3)])

    # side wing lattice denser
    lattice_window(img, 12, 96, 24, 112)
    lattice_window(img, 136, 96, 148, 112)

    return polish_universal(img, 1320)


def icon_inn_r4() -> Image.Image:
    """客棧 — 木紋加厚、酒旗金邊、門簾褶、匾額、燈籠、門檻。"""
    img = r1.icon_inn()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 14, 22, 146, 62, [
        WOOD[5], WOOD[3], WOOD[2], WOOD[1], WOOD[0], WOOD[6], WOOD[4]
    ], 1401)
    flying_eave_tips(pix, w, h, 14, 146, 54, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 22, span=8)

    micro_grain(pix, w, h, 28, 58, 132, 130, WALL, 0.06, 1402)
    micro_grain(pix, w, h, 28, 58, 132, 130, WOOD, 0.04, 1403)
    eave_soft_shadow(pix, w, h, 28, 62, 132, 74, strength=0.3, seed=1404)

    # inn plaque 「客棧」
    fancy_plaque(pix, d, w, h, 58, 58, 102, 70, n_glyphs=3)

    # denser balcony rail
    for x in range(34, 126):
        put(pix, w, h, x, 88, WOOD[1])
        put(pix, w, h, x, 89, WOOD[6])
        if x % 4 == 0:
            for y in range(80, 90):
                put(pix, w, h, x, y, WOOD[0])
                put(pix, w, h, x + 1, y, WOOD[2])

    # curtain fold polish + gold fringe
    for x in range(62, 98):
        put(pix, w, h, x, 104, GOLD[0])
        put(pix, w, h, x, 105, GOLD[1])
        if (x - 62) % 4 == 2:
            for y in range(106, 128):
                put(pix, w, h, x, y, VERM[2])

    threshold_bar(pix, w, h, 60, 128, 100, thick=3)

    # more lanterns
    hanging_lantern(img, 40, 92)
    hanging_lantern(img, 120, 92)
    hanging_lantern(img, 54, 98)
    hanging_lantern(img, 106, 98)

    # wine jars outside
    for jx in (24, 136):
        for dy in range(0, 14):
            for dx in range(-4, 5):
                if abs(dx) <= 4 - dy // 8:
                    put(pix, w, h, jx + dx, 128 + dy, WOOD_LAC[1] if dy < 10 else WOOD_LAC[0])
        put(pix, w, h, jx, 126, GOLD[2])
        put(pix, w, h, jx, 127, WOOD[1])

    # stool next to table
    wood_plank_h(pix, w, h, 52, 136, 62, 140, seed=1405)
    wood_plank_v(pix, w, h, 54, 140, 56, 148, seed=1406)

    # banner gold fringe denser
    for dx in range(0, 22):
        put(pix, w, h, 131 + dx, 72, GOLD[0] if dx % 2 else GOLD[2])

    # iron bands on posts
    for cx in (34, 58, 80, 102, 126):
        iron_band_h(pix, w, h, cx - 2, 100, cx + 2)

    return polish_universal(img, 1410)


def icon_forge_r4() -> Image.Image:
    """鐵匠鋪 — 火光層次、煙囪煙、掛刀架、鐵砧細節、瓦紋。"""
    img = r1.icon_forge()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    # roof polish if present — scan upper band
    tile_dither_extra(pix, w, h, 20, 20, 140, 70, ROOF_BK + ROOF_SL, 1501)
    flying_eave_tips(pix, w, h, 22, 138, 58, ROOF_BK)

    micro_grain(pix, w, h, 24, 70, 136, 126, WOOD, 0.08, 1502)
    micro_grain(pix, w, h, 22, 120, 138, 140, STONE, 0.1, 1503)
    eave_soft_shadow(pix, w, h, 24, 68, 136, 80, strength=0.28, seed=1504)

    # plaque 「鐵鋪」
    fancy_plaque(pix, d, w, h, 58, 48, 102, 60, n_glyphs=3, lacquer=True)

    # hung blades denser left post
    for i, hx in enumerate((36, 42, 48)):
        for y in range(72, 110):
            put(pix, w, h, hx, y, IRON[1])
            put(pix, w, h, hx + 1, y, IRON[3])
        put(pix, w, h, hx, 70, IRON[0])
        for dx in range(-2, 4):
            put(pix, w, h, hx + dx, 96, GOLD[0] if i == 0 else IRON[0])

    # anvil polish center-front
    for y in range(118, 130):
        for x in range(68, 96):
            put(pix, w, h, x, y, IRON[0] if y < 122 else IRON[2])
    for x in range(70, 94):
        put(pix, w, h, x, 118, IRON[3])
        put(pix, w, h, x, 129, INK)
    # horn
    for dx in range(0, 10):
        put(pix, w, h, 96 + dx, 120, IRON[1])
        put(pix, w, h, 96 + dx, 121, IRON[0])

    # fire glow denser in forge mouth
    for y in range(88, 118):
        for x in range(70, 100):
            n = noise(x, y, 1505)
            if n > 0.35:
                c = FIRE[int(n * (len(FIRE) - 1))]
                put(pix, w, h, x, y, c)
            if n > 0.85:
                put(pix, w, h, x, y, GOLD[3])

    # chimney smoke wisps
    for i, (sx, sy) in enumerate([(118, 28), (122, 22), (126, 18), (120, 14)]):
        for dy in range(0, 8):
            for dx in range(-3, 4):
                if abs(dx) <= 3 - dy // 3 and noise(sx + dx, sy - dy, 1506 + i) < 0.65:
                    put(pix, w, h, sx + dx, sy - dy, blend(CLOUD_DK, SKY2, 0.4 + 0.1 * i))

    # hanging lanterns
    hanging_lantern(img, 56, 64)
    hanging_lantern(img, 104, 64)

    # coal pile
    for i in range(30):
        cx = 48 + (hash2(i, 1, 1507) % 20)
        cy = 132 + (hash2(i, 2, 1508) % 10)
        put(pix, w, h, cx, cy, INK if i % 2 else INK2)
        put(pix, w, h, cx + 1, cy, INK3)

    # tongs / hammer on ground
    for x in range(100, 120):
        put(pix, w, h, x, 136, IRON[0])
        put(pix, w, h, x, 137, WOOD[0])
    put(pix, w, h, 120, 135, IRON[3])
    put(pix, w, h, 121, 134, IRON[1])

    threshold_bar(pix, w, h, 52, 126, 108, thick=2)
    return polish_universal(img, 1510)


def icon_clinic_r4() -> Image.Image:
    """藥鋪 — 藥罐／懸草加厚、匾額金邊、瓦紋、燈籠。"""
    img = r2.icon_clinic()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 16, 12, 144, 58, ROOF_SL + ROOF_R, 1601)
    flying_eave_tips(pix, w, h, 16, 144, 52, ROOF_SL)
    ridge_ornaments(pix, w, h, 80, 12, span=8)

    micro_grain(pix, w, h, 28, 54, 132, 128, WALL, 0.06, 1602)
    eave_soft_shadow(pix, w, h, 28, 56, 132, 70, strength=0.3, seed=1603)

    fancy_plaque(pix, d, w, h, 52, 56, 108, 70, n_glyphs=4)
    vermilion_couplet(pix, w, h, 58, 74, 112)
    vermilion_couplet(pix, w, h, 98, 74, 112)
    threshold_bar(pix, w, h, 64, 122, 96, thick=3)

    # extra herb jars
    herb_jar(pix, w, h, 24, 120, JADE[0])
    herb_jar(pix, w, h, 136, 118, HERB[0])
    hanging_herb(pix, w, h, 40, 78)
    hanging_herb(pix, w, h, 120, 78)

    hanging_lantern(img, 48, 64)
    hanging_lantern(img, 112, 64)
    hanging_lantern(img, 70, 100)
    hanging_lantern(img, 90, 100)

    # mortar & pestle hint
    fill_disk(pix, w, h, 34, 136, 5, STONE, seed=1604)
    put(pix, w, h, 34, 132, WOOD[0])
    for y in range(124, 134):
        put(pix, w, h, 38, y, WOOD[1])

    return polish_universal(img, 1610)


def icon_training_r4() -> Image.Image:
    """演武場 — 兵器架、旗、沙袋、木樁加厚。"""
    img = r2.icon_training()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 18, 10, 142, 55, ROOF_R, 1701)
    flying_eave_tips(pix, w, h, 20, 140, 50, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 10, span=8)

    micro_grain(pix, w, h, 24, 50, 136, 130, WOOD, 0.07, 1702)
    eave_soft_shadow(pix, w, h, 24, 52, 136, 66, strength=0.28, seed=1703)

    fancy_plaque(pix, d, w, h, 54, 52, 106, 66, n_glyphs=4)

    # extra weapons on rack
    for i, hx in enumerate((28, 34, 40, 120, 126, 132)):
        sword_on_rack(pix, w, h, hx, 70, 124, gold_guard=(i % 2 == 0))

    # training dummy polish
    fill_disk(pix, w, h, 80, 118, 10, SAND, seed=1704)
    for y in range(90, 118):
        put(pix, w, h, 78, y, WOOD[0])
        put(pix, w, h, 82, y, WOOD[2])
    for dy in range(0, 16):
        for dx in range(-8, 9):
            if abs(dx) <= 8 - dy // 3:
                put(pix, w, h, 80 + dx, 78 + dy, SAND[int(noise(80 + dx, 78 + dy, 1705) * 3)])
    put(pix, w, h, 76, 84, INK2)  # eye
    put(pix, w, h, 84, 84, INK2)

    hanging_lantern(img, 50, 60)
    hanging_lantern(img, 110, 60)

    # banners left/right
    for bx, col in ((18, VERM), (142, TEAL)):
        for y in range(40, 100):
            put(pix, w, h, bx, y, WOOD[0])
        for dy in range(0, 36):
            for dx in range(0, 14):
                c = col[0] if dx < 11 else col[2]
                if 4 <= dx <= 9 and 8 <= dy <= 28 and ((dy - 8) // 5) % 2 == 0:
                    c = CREAM
                put(pix, w, h, bx + (2 if bx < 80 else -15) + dx, 44 + dy, c)

    threshold_bar(pix, w, h, 50, 128, 110, thick=2)
    return polish_universal(img, 1710)


def icon_bounty_r4() -> Image.Image:
    """懸賞榜 — 告示層次、封印、簷瓦、燈籠柱、石台加厚（對齊最密棟）。"""
    img = r2.icon_bounty()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 24, 8, 136, 40, ROOF_R, 1801)
    flying_eave_tips(pix, w, h, 24, 136, 30, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 7, span=6)

    micro_grain(pix, w, h, 48, 52, 112, 118, WOOD, 0.1, 1802)
    micro_grain(pix, w, h, 30, 122, 130, 150, STONE, 0.1, 1803)
    eave_soft_shadow(pix, w, h, 34, 38, 126, 52, strength=0.32, seed=1804)

    # denser notice papers overlay
    extra_papers = [
        (56, 60, 72, 74, 10),
        (88, 62, 106, 78, 11),
        (60, 88, 78, 106, 12),
        (84, 90, 108, 110, 13),
    ]
    for x0, y0, x1, y1, s in extra_papers:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                n = noise(x, y, 1810 + s)
                c = PAPER[int(n * (len(PAPER) - 1))]
                if n < 0.1:
                    c = PAPER[2]
                put(pix, w, h, x, y, c)
        ink_outline_rect(pix, w, h, x0, y0, x1, y1, WOOD[6])
        for ly in range(y0 + 3, y1 - 2, 3):
            for lx in range(x0 + 2, x1 - 1):
                if noise(lx, ly, 1820 + s) > 0.4:
                    put(pix, w, h, lx, ly, INK2 if (lx + ly) % 3 else INK)
        # seal
        sx, sy = x1 - 7, y1 - 8
        for dy in range(0, 6):
            for dx in range(0, 6):
                if abs(dx - 2.5) + abs(dy - 2.5) < 4:
                    put(pix, w, h, sx + dx, sy + dy, VERM[0])

    fancy_plaque(pix, d, w, h, 56, 26, 104, 42, n_glyphs=3)

    # lantern posts
    wood_plank_v(pix, w, h, 28, 90, 30, 140, seed=1830)
    wood_plank_v(pix, w, h, 130, 90, 132, 140, seed=1831)
    hanging_lantern(img, 29, 86)
    hanging_lantern(img, 131, 86)
    hanging_lantern(img, 48, 46)
    hanging_lantern(img, 112, 46)

    # more scroll tubes
    scroll_roll(pix, w, h, 36, 58, length=28, vert=True)
    scroll_roll(pix, w, h, 124, 58, length=28, vert=True)

    # wanted figure denser
    for dy in range(0, 20):
        for dx in range(-5, 6):
            if abs(dx) <= 5 - dy // 5:
                put(pix, w, h, 80 + dx, 74 + dy, INK3 if dy < 5 else INK2)
    put(pix, w, h, 80, 72, INK)
    put(pix, w, h, 78, 76, INK)  # arms hint
    put(pix, w, h, 82, 76, INK)

    # chain / rope under board
    for x in range(50, 110):
        if x % 3 == 0:
            put(pix, w, h, x, 116, IRON[1])
            put(pix, w, h, x, 117, IRON[0])

    threshold_bar(pix, w, h, 55, 140, 105, thick=2)
    return polish_universal(img, 1840)


def icon_warehouse_r4() -> Image.Image:
    """貨棧 — 貨箱／麻袋／吊索加厚。"""
    img = r2.icon_warehouse()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 14, 14, 146, 58, ROOF_BK + ROOF_SL, 1901)
    flying_eave_tips(pix, w, h, 16, 144, 52, ROOF_BK)
    ridge_ornaments(pix, w, h, 80, 14, span=8)

    micro_grain(pix, w, h, 26, 55, 134, 130, WOOD, 0.08, 1902)
    eave_soft_shadow(pix, w, h, 26, 56, 134, 70, strength=0.3, seed=1903)

    fancy_plaque(pix, d, w, h, 54, 54, 106, 68, n_glyphs=3)

    # extra crates
    draw_crate(pix, w, h, 18, 118, 42, 140, seed=1904)
    draw_crate(pix, w, h, 118, 120, 142, 142, seed=1905)
    draw_crate(pix, w, h, 44, 128, 66, 146, seed=1906)

    # sacks
    for cx, cy in [(70, 136), (90, 138), (110, 134)]:
        for dy in range(0, 12):
            for dx in range(-6, 7):
                if abs(dx) <= 6 - dy // 4:
                    put(pix, w, h, cx + dx, cy + dy, SAND[int(noise(cx + dx, cy + dy, 1907) * 3)])
        put(pix, w, h, cx, cy - 1, ROPE[0])

    # hoist rope + hook
    for y in range(60, 100):
        put(pix, w, h, 100, y, ROPE[1])
        put(pix, w, h, 101, y, ROPE[0])
    put(pix, w, h, 100, 100, IRON[0])
    put(pix, w, h, 99, 101, IRON[1])
    put(pix, w, h, 101, 101, IRON[1])

    hanging_lantern(img, 48, 62)
    hanging_lantern(img, 112, 62)
    threshold_bar(pix, w, h, 60, 124, 100, thick=3)

    # ledger desk
    wood_plank_h(pix, w, h, 28, 110, 50, 116, seed=1908)
    open_book(pix, w, h, 30, 102, 46, 112)

    return polish_universal(img, 1910)


def icon_academy_r4() -> Image.Image:
    """書院 — R3 已密；再加瓦紋／微粒／門檻／燈籠統一。"""
    img = r3.icon_academy()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    tile_dither_extra(pix, w, h, 10, 12, 150, 54, INK_TILE, 2001)
    flying_eave_tips(pix, w, h, 10, 150, 46, INK_TILE)
    ridge_ornaments(pix, w, h, 80, 10, span=10)

    micro_grain(pix, w, h, 30, 54, 130, 120, WALL, 0.05, 2002)
    micro_grain(pix, w, h, 24, 116, 136, 142, STONE, 0.07, 2003)
    eave_soft_shadow(pix, w, h, 26, 54, 134, 66, strength=0.28, seed=2004)

    fancy_plaque(pix, d, w, h, 50, 56, 110, 70, n_glyphs=4)
    threshold_bar(pix, w, h, 62, 118, 98, thick=3)

    hanging_lantern(img, 58, 62)
    hanging_lantern(img, 102, 62)
    hanging_lantern(img, 49, 96)
    hanging_lantern(img, 111, 96)

    # extra fallen leaves + grit
    for fx, fy in [(22, 136), (26, 140), (30, 134), (128, 138), (132, 142)]:
        put(pix, w, h, fx, fy, HERB[3] if fx % 2 else VERM[3])

    particle_speck(pix, w, h, 10, 50, 150, 150, density=0.03, seed=2005)
    return polish_universal(img, 2010)


# ===================== VILLAGE LAYERS R4 =====================

def gen_ground_r4() -> Image.Image:
    """R2 ground + 路面石縫、草叢邊、中央淨空保留。"""
    img = r2.gen_ground_r2()
    pix = img.load()

    # stone-seam paths (avoid dead center build pad ~360–460 y, 300–660 x)
    # ring path around plateau
    for i in range(220):
        t = i / 219.0
        ang = t * math.pi * 2
        rx, ry = 300, 130
        cx, cy = 480, 360
        x = int(cx + rx * math.cos(ang))
        y = int(cy + ry * math.sin(ang) * 0.72)
        if 0 <= x < VW and HORIZON <= y < VH:
            # skip very center
            if abs(x - 480) < 90 and abs(y - 360) < 50:
                continue
            for dx in range(-2, 3):
                for dy in range(-1, 2):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < VW and 0 <= yy < VH:
                        put(pix, VW, VH, xx, yy, STONE[(dx + dy + 3) % len(STONE)])
            # mortar seam
            put(pix, VW, VH, x, y, MORTAR)

    # grass clumps on plateau rim / sides (not center)
    for i in range(180):
        x = 40 + (hash2(i, 1, 2100) % (VW - 80))
        y = HORIZON + 20 + (hash2(i, 2, 2101) % (VH - HORIZON - 40))
        # keep center clear
        if abs(x - 480) < 140 and abs(y - 370) < 70:
            continue
        if noise(x, y, 2102) < 0.55:
            for k in range(6):
                ox = (k % 3) - 1
                oy = (k // 3)
                put(pix, VW, VH, x + ox, y + oy, LEAF if k % 2 else LEAF_LT)
                put(pix, VW, VH, x + ox, y + oy - 1, LEAF_DK)

    # extra pebbles / grit off-center
    for i in range(200):
        x = 80 + (hash2(i, 3, 2103) % 800)
        y = 240 + (hash2(i, 4, 2104) % 260)
        if abs(x - 480) < 100 and abs(y - 360) < 55:
            continue
        if noise(x, y, 2105) < 0.35:
            put(pix, VW, VH, x, y, STONE[hash2(i, 5, 2106) % len(STONE)])

    # soft worn packed-earth patches near building anchors (subtle)
    for cx, cy in [(480, 240), (100, 310), (860, 310), (140, 510), (840, 510),
                   (340, 520), (620, 520), (300, 380)]:
        for dy in range(-18, 20):
            for dx in range(-40, 41):
                if (dx * dx) / 1600 + (dy * dy) / 400 < 1 and noise(cx + dx, cy + dy, 2107) < 0.4:
                    xx, yy = cx + dx, cy + dy
                    if 0 <= xx < VW and 0 <= yy < VH:
                        cur = pix[xx, yy]
                        if cur[3]:
                            pix[xx, yy] = blend(cur, PACK[1], 0.25)

    return img


def gen_hills_r4() -> Image.Image:
    """遠山多一層暈、松林密、煙縷、飛鳥。"""
    img = r2.gen_hills_r2()
    pix = img.load()

    # extra far ridge silhouette haze
    hill_ramp = [HILL_FAR, HILL_MID, HILL_NEAR]
    for x in range(VW):
        y0 = 70 + int(10 * math.sin(x * 0.012)) + int(6 * math.sin(x * 0.037))
        for y in range(y0, min(y0 + 28, HORIZON + 10)):
            t = (y - y0) / 28.0
            if noise(x, y, 2200) < 0.85:
                cur = pix[x, y]
                base = hill_ramp[min(int(t * (len(hill_ramp) - 1)), len(hill_ramp) - 1)]
                if cur[3] == 0:
                    put(pix, VW, VH, x, y, blend(base, SKY2, 0.35 + 0.3 * t))
                else:
                    pix[x, y] = blend(cur, base, 0.15)

    # denser mid pines
    for i in range(22):
        tx = 20 + i * 44 + (hash2(i, 0, 2201) % 20)
        ty = 148 + (hash2(i, 1, 2202) % 30)
        hgt = 16 + (hash2(i, 2, 2203) % 18)
        for dy in range(0, hgt):
            half = max(1, 6 - dy // 4)
            for dx in range(-half, half + 1):
                put(pix, VW, VH, tx + dx, ty - dy, PINE if dx % 2 else PINE_LT)
        put(pix, VW, VH, tx, ty + 1, WOOD[4])

    # more birds
    for bx, by in [(120, 48), (340, 32), (560, 50), (740, 28), (880, 42), (400, 70)]:
        put(pix, VW, VH, bx, by, INK2)
        put(pix, VW, VH, bx - 1, by - 1, INK3)
        put(pix, VW, VH, bx + 1, by - 1, INK3)

    # temple distant roof hint (tiny, non-copyright)
    for px, py in [(620, 100), (280, 110)]:
        for x in range(px - 10, px + 11):
            put(pix, VW, VH, x, py, ROOF_R[2])
            put(pix, VW, VH, x, py + 1, ROOF_R[0])
        put(pix, VW, VH, px, py - 2, GOLD[2])

    # cloud bands
    for cx, cy, r in [(160, 40, 18), (500, 28, 22), (800, 45, 16)]:
        for dy in range(-r // 2, r // 2 + 1):
            for dx in range(-r, r + 1):
                if (dx * dx) / (r * r) + (dy * dy) / ((r * 0.4) ** 2) < 1:
                    if noise(cx + dx, cy + dy, 2204) < 0.55:
                        put(pix, VW, VH, cx + dx, cy + dy, blend(CLOUD, SKY1, 0.4))

    return img


def gen_pad_r4() -> Image.Image:
    """建築墊層：正式 tile 全透明（唔焗碰撞／預覽灰框）；可建提示用遊戲內 pad_hint。"""
    return new_img(VW, VH)


def gen_fg_r4() -> Image.Image:
    """前景：籬笆、燈籠柱、竹、石、桶；兩側密、中央淨。"""
    img = r2.gen_fg_r2()
    pix = img.load()

    # side fences (not across center)
    for base_x in list(range(0, 160, 14)) + list(range(800, VW, 14)):
        wood_plank_v(pix, VW, VH, base_x + 2, VH - 70, base_x + 5, VH - 8, seed=2400 + base_x)
        if base_x + 14 < VW:
            for yy in (VH - 58, VH - 40):
                for xx in range(base_x + 2, min(base_x + 16, VW)):
                    put(pix, VW, VH, xx, yy, WOOD[2])
                    put(pix, VW, VH, xx, yy + 1, WOOD[0])

    # mid-side fence stubs (leave center open)
    for base_x in (180, 200, 740, 760):
        wood_plank_v(pix, VW, VH, base_x, 380, base_x + 3, 460, seed=2410 + base_x)
        for yy in (400, 430):
            for xx in range(base_x, base_x + 20):
                put(pix, VW, VH, xx, yy, WOOD[1])

    # lantern posts sides
    for lx, ly in [(70, 250), (890, 250), (55, 380), (905, 380), (100, 480), (860, 480)]:
        wood_plank_v(pix, VW, VH, lx, ly, lx + 3, ly + 50, seed=2420 + lx)
        hanging_lantern(img, lx + 1, ly - 4)

    # bamboo denser sides
    for bx in (15, 35, 55, 920, 940, 900):
        bamboo_post(pix, VW, VH, bx, 280, 420, seed=2430 + bx)
        bamboo_post(pix, VW, VH, bx + 5, 300, 440, seed=2431 + bx)

    # barrels / jars FG bottom sides
    for cx, cy in [(130, VH - 32), (200, VH - 30), (760, VH - 32), (830, VH - 28)]:
        for dy in range(0, 16):
            for dx in range(-6, 7):
                if abs(dx) <= 6 - dy // 8:
                    put(pix, VW, VH, cx + dx, cy + dy, WOOD_LAC[1] if dy < 12 else WOOD[0])
        put(pix, VW, VH, cx, cy - 1, IRON[0])
        iron_band_h(pix, VW, VH, cx - 5, cy + 6, cx + 5)

    # rocks
    for rx, ry, rr in [(90, VH - 24, 7), (870, VH - 22, 6), (250, VH - 20, 5), (700, VH - 20, 5)]:
        fill_disk(pix, VW, VH, rx, ry, rr, STONE, seed=2440 + rx)
        put(pix, VW, VH, rx - 2, ry - 2, STONE[3])

    # fallen leaves denser near FG fence (not center)
    for i in range(160):
        x = hash2(i, 1, 2450) % VW
        if 280 < x < 680:
            continue
        y = VH - 70 + (hash2(i, 2, 2451) % 60)
        put(pix, VW, VH, x, y, LEAF_Y if i % 3 else VERM[3])

    # ensure center FG stays clear (wipe any accidental props)
    for y in range(280, 460):
        for x in range(380, 580):
            # keep transparent — wipe fg clutter in buildable center
            if abs(x - 480) < 90 and abs(y - 360) < 70:
                pix[x, y] = TRANS

    return img


# ===================== BACKUP / MAIN =====================

BUILDING_NAMES = ["manor", "inn", "forge", "clinic", "training", "bounty", "warehouse", "academy"]

SLOTS = {
    "manor": (480, 225),
    "warehouse": (100, 295),
    "forge": (860, 295),
    "inn": (140, 505),
    "training": (840, 505),
    "clinic": (340, 518),
    "bounty": (620, 518),
    "academy": (300, 360),
}


def ensure_backup():
    PREV.mkdir(parents=True, exist_ok=True)
    (PREV / "buildings").mkdir(exist_ok=True)
    (PREV / "tiles").mkdir(exist_ok=True)
    for name in BUILDING_NAMES:
        src = BUILDINGS / f"{name}.png"
        dst = PREV / "buildings" / f"{name}.png"
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)
    for name in (
        "village_ground.png", "village_hills.png", "village_buildings_pad.png",
        "village_fg.png", "village_composed.png",
    ):
        src = TILES / name
        dst = PREV / "tiles" / name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)


def main():
    ensure_backup()
    PREVIEW.mkdir(parents=True, exist_ok=True)
    BUILDINGS.mkdir(parents=True, exist_ok=True)
    TILES.mkdir(parents=True, exist_ok=True)

    gens = {
        "manor": icon_manor_r4,
        "inn": icon_inn_r4,
        "forge": icon_forge_r4,
        "clinic": icon_clinic_r4,
        "training": icon_training_r4,
        "bounty": icon_bounty_r4,
        "warehouse": icon_warehouse_r4,
        "academy": icon_academy_r4,
    }

    buildings = {}
    print("Generating R4 buildings 160×160…")
    for name in BUILDING_NAMES:
        print(f"  · {name}")
        im = gens[name]()
        assert im.size == (ICON, ICON), f"{name} size {im.size}"
        im.save(BUILDINGS / f"{name}.png")
        buildings[name] = im

    print("Generating R4 village layers 960×540…")
    ground = gen_ground_r4()
    hills = gen_hills_r4()
    pad = gen_pad_r4()
    fg = gen_fg_r4()
    for layer, im in (
        ("village_ground.png", ground),
        ("village_hills.png", hills),
        ("village_buildings_pad.png", pad),
        ("village_fg.png", fg),
    ):
        assert im.size == (VW, VH), f"{layer} size {im.size}"
        im.save(TILES / layer)

    print("Composing previews…")
    composed = compose(ground, hills, pad, fg, buildings, SLOTS)
    composed.save(TILES / "village_composed.png")
    composed.save(PREVIEW / "pivot_r4_village.png")
    composed.save(PREVIEW / "village_composed.png")

    layers_only = compose(ground, hills, pad, fg)
    layers_only.save(PREVIEW / "pivot_r4_layers_only.png")

    row_all = preview_row([(buildings[n], n) for n in BUILDING_NAMES])
    row_all.save(PREVIEW / "pivot_r4_all_buildings.png")
    row_all.resize((row_all.width * 2, row_all.height * 2), Image.NEAREST).save(
        PREVIEW / "pivot_r4_all_buildings_x2.png"
    )

    print("OK")
    print(f"  backup: {PREV}")
    for n in BUILDING_NAMES:
        p = BUILDINGS / f"{n}.png"
        im = Image.open(p)
        print(f"  buildings/{n}.png: {im.size[0]}×{im.size[1]}")
    for n in ("village_ground", "village_hills", "village_buildings_pad", "village_fg", "village_composed"):
        p = TILES / f"{n}.png"
        im = Image.open(p)
        print(f"  tiles/{n}.png: {im.size[0]}×{im.size[1]}")
    print(f"  preview: {PREVIEW / 'pivot_r4_all_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r4_all_buildings_x2.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r4_village.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r4_layers_only.png'}")
    print("錨點:", SLOTS)
    print("重生：python3 tools/gen_pivot_r4.py")


if __name__ == "__main__":
    main()
