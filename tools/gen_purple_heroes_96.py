#!/usr/bin/env python3
"""墨點俠村 — 紫階十二人 96×96 硬邊像素精靈（一方宗師）

解像階梯：白綠64｜藍紫96｜橙128｜紅256
華麗度：高於綠64、低於橙128
禁止：柔邊／抗鋸齒／寫實／NN放大／抄原著立繪／抄俠客棧／銀樓舊稿
色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227
     ＋梵紫#5A4060＋skin/wood/boot/shade 微調
"""
from __future__ import annotations

import os
from PIL import Image

SIZE = 96
WALK_FRAMES = 4
ROOT = "/workspace/modian-xiacun/assets/art"
OUT = f"{ROOT}/heroes/purple"
PREV = f"{ROOT}/_preview"
MANIFEST = "/workspace/modian-xiacun/tools/MANIFEST_purple_heroes.md"

P = {
    "ink": (26, 21, 16, 255),
    "paper": (232, 220, 200, 255),
    "cinnabar": (196, 60, 44, 255),
    "teal": (47, 107, 90, 255),
    "gold": (201, 162, 39, 255),
    "skin": (200, 170, 140, 255),
    "skin2": (184, 148, 116, 255),
    "skin3": (168, 132, 100, 255),
    "wood": (90, 64, 48, 255),
    "wood2": (112, 80, 56, 255),
    "wood3": (72, 52, 40, 255),
    "boot": (58, 40, 32, 255),
    "shade": (74, 64, 52, 255),
    "shade2": (98, 86, 72, 255),
    "stone": (106, 96, 85, 255),
    "silver": (180, 176, 168, 255),
    "pale_gold": (212, 186, 110, 255),
    "black": (42, 36, 32, 255),
    "black2": (32, 28, 24, 255),
    "black3": (58, 50, 44, 255),
    "brown": (110, 78, 52, 255),
    "brown2": (88, 62, 42, 255),
    "brown3": (130, 96, 64, 255),
    "qing": (58, 100, 88, 255),
    "qing2": (42, 78, 68, 255),
    "qing3": (74, 118, 104, 255),
    "white": (232, 220, 200, 255),
    "white2": (210, 198, 178, 255),
    "white3": (190, 178, 158, 255),
    "grey": (120, 112, 100, 255),
    "grey2": (96, 90, 80, 255),
    "grey3": (140, 132, 118, 255),
    "redrobe": (168, 48, 40, 255),
    "redrobe2": (140, 36, 32, 255),
    "redrobe3": (196, 60, 44, 255),
    "iron": (90, 92, 96, 255),
    "iron2": (70, 72, 76, 255),
    "purple": (90, 64, 96, 255),    # #5A4060 梵紫
    "purple2": (72, 50, 78, 255),
    "purple3": (110, 80, 118, 255),
    "monk": (110, 100, 88, 255),
    "monk2": (88, 78, 66, 255),
    "earth": (140, 110, 78, 255),
    "earth2": (118, 92, 64, 255),
    "earth3": (158, 128, 92, 255),
    "trans": (0, 0, 0, 0),
}

ALLOWED = {(c[0], c[1], c[2]) for c in P.values() if c[3] > 0}


def nf() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), P["trans"])


def put(im: Image.Image, x: int, y: int, c: tuple) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE and c[3]:
        im.putpixel((x, y), c)


def R(im: Image.Image, x: int, y: int, w: int, h: int, c: tuple) -> None:
    for j in range(max(0, h)):
        for i in range(max(0, w)):
            put(im, x + i, y + j, c)


def Hline(im, x, y, w, c):
    R(im, x, y, w, 1, c)


def Vline(im, x, y, h, c):
    R(im, x, y, 1, h, c)


def box(im, x, y, w, h, fill, edge=None):
    edge = edge or P["ink"]
    R(im, x, y, w, h, fill)
    Hline(im, x, y, w, edge)
    Hline(im, x, y + h - 1, w, edge)
    Vline(im, x, y, h, edge)
    Vline(im, x + w - 1, y, h, edge)


def fold_v(im, x, y, h, c=None):
    Vline(im, x, y, h, c or P["shade"])


def fold_h(im, x, y, w, c=None):
    Hline(im, x, y, w, c or P["shade"])


def gold_trim(im, x, y, w, h):
    Hline(im, x, y, w, P["gold"])
    Hline(im, x, y + h - 1, w, P["gold"])
    Vline(im, x, y, h, P["gold"])
    Vline(im, x + w - 1, y, h, P["gold"])


def shadow(im, cx=48, y=88, w=36):
    x = cx - w // 2
    R(im, x, y, w, 3, P["shade"])
    R(im, x + 4, y + 1, w - 8, 1, P["ink"])


