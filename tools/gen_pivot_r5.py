#!/usr/bin/env python3
"""墨點俠村 · Pivot R5（再打磨一級）

總開發：R4fix 灰框已清乾淨 OK；繼續自主打磨，預覽交總開發即可。

本輪：八棟 160 再密（優先倉庫／懸賞／鐵匠／醫館：瓦紋／木紋／燈籠／匾額／道具／陰影／微粒）
＋村景再密（ground／hills／fg）；pad 空層（唔焗碰撞盒／灰框／金角標）。
備份 R4 → assets/art/_prev_pivot_r4/

重生：python3 tools/gen_pivot_r5.py
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
import gen_pivot_r4 as r4  # noqa: E402

ART = ROOT / "assets" / "art"
TILES = ART / "tiles"
BUILDINGS = ART / "buildings"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_pivot_r4"

VW, VH = r1.VW, r1.VH
ICON = r1.ICON
HORIZON = r1.HORIZON
TRANS = r1.TRANS

INK, INK2, INK3 = r1.INK, r1.INK2, r1.INK3
SHADOW = r1.SHADOW
WOOD, WOOD_LAC = r1.WOOD, r1.WOOD_LAC
WALL = r1.WALL
ROOF_R, ROOF_SL, ROOF_BK = r1.ROOF_R, r1.ROOF_SL, r1.ROOF_BK
GOLD, IRON, FIRE = r1.GOLD, r1.IRON, r1.FIRE
TEAL, VERM, CREAM = r1.TEAL, r1.VERM, r1.CREAM
STONE, MORTAR, DIRT, PACK = r1.STONE, r1.MORTAR, r1.DIRT, r1.PACK
LEAF, LEAF_LT, LEAF_DK, LEAF_Y = r1.LEAF, r1.LEAF_LT, r1.LEAF_DK, r1.LEAF_Y
PINE, PINE_LT, PINE_DK = r1.PINE, r1.PINE_LT, r1.PINE_DK
HILL_FAR, HILL_MID, HILL_NEAR = r1.HILL_FAR, r1.HILL_MID, r1.HILL_NEAR
SKY1, SKY2 = r1.SKY1, r1.SKY2
CLOUD, CLOUD_DK = r1.CLOUD, r1.CLOUD_DK

HERB = r2.HERB
PAPER = r2.PAPER
JADE = r2.JADE
SAND = r2.SAND
ROPE = r2.ROPE

INK_TILE = r3.INK_TILE
BAMBOO = r3.BAMBOO

new_img = r1.new_img
put = r1.put
blend = r1.blend
hash2 = r1.hash2
noise = r1.noise
rect = r1.rect
fill_disk = r1.fill_disk
wood_plank_v = r1.wood_plank_v
wood_plank_h = r1.wood_plank_h
stone_bricks = r1.stone_bricks
hanging_lantern = r1.hanging_lantern
lattice_window = r1.lattice_window

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

eave_soft_shadow = r4.eave_soft_shadow
particle_speck = r4.particle_speck
vermilion_couplet = r4.vermilion_couplet
fancy_plaque = r4.fancy_plaque
threshold_bar = r4.threshold_bar
iron_band_h = r4.iron_band_h
flying_eave_tips = r4.flying_eave_tips
ridge_ornaments = r4.ridge_ornaments
polish_universal = r4.polish_universal


# ===================== R5 polish helpers =====================

def roof_scale_rows(pix, w, h, x0, y0, x1, y1, cols, seed=3000):
    """Extra curved-tile scale rows (denser than dither alone)."""
    for y in range(y0, y1 + 1, 3):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            n = noise(x, y, seed)
            c = cols[int(n * (len(cols) - 1))]
            if (x + y // 3) % 5 == 0:
                put(pix, w, h, x, y, blend(cur, INK2, 0.25))
            elif n > 0.55:
                put(pix, w, h, x, y, blend(cur, c, 0.45))
            if (x % 7 == 0) and y + 1 <= y1:
                put(pix, w, h, x, y + 1, blend(cur, cols[0], 0.35))


def warm_vermilion_boost(pix, w, h, x0, y0, x1, y1, strength=0.18, seed=3010):
    """Push roof/banner vermilion warmer-orange (紅六人 Pivot 真靚)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            r, g, b, a = cur
            # reddish pixels
            if r > g + 20 and r > b + 20 and r > 80:
                warm = (min(255, r + 18), min(255, g + 8), max(0, b - 6), a)
                pix[x, y] = blend(cur, warm, strength * (0.6 + 0.4 * noise(x, y, seed)))


def contact_ground_shadow(pix, w, h, cx, cy, rx=42, ry=8, strength=0.4, seed=3020):
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            if (dx * dx) / max(1, rx * rx) + (dy * dy) / max(1, ry * ry) > 1:
                continue
            x, y = cx + dx, cy + dy
            if not (0 <= x < w and 0 <= y < h):
                continue
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            t = 1.0 - ((dx * dx) / max(1, rx * rx) + (dy * dy) / max(1, ry * ry))
            pix[x, y] = blend(cur, SHADOW, strength * t * (0.7 + 0.3 * noise(x, y, seed)))


