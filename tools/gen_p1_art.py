#!/usr/bin/env python3
"""墨點俠村 P1 村莊／UI 像素素材生成器
墨點江湖：宣紙底、硬邊直角、嚴格色盤、Nearest。
"""
from __future__ import annotations

import os
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

# 家族微調
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
SKY = (0xC8, 0xD4, 0xC8, 255)  # 宣紙偏青綠天邊
SKY_DK = (0xA8, 0xB8, 0xB0, 255)
HILL = (0x3A, 0x5A, 0x4A, 255)
HILL_MID = (0x4A, 0x6A, 0x58, 255)
HILL_FAR = (0x6A, 0x82, 0x72, 255)
SHADOW = (0x1A, 0x15, 0x10, 90)
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

# 六建築位中心（960×540），可點區域約 120×100
BUILDING_SLOTS = {
    "manor": (480, 210),      # 中央偏上
    "inn": (220, 280),        # 左中
    "forge": (740, 280),      # 右中
    "clinic": (160, 380),     # 左下
    "training": (800, 380),   # 右下
    "bounty": (480, 360),     # 中央偏下
}


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), TRANS)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c, size: int = 1) -> None:
    if size == 1:
        draw.point((x, y), fill=c)
    else:
        draw.rectangle([x, y, x + size - 1, y + size - 1], fill=c)


def rect(draw: ImageDraw.ImageDraw, x0, y0, x1, y1, c) -> None:
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