def face96(im, x, y, *, smile=False, stern=False, smirk=False, cold=False):
    """約 18×20 臉"""
    box(im, x, y, 18, 20, P["skin"])
    R(im, x + 1, y + 1, 3, 16, P["skin2"])
    R(im, x + 14, y + 2, 2, 14, P["skin2"])
    R(im, x + 4, y + 15, 10, 3, P["skin3"])
    # brows
    Hline(im, x + 3, y + 5, 5, P["ink"])
    Hline(im, x + 10, y + 5, 5, P["ink"])
    if stern:
        Hline(im, x + 3, y + 4, 5, P["ink"])
        Hline(im, x + 10, y + 4, 5, P["ink"])
    # eyes
    R(im, x + 4, y + 7, 3, 2, P["ink"])
    R(im, x + 11, y + 7, 3, 2, P["ink"])
    put(im, x + 5, y + 7, P["paper"])
    put(im, x + 12, y + 7, P["paper"])
    if cold:
        Hline(im, x + 4, y + 6, 3, P["ink"])
        Hline(im, x + 11, y + 6, 3, P["ink"])
    # nose
    Vline(im, x + 9, y + 8, 4, P["skin2"])
    Hline(im, x + 8, y + 11, 2, P["skin3"])
    # mouth
    if smile:
        R(im, x + 6, y + 14, 6, 2, P["cinnabar"])
        put(im, x + 6, y + 14, P["ink"])
        put(im, x + 11, y + 14, P["ink"])
    elif smirk:
        R(im, x + 7, y + 14, 5, 2, P["cinnabar"])
        Hline(im, x + 7, y + 14, 5, P["ink"])
        put(im, x + 11, y + 15, P["ink"])
    else:
        R(im, x + 6, y + 14, 6, 2, P["cinnabar"])
        Hline(im, x + 6, y + 14, 6, P["ink"])


def hair_short_black(im, x, y, sway=0):
    R(im, x + 1, y - 5, 16, 6, P["ink"])
    R(im, x + 2, y - 8, 14, 4, P["ink"])
    R(im, x, y, 3, 8, P["ink"])
    R(im, x + 15, y, 3, 8, P["ink"])


def hair_youth(im, x, y, sway=0):
    """少年束髮"""
    R(im, x + 1, y - 5, 16, 6, P["ink"])
    R(im, x + 3, y - 9, 12, 5, P["ink"])
    box(im, x + 6, y - 14, 6, 6, P["ink"])
    put(im, x + 8, y - 12, P["gold"])
    R(im, x + 16 + sway, y - 1, 4, 16, P["ink"])


def hair_long_black(im, x, y, sway=0):
    R(im, x + 1, y - 5, 16, 7, P["ink"])
    R(im, x + 2, y - 10, 14, 6, P["ink"])
    R(im, x + 16 + sway, y - 2, 5, 28, P["ink"])
    R(im, x + 18 + sway, y + 10, 4, 18, P["black3"])
    R(im, x - 1, y, 3, 14, P["ink"])


def hair_long_white(im, x, y, sway=0):
    R(im, x + 1, y - 5, 16, 7, P["paper"])
    R(im, x + 2, y - 10, 14, 6, P["white2"])
    R(im, x + 16 + sway, y - 2, 5, 30, P["paper"])
    R(im, x + 18 + sway, y + 12, 4, 20, P["white2"])
    R(im, x - 1, y, 3, 16, P["white2"])
    for i in range(0, 24, 5):
        fold_v(im, x + 17 + sway, y + i, 3, P["shade"])


def hair_bun_ornament(im, x, y, ornament=P["gold"]):
    R(im, x + 1, y - 5, 16, 6, P["ink"])
    R(im, x + 3, y - 9, 12, 5, P["ink"])
    box(im, x + 5, y - 15, 8, 7, P["ink"])
    gold_trim(im, x + 5, y - 15, 8, 7)
    put(im, x + 8, y - 12, ornament)


def hair_nun_purple(im, x, y):
    R(im, x, y - 6, 18, 8, P["purple2"])
    R(im, x + 1, y - 10, 16, 5, P["purple"])
    box(im, x + 3, y - 14, 12, 6, P["purple3"])
    Hline(im, x + 3, y - 14, 12, P["ink"])
    R(im, x - 1, y, 4, 12, P["purple2"])
    R(im, x + 15, y, 4, 12, P["purple2"])


def hair_cap_eunuch(im, x, y):
    """小太監帽／青帽"""
    R(im, x + 1, y - 6, 16, 7, P["qing2"])
    R(im, x + 3, y - 10, 12, 5, P["qing"])
    box(im, x + 5, y - 14, 8, 5, P["qing3"])
    put(im, x + 8, y - 12, P["gold"])
    Hline(im, x + 1, y - 1, 16, P["gold"])


def hair_bald(im, x, y):
    R(im, x + 2, y - 4, 14, 5, P["skin"])
    R(im, x + 3, y - 7, 12, 4, P["skin2"])
    R(im, x + 5, y - 9, 8, 3, P["skin3"])
    for dx in (5, 8, 11):
        put(im, x + dx, y - 1, P["ink"])