def lacquer_door(pix, w, h, x0, y0, x1, y1, seed=3030):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            n = noise(x, y, seed)
            c = WOOD_LAC[int(n * (len(WOOD_LAC) - 1))]
            put(pix, w, h, x, y, c)
            if x == (x0 + x1) // 2:
                put(pix, w, h, x, y, WOOD[6])
    # studs
    for y in range(y0 + 3, y1 - 2, 6):
        for x in (x0 + 3, x1 - 4):
            put(pix, w, h, x, y, GOLD[1])
            put(pix, w, h, x + 1, y, GOLD[0])
    # ring knockers
    mx = (x0 + x1) // 2
    my = (y0 + y1) // 2
    for dx, dy in ((-6, 0), (5, 0)):
        put(pix, w, h, mx + dx, my, GOLD[0])
        put(pix, w, h, mx + dx + 1, my, IRON[0])
        put(pix, w, h, mx + dx, my + 1, IRON[1])


def ember_glow(pix, w, h, x0, y0, x1, y1, seed=3040):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            n = noise(x, y, seed)
            if n > 0.55:
                c = FIRE[int((n - 0.55) / 0.45 * (len(FIRE) - 1))]
                cur = pix[x, y]
                if cur[3]:
                    pix[x, y] = blend(cur, c, 0.55)
                else:
                    put(pix, w, h, x, y, c)
            if n > 0.9:
                put(pix, w, h, x, y, GOLD[3])


def polish_r5(img: Image.Image, seed: int = 3100) -> Image.Image:
    """Second universal pass: denser speck + warmer rim."""
    pix = img.load()
    w = h = ICON
    particle_speck(pix, w, h, 0, 0, w - 1, h - 1, density=0.05, seed=seed)
    warm_vermilion_boost(pix, w, h, 0, 0, w - 1, h // 2, strength=0.22, seed=seed + 1)
    for y in range(h):
        for x in range(w):
            cur = pix[x, y]
            if cur[3] == 0:
                continue
            edge = False
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or pix[nx, ny][3] == 0:
                    edge = True
                    break
            if edge and noise(x, y, seed + 7) > 0.4:
                pix[x, y] = blend(cur, INK, 0.18)
    return img


# ===================== BUILDINGS R5 =====================

def icon_manor_r5() -> Image.Image:
    img = r4.icon_manor_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 18, 10, 142, 58, ROOF_R, 3201)
    roof_scale_rows(pix, w, h, 44, 8, 116, 34, ROOF_R, 3202)
    flying_eave_tips(pix, w, h, 18, 142, 54, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 7, span=12)
    micro_grain(pix, w, h, 30, 62, 130, 122, WOOD, 0.05, 3203)
    eave_soft_shadow(pix, w, h, 28, 64, 132, 76, strength=0.36, seed=3204)
    fancy_plaque(pix, d, w, h, 52, 64, 108, 80, n_glyphs=4)
    vermilion_couplet(pix, w, h, 60, 84, 118)
    vermilion_couplet(pix, w, h, 96, 84, 118)
    lacquer_door(pix, w, h, 68, 86, 92, 120, seed=3205)
    threshold_bar(pix, w, h, 64, 120, 96, thick=3)
    hanging_lantern(img, 42, 90)
    hanging_lantern(img, 118, 90)
    hanging_lantern(img, 50, 66)
    hanging_lantern(img, 110, 66)
    contact_ground_shadow(pix, w, h, 80, 148, rx=50, ry=7, strength=0.35, seed=3206)
    stone_bricks(pix, w, h, 18, 118, 142, 148, bw=8, bh=5, seed=3207)
    return polish_r5(img, 3210)


def icon_inn_r5() -> Image.Image:
    img = r4.icon_inn_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 14, 22, 146, 60, ROOF_R, 3301)
    flying_eave_tips(pix, w, h, 14, 146, 54, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 20, span=10)
    micro_grain(pix, w, h, 28, 58, 132, 130, WOOD, 0.06, 3302)
    eave_soft_shadow(pix, w, h, 28, 60, 132, 74, strength=0.34, seed=3303)
    fancy_plaque(pix, d, w, h, 56, 56, 104, 70, n_glyphs=3)
    # wine flag denser fringe
    for dx in range(0, 24):
        put(pix, w, h, 130 + dx, 70, GOLD[0] if dx % 2 else VERM[0])
        put(pix, w, h, 130 + dx, 71, VERM[1])
    for y in range(72, 110):
        for x in range(132, 150):
            if noise(x, y, 3304) > 0.35:
                put(pix, w, h, x, y, VERM[(x + y) % len(VERM)])
    lacquer_door(pix, w, h, 66, 108, 94, 128, seed=3305)
    threshold_bar(pix, w, h, 60, 128, 100, thick=3)
    hanging_lantern(img, 38, 90)
    hanging_lantern(img, 122, 90)
    hanging_lantern(img, 56, 96)
    hanging_lantern(img, 104, 96)
    # stool + bowl
    wood_plank_h(pix, w, h, 48, 136, 60, 140, seed=3306)
    fill_disk(pix, w, h, 54, 134, 3, CREAM, seed=3307)
    contact_ground_shadow(pix, w, h, 80, 150, rx=48, ry=6, strength=0.32, seed=3308)
    return polish_r5(img, 3310)