def fill_checker(img: Image.Image, x0, y0, x1, y1, c1, c2, step=4) -> None:
    pix = img.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                pix[x, y] = c1 if ((x // step) + (y // step)) % 2 == 0 else c2


def dither_dot(img: Image.Image, x0, y0, x1, y1, c, dens=0.12, seed=7) -> None:
    """Deterministic sparse dots for texture (no AA)."""
    pix = img.load()
    n = seed
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < img.width and 0 <= y < img.height:
                n = (n * 1103515245 + 12345 + x * 17 + y * 31) & 0x7FFFFFFF
                if (n % 1000) < int(dens * 1000):
                    pix[x, y] = c


# ===================== VILLAGE LAYERS =====================

def gen_village_ground() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    # 下半泥土／草地；上半留空給遠山
    horizon = 200
    # 草地帶
    rect(d, 0, horizon, VW - 1, VH - 1, GRASS)
    # 草地明暗帶
    for y in range(horizon, VH, 8):
        shade = GRASS_LT if (y // 8) % 2 == 0 else GRASS_DK
        dens = 0.05 if shade == GRASS_LT else 0.04
        dither_dot(img, 0, y, VW - 1, min(y + 7, VH - 1), shade, dens=dens, seed=y)

    # 中央石徑（蜿蜒到村長府）
    path_pts = []
    for i in range(40):
        t = i / 39
        y = 220 + int(t * 300)
        x = 480 + int(28 * (1 if i % 2 == 0 else -1) * (0.3 + 0.7 * t * (1 - t) * 4))
        # simpler: straight with slight wobble
        x = 480 + int(18 * __import__("math").sin(t * 3.14 * 2))
        path_pts.append((x, y))

    # 石徑寬帶
    pix = img.load()
    for i, (cx, cy) in enumerate(path_pts):
        half = 28 + (i // 8)
        for dy in range(-6, 7):
            for dx in range(-half, half + 1):
                x, y = cx + dx, cy + dy
                if 0 <= x < VW and 0 <= y < VH and y >= horizon:
                    # 石塊格子
                    tile = ((x // 6) + (y // 5)) % 3
                    if tile == 0:
                        pix[x, y] = STONE
                    elif tile == 1:
                        pix[x, y] = STONE_LT
                    else:
                        pix[x, y] = STONE_DK
                    # 縫
                    if x % 6 == 0 or y % 5 == 0:
                        pix[x, y] = INK_MID

    # 泥土邊緣沿石徑
    for i, (cx, cy) in enumerate(path_pts):
        half = 28 + (i // 8)
        for side in (-1, 1):
            for dy in range(-4, 5):
                for dx in range(0, 10):
                    x = cx + side * (half + dx)
                    y = cy + dy
                    if 0 <= x < VW and 0 <= y < VH and y >= horizon:
                        pix[x, y] = DIRT if dx < 5 else DIRT_LT

    # 左右泥土／草混
    for y in range(horizon + 20, VH):
        for x in range(0, 80):
            if ((x + y) % 9) < 3:
                pix[x, y] = DIRT
        for x in range(VW - 80, VW):
            if ((x + y) % 9) < 3:
                pix[x, y] = DIRT

    # 石徑磚縫加強（可讀密度）
    for y in range(horizon, VH, 10):
        for x in range(400, 560):
            if 0 <= x < VW and pix[x, y][0:3] in (STONE[:3], STONE_LT[:3], STONE_DK[:3]):
                if x % 12 == 0:
                    pix[x, y] = INK_SOFT

    # 小石點散佈
    dither_dot(img, 100, horizon + 40, 380, VH - 20, STONE_DK, dens=0.015, seed=99)
    dither_dot(img, 580, horizon + 40, 860, VH - 20, STONE_DK, dens=0.015, seed=101)

    # 草叢點（青綠家族）
    for gx, gy in [(90, 320), (120, 450), (850, 340), (880, 470), (300, 500), (660, 510)]:
        for dy in range(-3, 4):
            for dx in range(-5, 6):
                x, y = gx + dx, gy + dy
                if 0 <= x < VW and 0 <= y < VH:
                    if abs(dx) + abs(dy) < 6:
                        pix[x, y] = TEAL if (dx + dy) % 2 == 0 else TEAL_DK

    return img


def gen_village_hills() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    # 天邊淡帶（宣紙偏青）——硬邊水平
    rect(d, 0, 0, VW - 1, 199, SKY)
    # 天邊漸層用硬邊條帶（唔用柔邊）
    for i, c in enumerate([SKY, SKY, SKY_DK, PAPER_DK]):
        y0 = 40 + i * 20
        rect(d, 0, y0, VW - 1, y0 + 19, c)

    # 遠山三層硬邊山帶
    def mountain_band(base_y, peaks, color, mid_color):
        # peaks: list of (x, height)
        pts = [(0, base_y)]
        for px_, h in peaks:
            pts.append((px_ - 40, base_y))
            pts.append((px_, base_y - h))
            pts.append((px_ + 40, base_y))
        pts.append((VW - 1, base_y))
        pts.append((VW - 1, 199))
        pts.append((0, 199))
        d.polygon(pts, fill=color)
        # 山脊墨線
        for i in range(len(peaks)):
            px_, h = peaks[i]
            d.line([(px_ - 40, base_y), (px_, base_y - h), (px_ + 40, base_y)], fill=INK, width=1)
        # 山腰暗帶
        for px_, h in peaks:
            rect(d, px_ - 15, base_y - h // 3, px_ + 8, base_y - 2, mid_color)

    mountain_band(160, [(120, 70), (280, 95), (450, 60), (620, 100), (800, 75), (920, 55)], HILL_FAR, HILL_MID)
    mountain_band(185, [(80, 50), (220, 70), (400, 45), (560, 80), (720, 55), (880, 65)], HILL_MID, HILL)
    mountain_band(200, [(150, 40), (340, 55), (520, 35), (700, 60), (860, 40)], HILL, TEAL_DK)

    # 山腳墨點樹叢剪影
    pix = img.load()
    for tx in range(0, VW, 18):
        by = 195 + (tx * 7 % 5)
        for dy in range(0, 12):
            w = 6 - dy // 3
            for dx in range(-w, w + 1):
                x, y = tx + dx, by - dy
                if 0 <= x < VW and 0 <= y < VH:
                    pix[x, y] = INK if dy > 8 else TEAL_DK

    return img


def gen_village_buildings_pad() -> Image.Image:
    """建築位墊：清晰可點基座，唔畫滿建築本體。"""
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # pad size
    pw, ph = 110, 72

    for key, (cx, cy) in BUILDING_SLOTS.items():
        x0, y0 = cx - pw // 2, cy - ph // 2
        x1, y1 = x0 + pw - 1, y0 + ph - 1
        # 陰影硬位移
        rect(d, x0 + 3, y0 + 3, x1 + 3, y1 + 3, INK_SOFT)
        # 木台基座
        rect(d, x0, y0, x1, y1, WOOD)
        # 頂面宣紙淺
        rect(d, x0 + 2, y0 + 2, x1 - 2, y1 - 10, PAPER_DK)
        # 木紋橫線
        for yy in range(y0 + 4, y1 - 10, 5):
            hline(d, x0 + 3, x1 - 3, yy, WOOD_DK if (yy // 5) % 2 == 0 else WOOD_LT)
        # 石腳
        rect(d, x0, y1 - 8, x1, y1, STONE)
        for xx in range(x0, x1, 8):
            vline(d, xx, y1 - 8, y1, STONE_DK)
        hard_border(d, x0, y0, x1, y1, INK)
        # 金角點綴（可點提示）
        rect(d, x0 + 2, y0 + 2, x0 + 5, y0 + 5, GOLD)
        rect(d, x1 - 5, y0 + 2, x1 - 2, y0 + 5, GOLD)
        # 中心小標記（建築錨）
        ax, ay = cx, cy - 4
        rect(d, ax - 3, ay - 3, ax + 3, ay + 3, TEAL)
        hard_border(d, ax - 3, ay - 3, ax + 3, ay + 3, INK)
        # 腳點
        dither_dot(img, x0 + 4, y1 - 6, x1 - 4, y1 - 2, STONE_DK, dens=0.2, seed=hash(key) % 1000)

    return img


def gen_village_fg() -> Image.Image:
    img = new_img(VW, VH)
    d = ImageDraw.Draw(img)
    pix = img.load()

    # 左右樹梢（唔擋中央）
    def tree(tx, ty, h=80):
        # 樹幹
        rect(d, tx - 3, ty - h // 2, tx + 3, ty + 20, WOOD_DK)
        hard_border(d, tx - 3, ty - h // 2, tx + 3, ty + 20, INK)
        # 葉團硬邊三角／方
        for i, (ox, oy, r) in enumerate([(-18, -h // 2, 22), (10, -h // 2 - 8, 20), (-2, -h // 2 - 18, 18)]):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if abs(dx) + abs(dy) < r:
                        x, y = tx + ox + dx, ty + oy + dy
                        if 0 <= x < VW and 0 <= y < VH:
                            pix[x, y] = TEAL if (dx + dy + i) % 3 else TEAL_DK
            # 墨輪廓稀疏
            for a in range(0, 360, 20):
                import math
                x = tx + ox + int(r * 0.9 * math.cos(a * 3.14159 / 180))
                y = ty + oy + int(r * 0.9 * math.sin(a * 3.14159 / 180))
                if 0 <= x < VW and 0 <= y < VH:
                    pix[x, y] = INK

    tree(40, 420, 90)
    tree(30, 300, 70)
    tree(920, 400, 85)
    tree(930, 280, 65)

    # 前景籬笆邊緣（底邊）
    for x in range(0, VW, 14):
        # 木樁
        bx = x + 2
        rect(d, bx, VH - 36, bx + 4, VH - 4, WOOD)
        hard_border(d, bx, VH - 36, bx + 4, VH - 4, INK)
        # 橫條
        if x + 14 < VW:
            rect(d, bx, VH - 28, x + 14, VH - 25, WOOD_LT)
            rect(d, bx, VH - 16, x + 14, VH - 13, WOOD_LT)

    # 左右燈籠
    def lantern(lx, ly):
        # 掛繩
        vline(d, lx, ly - 30, ly - 2, INK)
        # 燈身硃紅
        rect(d, lx - 8, ly - 2, lx + 8, ly + 18, VERMILION)
        rect(d, lx - 6, ly, lx + 6, ly + 14, VERM_LT)
        hard_border(d, lx - 8, ly - 2, lx + 8, ly + 18, INK)
        # 金頂底
        rect(d, lx - 9, ly - 4, lx + 9, ly - 2, GOLD)
        rect(d, lx - 9, ly + 18, lx + 9, ly + 20, GOLD)
        # 穗
        vline(d, lx, ly + 20, ly + 28, VERM_DK)

    lantern(70, 200)
    lantern(890, 200)

    # 底角草叢前景
    for gx in [20, 50, 900, 940]:
        for dy in range(0, 16):
            for dx in range(-8, 9):
                if abs(dx) < 8 - dy // 2:
                    x, y = gx + dx, VH - 40 - dy
                    if 0 <= x < VW and 0 <= y < VH:
                        pix[x, y] = GRASS_DK if dx % 2 == 0 else TEAL

    return img


def compose_village() -> Image.Image:
    layers = [
        gen_village_ground(),
        gen_village_hills(),
        gen_village_buildings_pad(),
        gen_village_fg(),
    ]
    # 正確 z：ground → hills → pad → fg；但 hills 應在 ground 上、且 hills 上部覆蓋
    # ground 只應在下半；hills 畫了天空+山。合成時 hills 先、還是 ground 先？
    # z-order: ground → hills → buildings_pad → fg
    # 但 hills 有天空會蓋住 ground 上半空白——OK。hills 下半透明？我們 hills 只畫到 ~200。
    # ground 從 200 開始。合成：
    out = new_img(VW, VH)
    # 宣紙底
    d = ImageDraw.Draw(out)
    rect(d, 0, 0, VW - 1, VH - 1, PAPER)
    for layer in layers:
        out = Image.alpha_composite(out, layer)
    return out


# ===================== BUILDING ICONS 96×96 =====================

def foot_shadow(d, x0, y0, x1, y1, ox=3, oy=3):
    """硬位移腳影（不透明墨褐，保持盤內色），唔用實心背板。"""
    rect(d, x0 + ox, y0 + oy, x1 + ox, y1 + oy, INK_SOFT)


def icon_manor() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 14, 70, 80, 86)
    # 台基
    rect(d, 14, 70, 80, 86, STONE)
    hard_border(d, 14, 70, 80, 86, INK)
    # 主體牆宣紙
    rect(d, 20, 36, 74, 72, PAPER)
    hard_border(d, 20, 36, 74, 72, INK)
    # 柱
    rect(d, 24, 38, 28, 70, WOOD)
    rect(d, 66, 38, 70, 70, WOOD)
    # 門
    rect(d, 40, 48, 54, 72, WOOD_DK)
    hard_border(d, 40, 48, 54, 72, INK)
    rect(d, 46, 56, 48, 60, GOLD)  # 門環
    # 屋簷硃紅
    d.polygon([(16, 40), (48, 18), (80, 40)], fill=VERMILION)
    d.line([(16, 40), (48, 18), (80, 40)], fill=INK)
    rect(d, 18, 38, 78, 42, VERM_DK)
    # 脊金點
    rect(d, 46, 16, 50, 20, GOLD)
    # 窗
    rect(d, 26, 48, 34, 56, TEAL_DK)
    rect(d, 60, 48, 68, 56, TEAL_DK)
    hard_border(d, 26, 48, 34, 56, INK)
    hard_border(d, 60, 48, 68, 56, INK)
    return img


def icon_inn() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 18, 40, 78, 80)
    # 兩層樓
    rect(d, 18, 40, 78, 80, PAPER_DK)
    hard_border(d, 18, 40, 78, 80, INK)
    rect(d, 22, 48, 74, 56, WOOD)  # 二樓欄
    # 招牌硃紅旗
    rect(d, 70, 28, 86, 52, VERMILION)
    hard_border(d, 70, 28, 86, 52, INK)
    rect(d, 74, 34, 82, 38, CREAM)
    rect(d, 74, 42, 82, 46, CREAM)
    # 屋頂
    d.polygon([(14, 44), (48, 22), (82, 44)], fill=WOOD)
    d.line([(14, 44), (48, 22), (82, 44)], fill=INK)
    rect(d, 16, 42, 80, 46, WOOD_DK)
    # 門簾
    rect(d, 38, 58, 58, 80, VERM_LT)
    vline(d, 48, 58, 80, INK)
    hard_border(d, 38, 58, 58, 80, INK)
    # 燈籠
    rect(d, 24, 60, 32, 72, VERMILION)
    hard_border(d, 24, 60, 32, 72, INK)
    return img


def icon_forge() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 16, 48, 78, 82)
    # 棚屋
    rect(d, 16, 48, 78, 82, WOOD)
    hard_border(d, 16, 48, 78, 82, INK)
    d.polygon([(12, 52), (48, 28), (84, 52)], fill=INK_MID)
    d.line([(12, 52), (48, 28), (84, 52)], fill=INK)
    # 爐火
    rect(d, 28, 56, 48, 78, INK)
    rect(d, 32, 60, 44, 74, VERM_DK)
    rect(d, 34, 64, 42, 70, VERMILION)
    rect(d, 36, 66, 40, 68, GOLD_LT)  # 火芯
    # 鐵砧剪影
    rect(d, 54, 64, 74, 72, STONE_DK)
    rect(d, 58, 58, 70, 64, STONE)
    rect(d, 62, 72, 66, 80, STONE_DK)
    hard_border(d, 54, 64, 74, 72, INK)
    hard_border(d, 58, 58, 70, 64, INK)
    # 煙
    for sx, sy in [(36, 44), (40, 36), (34, 30)]:
        rect(d, sx, sy, sx + 4, sy + 4, PAPER_SH)
    return img


def icon_clinic() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 22, 42, 74, 80)
    rect(d, 22, 42, 74, 80, PAPER)
    hard_border(d, 22, 42, 74, 80, INK)
    # 青綠屋簷（藥）
    d.polygon([(18, 46), (48, 24), (78, 46)], fill=TEAL)
    d.line([(18, 46), (48, 24), (78, 46)], fill=INK)
    rect(d, 20, 44, 76, 48, TEAL_DK)
    # 門
    rect(d, 40, 56, 56, 80, WOOD)
    hard_border(d, 40, 56, 56, 80, INK)
    # 藥葫蘆
    rect(d, 26, 58, 36, 64, TEAL_LT)  # 上
    rect(d, 24, 64, 38, 76, TEAL)     # 下
    hard_border(d, 24, 64, 38, 76, INK)
    hline(d, 24, 38, 64, INK)
    rect(d, 28, 56, 34, 58, GOLD)  # 塞
    # 旗
    vline(d, 68, 28, 50, INK)
    rect(d, 68, 28, 84, 40, VERMILION)
    hard_border(d, 68, 28, 84, 40, INK)
    return img


def icon_training() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 12, 60, 84, 86)
    # 場地
    rect(d, 12, 60, 84, 86, DIRT)
    hard_border(d, 12, 60, 84, 86, INK)
    # 木紋地
    for y in range(64, 84, 4):
        hline(d, 14, 82, y, DIRT_DK if (y // 4) % 2 == 0 else DIRT_LT)
    # 圍欄
    for x in (16, 30, 44, 58, 72):
        rect(d, x, 48, x + 3, 62, WOOD)
        hard_border(d, x, 48, x + 3, 62, INK)
    hline(d, 16, 75, 52, WOOD_LT)
    # 木人樁
    rect(d, 42, 28, 54, 60, WOOD_DK)
    hard_border(d, 42, 28, 54, 60, INK)
    # 頭
    rect(d, 40, 18, 56, 32, WOOD)
    hard_border(d, 40, 18, 56, 32, INK)
    # 橫臂
    rect(d, 28, 36, 68, 42, WOOD)
    hard_border(d, 28, 36, 68, 42, INK)
    # 硃紅靶點
    rect(d, 46, 38, 50, 40, VERMILION)
    return img


def icon_bounty() -> Image.Image:
    img = new_img(96, 96)
    d = ImageDraw.Draw(img)
    foot_shadow(d, 18, 28, 78, 86)
    # 木板架
    rect(d, 28, 20, 36, 86, WOOD_DK)
    rect(d, 60, 20, 68, 86, WOOD_DK)
    hard_border(d, 28, 20, 36, 86, INK)
    hard_border(d, 60, 20, 68, 86, INK)
    # 告示板
    rect(d, 18, 28, 78, 72, PAPER)
    hard_border(d, 18, 28, 78, 72, INK)
    # 金邊內框
    hard_border(d, 22, 32, 74, 68, GOLD)
    # 告示條
    rect(d, 28, 38, 68, 44, VERMILION)
    rect(d, 28, 48, 68, 52, INK_MID)
    rect(d, 28, 56, 58, 60, INK_SOFT)
    # 頂橫木
    rect(d, 16, 18, 80, 26, WOOD)
    hard_border(d, 16, 18, 80, 26, INK)
    # 釘
    rect(d, 30, 20, 32, 22, GOLD)
    rect(d, 64, 20, 66, 22, GOLD)
    return img


# ===================== UI =====================

def gen_hud_panel() -> Image.Image:
    w, h = 320, 64
    img = new_img(w, h)
    d = ImageDraw.Draw(img)
    # 外墨
    rect(d, 0, 0, w - 1, h - 1, INK)
    # 金邊
    rect(d, 2, 2, w - 3, h - 3, GOLD)
    # 宣紙底
    rect(d, 4, 4, w - 5, h - 5, PAPER)
    # 內墨細線
    hard_border(d, 4, 4, w - 5, h - 5, INK)
    # 頂高光 1px cream
    hline(d, 5, w - 6, 5, CREAM)
    # 底暗
    hline(d, 5, w - 6, h - 6, PAPER_SH)
    # 分隔槽（資源位示意）
    for x in (64, 128, 192, 256):
        vline(d, x, 10, h - 11, PAPER_DK)
        vline(d, x + 1, 10, h - 11, PAPER_SH)
    # 四角金飾
    for cx, cy in [(8, 8), (w - 12, 8), (8, h - 12), (w - 12, h - 12)]:
        rect(d, cx, cy, cx + 3, cy + 3, GOLD_DK)
    return img


# 極簡硬像素漢字（點陣）——派遣／建造
# 用 5×7 風格自繪可讀字形

DISPATCH_GLYPHS = {
    # 「派」簡化 7×7 兩字並排會太大；改畫單字標記 + 色塊
}


def _blit_pixel_font(draw, text_key, ox, oy, color=INK):
    """極簡可讀硬像素字形（自製 5×7）。"""
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
    # 陰影
    rect(d, 3, 3, w - 1, h - 1, INK_SOFT)
    # 外框墨
    rect(d, 0, 0, w - 4, h - 4, INK)
    # 金邊
    rect(d, 2, 2, w - 6, h - 6, GOLD)
    # 底色
    rect(d, 4, 4, w - 8, h - 8, accent)
    # 內宣紙帶
    rect(d, 8, 8, w - 12, h - 12, PAPER)
    hard_border(d, 8, 8, w - 12, h - 12, INK)
    # 高光
    hline(d, 9, w - 13, 9, CREAM)
    # 字形
    gap = 28
    start_x = (w - 4 - gap * (len(label_chars) - 1) - 14) // 2
    for i, ch in enumerate(label_chars):
        _blit_pixel_font(d, ch, start_x + i * gap, 12, INK)
    return img


def gen_btn_dispatch() -> Image.Image:
    return gen_btn(["派", "遣"], VERMILION)


def gen_btn_build() -> Image.Image:
    return gen_btn(["建", "造"], TEAL)


# ===================== RESOURCE ICONS 32×32 =====================

def icon_silver() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    # 元寶／銀錠
    rect(d, 10, 14, 24, 26, INK_SOFT)  # shadow
    d.polygon([(6, 18), (10, 10), (22, 10), (26, 18), (22, 24), (10, 24)], fill=STONE_LT)
    d.line([(6, 18), (10, 10), (22, 10), (26, 18), (22, 24), (10, 24), (6, 18)], fill=INK)
    rect(d, 12, 14, 20, 18, CREAM)
    rect(d, 14, 12, 18, 14, GOLD)  # 金印
    return img


def icon_wood() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 12, 28, 28, INK_SOFT)
    # 三根原木
    for i, y in enumerate((8, 14, 20)):
        rect(d, 6, y, 26, y + 6, WOOD if i != 1 else WOOD_LT)
        hard_border(d, 6, y, 26, y + 6, INK)
        # 年輪端
        rect(d, 6, y + 1, 9, y + 5, WOOD_DK)
        rect(d, 7, y + 2, 8, y + 3, PAPER_DK)
    return img


def icon_hide() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 10, 26, 28, INK_SOFT)
    # 獸皮捲
    d.ellipse([6, 8, 26, 26], fill=WOOD_LT)
    d.ellipse([6, 8, 26, 26], outline=INK)
    d.ellipse([10, 12, 22, 22], fill=WOOD)
    d.ellipse([10, 12, 22, 22], outline=INK)
    # 毛點
    for p in [(9, 11), (20, 10), (12, 20), (18, 18)]:
        rect(d, p[0], p[1], p[0] + 1, p[1] + 1, DIRT_DK)
    return img


def icon_iron() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    rect(d, 8, 12, 26, 28, INK_SOFT)
    # 鐵錠
    rect(d, 6, 10, 26, 22, STONE_DK)
    hard_border(d, 6, 10, 26, 22, INK)
    rect(d, 8, 12, 24, 14, STONE)
    rect(d, 8, 18, 24, 20, INK)
    # 高光
    hline(d, 8, 16, 12, STONE_LT)
    return img


def icon_herb() -> Image.Image:
    img = new_img(32, 32)
    d = ImageDraw.Draw(img)
    # 葉
    rect(d, 14, 18, 18, 28, TEAL_DK)  # 莖
    hard_border(d, 14, 18, 18, 28, INK)
    d.polygon([(16, 4), (6, 16), (16, 14)], fill=TEAL)
    d.polygon([(16, 4), (26, 16), (16, 14)], fill=TEAL_LT)
    d.line([(16, 4), (6, 16), (16, 14), (16, 4)], fill=INK)
    d.line([(16, 4), (26, 16), (16, 14)], fill=INK)
    # 硃紅花蕾
    rect(d, 14, 2, 18, 6, VERMILION)
    hard_border(d, 14, 2, 18, 6, INK)
    return img


# ===================== MAIN =====================

def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(f"  wrote {path.relative_to(ROOT)}  {img.size[0]}×{img.size[1]}")


def audit_colors(img: Image.Image, name: str, allowed_rgb: set) -> list:
    """回報盤外色（忽略透明）。"""
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
    return list(bad.keys())


def main() -> None:
    print("=== 墨點俠村 P1 art gen ===")
    PREVIEW.mkdir(parents=True, exist_ok=True)

    # Village layers
    print("-- tiles --")
    ground = gen_village_ground()
    hills = gen_village_hills()
    pads = gen_village_buildings_pad()
    fg = gen_village_fg()
    save(ground, TILES / "village_ground.png")
    save(hills, TILES / "village_hills.png")
    save(pads, TILES / "village_buildings_pad.png")
    save(fg, TILES / "village_fg.png")

    composed = new_img(VW, VH)
    d = ImageDraw.Draw(composed)
    rect(d, 0, 0, VW - 1, VH - 1, PAPER)
    for layer in (ground, hills, pads, fg):
        composed = Image.alpha_composite(composed, layer)
    # 建築圖示疊上預覽
    building_imgs = {
        "manor": icon_manor(),
        "inn": icon_inn(),
        "forge": icon_forge(),
        "clinic": icon_clinic(),
        "training": icon_training(),
        "bounty": icon_bounty(),
    }
    for key, icon in building_imgs.items():
        cx, cy = BUILDING_SLOTS[key]
        composed.alpha_composite(icon, (cx - 48, cy - 56))
    save(composed, TILES / "village_composed.png")
    save(composed, PREVIEW / "village_composed.png")

    print("-- buildings --")
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

    # UI strip preview
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
    # building row
    bx = 8
    brow = new_img(600, 100)
    bd = ImageDraw.Draw(brow)
    rect(bd, 0, 0, 599, 99, PAPER_SH)
    for key in ("manor", "inn", "forge", "clinic", "training", "bounty"):
        brow.alpha_composite(building_imgs[key], (bx, 2))
        bx += 100
    save(strip, PREVIEW / "ui_strip.png")
    save(brow, PREVIEW / "buildings_row.png")

    # Color audit
    allowed = set()
    for hx in PALETTE_HEX.values():
        r = int(hx[1:3], 16)
        g = int(hx[3:5], 16)
        b = int(hx[5:7], 16)
        allowed.add((r, g, b))
    print("-- audit --")
    for p in list(TILES.glob("*.png")) + list(BUILDINGS.glob("*.png")) + list(UI.glob("*.png")):
        im = Image.open(p).convert("RGBA")
        audit_colors(im, p.name, allowed)

    # manifest
    print("\n=== DONE ===")
    print("BUILDING_SLOTS (cx,cy):")
    for k, v in BUILDING_SLOTS.items():
        print(f"  {k}: {v}")
    print("Palette:")
    for k, v in PALETTE_HEX.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
