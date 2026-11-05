#!/usr/bin/env python3
"""墨點俠村 · 重大風格轉向 R1（密度對齊獵魔村感覺，唔抄資產）

Lemon 轉向：暫時放棄墨點硬邊／嚴格 5 色盤。
建築／村景用更豐富色階＋微柔口陰影；仍係像素藝術（唔寫實／唔 AI 糊邊）。
質素＞數量；本輪只做 manor／inn／forge＋村景 960×540。

尺寸：建築 160×160；村景 960×540。
重生：python3 tools/gen_pivot_r1.py
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
PREV = ART / "_prev_before_density_pivot"

VW, VH = 960, 540
ICON = 160  # denser readable building icons
HORIZON = 188
TRANS = (0, 0, 0, 0)

# —— 豐富色階（武俠村／大地／木材／瓦）——
def C(h: str, a: int = 255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


INK = C("1A1510")
INK2 = C("2A2218")
INK3 = C("3A3228")
SHADOW = C("12100C")
SHADOW_A = C("1A1510", 140)

# sky
SKY0 = C("B8C8D8")
SKY1 = C("C8D4E0")
SKY2 = C("D8E0E8")
SKY3 = C("E8E4D8")
CLOUD = C("F2F0EA")
CLOUD_DK = C("D8D4CC")

# hills / foliage
HILL_FAR = C("6A8A78")
HILL_MID = C("4A6E58")
HILL_NEAR = C("355848")
HILL_EDGE = C("2A4438")
PINE = C("2E5A40")
PINE_LT = C("3E7A58")
PINE_DK = C("1E3A2C")
LEAF = C("4A7A42")
LEAF_LT = C("5E9452")
LEAF_DK = C("2E5230")
LEAF_Y = C("8A9A48")

# grass / dirt / pack
GRASS = [
    C("3A6A38"), C("4A7A42"), C("56884C"), C("3E7040"),
    C("2E582E"), C("4A8248"), C("628E52"), C("365C34"),
]
DIRT = [C("6A4A2E"), C("7A5A38"), C("8A6A44"), C("5A3A24"), C("9A7A52")]
PACK = [C("A09070"), C("B0A080"), C("908060"), C("C0B090"), C("807050"), C("D0C0A0")]
STONE = [C("7A7468"), C("8A8478"), C("6A6458"), C("9A9488"), C("5A5448"), C("AAA498")]
MORTAR = C("5A5248")
PATH = [C("8A8070"), C("9A9080"), C("7A7060"), C("AAA090")]

# wood
WOOD = [C("5A3A22"), C("6B4A2E"), C("7A5A38"), C("8A6A44"), C("4A2E18"), C("9A7A52"), C("3A2412")]
WOOD_LAC = [C("6A2818"), C("8A3820"), C("A04828"), C("4A1810")]  # lacquered red-brown

# plaster / paper walls
WALL = [C("E8DCC8"), C("F0E8D4"), C("D8CCB4"), C("C8BCA0"), C("F8F0E0"), C("B8AC90")]
WALL_SH = C("C0B498")

# roof tiles — vermilion / slate / charcoal
ROOF_R = [C("C43C2C"), C("A83024"), C("D85840"), C("8A2418"), C("E07058"), C("6A1810"), C("B83828")]
ROOF_SL = [C("4A4E58"), C("3A3E48"), C("5A5E68"), C("2A2E38"), C("6A6E78"), C("1A1E28")]
ROOF_BK = [C("2A2824"), C("3A3834"), C("1A1814"), C("4A4844")]

# metal / gold / fire
GOLD = [C("C9A227"), C("E0C048"), C("9A7818"), C("F0D868"), C("7A5A10")]
IRON = [C("4A4A50"), C("5A5A60"), C("3A3A40"), C("6A6A70")]
FIRE = [C("FFE8A0"), C("FFC040"), C("FF8020"), C("E04010"), C("FF6040")]
TEAL = [C("2F6B5A"), C("3E8570"), C("1E4A3E"), C("50A088"), C("0E2A22")]
VERM = [C("C43C2C"), C("D85840"), C("8A281C"), C("E87860"), C("A03020")]
CREAM = C("F2EAD8")
BANNER = C("C43C2C")
BANNER_DK = C("8A281C")


def new_img(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), TRANS)


def put(pix, w, h, x, y, c):
    if 0 <= x < w and 0 <= y < h:
        pix[x, y] = c


def blend(a, b, t: float):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)


def hash2(x, y, s=0) -> int:
    return (int(x) * 374761393 + int(y) * 668265263 + int(s * 1000 if isinstance(s, float) else s) * 1274126177) & 0x7FFFFFFF


def noise(x, y, s=0) -> float:
    return (hash2(x, y, s) % 10000) / 10000.0


def rect(d, x0, y0, x1, y1, c):
    d.rectangle([x0, y0, x1, y1], fill=c)


def ellipse_shadow(img, cx, cy, rx, ry, col=None, strength=0.55):
    """Soft elliptical foot shadow via alpha dither (pixel soft mouth)."""
    if col is None:
        col = SHADOW
    pix = img.load()
    w, h = img.size
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            nx, ny = dx / max(1, rx), dy / max(1, ry)
            rr = nx * nx + ny * ny
            if rr > 1.0:
                continue
            fall = (1.0 - rr) * strength
            x, y = cx + dx, cy + dy
            if not (0 <= x < w and 0 <= y < h):
                continue
            # dither soft mouth — denser near center
            if noise(x, y, 99) < fall:
                pix[x, y] = col


def fill_disk(pix, w, h, cx, cy, r, cols, seed=1):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                x, y = cx + dx, cy + dy
                if 0 <= x < w and 0 <= y < h:
                    pix[x, y] = cols[hash2(x, y, seed) % len(cols)]


def wood_plank_v(pix, w, h, x0, y0, x1, y1, seed=3):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            n = noise(x, y, seed)
            # vertical grain
            g = noise(x // 2, y, seed + 1)
            base = WOOD[int(g * (len(WOOD) - 1))]
            if n < 0.08:
                base = WOOD[4]  # dark knot
            elif n > 0.92:
                base = WOOD[5]
            # seam every ~5 px
            if (x - x0) % 5 == 0:
                base = WOOD[6]
            # subtle top highlight
            if y == y0 and n > 0.4:
                base = WOOD[5]
            pix[x, y] = base


def wood_plank_h(pix, w, h, x0, y0, x1, y1, seed=4):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            n = noise(x, y, seed)
            g = noise(x, y // 2, seed + 2)
            base = WOOD[int(g * (len(WOOD) - 1))]
            if (y - y0) % 4 == 0:
                base = WOOD[6]
            if n < 0.06:
                base = WOOD[4]
            pix[x, y] = base


def plaster_wall(pix, w, h, x0, y0, x1, y1, seed=5, shade_right=True):
    bw = max(1, x1 - x0)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            t = (x - x0) / bw
            n = noise(x, y, seed)
            if shade_right:
                base = blend(WALL[1], WALL[3], t * 0.55 + n * 0.15)
            else:
                base = blend(WALL[3], WALL[1], t * 0.55 + n * 0.15)
            if n < 0.04:
                base = WALL[3]
            elif n > 0.96:
                base = WALL[4]
            # speckled plaster grit
            if (hash2(x, y, seed + 9) % 40) == 0:
                base = WALL[5]
            pix[x, y] = base


def stone_bricks(pix, w, h, x0, y0, x1, y1, bw=8, bh=5, seed=6):
    for y in range(y0, y1 + 1):
        row = (y - y0) // bh
        off = (bw // 2) if row % 2 else 0
        for x in range(x0, x1 + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            local_x = x - x0 + off
            if (local_x % bw) == 0 or ((y - y0) % bh) == 0:
                pix[x, y] = MORTAR
            else:
                n = noise(local_x // bw, row, seed)
                pix[x, y] = STONE[int(n * (len(STONE) - 1))]


def roof_tile_band(pix, w, h, pts_top, pts_bot, cols, seed=7):
    """Fill trapezoid-ish roof strip between two polylines with tile pattern."""
    # pts are lists of (x,y) left→right
    n = min(len(pts_top), len(pts_bot))
    if n < 2:
        return
    xmin = min(p[0] for p in pts_top + pts_bot)
    xmax = max(p[0] for p in pts_top + pts_bot)
    for x in range(xmin, xmax + 1):
        # interpolate y top/bot at x
        def y_at(pts, x):
            for i in range(len(pts) - 1):
                x0, y0 = pts[i]
                x1, y1 = pts[i + 1]
                if x0 <= x <= x1 or x1 <= x <= x0:
                    if x1 == x0:
                        return y0
                    t = (x - x0) / (x1 - x0)
                    return int(y0 + t * (y1 - y0))
            return pts[0][1]

        yt = y_at(pts_top, x)
        yb = y_at(pts_bot, x)
        if yb < yt:
            yt, yb = yb, yt
        for y in range(yt, yb + 1):
            if not (0 <= x < w and 0 <= y < h):
                continue
            row = (y - yt) // 3
            # scalloped tile look
            wave = int(1.5 * math.sin((x + row * 3) * 0.9))
            n = noise(x, y, seed + row)
            idx = (row + int(n * 3) + (x // 4)) % len(cols)
            c = cols[idx]
            # ridge dark
            if (y - yt) % 3 == 0:
                c = cols[min(len(cols) - 1, idx + 1)]
            # highlight on left of tile
            if ((x + wave) % 5) == 1:
                c = cols[max(0, idx - 1)]
            pix[x, y] = c


def draw_curved_roof(img, apex, left, right, base_y, cols, eave_drop=8, seed=8):
    """Classic Chinese hip-ish roof with slight upturned eaves."""
    pix = img.load()
    w, h = img.size
    ax, ay = apex
    lx, ly = left
    rx, ry = right
    # top ridge line
    pts_top = []
    pts_bot = []
    for i in range(33):
        t = i / 32
        # quadratic bezier left→apex→right for top
        if t < 0.5:
            u = t * 2
            x = int(lx + (ax - lx) * u)
            y = int(ly + (ay - ly) * u)
        else:
            u = (t - 0.5) * 2
            x = int(ax + (rx - ax) * u)
            y = int(ay + (ry - ay) * u)
        # eave lift near ends
        lift = int(eave_drop * (1 - abs(t - 0.5) * 2) ** 0.5 * 0)  # keep peak high
        end_lift = int(eave_drop * max(0, abs(t - 0.5) * 2 - 0.55) / 0.45) if abs(t - 0.5) > 0.55 else 0
        pts_top.append((x, y - end_lift))
        # bottom eave follows with slight curve up at ends
        bx = int(lx + (rx - lx) * t)
        by = base_y - int(eave_drop * (abs(t - 0.5) * 2) ** 1.6)
        pts_bot.append((bx, by))
    roof_tile_band(pix, w, h, pts_top, pts_bot, cols, seed=seed)
    # outline ridge
    for i in range(len(pts_top) - 1):
        x0, y0 = pts_top[i]
        x1, y1 = pts_top[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for s in range(steps + 1):
            x = x0 + (x1 - x0) * s // steps
            y = y0 + (y1 - y0) * s // steps
            put(pix, w, h, x, y, INK)
            put(pix, w, h, x, y + 1, cols[-1])
    # bottom eave outline
    for i in range(len(pts_bot) - 1):
        x0, y0 = pts_bot[i]
        x1, y1 = pts_bot[i + 1]
        steps = max(abs(x1 - x0), 1)
        for s in range(steps + 1):
            x = x0 + (x1 - x0) * s // steps
            y = y0 + (y1 - y0) * s // steps
            put(pix, w, h, x, y, INK2)
            put(pix, w, h, x, y + 1, cols[-2] if len(cols) > 2 else cols[-1])


def lattice_window(img, x0, y0, x1, y1, pane=None):
    pix = img.load()
    w, h = img.size
    d = ImageDraw.Draw(img)
    if pane is None:
        pane = TEAL[2]
    rect(d, x0, y0, x1, y1, pane)
    # inner lighter panes
    for y in range(y0 + 1, y1):
        for x in range(x0 + 1, x1):
            if noise(x, y, 11) > 0.7:
                put(pix, w, h, x, y, TEAL[1])
            elif noise(x, y, 12) < 0.15:
                put(pix, w, h, x, y, TEAL[0])
    # frame
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, y0, WOOD[0])
        put(pix, w, h, x, y1, WOOD[0])
    for y in range(y0, y1 + 1):
        put(pix, w, h, x0, y, WOOD[0])
        put(pix, w, h, x1, y, WOOD[0])
    mx = (x0 + x1) // 2
    my = (y0 + y1) // 2
    for y in range(y0, y1 + 1):
        put(pix, w, h, mx, y, WOOD[1])
    for x in range(x0, x1 + 1):
        put(pix, w, h, x, my, WOOD[1])
    # outer ink
    for x in range(x0 - 1, x1 + 2):
        put(pix, w, h, x, y0 - 1, INK)
        put(pix, w, h, x, y1 + 1, INK)
    for y in range(y0 - 1, y1 + 2):
        put(pix, w, h, x0 - 1, y, INK)
        put(pix, w, h, x1 + 1, y, INK)


def hanging_lantern(img, cx, cy):
    pix = img.load()
    w, h = img.size
    # cord
    for y in range(cy - 14, cy - 2):
        put(pix, w, h, cx, y, INK)
    # body
    for dy in range(0, 16):
        for dx in range(-6, 7):
            if abs(dx) <= 6 - dy // 6:
                n = noise(cx + dx, cy + dy, 20)
                c = VERM[1] if n > 0.5 else VERM[0]
                if abs(dx) > 4:
                    c = VERM[2]
                if dy < 2 or dy > 13:
                    c = GOLD[0]
                put(pix, w, h, cx + dx, cy + dy, c)
    # glow dither
    for dy in range(-2, 18):
        for dx in range(-10, 11):
            rr = (dx / 10) ** 2 + ((dy - 7) / 10) ** 2
            if rr < 1 and noise(cx + dx, cy + dy, 21) < 0.12 * (1 - rr):
                put(pix, w, h, cx + dx, cy + dy, FIRE[1])
    # tassel
    for y in range(cy + 16, cy + 22):
        put(pix, w, h, cx, y, VERM[2])
    put(pix, w, h, cx, cy + 22, GOLD[2])


# ===================== BUILDINGS 160 =====================

def icon_manor() -> Image.Image:
    """村長府 — 雙層飛檐硃紅瓦、石基、匾額、燈籠、石獅暗示。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    # soft foot shadow
    ellipse_shadow(img, 80, 148, 62, 12, SHADOW, 0.7)

    # stone terrace / steps
    stone_bricks(pix, w, h, 18, 118, 142, 148, bw=9, bh=6, seed=31)
    # front steps
    for i, (sx0, sx1, sy) in enumerate([(58, 102, 140), (62, 98, 144), (66, 94, 148)]):
        for x in range(sx0, sx1 + 1):
            for y in range(sy, sy + 3):
                put(pix, w, h, x, y, STONE[1 + (i % 3)])
            put(pix, w, h, x, sy, MORTAR)

    # side wing walls
    plaster_wall(pix, w, h, 10, 88, 28, 120, seed=32, shade_right=True)
    plaster_wall(pix, w, h, 132, 88, 150, 120, seed=33, shade_right=False)
    for x in range(10, 29):
        put(pix, w, h, x, 88, WOOD[0])
        put(pix, w, h, x, 120, INK)
    for x in range(132, 151):
        put(pix, w, h, x, 88, WOOD[0])
        put(pix, w, h, x, 120, INK)

    # main body plaster
    plaster_wall(pix, w, h, 30, 62, 130, 122, seed=34, shade_right=True)
    # wood columns
    for cx in (36, 56, 78, 100, 122):
        wood_plank_v(pix, w, h, cx - 3, 64, cx + 3, 120, seed=40 + cx)
        for y in range(64, 121):
            put(pix, w, h, cx - 4, y, INK2)
            put(pix, w, h, cx + 4, y, INK)

    # beam under eaves
    wood_plank_h(pix, w, h, 28, 58, 132, 66, seed=41)
    for x in range(28, 133):
        put(pix, w, h, x, 58, GOLD[2])
        put(pix, w, h, x, 66, INK)

    # door
    wood_plank_v(pix, w, h, 68, 86, 92, 122, seed=42)
    for y in range(86, 123):
        put(pix, w, h, 80, y, WOOD[6])  # seam
    # door studs
    for yy in (92, 100, 108):
        for xx in (72, 76, 84, 88):
            put(pix, w, h, xx, yy, GOLD[0])
            put(pix, w, h, xx, yy + 1, GOLD[2])
    # ring knockers
    put(pix, w, h, 76, 104, GOLD[1])
    put(pix, w, h, 84, 104, GOLD[1])

    # windows
    lattice_window(img, 42, 78, 54, 94)
    lattice_window(img, 106, 78, 118, 94)

    # upper mezzanine band
    plaster_wall(pix, w, h, 40, 48, 120, 60, seed=35)
    wood_plank_h(pix, w, h, 38, 46, 122, 50, seed=43)
    lattice_window(img, 52, 50, 64, 58)
    lattice_window(img, 96, 50, 108, 58)

    # lower roof (hip)
    draw_curved_roof(
        img,
        apex=(80, 34),
        left=(18, 56),
        right=(142, 56),
        base_y=60,
        cols=ROOF_R,
        eave_drop=10,
        seed=50,
    )
    # upper roof
    draw_curved_roof(
        img,
        apex=(80, 10),
        left=(44, 32),
        right=(116, 32),
        base_y=36,
        cols=ROOF_R,
        eave_drop=7,
        seed=51,
    )

    # ridge ornaments
    for ox in (-6, 0, 6):
        put(pix, w, h, 80 + ox, 8, GOLD[0])
        put(pix, w, h, 80 + ox, 7, GOLD[1])
    put(pix, w, h, 80, 5, VERM[0])
    put(pix, w, h, 80, 4, GOLD[3])
    # chiwen ends
    for ex, ey in [(22, 54), (138, 54)]:
        for dy in range(0, 6):
            put(pix, w, h, ex, ey - dy, ROOF_R[3])
            put(pix, w, h, ex + (1 if ex < 80 else -1), ey - dy, ROOF_R[1])

    # plaque
    rect(d, 58, 68, 102, 78, WOOD[0])
    for x in range(58, 103):
        put(pix, w, h, x, 68, GOLD[0])
        put(pix, w, h, x, 78, GOLD[2])
    for y in range(68, 79):
        put(pix, w, h, 58, y, GOLD[0])
        put(pix, w, h, 102, y, GOLD[0])
    # fake seal chars as blocks
    for i, xx in enumerate((64, 74, 84, 94)):
        rect(d, xx, 70, xx + 5, 76, CREAM if i % 2 == 0 else GOLD[1])

    # lanterns
    hanging_lantern(img, 48, 70)
    hanging_lantern(img, 112, 70)

    # stone lions (tiny readable lumps)
    for lx in (48, 108):
        fill_disk(pix, w, h, lx, 132, 5, STONE, seed=60)
        put(pix, w, h, lx, 127, STONE[3])
        put(pix, w, h, lx - 1, 126, STONE[1])
        put(pix, w, h, lx + 1, 126, STONE[1])

    # outline polish on silhouette edges — darken extreme left/right plaster
    for y in range(62, 122):
        put(pix, w, h, 30, y, WALL[5])
        put(pix, w, h, 130, y, WALL_SH)

    return img