def icon_forge_r5() -> Image.Image:
    """鐵匠鋪 — 優先打磨：火光、煙、掛刀、鐵砧、煤堆再密。"""
    img = r4.icon_forge_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 20, 18, 140, 68, ROOF_BK + ROOF_SL, 3401)
    flying_eave_tips(pix, w, h, 22, 138, 58, ROOF_BK)
    micro_grain(pix, w, h, 24, 70, 136, 126, WOOD, 0.1, 3402)
    micro_grain(pix, w, h, 22, 118, 138, 142, STONE, 0.12, 3403)
    eave_soft_shadow(pix, w, h, 24, 66, 136, 80, strength=0.34, seed=3404)
    fancy_plaque(pix, d, w, h, 56, 46, 104, 60, n_glyphs=3, lacquer=True)
    # hung blades denser
    for i, hx in enumerate((32, 38, 44, 50)):
        for y in range(70, 112):
            put(pix, w, h, hx, y, IRON[1 if i % 2 else 0])
            put(pix, w, h, hx + 1, y, IRON[3])
        put(pix, w, h, hx, 68, GOLD[0] if i == 0 else IRON[0])
        for dx in range(-2, 4):
            put(pix, w, h, hx + dx, 94, GOLD[1] if i % 2 == 0 else IRON[0])
    # right rack spears
    for i, hx in enumerate((110, 116, 122)):
        sword_on_rack(pix, w, h, hx, 72, 118, gold_guard=(i == 1))
    # anvil denser
    for y in range(116, 132):
        for x in range(66, 98):
            put(pix, w, h, x, y, IRON[0 if y < 120 else 2])
    for x in range(68, 96):
        put(pix, w, h, x, 116, IRON[3])
        put(pix, w, h, x, 131, INK)
    for dx in range(0, 12):
        put(pix, w, h, 98 + dx, 118, IRON[1])
        put(pix, w, h, 98 + dx, 119, IRON[0])
    ember_glow(pix, w, h, 68, 86, 102, 118, seed=3405)
    # chimney smoke denser
    for i, (sx, sy) in enumerate([(116, 26), (120, 20), (124, 16), (118, 12), (122, 10)]):
        for dy in range(0, 10):
            for dx in range(-4, 5):
                if abs(dx) <= 4 - dy // 3 and noise(sx + dx, sy - dy, 3406 + i) < 0.7:
                    put(pix, w, h, sx + dx, sy - dy, blend(CLOUD_DK, SKY2, 0.35 + 0.08 * i))
    hanging_lantern(img, 54, 62)
    hanging_lantern(img, 106, 62)
    # coal pile denser
    for i in range(50):
        cx = 40 + (hash2(i, 1, 3407) % 28)
        cy = 128 + (hash2(i, 2, 3408) % 14)
        put(pix, w, h, cx, cy, INK if i % 2 else INK2)
        put(pix, w, h, cx + 1, cy, INK3)
        if i % 7 == 0:
            put(pix, w, h, cx, cy - 1, FIRE[3])
    # tongs / hammer
    for x in range(102, 126):
        put(pix, w, h, x, 136, IRON[0])
        put(pix, w, h, x, 137, WOOD[0])
    put(pix, w, h, 126, 134, IRON[3])
    put(pix, w, h, 127, 133, IRON[1])
    put(pix, w, h, 128, 132, IRON[0])
    threshold_bar(pix, w, h, 50, 126, 110, thick=2)
    contact_ground_shadow(pix, w, h, 80, 148, rx=48, ry=6, strength=0.34, seed=3409)
    return polish_r5(img, 3410)


def icon_clinic_r5() -> Image.Image:
    """藥鋪 — 優先打磨：藥罐／懸草／匾／瓦／燈籠。"""
    img = r4.icon_clinic_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 16, 10, 144, 56, ROOF_SL + ROOF_R, 3501)
    flying_eave_tips(pix, w, h, 16, 144, 52, ROOF_SL)
    ridge_ornaments(pix, w, h, 80, 10, span=10)
    micro_grain(pix, w, h, 28, 54, 132, 128, WALL, 0.07, 3502)
    eave_soft_shadow(pix, w, h, 28, 54, 132, 70, strength=0.34, seed=3503)
    fancy_plaque(pix, d, w, h, 50, 54, 110, 70, n_glyphs=4)
    vermilion_couplet(pix, w, h, 56, 72, 114)
    vermilion_couplet(pix, w, h, 100, 72, 114)
    lacquer_door(pix, w, h, 68, 86, 92, 122, seed=3504)
    threshold_bar(pix, w, h, 62, 122, 98, thick=3)
    # jars denser
    herb_jar(pix, w, h, 20, 118, JADE[0])
    herb_jar(pix, w, h, 34, 122, HERB[0])
    herb_jar(pix, w, h, 126, 118, JADE[1] if len(JADE) > 1 else JADE[0])
    herb_jar(pix, w, h, 140, 120, HERB[1] if len(HERB) > 1 else HERB[0])
    hanging_herb(pix, w, h, 38, 76)
    hanging_herb(pix, w, h, 46, 80)
    hanging_herb(pix, w, h, 114, 76)
    hanging_herb(pix, w, h, 122, 80)
    hanging_lantern(img, 46, 62)
    hanging_lantern(img, 114, 62)
    hanging_lantern(img, 68, 98)
    hanging_lantern(img, 92, 98)
    # mortar & pestle
    fill_disk(pix, w, h, 32, 138, 6, STONE, seed=3505)
    put(pix, w, h, 32, 133, WOOD[0])
    for y in range(122, 136):
        put(pix, w, h, 38, y, WOOD[1])
        put(pix, w, h, 39, y, WOOD[2])
    # dried roots on shelf
    wood_plank_h(pix, w, h, 108, 100, 140, 104, seed=3506)
    for i, xx in enumerate(range(110, 138, 6)):
        put(pix, w, h, xx, 98, HERB[i % len(HERB)])
        put(pix, w, h, xx + 1, 97, LEAF_Y)
    contact_ground_shadow(pix, w, h, 80, 150, rx=46, ry=6, strength=0.32, seed=3507)
    return polish_r5(img, 3510)