def hair_messy_brown(im, x, y, sway=0):
    R(im, x + 1, y - 5, 16, 6, P["wood3"])
    R(im, x + 2, y - 9, 14, 5, P["wood"])
    R(im, x + 15 + sway, y, 4, 12, P["wood"])
    R(im, x - 1, y, 3, 8, P["wood"])


def robe_torso(im, x, y, w, h, fill, shade, accent=None, dense=True):
    box(im, x, y, w, h, fill)
    R(im, x + 1, y + 1, 4, h - 2, shade)
    R(im, x + w - 5, y + 2, 3, h - 4, shade)
    if dense:
        for i in range(5, w - 3, 6):
            fold_v(im, x + i, y + 3, h - 10, shade)
        for j in range(8, h - 6, 8):
            fold_h(im, x + 5, y + j, w - 10, shade)
    if accent:
        R(im, x + 2, y + h - 5, w - 4, 3, accent)
        Hline(im, x + 2, y + h - 5, w - 4, P["ink"])


def sleeves(im, xl, xr, y, w, h, fill, shade, bob=0):
    box(im, xl, y + bob, w, h, fill)
    box(im, xr, y + bob, w, h, fill)
    R(im, xl + 1, y + bob + 1, 2, h - 2, shade)
    R(im, xr + 1, y + bob + 1, 2, h - 2, shade)
    for i in range(4, h - 2, 6):
        fold_h(im, xl + 2, y + bob + i, w - 4, shade)
        fold_h(im, xr + 2, y + bob + i, w - 4, shade)


def legs(im, x, y, fill, shade, step=0, lean=0, boot=True, pant_h=20):
    lx = lean + (-4 if step < 0 else (4 if step > 0 else 0))
    rx = lean + (4 if step < 0 else (-4 if step > 0 else 0))
    ly = -2 if step < 0 else 0
    ry = -2 if step > 0 else 0
    R(im, x + lx, y + ly, 11, pant_h, fill)
    R(im, x + lx + 1, y + ly + 1, 2, pant_h - 3, shade)
    fold_v(im, x + lx + 5, y + ly + 2, pant_h - 6, shade)
    R(im, x + 14 + rx, y + ry, 11, pant_h, fill)
    R(im, x + 15 + rx, y + ry + 1, 2, pant_h - 3, shade)
    fold_v(im, x + 19 + rx, y + ry + 2, pant_h - 6, shade)
    if boot:
        R(im, x + lx - 1, y + pant_h - 3 + ly, 12, 6, P["boot"])
        Hline(im, x + lx - 1, y + pant_h - 3 + ly, 12, P["ink"])
        Hline(im, x + lx - 1, y + pant_h + 2 + ly, 12, P["ink"])
        R(im, x + 14 + rx - 1, y + pant_h - 3 + ry, 12, 6, P["boot"])
        Hline(im, x + 14 + rx - 1, y + pant_h - 3 + ry, 12, P["ink"])
        Hline(im, x + 14 + rx - 1, y + pant_h + 2 + ry, 12, P["ink"])


def belt(im, x, y, w, jewel=True, color=None):
    color = color or P["gold"]
    R(im, x, y, w, 6, color)
    Hline(im, x, y, w, P["ink"])
    Hline(im, x, y + 5, w, P["ink"])
    Hline(im, x + 2, y + 2, w - 4, P["pale_gold"] if color == P["gold"] else P["shade"])
    bx = x + w // 2 - 3
    box(im, bx, y + 1, 6, 4, P["gold"])
    if jewel:
        put(im, bx + 2, y + 2, P["cinnabar"])


def fist(im, x, y):
    box(im, x, y, 9, 8, P["skin"])
    R(im, x + 1, y + 1, 2, 5, P["skin2"])
    for i in range(3):
        Vline(im, x + 2 + i * 2, y + 2, 4, P["ink"])


def palm(im, x, y, big=False):
    w, h = (12, 10) if big else (10, 9)
    box(im, x, y, w, h, P["skin"])
    R(im, x + 1, y + 1, 2, h - 3, P["skin2"])
    for i in range(4 if big else 3):
        Vline(im, x + 2 + i * 2, y + 2, h - 4, P["ink"])


