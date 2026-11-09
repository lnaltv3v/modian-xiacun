#!/usr/bin/env python3
"""墨點俠村 · Pivot R6 UI 高密度

武俠 UI：木框／宣紙或暗漆、硃紅金點綴；對齊 Pivot 高密度，唔抄版權資產。
暫時放寬舊墨點硬邊／5 色盤。按鈕中央留白俾 Godot Button 字。

尺寸：hud 320×64；btn 128×40；icon 32×32。
重生：python3 tools/gen_pivot_r6_ui.py
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
UI = ART / "ui"
PREVIEW = ART / "_preview"
PREV = ART / "_prev_pivot_r5" / "ui"

TRANS = r1.TRANS
C = r1.C
INK, INK2, INK3 = r1.INK, r1.INK2, r1.INK3
SHADOW = r1.SHADOW
WOOD = r1.WOOD
WOOD_LAC = r1.WOOD_LAC
GOLD = r1.GOLD
IRON = r1.IRON
TEAL = r1.TEAL
VERM = r1.VERM
CREAM = r1.CREAM
STONE = r1.STONE
DIRT = r1.DIRT
PAPER = r2.PAPER
HERB = r2.HERB
JADE = r2.JADE

new_img = r1.new_img
put = r1.put
blend = r1.blend
hash2 = r1.hash2
noise = r1.noise
rect = r1.rect
wood_plank_h = r1.wood_plank_h
wood_plank_v = r1.wood_plank_v
micro_grain = r2.micro_grain

# silver metal extras
SILVER = [C("D8DCE0"), C("C0C4C8"), C("E8ECF0"), C("A8ACB0"), C("F4F6F8"), C("888C90")]
HIDE = [C("A87848"), C("8A5A30"), C("C09058"), C("6A4020"), C("D0A868"), C("B88850")]


def ensure_backup() -> None:
    PREV.mkdir(parents=True, exist_ok=True)
    for name in (
        "hud_panel.png",
        "btn_dispatch.png",
        "btn_build.png",
        "icon_silver.png",
        "icon_wood.png",
        "icon_hide.png",
        "icon_iron.png",
        "icon_herb.png",
    ):
        src = UI / name
        dst = PREV / name
        if src.exists() and not dst.exists():
            shutil.copy2(src, dst)


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print(f"  wrote {path.relative_to(ROOT)}  {img.size[0]}×{img.size[1]}")


def nearest_x2(img: Image.Image) -> Image.Image:
    return img.resize((img.width * 2, img.height * 2), Image.NEAREST)


# ---------- wood / lacquer helpers ----------

def fill_wood_frame(pix, w, h, x0, y0, x1, y1, seed=10):
    """Horizontal wood grain band for outer frame."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            n = noise(x, y, seed)
            g = noise(x, y // 2, seed + 2)
            base = WOOD[int(g * (len(WOOD) - 1))]
            if (y - y0) % 3 == 0 and n > 0.35:
                base = WOOD[6]
            if n < 0.05:
                base = WOOD[4]
            elif n > 0.94:
                base = WOOD[5]
            # top edge highlight
            if y == y0 and n > 0.3:
                base = blend(base, WOOD[5], 0.55)
            if y == y1:
                base = blend(base, WOOD[6], 0.45)
            pix[x, y] = base


def fill_lacquer(pix, w, h, x0, y0, x1, y1, seed=20, dark=False):
    """Dark lacquer or warm paper fill with micro grit."""
    cols = WOOD_LAC if dark else PAPER
    bh = max(1, y1 - y0)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            t = (y - y0) / bh
            n = noise(x, y, seed)
            if dark:
                base = blend(cols[1], cols[3], t * 0.55 + n * 0.2)
                if n < 0.06:
                    base = cols[3]
                elif n > 0.93:
                    base = cols[2]
            else:
                base = blend(cols[0], cols[2], t * 0.4 + n * 0.18)
                if n < 0.05:
                    base = cols[2]
                elif n > 0.95:
                    base = cols[3]
            if (hash2(x, y, seed + 7) % 37) == 0:
                base = blend(base, INK2, 0.18) if dark else cols[2]
            pix[x, y] = base


def gold_rim(pix, w, h, x0, y0, x1, y1):
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y0, GOLD[0])
        put(pix, w, h, x, y1, GOLD[2])
        if x % 5 == 0:
            put(pix, w, h, x, y0, GOLD[1])
            put(pix, w, h, x, y1, GOLD[0])
    for y in range(y0, y1 + 1):
        put(pix, w, h, x0, y, GOLD[0])
        put(pix, w, h, x1, y, GOLD[2])
        if y % 4 == 0:
            put(pix, w, h, x0, y, GOLD[1])
            put(pix, w, h, x1, y, GOLD[0])
    # corner bright studs
    for cx, cy in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        put(pix, w, h, cx, cy, GOLD[1])
        put(pix, w, h, cx + 1 if cx == x0 else cx - 1, cy, GOLD[3])
        put(pix, w, h, cx, cy + 1 if cy == y0 else cy - 1, GOLD[3])