def icon_training_r5() -> Image.Image:
    img = r4.icon_training_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 18, 8, 142, 52, ROOF_R, 3601)
    flying_eave_tips(pix, w, h, 20, 140, 50, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 8, span=10)
    micro_grain(pix, w, h, 24, 50, 136, 130, WOOD, 0.08, 3602)
    eave_soft_shadow(pix, w, h, 24, 50, 136, 66, strength=0.32, seed=3603)
    fancy_plaque(pix, d, w, h, 52, 50, 108, 66, n_glyphs=4)
    for i, hx in enumerate((24, 30, 36, 42, 118, 124, 130, 136)):
        sword_on_rack(pix, w, h, hx, 68, 126, gold_guard=(i % 2 == 0))
    # dummy denser
    fill_disk(pix, w, h, 80, 120, 12, SAND, seed=3604)
    for y in range(88, 120):
        put(pix, w, h, 77, y, WOOD[0])
        put(pix, w, h, 83, y, WOOD[2])
    for dy in range(0, 18):
        for dx in range(-10, 11):
            if abs(dx) <= 10 - dy // 3:
                put(pix, w, h, 80 + dx, 74 + dy, SAND[int(noise(80 + dx, 74 + dy, 3605) * 3)])
    put(pix, w, h, 75, 82, INK2)
    put(pix, w, h, 85, 82, INK2)
    hanging_lantern(img, 48, 58)
    hanging_lantern(img, 112, 58)
    # sand ring
    for ang_i in range(48):
        ang = ang_i / 48.0 * math.pi * 2
        x = int(80 + 28 * math.cos(ang))
        y = int(130 + 10 * math.sin(ang))
        put(pix, w, h, x, y, SAND[ang_i % len(SAND)])
    threshold_bar(pix, w, h, 48, 128, 112, thick=2)
    contact_ground_shadow(pix, w, h, 80, 150, rx=50, ry=6, strength=0.3, seed=3606)
    return polish_r5(img, 3610)


def icon_bounty_r5() -> Image.Image:
    """懸賞榜 — 優先打磨：告示／封印／簷瓦／燈籠柱。"""
    img = r4.icon_bounty_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 24, 6, 136, 38, ROOF_R, 3701)
    flying_eave_tips(pix, w, h, 24, 136, 30, ROOF_R)
    ridge_ornaments(pix, w, h, 80, 5, span=8)
    micro_grain(pix, w, h, 46, 50, 114, 120, WOOD, 0.12, 3702)
    micro_grain(pix, w, h, 28, 120, 132, 152, STONE, 0.12, 3703)
    eave_soft_shadow(pix, w, h, 34, 36, 126, 52, strength=0.36, seed=3704)
    fancy_plaque(pix, d, w, h, 54, 24, 106, 42, n_glyphs=3)
    # denser notice stack
    papers = [
        (52, 56, 74, 78, 21),
        (78, 54, 104, 76, 22),
        (54, 80, 76, 104, 23),
        (80, 82, 110, 112, 24),
        (64, 70, 90, 94, 25),
    ]
    for x0, y0, x1, y1, s in papers:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                n = noise(x, y, 3710 + s)
                c = PAPER[int(n * (len(PAPER) - 1))]
                if n < 0.12:
                    c = PAPER[min(2, len(PAPER) - 1)]
                put(pix, w, h, x, y, c)
        ink_outline_rect(pix, w, h, x0, y0, x1, y1, WOOD[6])
        for ly in range(y0 + 3, y1 - 2, 3):
            for lx in range(x0 + 2, x1 - 1):
                if noise(lx, ly, 3720 + s) > 0.38:
                    put(pix, w, h, lx, ly, INK2 if (lx + ly) % 3 else INK)
        sx, sy = x1 - 7, y1 - 8
        for dy in range(0, 6):
            for dx in range(0, 6):
                if abs(dx - 2.5) + abs(dy - 2.5) < 4:
                    put(pix, w, h, sx + dx, sy + dy, VERM[0])
    # lantern posts + side scrolls
    wood_plank_v(pix, w, h, 26, 88, 29, 142, seed=3730)
    wood_plank_v(pix, w, h, 131, 88, 134, 142, seed=3731)
    hanging_lantern(img, 27, 84)
    hanging_lantern(img, 132, 84)
    hanging_lantern(img, 46, 44)
    hanging_lantern(img, 114, 44)
    scroll_roll(pix, w, h, 34, 56, length=32, vert=True)
    scroll_roll(pix, w, h, 126, 56, length=32, vert=True)
    # wanted silhouette denser
    for dy in range(0, 22):
        for dx in range(-6, 7):
            if abs(dx) <= 6 - dy // 5:
                put(pix, w, h, 80 + dx, 72 + dy, INK3 if dy < 6 else INK2)
    put(pix, w, h, 80, 70, INK)
    put(pix, w, h, 77, 76, INK)
    put(pix, w, h, 83, 76, INK)
    # chain under board
    for x in range(48, 112):
        if x % 3 == 0:
            put(pix, w, h, x, 114, IRON[1])
            put(pix, w, h, x, 115, IRON[0])
    # stone dais
    stone_bricks(pix, w, h, 30, 128, 130, 150, bw=10, bh=6, seed=3732)
    threshold_bar(pix, w, h, 54, 140, 106, thick=2)
    contact_ground_shadow(pix, w, h, 80, 152, rx=46, ry=5, strength=0.32, seed=3733)
    return polish_r5(img, 3740)