def walk_params(walk_i):
    if walk_i < 0:
        return 0, 0, 0, 0
    step = (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -1 if walk_i % 2 else 0
    sway = (walk_i % 4 - 1) * 1
    return step, lean, bob, sway


def dao_blade(im, sx, sy, length=40, tip_up=True):
    """苗刀／樸刀側影"""
    for i in range(length):
        yy = sy - i if tip_up else sy + i
        R(im, sx, yy, 3, 1, P["iron"])
        put(im, sx + 2, yy, P["silver"])
    R(im, sx - 2, sy + (2 if tip_up else -2), 8, 5, P["wood3"])
    Hline(im, sx - 2, sy + (2 if tip_up else -2), 8, P["ink"])
    R(im, sx, sy + (6 if tip_up else -8), 3, 8, P["wood"])


def jian_blade(im, sx, sy, length=42):
    for i in range(length):
        R(im, sx, sy + i, 2, 1, P["silver"])
        put(im, sx + 1, sy + i, P["stone"])
    R(im, sx - 2, sy + length - 2, 7, 4, P["gold"])
    Hline(im, sx - 2, sy + length - 2, 7, P["ink"])
    R(im, sx, sy + length + 2, 2, 8, P["wood"])


# ===================== 十二人 ===================== #

def draw_weixiaobao(im, walk_i=-1):
    """韋小保｜暗器｜青衣小太監感、匕首多柄、腰牌；青綠＋金邊小飾"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["qing2"], P["qing"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["qing3"], P["qing2"], P["gold"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["qing"], P["qing2"])
    # eunuch collar gold
    R(im, cx - 8, 30 + bob, 16, 3, P["gold"])
    Hline(im, cx - 8, 30 + bob, 16, P["ink"])
    belt(im, cx - 12, 56 + bob, 24)
    # waist plaque
    box(im, cx + 10, 54 + bob, 10, 10, P["gold"])
    put(im, cx + 14, 58 + bob, P["cinnabar"])
    Hline(im, cx + 12, 56 + bob, 6, P["pale_gold"])
    # multi daggers at hip
    for i, dx in enumerate((-2, 2, 6)):
        R(im, cx - 18 + dx, 58 + bob + i, 2, 12, P["silver"])
        put(im, cx - 18 + dx, 58 + bob + i, P["iron"])
        R(im, cx - 19 + dx, 68 + bob + i, 4, 3, P["wood"])
    fist(im, cx - 28, 52 + bob)
    fist(im, cx + 20 + (1 if walk_i >= 0 else 0), 50 + bob)
    face96(im, cx - 9, 12 + bob, smile=True)
    hair_cap_eunuch(im, cx - 9, 12 + bob)


def draw_hufei(im, walk_i=-1):
    """胡飛｜刀｜少年勁裝、苗刀、義氣眉目；土褐／墨刀"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["brown2"], P["wood3"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["earth"], P["earth2"], None, True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["brown3"], P["brown2"])
    # chest sash
    R(im, cx - 10, 34 + bob, 20, 4, P["wood"])
    Hline(im, cx - 10, 34 + bob, 20, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["wood2"])
    # miao dao on back-right
    sx = cx + 18
    for i in range(38):
        R(im, sx + i // 12, 18 + bob + i, 3, 1, P["iron"])
        put(im, sx + i // 12 + 2, 18 + bob + i, P["silver"])
    R(im, sx - 1, 52 + bob, 7, 5, P["wood3"])
    Hline(im, sx - 1, 52 + bob, 7, P["ink"])
    put(im, sx + 2, 54 + bob, P["gold"])
    fist(im, cx - 28, 52 + bob)
    fist(im, cx + 20, 50 + bob)
    face96(im, cx - 9, 12 + bob, smile=False)
    # righteous brows (extra thick)
    Hline(im, cx - 6, 16 + bob, 5, P["ink"])
    Hline(im, cx + 1, 16 + bob, 5, P["ink"])
    hair_youth(im, cx - 9, 12 + bob, sway)


def draw_miaorenfeng(im, walk_i=-1):
    """苗人風｜刀｜金面／半面金紋、大刀、壯碩；金邊＋硃紅"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 40)
    legs(im, cx - 14, 62 + bob, P["black2"], P["black"], step, lean, pant_h=22)
    # bulky torso
    robe_torso(im, cx - 18, 28 + bob, 36, 38, P["black3"], P["black2"], P["cinnabar"], True)
    sleeves(im, cx - 28, cx + 20, 32 + bob, 12, 26, P["black"], P["black2"])
    gold_trim(im, cx - 18, 28 + bob, 36, 38)
    belt(im, cx - 16, 56 + bob, 32)
    # big dao forward-right
    sx = cx + 22 + (1 if walk_i >= 0 else 0)
    for i in range(44):
        ww = 4 if i < 30 else 3
        R(im, sx, 16 + bob + i, ww, 1, P["iron"])
        put(im, sx + ww - 1, 16 + bob + i, P["silver"])
    R(im, sx - 3, 56 + bob, 10, 6, P["wood3"])
    gold_trim(im, sx - 3, 56 + bob, 10, 6)
    R(im, sx, 62 + bob, 3, 10, P["wood"])
    put(im, sx + 1, 66 + bob, P["cinnabar"])
    fist(im, sx - 2, 58 + bob)
    fist(im, cx - 32, 50 + bob)
    face96(im, cx - 9, 10 + bob, stern=True)
    # gold half-mask / face gold pattern (right half)
    R(im, cx, 10 + bob, 9, 18, P["gold"])
    R(im, cx + 1, 12 + bob, 6, 12, P["pale_gold"])
    put(im, cx + 3, 16 + bob, P["ink"])  # eye slit
    put(im, cx + 4, 16 + bob, P["ink"])
    Hline(im, cx, 10 + bob, 9, P["ink"])
    Vline(im, cx, 10 + bob, 18, P["ink"])
    hair_short_black(im, cx - 9, 10 + bob)
    # forehead gold band
    R(im, cx - 8, 8 + bob, 16, 3, P["gold"])
    Hline(im, cx - 8, 8 + bob, 16, P["ink"])


def draw_yuanchengzhi(im, walk_i=-1):
    """袁承智｜劍｜金蛇意象短劍、英俊勁裝；金＋青"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["qing2"], P["qing"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["qing3"], P["qing2"], P["gold"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["qing"], P["qing2"])
    # gold collar
    R(im, cx - 8, 30 + bob, 16, 3, P["gold"])
    Hline(im, cx - 8, 30 + bob, 16, P["ink"])
    belt(im, cx - 12, 56 + bob, 24)
    # snake-motif short sword (wavy blade)
    sx = cx + 20 + (1 if walk_i >= 0 else 0)
    for i in range(32):
        ox = (i % 6) // 3  # slight wave
        R(im, sx + ox, 28 + bob + i, 2, 1, P["gold"])
        put(im, sx + ox + 1, 28 + bob + i, P["pale_gold"])
    R(im, sx - 2, 56 + bob, 7, 4, P["gold"])
    Hline(im, sx - 2, 56 + bob, 7, P["ink"])
    # snake head tip
    put(im, sx, 26 + bob, P["cinnabar"])
    put(im, sx + 1, 27 + bob, P["ink"])
    # wrist snake guard left
    R(im, cx - 24, 52 + bob, 10, 5, P["gold"])
    Hline(im, cx - 24, 52 + bob, 10, P["ink"])
    put(im, cx - 20, 54 + bob, P["teal"])
    fist(im, cx - 28, 54 + bob)
    fist(im, sx - 2, 58 + bob)
    face96(im, cx - 9, 12 + bob, smile=True)
    hair_youth(im, cx - 9, 12 + bob, sway)
    put(im, cx - 1, 0 + bob, P["gold"])  # hair ornament


def draw_diyun(im, walk_i=-1):
    """狄芸｜刀｜樸刀、破衣堅毅、短髮／束髮；灰褐"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["grey2"], P["grey"], step, lean)
    # ragged robe
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["earth2"], P["brown2"], None, True)
    # tear patches
    R(im, cx + 6, 40 + bob, 6, 8, P["shade"])
    R(im, cx - 12, 48 + bob, 5, 6, P["shade2"])
    put(im, cx + 8, 42 + bob, P["ink"])
    put(im, cx - 10, 50 + bob, P["ink"])
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 22, P["brown"], P["brown2"])
    # frayed sleeve edge
    for dx in range(0, 8, 2):
        put(im, cx - 24 + dx, 56 + bob, P["ink"])
        put(im, cx + 18 + dx, 56 + bob, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["wood3"], jewel=False)
    # pu dao
    sx = cx + 18
    for i in range(36):
        R(im, sx, 22 + bob + i, 3, 1, P["iron"])
        put(im, sx + 2, 22 + bob + i, P["stone"])
    R(im, sx - 2, 54 + bob, 8, 5, P["wood3"])
    Hline(im, sx - 2, 54 + bob, 8, P["ink"])
    R(im, sx, 58 + bob, 3, 8, P["wood"])
    fist(im, cx - 28, 50 + bob)
    fist(im, sx - 2, 56 + bob)
    face96(im, cx - 9, 12 + bob, stern=True)
    hair_messy_brown(im, cx - 9, 12 + bob, sway)


def draw_shipotian(im, walk_i=-1):
    """石破添｜拳腳｜粗布、巨掌、傻笑、護腕；土黄"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 38)
    legs(im, cx - 14, 64 + bob, P["earth2"], P["wood3"], step, lean)
    robe_torso(im, cx - 16, 30 + bob, 32, 36, P["earth3"], P["earth"], None, True)
    sleeves(im, cx - 26, cx + 18, 34 + bob, 11, 22, P["earth"], P["earth2"])
    # thick wrist guards
    R(im, cx - 26, 50 + bob, 12, 7, P["wood"])
    R(im, cx + 18, 50 + bob, 12, 7, P["wood"])
    Hline(im, cx - 26, 50 + bob, 12, P["ink"])
    Hline(im, cx + 18, 50 + bob, 12, P["ink"])
    Hline(im, cx - 24, 53 + bob, 8, P["wood2"])
    Hline(im, cx + 20, 53 + bob, 8, P["wood2"])
    belt(im, cx - 14, 56 + bob, 28, color=P["wood2"], jewel=False)
    # giant palms
    palm(im, cx - 34, 52 + bob, big=True)
    palm(im, cx + 24 + (1 if walk_i >= 0 else 0), 50 + bob, big=True)
    face96(im, cx - 9, 12 + bob, smile=True)
    hair_short_black(im, cx - 9, 12 + bob)
    # simple cloth collar
    R(im, cx - 6, 30 + bob, 12, 3, P["earth2"])


def draw_xuzhu(im, walk_i=-1):
    """虛竺｜拳腳｜僧衣轉逍遙袍、念珠、光頭；僧灰／淡紫"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["purple2"], P["purple"], step, lean)
    # half monk / half xiaoyao: grey body + purple sash
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["monk"], P["monk2"], P["purple"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["monk2"], P["shade"])
    # purple sash
    R(im, cx - 12, 48 + bob, 24, 5, P["purple3"])
    Hline(im, cx - 12, 48 + bob, 24, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["purple2"], jewel=False)
    # prayer beads
    for i, dx in enumerate((-8, -4, 0, 4, 8)):
        put(im, cx + dx, 32 + bob, P["wood"])
        put(im, cx + dx, 33 + bob, P["wood2"])
    put(im, cx, 34 + bob, P["gold"])
    # optional short staff behind
    R(im, cx + 16, 20 + bob, 3, 48, P["wood3"])
    fold_v(im, cx + 17, 22 + bob, 40, P["wood"])
    palm(im, cx - 28, 52 + bob)
    palm(im, cx + 20, 50 + bob)
    face96(im, cx - 9, 14 + bob, smile=True)
    hair_bald(im, cx - 9, 14 + bob)


def draw_limochou(im, walk_i=-1):
    """李莫秋｜暗器｜赤練衣、銀針／鞭影、面紗；硃紅＋銀"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["redrobe2"], P["redrobe"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["redrobe3"], P["redrobe2"], P["silver"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["redrobe"], P["redrobe2"])
    # silver trim collar
    R(im, cx - 8, 30 + bob, 16, 3, P["silver"])
    Hline(im, cx - 8, 30 + bob, 16, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["silver"], jewel=True)
    # silver needles at hip
    for i in range(5):
        Vline(im, cx - 16 + i * 2, 54 + bob, 10, P["silver"])
        put(im, cx - 16 + i * 2, 54 + bob, P["iron"])
    # whip shadow arc (right)
    for i in range(20):
        put(im, cx + 22 + i // 3, 40 + bob + (i % 5), P["silver"])
        put(im, cx + 23 + i // 3, 41 + bob + (i % 5), P["shade"])
    fist(im, cx - 28, 52 + bob)
    fist(im, cx + 20, 50 + bob)
    face96(im, cx - 9, 12 + bob, cold=True)
    hair_long_black(im, cx - 9, 12 + bob, sway)
    # veil
    R(im, cx - 8, 22 + bob, 16, 6, P["redrobe2"])
    Hline(im, cx - 8, 22 + bob, 16, P["ink"])
    for i in range(0, 14, 3):
        put(im, cx - 6 + i, 25 + bob, P["silver"])


def draw_xiaolongnu(im, walk_i=-1):
    """小龍妞｜劍｜白衣古墓感、長髮、細劍；宣紙白＋墨邊"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 32)
    legs(im, cx - 12, 64 + bob, P["white2"], P["white3"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["paper"], P["white2"], None, True)
    # ink edge accents
    Hline(im, cx - 14, 30 + bob, 28, P["ink"])
    Vline(im, cx - 14, 30 + bob, 36, P["ink"])
    Vline(im, cx + 13, 30 + bob, 36, P["ink"])
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["white"], P["white2"])
    belt(im, cx - 12, 56 + bob, 24, color=P["ink"], jewel=False)
    # thin gold buckle only
    box(im, cx - 2, 57 + bob, 4, 4, P["gold"])
    # thin sword
    sx = cx + 20
    for i in range(44):
        R(im, sx, 16 + bob + i, 2, 1, P["silver"])
        put(im, sx + 1, 16 + bob + i, P["paper"])
    R(im, sx - 2, 56 + bob, 6, 3, P["ink"])
    R(im, sx, 58 + bob, 2, 8, P["wood"])
    put(im, sx, 62 + bob, P["gold"])
    fist(im, cx - 28, 52 + bob)
    fist(im, sx - 2, 56 + bob)
    face96(im, cx - 9, 12 + bob, cold=True)
    hair_long_white(im, cx - 9, 12 + bob, sway)
    # pale forehead band
    R(im, cx - 7, 10 + bob, 14, 2, P["white2"])
    Hline(im, cx - 7, 10 + bob, 14, P["ink"])


def draw_zhaomin(im, walk_i=-1):
    """趙敏｜暗器／扇｜郡主勁裝、摺扇／短刃、髮飾；硃紅＋金"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["redrobe2"], P["redrobe"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["redrobe"], P["redrobe2"], P["gold"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["redrobe3"], P["redrobe2"])
    # gold collar junzhu style
    R(im, cx - 8, 30 + bob, 16, 4, P["gold"])
    Hline(im, cx - 8, 30 + bob, 16, P["ink"])
    put(im, cx - 1, 31 + bob, P["cinnabar"])
    put(im, cx + 1, 31 + bob, P["cinnabar"])
    belt(im, cx - 12, 56 + bob, 24)
    # folding fan in right hand
    fx = cx + 20 + (1 if walk_i >= 0 else 0)
    for i in range(8):
        R(im, fx + i, 44 + bob - i // 2, 2, 14 + i // 2, P["paper"])
        put(im, fx + i, 44 + bob - i // 2, P["gold"])
    Vline(im, fx, 48 + bob, 12, P["wood"])
    # short blade at left hip
    R(im, cx - 18, 54 + bob, 2, 12, P["silver"])
    R(im, cx - 19, 64 + bob, 4, 3, P["gold"])
    fist(im, cx - 28, 52 + bob)
    fist(im, fx - 2, 56 + bob)
    face96(im, cx - 9, 12 + bob, smile=True)
    hair_bun_ornament(im, cx - 9, 12 + bob, P["cinnabar"])
    # side hair ornament
    put(im, cx + 8, 14 + bob, P["gold"])
    put(im, cx + 9, 15 + bob, P["cinnabar"])


def draw_zhouzhiruo(im, walk_i=-1):
    """周芷偌｜劍｜峨眉紫灰尼袍／紫帶、長劍、頭巾；梵紫＋青灰"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["grey2"], P["grey"], step, lean)
    robe_torso(im, cx - 14, 30 + bob, 28, 36, P["grey3"], P["grey2"], P["purple"], True)
    sleeves(im, cx - 24, cx + 16, 34 + bob, 10, 24, P["grey"], P["grey2"])
    # purple sash
    R(im, cx - 12, 48 + bob, 24, 5, P["purple3"])
    Hline(im, cx - 12, 48 + bob, 24, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["purple2"], jewel=False)
    # long sword
    sx = cx + 20
    for i in range(42):
        R(im, sx, 18 + bob + i, 2, 1, P["silver"])
        put(im, sx + 1, 18 + bob + i, P["stone"])
    R(im, sx - 2, 56 + bob, 7, 4, P["purple"])
    Hline(im, sx - 2, 56 + bob, 7, P["ink"])
    R(im, sx, 60 + bob, 2, 8, P["wood"])
    put(im, sx, 64 + bob, P["gold"])
    fist(im, cx - 28, 52 + bob)
    fist(im, sx - 2, 56 + bob)
    face96(im, cx - 9, 12 + bob, cold=True)
    hair_nun_purple(im, cx - 9, 12 + bob)
    # soft collar
    R(im, cx - 6, 30 + bob, 12, 3, P["grey2"])


def draw_yuebuqun(im, walk_i=-1):
    """岳不裙｜劍｜君子白／青長袍、長劍、假笑冠帶；宣紙白＋青綠"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 48 + lean
    shadow(im, 48 + lean, 88 + bob, 34)
    legs(im, cx - 12, 64 + bob, P["qing2"], P["qing"], step, lean)
    robe_torso(im, cx - 14, 28 + bob, 28, 38, P["paper"], P["white2"], P["teal"], True)
    sleeves(im, cx - 24, cx + 16, 32 + bob, 10, 26, P["white"], P["white2"])
    # teal lapel (君子)
    R(im, cx - 4, 28 + bob, 4, 30, P["teal"])
    Vline(im, cx - 4, 28 + bob, 30, P["ink"])
    Vline(im, cx, 28 + bob, 30, P["ink"])
    belt(im, cx - 12, 56 + bob, 24, color=P["teal"])
    # long sword on back
    sx, sy = cx + 12, 14 + bob
    for i in range(52):
        R(im, sx + i // 10, sy + i, 3, 1, P["silver"])
        put(im, sx + i // 10 + 2, sy + i, P["stone"])
    R(im, sx - 1, sy + 4, 8, 6, P["wood3"])
    Hline(im, sx - 1, sy + 4, 8, P["ink"])
    put(im, sx + 2, sy + 6, P["gold"])
    fist(im, cx - 28, 52 + bob)
    fist(im, cx + 20, 50 + bob)
    face96(im, cx - 9, 10 + bob, smirk=True)
    # gentleman crown / guan
    R(im, cx - 7, 4 + bob, 14, 6, P["ink"])
    R(im, cx - 5, 1 + bob, 10, 4, P["ink"])
    put(im, cx - 1, 2 + bob, P["gold"])
    put(im, cx + 1, 3 + bob, P["teal"])
    # side hair
    R(im, cx - 10, 12 + bob, 3, 10, P["ink"])
    R(im, cx + 7, 12 + bob, 3, 10, P["ink"])
    # ribbon
    R(im, cx + 8 + sway, 8 + bob, 3, 14, P["teal"])
    fold_v(im, cx + 9 + sway, 10 + bob, 10, P["qing2"])


HEROES = [
    ("purple_weixiaobao", "韋小保", draw_weixiaobao, "青衣太監帽、多柄匕首、金腰牌"),
    ("purple_hufei", "胡飛", draw_hufei, "少年土褐勁裝、背苗刀、義氣粗眉"),
    ("purple_miaorenfeng", "苗人風", draw_miaorenfeng, "壯碩黑甲金邊、半面金紋、硃紅點大刀"),
    ("purple_yuanchengzhi", "袁承智", draw_yuanchengzhi, "青金勁裝、蛇形波刃短劍、金護腕"),
    ("purple_diyun", "狄芸", draw_diyun, "灰褐破衣樸刀、短亂髮、堅毅眉"),
    ("purple_shipotian", "石破添", draw_shipotian, "土黄粗布、巨掌護腕、傻笑"),
    ("purple_xuzhu", "虛竺", draw_xuzhu, "僧灰袍淡紫帶、光頭念珠、短杖"),
    ("purple_limochou", "李莫秋", draw_limochou, "赤練衣面紗、銀針排、鞭影銀線"),
    ("purple_xiaolongnu", "小龍妞", draw_xiaolongnu, "宣紙白衣長白髮、細劍墨邊"),
    ("purple_zhaomin", "趙敏", draw_zhaomin, "硃紅郡主裝金飾、摺扇＋短刃"),
    ("purple_zhouzhiruo", "周芷偌", draw_zhouzhiruo, "紫灰峨眉尼袍紫帶、頭巾長劍"),
    ("purple_yuebuqun", "岳不裙", draw_yuebuqun, "白青君子袍冠帶、背長劍、假笑"),
]


def walk_sheet(draw_fn) -> Image.Image:
    sheet = Image.new("RGBA", (SIZE * WALK_FRAMES, SIZE), P["trans"])
    for i in range(WALK_FRAMES):
        fr = nf()
        draw_fn(fr, walk_i=i)
        sheet.paste(fr, (i * SIZE, 0), fr)
    return sheet


def palette_ok(im: Image.Image) -> tuple[bool, int]:
    bad = 0
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if a not in (0, 255):
                bad += 1
            if (r, g, b) not in ALLOWED:
                bad += 1
    return bad == 0, bad


def opaque_count(im: Image.Image) -> int:
    px = im.load()
    w, h = im.size
    n = 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 255:
                n += 1
    return n


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    rows = []
    roster = Image.new("RGBA", (SIZE * 6, SIZE * 2), P["trans"])
    for idx, (hid, name, fn, feat) in enumerate(HEROES):
        idle = nf()
        fn(idle, -1)
        idle_path = f"{OUT}/{hid}_idle.png"
        idle.save(idle_path)
        walk = walk_sheet(fn)
        walk_path = f"{OUT}/{hid}_walk.png"
        walk.save(walk_path)
        ok_i, bad_i = palette_ok(idle)
        ok_w, bad_w = palette_ok(walk)
        oc = opaque_count(idle)
        assert idle.size == (96, 96), idle.size
        assert walk.size == (384, 96), walk.size
        assert oc > 450, f"{hid} too sparse: {oc}"
        col, row = idx % 6, idx // 6
        roster.paste(idle, (col * SIZE, row * SIZE), idle)
        rows.append(
            f"| `{hid}` | {name} | {idle.size[0]}×{idle.size[1]} | "
            f"{walk.size[0]}×{walk.size[1]} | {feat} | "
            f"idle_bad={bad_i} walk_bad={bad_w} opaque={oc} |"
        )
        print(f"OK {hid} idle={idle.size} walk={walk.size} bad={bad_i}/{bad_w} opaque={oc}")

    p1 = f"{PREV}/purple_roster96_x1.png"
    p2 = f"{PREV}/purple_roster96_x2.png"
    roster.save(p1)
    roster.resize((roster.width * 2, roster.height * 2), Image.NEAREST).save(p2)

    md = f"""# MANIFEST — 紫階十二人 96×96

生成腳本：`tools/gen_purple_heroes_96.py`
輸出目錄：`assets/art/heroes/purple/`
預覽：`assets/art/_preview/purple_roster96_x1.png`、`purple_roster96_x2.png`

## 規格
- Idle：96×96 RGBA 透明底硬邊
- Walk：384×96（4 幀 × 96）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋梵紫#5A4060 級＋skin/wood/boot/shade/robe 微調
- 解像階梯：紫＝96；Nearest 整數倍顯示
- 華麗度：高於綠64、低於橙128；技能特效今次未做

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
{chr(10).join(rows)}

## 自檢
- 尺寸正確；alpha 以 0/255 為主；非透明像素充足
- 十二剪影可辨：太監帽匕首／苗刀少年／金面大刀／蛇劍／破衣樸刀／巨掌／僧念珠／赤練面紗／白衣細劍／摺扇郡主／紫尼頭巾／君子冠帶
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型；全新構圖唔 NN 放大
"""
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(md)
    print("Wrote", MANIFEST)
    print("Preview", p1, p2)


if __name__ == "__main__":
    main()