def corner_ornament(pix, w, h, cx, cy, flip_x=False, flip_y=False):
    """L-shaped gold/vermilion corner decoration."""
    def px(dx, dy, c):
        x = cx + (-dx if flip_x else dx)
        y = cy + (-dy if flip_y else dy)
        put(pix, w, h, x, y, c)

    for i in range(7):
        px(i, 0, GOLD[0])
        px(0, i, GOLD[0])
    for i in range(1, 6):
        px(i, 1, GOLD[2])
        px(1, i, GOLD[2])
    px(2, 2, VERM[0])
    px(3, 2, VERM[1])
    px(2, 3, VERM[1])
    px(3, 3, GOLD[1])
    px(4, 2, GOLD[3])
    px(2, 4, GOLD[3])


def slot_divider(pix, w, h, x, y0, y1):
    """Resource slot hint — bevel + gold ticks, no fake text."""
    for y in range(y0, y1 + 1):
        put(pix, w, h, x - 1, y, WOOD[6])
        put(pix, w, h, x, y, WOOD[4])
        put(pix, w, h, x + 1, y, blend(WOOD[5], PAPER[0], 0.35))
    # gold ticks top/bottom
    for dx in (-1, 0, 1, 2):
        put(pix, w, h, x + dx, y0, GOLD[0])
        put(pix, w, h, x + dx, y0 + 1, GOLD[2])
        put(pix, w, h, x + dx, y1, GOLD[2])
        put(pix, w, h, x + dx, y1 - 1, GOLD[0])
    # tiny vermilion gem mid
    mid = (y0 + y1) // 2
    put(pix, w, h, x, mid, VERM[0])
    put(pix, w, h, x, mid - 1, GOLD[1])
    put(pix, w, h, x, mid + 1, GOLD[1])


# ---------- HUD 320×64 ----------

def gen_hud_panel() -> Image.Image:
    w, h = 320, 64
    img = new_img(w, h)
    pix = img.load()
    d = ImageDraw.Draw(img)

    # outer ink silhouette
    rect(d, 0, 0, w - 1, h - 1, INK)
    # wood frame (outer band)
    fill_wood_frame(pix, w, h, 1, 1, w - 2, h - 2, seed=11)
    # ink inset
    rect(d, 5, 5, w - 6, h - 6, INK2)
    # gold rim
    gold_rim(pix, w, h, 6, 6, w - 7, h - 7)
    # inner wood lip
    fill_wood_frame(pix, w, h, 7, 7, w - 8, 9, seed=12)
    fill_wood_frame(pix, w, h, 7, h - 10, w - 8, h - 8, seed=13)
    wood_plank_v(pix, w, h, 7, 7, 9, h - 8, seed=14)
    wood_plank_v(pix, w, h, w - 10, 7, w - 8, h - 8, seed=15)
    # lacquered/paper panel (slightly warm dark-lacquer wash over paper)
    fill_lacquer(pix, w, h, 10, 10, w - 11, h - 11, seed=21, dark=False)
    # top cream highlight / bottom shade
    for x in range(11, w - 11):
        if noise(x, 11, 30) > 0.25:
            put(pix, w, h, x, 11, PAPER[3])
        if noise(x, h - 12, 31) > 0.3:
            put(pix, w, h, x, h - 12, PAPER[2])
    # micro grit
    micro_grain(pix, w, h, 11, 12, w - 12, h - 13, [PAPER[1], PAPER[2], CREAM], density=0.1, seed=40)
    # resource slot dividers (5 slots → 4 dividers at 64,128,192,256)
    for sx in (64, 128, 192, 256):
        slot_divider(pix, w, h, sx, 14, h - 15)
    # corner ornaments
    corner_ornament(pix, w, h, 12, 12, False, False)
    corner_ornament(pix, w, h, w - 13, 12, True, False)
    corner_ornament(pix, w, h, 12, h - 13, False, True)
    corner_ornament(pix, w, h, w - 13, h - 13, True, True)
    # subtle vermilion accent line under top gold
    for x in range(20, w - 20):
        if x % 8 < 5:
            put(pix, w, h, x, 8, VERM[0] if x % 16 < 8 else VERM[2])
    return img