def icon_warehouse_r5() -> Image.Image:
    """貨棧 — 優先打磨：貨箱／麻袋／吊索／帳簿。"""
    img = r4.icon_warehouse_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 14, 12, 146, 56, ROOF_BK + ROOF_SL, 3801)
    flying_eave_tips(pix, w, h, 16, 144, 52, ROOF_BK)
    ridge_ornaments(pix, w, h, 80, 12, span=10)
    micro_grain(pix, w, h, 26, 54, 134, 130, WOOD, 0.1, 3802)
    eave_soft_shadow(pix, w, h, 26, 54, 134, 70, strength=0.34, seed=3803)
    fancy_plaque(pix, d, w, h, 52, 52, 108, 68, n_glyphs=3)
    lacquer_door(pix, w, h, 66, 88, 94, 124, seed=3804)
    # crates denser stack
    draw_crate(pix, w, h, 14, 116, 40, 140, seed=3805)
    draw_crate(pix, w, h, 20, 104, 44, 118, seed=3806)
    draw_crate(pix, w, h, 116, 118, 144, 144, seed=3807)
    draw_crate(pix, w, h, 118, 106, 142, 120, seed=3808)
    draw_crate(pix, w, h, 44, 128, 68, 148, seed=3809)
    # sacks denser
    for cx, cy in [(72, 136), (88, 138), (104, 134), (78, 128)]:
        for dy in range(0, 14):
            for dx in range(-7, 8):
                if abs(dx) <= 7 - dy // 4:
                    put(pix, w, h, cx + dx, cy + dy, SAND[int(noise(cx + dx, cy + dy, 3810) * 3)])
        put(pix, w, h, cx, cy - 1, ROPE[0])
        put(pix, w, h, cx - 1, cy, ROPE[1] if len(ROPE) > 1 else ROPE[0])
    # hoist boom + rope + hook
    wood_plank_h(pix, w, h, 90, 58, 120, 62, seed=3811)
    for y in range(60, 108):
        put(pix, w, h, 108, y, ROPE[1 if len(ROPE) > 1 else 0])
        put(pix, w, h, 109, y, ROPE[0])
    put(pix, w, h, 108, 108, IRON[0])
    put(pix, w, h, 107, 109, IRON[1])
    put(pix, w, h, 109, 109, IRON[1])
    put(pix, w, h, 108, 110, IRON[3])
    hanging_lantern(img, 46, 60)
    hanging_lantern(img, 114, 60)
    hanging_lantern(img, 70, 96)
    hanging_lantern(img, 100, 96)
    # ledger desk + abacus hint
    wood_plank_h(pix, w, h, 24, 108, 52, 116, seed=3812)
    open_book(pix, w, h, 28, 100, 48, 112)
    for bx in range(36, 50, 3):
        put(pix, w, h, bx, 106, WOOD[0])
        put(pix, w, h, bx, 107, GOLD[2])
    threshold_bar(pix, w, h, 58, 124, 102, thick=3)
    iron_band_h(pix, w, h, 30, 90, 50)
    iron_band_h(pix, w, h, 110, 90, 130)
    contact_ground_shadow(pix, w, h, 80, 150, rx=50, ry=6, strength=0.34, seed=3813)
    return polish_r5(img, 3820)