def icon_inn() -> Image.Image:
    """客棧 — 兩層木樓、酒旗、燈籠、屋簷掛飾、門簾。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 58, 11, SHADOW, 0.65)

    # raised wood platform
    wood_plank_h(pix, w, h, 22, 128, 138, 148, seed=70)
    stone_bricks(pix, w, h, 20, 144, 140, 152, bw=10, bh=4, seed=71)

    # main two-storey body
    plaster_wall(pix, w, h, 28, 58, 132, 130, seed=72, shade_right=True)
    # horizontal floor band
    wood_plank_h(pix, w, h, 26, 90, 134, 98, seed=73)
    for x in range(26, 135):
        put(pix, w, h, x, 90, WOOD[6])
        put(pix, w, h, x, 98, INK2)

    # columns
    for cx in (34, 58, 80, 102, 126):
        wood_plank_v(pix, w, h, cx - 2, 60, cx + 2, 128, seed=74 + cx)

    # upper windows row
    for wx in (42, 66, 94, 114):
        lattice_window(img, wx - 6, 68, wx + 6, 84)

    # balcony rail
    for x in range(36, 125):
        put(pix, w, h, x, 88, WOOD[1])
        if x % 3 == 0:
            for y in range(82, 89):
                put(pix, w, h, x, y, WOOD[0])

    # ground floor: door curtain + side windows
    # vermilion curtain strips
    for x in range(62, 98):
        for y in range(104, 130):
            stripe = ((x - 62) // 4) % 2
            c = VERM[0] if stripe == 0 else VERM[1]
            if y > 126:
                c = VERM[2]
            # soft fold
            if (x % 4) == 0:
                c = VERM[2]
            put(pix, w, h, x, y, c)
    for x in range(62, 98):
        put(pix, w, h, x, 104, GOLD[0])
        put(pix, w, h, x, 105, GOLD[2])

    lattice_window(img, 36, 108, 52, 122)
    lattice_window(img, 108, 108, 124, 122)

    # lantern by door
    hanging_lantern(img, 54, 100)
    hanging_lantern(img, 106, 100)

    # roof — warm wood tiles
    draw_curved_roof(
        img,
        apex=(80, 22),
        left=(14, 56),
        right=(146, 56),
        base_y=62,
        cols=[WOOD[5], WOOD[3], WOOD[2], WOOD[1], WOOD[0], WOOD[6], WOOD[4]],
        eave_drop=11,
        seed=80,
    )
    # ridge tile dark
    for x in range(40, 121):
        put(pix, w, h, x, 24 + int(0.02 * (x - 80) ** 2), ROOF_BK[0])

    # hanging wine banner (right)
    bx0, by0 = 128, 28
    # pole
    for y in range(by0, by0 + 50):
        put(pix, w, h, bx0, y, WOOD[0])
        put(pix, w, h, bx0 + 1, y, WOOD[2])
    # cloth
    for dy in range(0, 42):
        for dx in range(0, 22):
            c = BANNER if (dx < 18) else BANNER_DK
            if dy < 3 or dy > 38:
                c = GOLD[0]
            if 8 <= dx <= 14 and 10 <= dy <= 34:
                # character blocks
                if ((dy - 10) // 6) % 2 == 0:
                    c = CREAM
            put(pix, w, h, bx0 + 3 + dx, by0 + 4 + dy, c)
    # fringe
    for dx in range(0, 22, 2):
        put(pix, w, h, bx0 + 3 + dx, by0 + 46, BANNER_DK)
        put(pix, w, h, bx0 + 3 + dx, by0 + 47, VERM[2])

    # small side roof over entrance
    draw_curved_roof(
        img,
        apex=(80, 96),
        left=(56, 106),
        right=(104, 106),
        base_y=108,
        cols=ROOF_R,
        eave_drop=4,
        seed=81,
    )

    # table hint outside
    wood_plank_h(pix, w, h, 30, 132, 50, 138, seed=82)
    for leg in (32, 46):
        wood_plank_v(pix, w, h, leg, 138, leg + 2, 146, seed=83)

    # outline columns edges
    for y in range(60, 129):
        put(pix, w, h, 28, y, WALL[5])
        put(pix, w, h, 132, y, WALL_SH)

    return img


def icon_forge() -> Image.Image:
    """鐵匠鋪 — 厚木結構、敞開鍛爐火光、鐵砧、煙囪、掛刀。"""
    img = new_img(ICON, ICON)
    pix = img.load()
    d = ImageDraw.Draw(img)
    w = h = ICON

    ellipse_shadow(img, 80, 150, 60, 11, SHADOW, 0.7)

    # dirt/ash ground under forge
    for y in range(136, 152):
        for x in range(24, 140):
            n = noise(x, y, 90)
            put(pix, w, h, x, y, DIRT[int(n * (len(DIRT) - 1))])

    # stone foundation
    stone_bricks(pix, w, h, 22, 120, 138, 140, bw=8, bh=5, seed=91)

    # open timber frame body
    wood_plank_h(pix, w, h, 24, 70, 136, 126, seed=92)
    # vertical posts thick
    for cx in (30, 52, 108, 130):
        wood_plank_v(pix, w, h, cx - 4, 58, cx + 4, 128, seed=93 + cx)
        for y in range(58, 129):
            put(pix, w, h, cx - 5, y, INK2)
            put(pix, w, h, cx + 5, y, INK)

    # cross beams
    wood_plank_h(pix, w, h, 26, 58, 134, 66, seed=94)
    wood_plank_h(pix, w, h, 34, 88, 126, 94, seed=95)

    # dark interior recess
    for y in range(70, 120):
        for x in range(56, 104):
            n = noise(x, y, 96)
            put(pix, w, h, x, y, blend(INK, INK3, n))

    # forge furnace (left interior)
    for y in range(86, 118):
        for x in range(58, 86):
            put(pix, w, h, x, y, IRON[2])
    stone_bricks(pix, w, h, 58, 86, 86, 118, bw=6, bh=4, seed=97)
    # fire mouth
    for y in range(96, 114):
        for x in range(64, 80):
            rr = ((x - 72) / 8) ** 2 + ((y - 105) / 9) ** 2
            if rr < 1:
                idx = int((1 - rr) * (len(FIRE) - 1))
                put(pix, w, h, x, y, FIRE[min(len(FIRE) - 1, idx)])
            elif rr < 1.3 and noise(x, y, 98) < 0.35:
                put(pix, w, h, x, y, FIRE[3])
    # fire glow bleed (soft pixel)
    for y in range(90, 120):
        for x in range(56, 100):
            rr = ((x - 72) / 22) ** 2 + ((y - 105) / 18) ** 2
            if rr < 1 and noise(x, y, 99) < 0.18 * (1 - rr):
                cur = pix[x, y]
                put(pix, w, h, x, y, blend(cur, FIRE[1], 0.35 * (1 - rr)))

    # anvil (right)
    for y in range(108, 120):
        for x in range(96, 122):
            put(pix, w, h, x, y, IRON[0])
    for y in range(100, 108):
        for x in range(100, 120):
            put(pix, w, h, x, y, IRON[1])
    # anvil horn
    for x in range(90, 100):
        for y in range(102, 108):
            put(pix, w, h, x, y, IRON[3])
    for x in range(96, 122):
        put(pix, w, h, x, 100, INK)
        put(pix, w, h, x, 120, INK2)
    # anvil stand
    wood_plank_v(pix, w, h, 106, 120, 112, 132, seed=100)

    # hanging swords
    for i, hx in enumerate((40, 48)):
        for y in range(72, 96):
            put(pix, w, h, hx, y, IRON[1])
            put(pix, w, h, hx + 1, y, IRON[3])
        put(pix, w, h, hx, 70, GOLD[2])
        put(pix, w, h, hx, 96, IRON[0])
        # guard
        for dx in range(-3, 4):
            put(pix, w, h, hx + dx, 74, GOLD[0])

    # chimney
    stone_bricks(pix, w, h, 70, 28, 90, 70, bw=5, bh=4, seed=101)
    for x in range(68, 93):
        put(pix, w, h, x, 28, INK)
    # smoke puffs (pixel soft)
    for cx, cy, r in [(78, 18, 7), (86, 12, 5), (70, 10, 4), (92, 8, 3)]:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r and noise(cx + dx, cy + dy, 102) < 0.7:
                    put(pix, w, h, cx + dx, cy + dy, blend(CLOUD_DK, INK3, noise(cx + dx, cy + dy, 103)))

    # slate roof
    draw_curved_roof(
        img,
        apex=(80, 36),
        left=(16, 64),
        right=(144, 64),
        base_y=70,
        cols=ROOF_SL,
        eave_drop=9,
        seed=104,
    )

    # tool rack shelf
    wood_plank_h(pix, w, h, 110, 78, 134, 82, seed=105)
    for hx in (114, 122, 130):
        put(pix, w, h, hx, 76, IRON[0])
        for y in range(82, 92):
            put(pix, w, h, hx, y, IRON[1])

    # barrel
    for y in range(118, 136):
        for x in range(34, 50):
            n = noise(x, y, 106)
            put(pix, w, h, x, y, WOOD[int(n * 4)])
            if x in (34, 49) or y in (118, 135) or y == 126:
                put(pix, w, h, x, y, IRON[0])

    # ember scraps on ground
    for x, y in [(88, 134), (94, 136), (100, 133), (70, 135), (76, 137)]:
        put(pix, w, h, x, y, FIRE[2])
        put(pix, w, h, x + 1, y, FIRE[3])

    return img


# ===================== VILLAGE LAYERS =====================

def gen_ground() -> Image.Image:
    """Dense grass / dirt / packed earth / stone path — Fortias-like density."""
    img = new_img(VW, VH)
    pix = img.load()

    # fill below horizon
    for y in range(HORIZON, VH):
        for x in range(VW):
            n = noise(x, y, 1)
            n2 = noise(x // 3, y // 2, 2)
            # base grass with micro variance
            idx = int((n * 0.6 + n2 * 0.4) * (len(GRASS) - 1))
            c = GRASS[idx]
            # blade speckles
            if noise(x, y, 3) < 0.04:
                c = LEAF_DK if noise(x, y, 4) < 0.5 else LEAF_LT
            pix[x, y] = c

    # dirt patches (organic clumps)
    for cx, cy, r in [
        (70, 400, 38), (120, 500, 30), (880, 380, 36), (900, 500, 28),
        (40, 300, 22), (930, 280, 20), (200, 520, 26), (760, 520, 24),
        (480, 510, 18),
    ]:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                rr = (dx * dx) / (r * r) + (dy * dy) / (r * r * 0.7)
                if rr < 1.0:
                    x, y = cx + dx, cy + dy
                    if y >= HORIZON and 0 <= x < VW and 0 <= y < VH:
                        n = noise(x, y, 5)
                        edge = rr > 0.75
                        if edge and noise(x, y, 6) > 0.55:
                            continue
                        pix[x, y] = DIRT[int(n * (len(DIRT) - 1))]

    # central buildable packed-earth plateau (clear, readable)
    for y in range(230, 490):
        for x in range(140, 820):
            nx = (x - 480) / 320.0
            ny = (y - 360) / 140.0
            rr = nx * nx + ny * ny
            if rr > 1.0:
                continue
            n = noise(x, y, 7)
            n2 = noise(x // 2, y // 2, 8)
            # soft edge blend to grass
            if rr > 0.78:
                if noise(x, y, 9) > (1 - rr) * 4:
                    continue
            idx = int((n * 0.5 + n2 * 0.5) * (len(PACK) - 1))
            pix[x, y] = PACK[idx]
            # fine grit
            if noise(x, y, 10) < 0.06:
                pix[x, y] = PACK[(idx + 2) % len(PACK)]
            # sparse pebble
            if noise(x, y, 11) < 0.012:
                pix[x, y] = STONE[int(n * 3)]

    # winding stone path
    for i in range(100):
        t = i / 99
        y = 210 + int(t * 300)
        x = 480 + int(28 * math.sin(t * math.pi * 2.4))
        half = 22 + int(10 * t)
        for dy in range(-6, 7):
            for dx in range(-half, half + 1):
                px, py = x + dx, y + dy
                if not (0 <= px < VW and HORIZON <= py < VH):
                    continue
                # brick cell
                local_x = dx + half
                local_y = dy + 6 + i
                if local_x % 7 == 0 or local_y % 5 == 0:
                    pix[px, py] = MORTAR
                else:
                    n = noise(local_x // 7, local_y // 5, 12)
                    pix[px, py] = PATH[int(n * (len(PATH) - 1))]

    # grass tufts along plateau rim
    for i in range(80):
        tx = 160 + (hash2(i, 3, 13) % 640)
        ty = 240 + (hash2(i, 5, 14) % 240)
        nx = (tx - 480) / 320.0
        ny = (ty - 360) / 140.0
        rr = nx * nx + ny * ny
        if 0.7 < rr < 1.05:
            for dy in range(0, 5):
                for dx in range(-2, 3):
                    if abs(dx) <= 2 - dy // 2:
                        put(pix, VW, VH, tx + dx, ty - dy, LEAF if dx % 2 == 0 else LEAF_DK)

    # fallen leaves / petals
    for i in range(120):
        x = hash2(i, 1, 15) % VW
        y = HORIZON + (hash2(i, 2, 16) % (VH - HORIZON))
        if noise(x, y, 17) < 0.5:
            put(pix, VW, VH, x, y, LEAF_Y if i % 3 else VERM[3])

    return img


def gen_hills() -> Image.Image:
    img = new_img(VW, VH)
    pix = img.load()
    d = ImageDraw.Draw(img)

    # sky gradient bands
    for y in range(0, HORIZON + 40):
        t = y / (HORIZON + 40)
        if t < 0.35:
            c = blend(SKY0, SKY1, t / 0.35)
        elif t < 0.7:
            c = blend(SKY1, SKY2, (t - 0.35) / 0.35)
        else:
            c = blend(SKY2, SKY3, (t - 0.7) / 0.3)
        for x in range(VW):
            # very subtle horizontal banding only — no star-like speckles
            if (y % 5 == 0) and noise(x // 8, y, 20) < 0.08:
                c2 = blend(c, SKY1, 0.15)
            else:
                c2 = c
            pix[x, y] = c2

    # clouds
    for cx, cy, rx, ry in [
        (120, 50, 70, 18), (280, 36, 50, 14), (520, 44, 80, 16),
        (720, 30, 60, 12), (860, 55, 55, 14), (400, 70, 40, 10),
    ]:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx / rx) ** 2 + (dy / ry) ** 2 < 1:
                    x, y = cx + dx, cy + dy
                    if 0 <= x < VW and 0 <= y < VH:
                        n = noise(x, y, 21)
                        pix[x, y] = CLOUD if n > 0.3 else CLOUD_DK

    def hill_ridge(base_y, amp, freq, col_ramp, seed):
        pts = []
        for x in range(VW):
            y = base_y + int(amp * math.sin(x * freq + seed))
            y += int(amp * 0.35 * math.sin(x * freq * 2.3 + seed * 1.7))
            y += int((noise(x, int(seed * 10), 22) - 0.5) * 8)
            pts.append(y)
        for x in range(VW):
            y0 = pts[x]
            for y in range(max(0, y0), HORIZON + 50):
                if y >= VH:
                    break
                # vertical shade
                t = (y - y0) / max(1, HORIZON + 50 - y0)
                n = noise(x, y, seed)
                idx = min(len(col_ramp) - 1, int(t * (len(col_ramp) - 1) + n * 0.5))
                # don't overwrite lower layers heavily — hills only upper
                if y < HORIZON + 30:
                    pix[x, y] = col_ramp[idx]
            # ridge edge
            put(pix, VW, VH, x, y0, HILL_EDGE)
            if noise(x, y0, 23) < 0.3:
                put(pix, VW, VH, x, y0 + 1, col_ramp[0])

    hill_ridge(110, 28, 0.008, [HILL_FAR, blend(HILL_FAR, HILL_MID, 0.5), HILL_MID], 1.1)
    hill_ridge(140, 34, 0.011, [HILL_MID, HILL_NEAR, blend(HILL_NEAR, PINE_DK, 0.4)], 2.3)
    hill_ridge(165, 22, 0.015, [HILL_NEAR, PINE, PINE_DK], 3.7)

    # distant pines silhouette
    for i in range(28):
        tx = 20 + i * 34 + (hash2(i, 0, 24) % 20)
        ty = 150 + (hash2(i, 1, 25) % 30)
        hgt = 18 + (hash2(i, 2, 26) % 22)
        for dy in range(0, hgt):
            half = max(1, 6 - dy // 4)
            for dx in range(-half, half + 1):
                put(pix, VW, VH, tx + dx, ty - dy, PINE_DK if dx % 2 else PINE)
        for dy in range(0, 6):
            put(pix, VW, VH, tx, ty + dy, WOOD[4])

    # far pagoda hint (readable multi-eave silhouette)
    px, py = 640, 95
    # body
    for y in range(py + 8, py + 55):
        for x in range(px - 3, px + 4):
            put(pix, VW, VH, x, y, INK2 if abs(x - px) > 1 else INK3)
    # three eaves
    for ry, rw in [(py + 10, 22), (py + 26, 18), (py + 42, 14)]:
        for x in range(px - rw // 2, px + rw // 2 + 1):
            # roof tile row
            put(pix, VW, VH, x, ry, ROOF_R[3])
            put(pix, VW, VH, x, ry + 1, ROOF_R[1])
            put(pix, VW, VH, x, ry + 2, INK2)
            # upturned eave tips
        put(pix, VW, VH, px - rw // 2 - 1, ry - 1, ROOF_R[2])
        put(pix, VW, VH, px + rw // 2 + 1, ry - 1, ROOF_R[2])
    # finial
    for y in range(py, py + 10):
        put(pix, VW, VH, px, y, GOLD[2])
    put(pix, VW, VH, px, py - 1, GOLD[0])

    # mist dither near horizon
    for y in range(HORIZON - 20, HORIZON + 25):
        for x in range(VW):
            if noise(x, y, 27) < 0.08:
                cur = pix[x, y]
                if cur[3] > 0:
                    pix[x, y] = blend(cur, SKY3, 0.35)

    return img


def gen_pad() -> Image.Image:
    """Buildable-zone hint — soft dashed cells, no fixed slots locking gameplay."""
    img = new_img(VW, VH)
    pix = img.load()

    # faint grain over plateau
    for y in range(240, 485):
        for x in range(155, 805):
            nx = (x - 480) / 310.0
            ny = (y - 360) / 135.0
            if nx * nx + ny * ny > 0.95:
                continue
            if noise(x, y, 30) < 0.02:
                pix[x, y] = blend(PACK[2], WOOD[0], 0.5)

    # soft dashed preview cells (3×2 ghost)
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
        for t in range(0, cell_w, 5):
            if (t // 5) % 2 == 0:
                put(pix, VW, VH, ox + t, oy, GOLD[2])
                put(pix, VW, VH, ox + t, oy + cell_h, GOLD[2])
        for t in range(0, cell_h, 5):
            if (t // 5) % 2 == 0:
                put(pix, VW, VH, ox, oy + t, GOLD[2])
                put(pix, VW, VH, ox + cell_w, oy + t, GOLD[2])
        # soft inner wash
        for y in range(oy + 2, oy + cell_h - 1):
            for x in range(ox + 2, ox + cell_w - 1):
                if noise(x, y, 31) < 0.03:
                    pix[x, y] = blend(PACK[3], GOLD[0], 0.15)

    # corner markers
    for sx, sy in [(148, 232), (812, 232), (148, 488), (812, 488)]:
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if abs(dx) == 3 or abs(dy) == 3:
                    put(pix, VW, VH, sx + dx, sy + dy, TEAL[0])
        put(pix, VW, VH, sx, sy, GOLD[1])

    return img


def gen_fg() -> Image.Image:
    img = new_img(VW, VH)
    pix = img.load()

    def tree(tx, ty, hgt=90, seed=40):
        # trunk with bark noise
        wood_plank_v(pix, VW, VH, tx - 4, ty - hgt // 3, tx + 4, ty + 20, seed=seed)
        for y in range(ty - hgt // 3, ty + 20):
            put(pix, VW, VH, tx - 5, y, INK2)
            put(pix, VW, VH, tx + 5, y, INK)
        # foliage clusters
        clusters = [
            (-18, -hgt // 2, 22), (14, -hgt // 2 - 6, 20), (-4, -hgt // 2 - 22, 18),
            (-22, -hgt // 2 + 10, 16), (18, -hgt // 2 + 4, 15), (0, -hgt // 2 - 34, 14),
            (-10, -hgt // 2 - 14, 12), (10, -hgt // 2 - 18, 12),
        ]
        for i, (ox, oy, r) in enumerate(clusters):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if dx * dx + dy * dy * 0.85 <= r * r:
                        x, y = tx + ox + dx, ty + oy + dy
                        if 0 <= x < VW and 0 <= y < VH:
                            n = noise(x, y, seed + i)
                            cols = [LEAF, LEAF_LT, LEAF_DK, PINE_LT, LEAF_Y]
                            pix[x, y] = cols[int(n * (len(cols) - 1))]
            # soft outline dither
            for a in range(0, 360, 10):
                x = tx + ox + int(r * 0.95 * math.cos(a * math.pi / 180))
                y = ty + oy + int(r * 0.95 * math.sin(a * math.pi / 180))
                if noise(x, y, 41) < 0.6:
                    put(pix, VW, VH, x, y, PINE_DK)

    # side trees only — keep center clear for placement
    for spec in [
        (32, 400, 105, 50), (18, 300, 80, 51), (48, 490, 70, 52), (70, 350, 60, 53),
        (55, 250, 55, 54), (928, 390, 100, 55), (942, 290, 78, 56), (900, 480, 65, 57),
        (880, 340, 55, 58), (910, 240, 50, 59),
    ]:
        tree(*spec)

    # bottom fence with posts + rails
    for x in range(0, VW, 12):
        wood_plank_v(pix, VW, VH, x + 2, VH - 44, x + 6, VH - 2, seed=60 + x)
        if x + 12 < VW:
            for yy in (VH - 36, VH - 24):
                for xx in range(x + 2, x + 14):
                    put(pix, VW, VH, xx, yy, WOOD[2])
                    put(pix, VW, VH, xx, yy + 1, WOOD[0])
                    put(pix, VW, VH, xx, yy - 1, WOOD[5])

    # lanterns on sides
    hanging_lantern(img, 64, 200)
    hanging_lantern(img, 896, 200)
    hanging_lantern(img, 40, 270)
    hanging_lantern(img, 920, 270)

    # rocks
    for rx, ry, rr in [
        (110, VH - 28, 8), (260, VH - 26, 6), (480, VH - 28, 7),
        (700, VH - 26, 6), (850, VH - 28, 8), (40, VH - 50, 5),
    ]:
        fill_disk(pix, VW, VH, rx, ry, rr, STONE, seed=70)
        put(pix, VW, VH, rx - rr // 2, ry - rr // 2, STONE[3])

    # side hedges
    for side_x0, side_x1 in [(0, 100), (860, 959)]:
        for y in range(220, 480):
            for x in range(side_x0, side_x1):
                if noise(x, y, 71) < 0.18:
                    pix[x, y] = LEAF_DK if (x + y) % 2 else PINE

    # grass clumps FG
    for gx in [20, 50, 80, 880, 910, 940]:
        for dy in range(0, 22):
            for dx in range(-12, 13):
                if abs(dx) < 12 - dy // 2:
                    put(pix, VW, VH, gx + dx, VH - 48 - dy,
                        LEAF_DK if dx % 2 == 0 else LEAF)

    return img


def compose(ground, hills, pad, fg, buildings=None, slots=None) -> Image.Image:
    out = Image.new("RGBA", (VW, VH), SKY2)
    out.alpha_composite(hills)
    out.alpha_composite(ground)
    out.alpha_composite(pad)
    if buildings and slots:
        for name, (cx, cy) in slots.items():
            b = buildings.get(name)
            if b is None:
                continue
            x = cx - b.width // 2
            y = cy - b.height + 12
            out.alpha_composite(b, (x, y))
    out.alpha_composite(fg)
    return out


def buildings_preview_row(manor, inn, forge) -> Image.Image:
    pad = 16
    label_h = 18
    w = ICON * 3 + pad * 4
    h = ICON + pad * 2 + label_h
    img = Image.new("RGBA", (w, h), C("1A1814"))
    # checkerboard bg for readability
    pix = img.load()
    for y in range(h):
        for x in range(w):
            if ((x // 8) + (y // 8)) % 2 == 0:
                pix[x, y] = C("2A2620")
            else:
                pix[x, y] = C("22201A")
    for i, (im, name) in enumerate([(manor, "manor"), (inn, "inn"), (forge, "forge")]):
        x = pad + i * (ICON + pad)
        y = pad
        # soft shadow under
        ellipse_shadow(img, x + ICON // 2, y + ICON - 4, 50, 10, SHADOW, 0.5)
        img.alpha_composite(im, (x, y))
    return img


def ensure_backup():
    PREV.mkdir(parents=True, exist_ok=True)
    (PREV / "buildings").mkdir(exist_ok=True)
    (PREV / "tiles").mkdir(exist_ok=True)
    for name in ("manor.png", "inn.png", "forge.png"):
        src = BUILDINGS / name
        dst = PREV / "buildings" / name
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
    TILES.mkdir(parents=True, exist_ok=True)
    BUILDINGS.mkdir(parents=True, exist_ok=True)

    print("Generating buildings 160×160…")
    manor = icon_manor()
    inn = icon_inn()
    forge = icon_forge()
    manor.save(BUILDINGS / "manor.png")
    inn.save(BUILDINGS / "inn.png")
    forge.save(BUILDINGS / "forge.png")

    print("Generating village layers 960×540…")
    ground = gen_ground()
    hills = gen_hills()
    pad = gen_pad()
    fg = gen_fg()
    ground.save(TILES / "village_ground.png")
    hills.save(TILES / "village_hills.png")
    pad.save(TILES / "village_buildings_pad.png")
    fg.save(TILES / "village_fg.png")

    # preview-only placement (free-place gameplay)
    slots = {
        "manor": (480, 300),
        "inn": (270, 380),
        "forge": (700, 380),
    }
    buildings = {"manor": manor, "inn": inn, "forge": forge}
    composed = compose(ground, hills, pad, fg, buildings, slots)
    composed.save(TILES / "village_composed.png")

    # previews
    row = buildings_preview_row(manor, inn, forge)
    # scale ×2 nearest for readable preview
    row2 = row.resize((row.width * 2, row.height * 2), Image.NEAREST)
    row2.save(PREVIEW / "pivot_r1_buildings.png")

    village_prev = composed.copy()
    village_prev.save(PREVIEW / "pivot_r1_village.png")
    # also refresh common preview name
    composed.save(PREVIEW / "village_composed.png")

    # layers-only (no buildings) for art check
    layers_only = compose(ground, hills, pad, fg)
    layers_only.save(PREVIEW / "pivot_r1_layers_only.png")

    print("OK")
    print(f"  buildings: {ICON}×{ICON} → {BUILDINGS}")
    print(f"  tiles: {VW}×{VH} → {TILES}")
    print(f"  preview: {PREVIEW / 'pivot_r1_buildings.png'}")
    print(f"  preview: {PREVIEW / 'pivot_r1_village.png'}")
    print(f"  backup: {PREV}")
    print("已停等用戶睇預覽")


if __name__ == "__main__":
    main()