# ---------- Buttons 128×40 (center blank for Godot text) ----------

def gen_btn(accent_warm: bool) -> Image.Image:
    """accent_warm=True → vermilion (dispatch); False → teal (build)."""
    w, h = 128, 40
    img = new_img(w, h)
    pix = img.load()
    d = ImageDraw.Draw(img)

    # drop shadow (press feel)
    for dy in range(2, 5):
        for dx in range(2, 5):
            for x in range(dx, w):
                put(pix, w, h, x, h - 5 + dy, blend(SHADOW, INK, 0.4 + dy * 0.1))
    # clear and redraw cleanly
    img = new_img(w, h)
    pix = img.load()
    d = ImageDraw.Draw(img)

    # shadow body offset
    rect(d, 2, 3, w - 1, h - 1, blend(SHADOW, INK2, 0.5))
    for y in range(3, h):
        for x in range(2, w):
            if noise(x, y, 50) < 0.35:
                put(pix, w, h, x, y, SHADOW)

    # main plate
    rect(d, 0, 0, w - 3, h - 4, INK)
    fill_wood_frame(pix, w, h, 1, 1, w - 4, h - 5, seed=60 if accent_warm else 61)
    # gold rim
    gold_rim(pix, w, h, 2, 2, w - 5, h - 6)
    # accent lacquer band (left/right + thin top)
    accent = VERM if accent_warm else TEAL
    for y in range(3, h - 7):
        for x in range(3, 7):
            n = noise(x, y, 70)
            put(pix, w, h, x, y, accent[int(n * (len(accent) - 1))])
            put(pix, w, h, w - 6 - (x - 3), y, accent[int(n * (len(accent) - 1))])
    for x in range(3, w - 6):
        put(pix, w, h, x, 3, accent[1])
        put(pix, w, h, x, 4, accent[0] if accent_warm else accent[3])
        put(pix, w, h, x, h - 8, accent[2])

    # paper center blank for button text
    fill_lacquer(pix, w, h, 8, 7, w - 11, h - 10, seed=80, dark=False)
    # inner ink hairline
    for x in range(8, w - 10):
        put(pix, w, h, x, 7, INK2)
        put(pix, w, h, x, h - 10, WOOD[4])
    for y in range(7, h - 9):
        put(pix, w, h, 8, y, INK2)
        put(pix, w, h, w - 11, y, WOOD[4])
    # top highlight on paper
    for x in range(10, w - 12):
        if noise(x, 8, 90) > 0.2:
            put(pix, w, h, x, 8, PAPER[3])
    # corner gold ticks on accent
    for cx, cy in ((4, 5), (w - 8, 5), (4, h - 9), (w - 8, h - 9)):
        put(pix, w, h, cx, cy, GOLD[1])
        put(pix, w, h, cx + 1, cy, GOLD[0])
        put(pix, w, h, cx, cy + 1, GOLD[2])
    # micro grain on paper only
    micro_grain(pix, w, h, 10, 9, w - 13, h - 12, [PAPER[1], PAPER[2]], density=0.08, seed=91)
    return img


def gen_btn_dispatch() -> Image.Image:
    return gen_btn(True)


def gen_btn_build() -> Image.Image:
    return gen_btn(False)


# ---------- Icons 32×32 transparent ----------

def _outline(pix, w, h, mask_pts, col=INK):
    pts = set(mask_pts)
    for x, y in pts:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if (nx, ny) not in pts:
                put(pix, w, h, nx, ny, col)