def icon_academy_r5() -> Image.Image:
    img = r4.icon_academy_r4()
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON
    roof_scale_rows(pix, w, h, 10, 10, 150, 52, INK_TILE, 3901)
    flying_eave_tips(pix, w, h, 10, 150, 46, INK_TILE)
    ridge_ornaments(pix, w, h, 80, 8, span=12)
    micro_grain(pix, w, h, 30, 54, 130, 120, WALL, 0.06, 3902)
    micro_grain(pix, w, h, 24, 116, 136, 144, STONE, 0.08, 3903)
    eave_soft_shadow(pix, w, h, 26, 52, 134, 66, strength=0.32, seed=3904)
    fancy_plaque(pix, d, w, h, 48, 54, 112, 70, n_glyphs=4)
    vermilion_couplet(pix, w, h, 58, 74, 112)
    vermilion_couplet(pix, w, h, 98, 74, 112)
    lacquer_door(pix, w, h, 68, 84, 92, 118, seed=3905)
    threshold_bar(pix, w, h, 60, 118, 100, thick=3)
    hanging_lantern(img, 56, 60)
    hanging_lantern(img, 104, 60)
    hanging_lantern(img, 48, 94)
    hanging_lantern(img, 112, 94)
    # bamboo side
    bamboo_post(pix, w, h, 12, 90, 140, seed=3906)
    bamboo_post(pix, w, h, 148, 90, 140, seed=3907)
    scroll_roll(pix, w, h, 40, 78, length=24, vert=True)
    scroll_roll(pix, w, h, 120, 78, length=24, vert=True)
    open_book(pix, w, h, 22, 128, 40, 140)
    for fx, fy in [(20, 138), (24, 142), (28, 136), (130, 140), (134, 144), (138, 138)]:
        put(pix, w, h, fx, fy, HERB[3 % len(HERB)] if fx % 2 else VERM[3])
    lattice_window(img, 18, 88, 30, 108)
    lattice_window(img, 130, 88, 142, 108)
    contact_ground_shadow(pix, w, h, 80, 150, rx=48, ry=6, strength=0.3, seed=3908)
    return polish_r5(img, 3910)


# ===================== VILLAGE LAYERS R5 =====================

def gen_ground_r5() -> Image.Image:
    """石縫路、草叢層次；中央廣場淨。"""
    img = r4.gen_ground_r4()
    pix = img.load()

    # denser ring path with mortar seams (skip center plaza)
    for i in range(280):
        t = i / 279.0
        ang = t * math.pi * 2
        rx, ry = 310, 138
        cx, cy = 480, 365
        x = int(cx + rx * math.cos(ang))
        y = int(cy + ry * math.sin(ang) * 0.72)
        if not (0 <= x < VW and HORIZON <= y < VH):
            continue
        if abs(x - 480) < 100 and abs(y - 365) < 55:
            continue
        for dx in range(-3, 4):
            for dy in range(-2, 3):
                xx, yy = x + dx, y + dy
                if 0 <= xx < VW and 0 <= yy < VH:
                    put(pix, VW, VH, xx, yy, STONE[(dx + dy + 4) % len(STONE)])
        put(pix, VW, VH, x, y, MORTAR)
        if i % 9 == 0:
            put(pix, VW, VH, x + 1, y, PACK[1])

    # radial spokes toward anchors (light), avoid center wipe
    for cx, cy in [(480, 240), (100, 310), (860, 310), (140, 510), (840, 510),
                   (340, 520), (620, 520), (300, 380)]:
        for step in range(0, 40):
            t = step / 40.0
            x = int(480 + (cx - 480) * t)
            y = int(365 + (cy - 365) * t)
            if abs(x - 480) < 80 and abs(y - 365) < 45:
                continue
            if 0 <= x < VW and HORIZON <= y < VH and noise(x, y, 4001) < 0.55:
                put(pix, VW, VH, x, y, PACK[step % len(PACK)])
                put(pix, VW, VH, x + 1, y, STONE[step % len(STONE)])

    # grass clumps layered (not center)
    for i in range(260):
        x = 30 + (hash2(i, 1, 4002) % (VW - 60))
        y = HORIZON + 16 + (hash2(i, 2, 4003) % (VH - HORIZON - 30))
        if abs(x - 480) < 150 and abs(y - 370) < 75:
            continue
        if noise(x, y, 4004) < 0.6:
            hgt = 3 + (hash2(i, 3, 4005) % 5)
            for k in range(hgt):
                ox = (k % 3) - 1
                put(pix, VW, VH, x + ox, y - k, LEAF if k % 2 else LEAF_LT)
                put(pix, VW, VH, x + ox, y - k - 1, LEAF_DK if k == hgt - 1 else LEAF_Y)

    # pebbles / grit off-center
    for i in range(280):
        x = 60 + (hash2(i, 4, 4006) % 840)
        y = 220 + (hash2(i, 5, 4007) % 280)
        if abs(x - 480) < 110 and abs(y - 365) < 60:
            continue
        if noise(x, y, 4008) < 0.4:
            put(pix, VW, VH, x, y, STONE[hash2(i, 6, 4009) % len(STONE)])

    # soft packed earth near anchors
    for cx, cy in [(480, 240), (100, 310), (860, 310), (140, 510), (840, 510),
                   (340, 520), (620, 520), (300, 380)]:
        for dy in range(-20, 22):
            for dx in range(-44, 45):
                if (dx * dx) / 1936 + (dy * dy) / 484 < 1 and noise(cx + dx, cy + dy, 4010) < 0.42:
                    xx, yy = cx + dx, cy + dy
                    if 0 <= xx < VW and 0 <= yy < VH:
                        cur = pix[xx, yy]
                        if cur[3]:
                            pix[xx, yy] = blend(cur, PACK[1], 0.28)

    # wipe center plaza clean-ish (keep ground tone, clear clutter by blending pack soft)
    for y in range(320, 420):
        for x in range(410, 550):
            if abs(x - 480) < 65 and abs(y - 365) < 42:
                cur = pix[x, y]
                if cur[3]:
                    pix[x, y] = blend(cur, PACK[2], 0.55)

    return img