def icon_silver() -> Image.Image:
    """Sycee / silver ingot with gold seal."""
    w = h = 32
    img = new_img(w, h)
    pix = img.load()
    # soft foot shadow
    for dy in range(-2, 3):
        for dx in range(-6, 7):
            if dx * dx / 36 + dy * dy / 4 <= 1 and noise(16 + dx, 26 + dy, 1) < 0.55:
                put(pix, w, h, 16 + dx, 26 + dy, blend(SHADOW, INK, 0.3))
    body = []
    # trapezoid ingot
    for y in range(8, 26):
        t = (y - 8) / 17
        half = int(9 + (1 - abs(t - 0.45) * 1.2) * 2)
        if y < 12:
            half = 7 + (y - 8)
        elif y > 22:
            half = 10 - (y - 22)
        else:
            half = 10
        for x in range(16 - half, 16 + half + 1):
            n = noise(x, y, 2)
            # facet: top light, sides mid, bottom dark
            if y < 12:
                c = SILVER[2] if n > 0.4 else SILVER[0]
            elif y < 18:
                c = SILVER[0] if x < 16 else SILVER[1]
                if n < 0.1:
                    c = SILVER[3]
            else:
                c = SILVER[3] if n > 0.3 else SILVER[5]
            put(pix, w, h, x, y, c)
            body.append((x, y))
    # top face highlight
    for x in range(10, 23):
        put(pix, w, h, x, 9, SILVER[4])
        put(pix, w, h, x, 10, SILVER[2])
    # gold seal
    for y in range(13, 18):
        for x in range(13, 20):
            put(pix, w, h, x, y, GOLD[0] if (x + y) % 2 == 0 else GOLD[1])
    for x in range(13, 20):
        put(pix, w, h, x, 13, GOLD[2])
        put(pix, w, h, x, 17, GOLD[2])
    for y in range(13, 18):
        put(pix, w, h, 13, y, GOLD[2])
        put(pix, w, h, 19, y, GOLD[2])
    put(pix, w, h, 16, 15, GOLD[3])
    # ridge lines
    for x in range(9, 24):
        put(pix, w, h, x, 18, SILVER[5])
    _outline(pix, w, h, body, INK)
    return img


def icon_wood() -> Image.Image:
    """Stack of three cut logs with end-grain rings."""
    w = h = 32
    img = new_img(w, h)
    pix = img.load()
    for dy in range(-2, 3):
        for dx in range(-7, 8):
            if dx * dx / 49 + dy * dy / 4 <= 1 and noise(16 + dx, 28 + dy, 3) < 0.5:
                put(pix, w, h, 16 + dx, 28 + dy, blend(SHADOW, INK, 0.25))
    body = []
    rows = [(6, WOOD[4]), (13, WOOD[1]), (20, WOOD[5])]
    for i, (y0, _) in enumerate(rows):
        for y in range(y0, y0 + 7):
            for x in range(4, 28):
                n = noise(x, y, 4 + i)
                g = noise(x // 2, y, 10 + i)
                base = WOOD[int(g * (len(WOOD) - 1))]
                if x < 9:  # end grain
                    ring = ((x - 6) ** 2 + (y - (y0 + 3)) ** 2)
                    if ring < 2:
                        base = PAPER[2]
                    elif ring < 6:
                        base = WOOD[2]
                    else:
                        base = WOOD[4]
                else:
                    if (y - y0) % 3 == 0:
                        base = WOOD[6]
                    if n < 0.07:
                        base = WOOD[4]
                    elif n > 0.93:
                        base = WOOD[5]
                put(pix, w, h, x, y, base)
                body.append((x, y))
        # bark notch
        put(pix, w, h, 18, y0 + 2, WOOD[6])
        put(pix, w, h, 22, y0 + 4, WOOD[4])
    _outline(pix, w, h, body, INK)
    return img


def icon_hide() -> Image.Image:
    """Rolled animal hide with fur ticks."""
    w = h = 32
    img = new_img(w, h)
    pix = img.load()
    for dy in range(-2, 3):
        for dx in range(-6, 7):
            if dx * dx / 36 + dy * dy / 4 <= 1 and noise(16 + dx, 27 + dy, 5) < 0.5:
                put(pix, w, h, 16 + dx, 27 + dy, blend(SHADOW, INK, 0.25))
    body = []
    # outer oval roll
    for y in range(5, 28):
        for x in range(5, 27):
            nx = (x - 16) / 10.5
            ny = (y - 16) / 11.0
            rr = nx * nx + ny * ny
            if rr > 1.0:
                continue
            n = noise(x, y, 6)
            if rr > 0.72:
                c = HIDE[1] if n > 0.4 else HIDE[3]
            elif rr > 0.35:
                c = HIDE[0] if n > 0.5 else HIDE[2]
            else:
                c = HIDE[4] if n > 0.45 else HIDE[5]
            # spiral fold hint
            if abs(rr - 0.5) < 0.06:
                c = HIDE[3]
            put(pix, w, h, x, y, c)
            body.append((x, y))
    # fur ticks around rim
    for p in ((7, 10), (24, 9), (8, 22), (23, 21), (6, 16), (25, 16), (12, 6), (20, 6)):
        put(pix, w, h, p[0], p[1], HIDE[3])
        put(pix, w, h, p[0], p[1] - 1, HIDE[1])
    # rope tie
    for x in range(13, 20):
        put(pix, w, h, x, 15, C("8A6A38"))
        put(pix, w, h, x, 16, C("6A4A28"))
    put(pix, w, h, 16, 14, GOLD[0])
    _outline(pix, w, h, body, INK)
    return img


def icon_iron() -> Image.Image:
    """Iron bar with stamped seal."""
    w = h = 32
    img = new_img(w, h)
    pix = img.load()
    for dy in range(-2, 3):
        for dx in range(-7, 8):
            if dx * dx / 49 + dy * dy / 4 <= 1 and noise(16 + dx, 26 + dy, 7) < 0.5:
                put(pix, w, h, 16 + dx, 26 + dy, blend(SHADOW, INK, 0.25))
    body = []
    for y in range(9, 24):
        for x in range(4, 28):
            n = noise(x, y, 8)
            if y <= 11:
                c = IRON[3] if n > 0.4 else STONE[3]
            elif y <= 14:
                c = IRON[1]
            elif y <= 17:
                c = IRON[0] if n > 0.3 else IRON[2]
            else:
                c = IRON[2] if n > 0.4 else blend(IRON[2], INK, 0.25)
            # bevel left
            if x <= 6:
                c = blend(c, STONE[3], 0.4)
            if x >= 25:
                c = blend(c, INK, 0.3)
            put(pix, w, h, x, y, c)
            body.append((x, y))
    # facet ridges
    for x in range(6, 26):
        put(pix, w, h, x, 12, STONE[3])
        put(pix, w, h, x, 16, INK2)
        put(pix, w, h, x, 20, IRON[2])
    # gold stamp
    for y in range(14, 19):
        for x in range(12, 21):
            put(pix, w, h, x, y, GOLD[2] if (x == 12 or x == 20 or y == 14 or y == 18) else GOLD[0])
    put(pix, w, h, 16, 16, GOLD[1])
    _outline(pix, w, h, body, INK)
    return img


def icon_herb() -> Image.Image:
    """Herb sprig with vermilion bud."""
    w = h = 32
    img = new_img(w, h)
    pix = img.load()
    for dy in range(-1, 3):
        for dx in range(-3, 4):
            if dx * dx + dy * dy <= 8 and noise(16 + dx, 29 + dy, 9) < 0.45:
                put(pix, w, h, 16 + dx, 29 + dy, blend(SHADOW, INK, 0.2))
    body = []
    # stem
    for y in range(14, 30):
        for x in range(14, 18):
            n = noise(x, y, 11)
            c = JADE[2] if n < 0.4 else JADE[0]
            if x == 14:
                c = JADE[4]
            if x == 17:
                c = JADE[1]
            put(pix, w, h, x, y, c)
            body.append((x, y))
    # left leaf
    for y in range(4, 18):
        for x in range(3, 17):
            # diamond-ish leaf
            ly = y - 4
            t = ly / 13
            left = int(16 - 2 - t * 10)
            right = int(16 - 1 - t * 2)
            if left <= x <= right:
                n = noise(x, y, 12)
                c = HERB[1] if n > 0.5 else HERB[0]
                if x <= left + 1:
                    c = HERB[2]
                put(pix, w, h, x, y, c)
                body.append((x, y))
    # right leaf
    for y in range(4, 18):
        for x in range(16, 29):
            ly = y - 4
            t = ly / 13
            left = int(16 + 1 + t * 2)
            right = int(16 + 2 + t * 10)
            if left <= x <= right:
                n = noise(x, y, 13)
                c = HERB[3] if n > 0.45 else HERB[1]
                if x >= right - 1:
                    c = HERB[2]
                put(pix, w, h, x, y, c)
                body.append((x, y))
    # veins
    for i in range(10):
        put(pix, w, h, 15 - i // 2, 5 + i, HERB[4])
        put(pix, w, h, 17 + i // 2, 5 + i, HERB[2])
    # vermilion bud
    for y in range(1, 7):
        for x in range(13, 20):
            if abs(x - 16) + abs(y - 3) <= 3:
                n = noise(x, y, 14)
                c = VERM[1] if n > 0.4 else VERM[0]
                if abs(x - 16) + abs(y - 3) >= 3:
                    c = VERM[2]
                put(pix, w, h, x, y, c)
                body.append((x, y))
    put(pix, w, h, 16, 3, VERM[3])
    _outline(pix, w, h, body, INK)
    return img


# ---------- preview ----------

def make_preview(assets: dict) -> Image.Image:
    # strip: HUD on top, buttons + icons below
    pw, ph = 360, 130
    strip = new_img(pw, ph)
    d = ImageDraw.Draw(strip)
    # dark paper bg
    for y in range(ph):
        for x in range(pw):
            n = noise(x, y, 200)
            c = blend(PAPER[2], DIRT[0], 0.35 + n * 0.1)
            put(strip.load(), pw, ph, x, y, c)
    strip.alpha_composite(assets["hud"], (20, 8))
    strip.alpha_composite(assets["btn_dispatch"], (20, 82))
    strip.alpha_composite(assets["btn_build"], (156, 82))
    x = 300
    for key in ("icon_silver", "icon_wood", "icon_hide", "icon_iron", "icon_herb"):
        # icons wrap under if needed — place in a row starting after buttons if room,
        # else second row under HUD right side. Use compact row at y=82 after buttons.
        pass
    # icons to the right of buttons — panel is 360 wide; buttons end ~284; put icons at y=48 right of hud? 
    # Better: icons row under buttons right side — widen strip.
    return strip


def make_preview_wide(assets: dict) -> Image.Image:
    pw, ph = 520, 120
    strip = new_img(pw, ph)
    pix = strip.load()
    for y in range(ph):
        for x in range(pw):
            n = noise(x, y, 201)
            put(pix, pw, ph, x, y, blend(PAPER[1], DIRT[1], 0.25 + n * 0.12))
    strip.alpha_composite(assets["hud"], (8, 8))
    strip.alpha_composite(assets["btn_dispatch"], (8, 80))
    strip.alpha_composite(assets["btn_build"], (144, 80))
    x = 290
    for key in ("icon_silver", "icon_wood", "icon_hide", "icon_iron", "icon_herb"):
        strip.alpha_composite(assets[key], (x, 84))
        x += 40
    # labels as tiny color keys (not fake UI text) — skip text, just gold ticks under icons
    return strip


def main() -> None:
    print("=== 墨點俠村 Pivot R6 UI 高密度 ===")
    ensure_backup()
    UI.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)

    assets = {
        "hud": gen_hud_panel(),
        "btn_dispatch": gen_btn_dispatch(),
        "btn_build": gen_btn_build(),
        "icon_silver": icon_silver(),
        "icon_wood": icon_wood(),
        "icon_hide": icon_hide(),
        "icon_iron": icon_iron(),
        "icon_herb": icon_herb(),
    }

    mapping = [
        ("hud", "hud_panel.png"),
        ("btn_dispatch", "btn_dispatch.png"),
        ("btn_build", "btn_build.png"),
        ("icon_silver", "icon_silver.png"),
        ("icon_wood", "icon_wood.png"),
        ("icon_hide", "icon_hide.png"),
        ("icon_iron", "icon_iron.png"),
        ("icon_herb", "icon_herb.png"),
    ]
    for key, name in mapping:
        img = assets[key]
        assert img.size == ((320, 64) if key == "hud" else (128, 40) if key.startswith("btn") else (32, 32)), img.size
        save(img, UI / name)

    strip = make_preview_wide(assets)
    save(strip, PREVIEW / "pivot_r6_ui.png")
    save(nearest_x2(strip), PREVIEW / "pivot_r6_ui_x2.png")

    print("-- sizes --")
    for key, name in mapping:
        im = Image.open(UI / name)
        print(f"  {name}: {im.size[0]}×{im.size[1]} {im.mode}")
    print(f"  backup: {PREV}")
    print(f"  preview: {PREVIEW / 'pivot_r6_ui.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r6_ui_x2.png'}")
    print("重生：python3 tools/gen_pivot_r6_ui.py")


if __name__ == "__main__":
    main()