def gen_hills_r5() -> Image.Image:
    """遠山／樹再密一層。"""
    img = r4.gen_hills_r4()
    pix = img.load()

    # extra far haze ridge
    for x in range(VW):
        y0 = 60 + int(12 * math.sin(x * 0.01)) + int(7 * math.sin(x * 0.029))
        for y in range(y0, min(y0 + 32, HORIZON + 8)):
            t = (y - y0) / 32.0
            if noise(x, y, 4100) < 0.8:
                cur = pix[x, y]
                base = HILL_FAR if t < 0.4 else (HILL_MID if t < 0.75 else HILL_NEAR)
                if cur[3] == 0:
                    put(pix, VW, VH, x, y, blend(base, SKY2, 0.4 + 0.25 * t))
                else:
                    pix[x, y] = blend(cur, base, 0.12)

    # denser pine belts
    for i in range(30):
        tx = 10 + i * 32 + (hash2(i, 0, 4101) % 18)
        ty = 140 + (hash2(i, 1, 4102) % 36)
        hgt = 14 + (hash2(i, 2, 4103) % 22)
        for dy in range(0, hgt):
            half = max(1, 7 - dy // 3)
            for dx in range(-half, half + 1):
                c = PINE if dx % 2 == 0 else PINE_LT
                if dy > hgt - 4:
                    c = PINE_DK
                put(pix, VW, VH, tx + dx, ty - dy, c)
        put(pix, VW, VH, tx, ty + 1, WOOD[4])

    # deciduous clumps mid
    for i in range(14):
        tx = 40 + i * 64 + (hash2(i, 3, 4104) % 30)
        ty = 170 + (hash2(i, 4, 4105) % 24)
        for k in range(18):
            ox = (hash2(i, k, 4106) % 17) - 8
            oy = (hash2(i, k, 4107) % 12) - 6
            put(pix, VW, VH, tx + ox, ty + oy, LEAF if k % 2 else LEAF_LT)
            put(pix, VW, VH, tx + ox, ty + oy - 1, LEAF_DK)

    # birds
    for bx, by in [(100, 44), (220, 30), (360, 50), (520, 26), (680, 40), (820, 32), (900, 48), (440, 66)]:
        put(pix, VW, VH, bx, by, INK2)
        put(pix, VW, VH, bx - 1, by - 1, INK3)
        put(pix, VW, VH, bx + 1, by - 1, INK3)

    # distant roof tips
    for px, py in [(640, 96), (260, 108), (780, 102)]:
        for x in range(px - 12, px + 13):
            put(pix, VW, VH, x, py, ROOF_R[2])
            put(pix, VW, VH, x, py + 1, ROOF_R[0])
        put(pix, VW, VH, px, py - 2, GOLD[2])

    # cloud bands
    for cx, cy, r in [(140, 36, 20), (420, 24, 24), (700, 38, 18), (880, 30, 16)]:
        for dy in range(-r // 2, r // 2 + 1):
            for dx in range(-r, r + 1):
                if (dx * dx) / (r * r) + (dy * dy) / ((r * 0.4) ** 2) < 1:
                    if noise(cx + dx, cy + dy, 4108) < 0.55:
                        put(pix, VW, VH, cx + dx, cy + dy, blend(CLOUD, SKY1, 0.38))

    return img


def gen_pad_r5() -> Image.Image:
    """建築墊層：正式 tile 必須全透明（唔焗碰撞盒／灰框／虛線格／金角標）。"""
    return new_img(VW, VH)


def gen_fg_r5() -> Image.Image:
    """前景籬笆／桶／竹再密；中央淨。"""
    img = r4.gen_fg_r4()
    pix = img.load()

    # denser side fences
    for base_x in list(range(0, 180, 12)) + list(range(780, VW, 12)):
        wood_plank_v(pix, VW, VH, base_x + 1, VH - 74, base_x + 4, VH - 6, seed=4200 + base_x)
        for yy in (VH - 60, VH - 42, VH - 24):
            for xx in range(base_x + 1, min(base_x + 14, VW)):
                put(pix, VW, VH, xx, yy, WOOD[2 if yy % 2 else 1])
                put(pix, VW, VH, xx, yy + 1, WOOD[0])

    # mid-side stubs
    for base_x in (170, 190, 210, 730, 750, 770):
        wood_plank_v(pix, VW, VH, base_x, 370, base_x + 3, 470, seed=4210 + base_x)
        for yy in (390, 420, 450):
            for xx in range(base_x, base_x + 22):
                put(pix, VW, VH, xx, yy, WOOD[1])

    # lantern posts
    for lx, ly in [(60, 240), (900, 240), (48, 370), (912, 370), (90, 470), (870, 470), (30, 300), (930, 300)]:
        wood_plank_v(pix, VW, VH, lx, ly, lx + 3, ly + 54, seed=4220 + lx)
        hanging_lantern(img, lx + 1, ly - 4)

    # bamboo denser
    for bx in (8, 22, 38, 52, 908, 922, 938, 952):
        bamboo_post(pix, VW, VH, bx, 270, 430, seed=4230 + bx)
        bamboo_post(pix, VW, VH, bx + 6, 290, 450, seed=4231 + bx)

    # barrels / jars
    for cx, cy in [(120, VH - 34), (180, VH - 30), (220, VH - 36), (740, VH - 34), (800, VH - 30), (850, VH - 28)]:
        for dy in range(0, 18):
            for dx in range(-7, 8):
                if abs(dx) <= 7 - dy // 8:
                    put(pix, VW, VH, cx + dx, cy + dy, WOOD_LAC[1 if dy < 13 else 0])
        put(pix, VW, VH, cx, cy - 1, IRON[0])
        iron_band_h(pix, VW, VH, cx - 6, cy + 5, cx + 6)
        iron_band_h(pix, VW, VH, cx - 6, cy + 11, cx + 6)

    # rocks
    for rx, ry, rr in [(80, VH - 22, 8), (880, VH - 20, 7), (240, VH - 18, 5), (720, VH - 18, 5), (160, VH - 16, 4)]:
        fill_disk(pix, VW, VH, rx, ry, rr, STONE, seed=4240 + rx)
        put(pix, VW, VH, rx - 2, ry - 2, STONE[3])

    # fallen leaves sides
    for i in range(220):
        x = hash2(i, 1, 4250) % VW
        if 260 < x < 700:
            continue
        y = VH - 80 + (hash2(i, 2, 4251) % 70)
        put(pix, VW, VH, x, y, LEAF_Y if i % 3 else VERM[3])

    # crates near FG corners
    draw_crate(pix, VW, VH, 40, VH - 40, 70, VH - 12, seed=4260)
    draw_crate(pix, VW, VH, 890, VH - 42, 920, VH - 14, seed=4261)

    # wipe center FG
    for y in range(270, 470):
        for x in range(370, 590):
            if abs(x - 480) < 95 and abs(y - 360) < 75:
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
        "manor": icon_manor_r5,
        "inn": icon_inn_r5,
        "forge": icon_forge_r5,
        "clinic": icon_clinic_r5,
        "training": icon_training_r5,
        "bounty": icon_bounty_r5,
        "warehouse": icon_warehouse_r5,
        "academy": icon_academy_r5,
    }

    buildings = {}
    print("Generating R5 buildings 160×160…")
    for name in BUILDING_NAMES:
        print(f"  · {name}")
        im = gens[name]()
        assert im.size == (ICON, ICON), f"{name} size {im.size}"
        im.save(BUILDINGS / f"{name}.png")
        buildings[name] = im

    print("Generating R5 village layers 960×540…")
    ground = gen_ground_r5()
    hills = gen_hills_r5()
    pad = gen_pad_r5()
    fg = gen_fg_r5()
    for layer, im in (
        ("village_ground.png", ground),
        ("village_hills.png", hills),
        ("village_buildings_pad.png", pad),
        ("village_fg.png", fg),
    ):
        assert im.size == (VW, VH), f"{layer} size {im.size}"
        im.save(TILES / layer)

    # pad must be fully transparent
    nont = sum(1 for px in pad.getdata() if px[3] > 0)
    assert nont == 0, f"pad not empty: {nont} nont"

    print("Composing previews…")
    composed = compose(ground, hills, pad, fg, buildings, SLOTS)
    composed.save(TILES / "village_composed.png")
    composed.save(PREVIEW / "pivot_r5_village.png")
    composed.save(PREVIEW / "village_composed.png")

    layers_only = compose(ground, hills, pad, fg)
    layers_only.save(PREVIEW / "pivot_r5_layers_only.png")

    row_all = preview_row([(buildings[n], n) for n in BUILDING_NAMES])
    row_all.save(PREVIEW / "pivot_r5_all_buildings.png")
    row_all.resize((row_all.width * 2, row_all.height * 2), Image.NEAREST).save(
        PREVIEW / "pivot_r5_all_buildings_x2.png"
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
    pad_check = Image.open(TILES / "village_buildings_pad.png")
    nont2 = sum(1 for px in pad_check.getdata() if px[3] > 0)
    print(f"  pad nont: {nont2} (must 0)")
    print(f"  preview: {PREVIEW / 'pivot_r5_all_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r5_all_buildings_x2.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r5_village.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r5_layers_only.png'}")
    print("錨點:", SLOTS)
    print("重生：python3 tools/gen_pivot_r5.py")


if __name__ == "__main__":
    main()
