#!/usr/bin/env python3
"""墨點俠村 — 橙階十二人 128×128 硬邊像素精靈

解像階梯：白綠64｜藍紫96｜橙128｜紅256
華麗度：高於綠64、低於紅256（絕學級密度）
禁止：柔邊／抗鋸齒／寫實／NN放大／抄原著立繪／抄俠客棧／銀樓舊稿
色盤家族：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227
         ＋梵紫#5A4060（歐陽峰盤內）＋skin/wood/boot/shade/robe 微調
"""
from __future__ import annotations

import os
from PIL import Image

SIZE = 128
WALK_FRAMES = 4
ROOT = "/workspace/modian-xiacun/assets/art"
OUT = f"{ROOT}/heroes/orange"
PREV = f"{ROOT}/_preview"
MANIFEST = "/workspace/modian-xiacun/tools/MANIFEST_orange_heroes.md"

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
    # robes
    "black": (42, 36, 32, 255),
    "black2": (32, 28, 24, 255),
    "black3": (58, 50, 44, 255),
    "brown": (110, 78, 52, 255),
    "brown2": (88, 62, 42, 255),
    "brown3": (130, 96, 64, 255),
    "qing": (58, 100, 88, 255),
    "qing2": (42, 78, 68, 255),
    "qing3": (74, 118, 104, 255),
    "dao": (72, 88, 92, 255),
    "dao2": (56, 72, 78, 255),
    "dao3": (90, 108, 110, 255),
    "white": (232, 220, 200, 255),
    "white2": (210, 198, 178, 255),
    "white3": (190, 178, 158, 255),
    "grey": (120, 112, 100, 255),
    "grey2": (96, 90, 80, 255),
    "grey3": (140, 132, 118, 255),
    "redrobe": (168, 48, 40, 255),
    "redrobe2": (140, 36, 32, 255),
    "redrobe3": (196, 60, 44, 255),
    "greenbag": (52, 110, 72, 255),
    "greenbag2": (38, 86, 56, 255),
    "peach": (196, 120, 110, 255),  # restrained peach within cinnabar family
    "iron": (90, 92, 96, 255),
    "iron2": (70, 72, 76, 255),
    "purple": (90, 64, 96, 255),    # #5A4060 family 梵紫
    "purple2": (72, 50, 78, 255),
    "snakegreen": (58, 110, 78, 255),
    "snakegreen2": (42, 86, 60, 255),
    "monk": (110, 100, 88, 255),
    "monk2": (88, 78, 66, 255),
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


def shadow(im, cx=64, y=118, w=48):
    x = cx - w // 2
    R(im, x, y, w, 4, P["shade"])
    R(im, x + 6, y + 1, w - 12, 2, P["ink"])


def _skull128(im, x, y, narrow=False):
    w, h = (20, 26) if narrow else (24, 26)
    xx = x + (2 if narrow else 0)
    box(im, xx, y, w, h, P["skin"])
    R(im, xx + 1, y + 1, 3, h - 4, P["skin2"])
    R(im, xx + w - 4, y + 2, 2, h - 6, P["skin2"])
    R(im, xx + 4, y + h - 6, w - 8, 4, P["skin3"])
    return xx, w


def face_yangguo(im, x, y):
    """ Melancholy youth, one sleeve vibe — soft round eyes, slight frown """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 7, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])
    put(im, x + 9, y + 6, P["ink"]); put(im, x + 14, y + 6, P["ink"])  # frown brow
    R(im, x + 5, y + 9, 5, 4, P["ink"]); R(im, x + 15, y + 9, 5, 4, P["ink"])
    put(im, x + 7, y + 10, P["paper"]); put(im, x + 17, y + 10, P["paper"])
    Vline(im, x + 12, y + 12, 4, P["skin2"]); Hline(im, x + 11, y + 15, 3, P["skin3"])
    Hline(im, x + 8, y + 19, 8, P["ink"]); put(im, x + 9, y + 18, P["ink"]); put(im, x + 14, y + 18, P["ink"])


def face_guojing(im, x, y):
    """ Honest round face, open eyes, simple smile """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 7, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])
    R(im, x + 4, y + 9, 6, 4, P["ink"]); R(im, x + 14, y + 9, 6, 4, P["ink"])
    R(im, x + 5, y + 10, 4, 2, P["paper"]); R(im, x + 15, y + 10, 4, 2, P["paper"])
    put(im, x + 7, y + 11, P["ink"]); put(im, x + 17, y + 11, P["ink"])
    Vline(im, x + 12, y + 12, 5, P["skin2"]); Hline(im, x + 11, y + 16, 3, P["skin3"])
    R(im, x + 8, y + 18, 8, 3, P["cinnabar"])
    put(im, x + 8, y + 18, P["ink"]); put(im, x + 15, y + 18, P["ink"]); put(im, x + 11, y + 20, P["ink"])


def face_linghuzhong(im, x, y):
    """ Romantic rogue — tilted brow, charming smirk """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 6, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])
    put(im, x + 10, y + 5, P["ink"])
    R(im, x + 5, y + 9, 4, 3, P["ink"]); R(im, x + 15, y + 9, 5, 3, P["ink"])
    put(im, x + 7, y + 10, P["paper"]); put(im, x + 17, y + 10, P["paper"])
    Vline(im, x + 12, y + 11, 5, P["skin2"]); Hline(im, x + 11, y + 15, 3, P["skin3"])
    Hline(im, x + 8, y + 18, 6, P["ink"]); Hline(im, x + 13, y + 17, 5, P["ink"])
    put(im, x + 17, y + 16, P["ink"]); R(im, x + 9, y + 19, 7, 2, P["cinnabar"])


def face_qiaofeng(im, x, y):
    """ Broad heroic — thick brows, square eyes, firm mouth """
    _skull128(im, x, y)
    Hline(im, x + 3, y + 6, 8, P["ink"]); Hline(im, x + 13, y + 6, 8, P["ink"])
    Hline(im, x + 3, y + 7, 8, P["ink"]); Hline(im, x + 13, y + 7, 8, P["ink"])
    R(im, x + 5, y + 9, 5, 4, P["ink"]); R(im, x + 15, y + 9, 5, 4, P["ink"])
    put(im, x + 7, y + 10, P["paper"]); put(im, x + 17, y + 10, P["paper"])
    Vline(im, x + 12, y + 12, 5, P["skin2"]); Hline(im, x + 10, y + 16, 4, P["skin3"])
    Hline(im, x + 7, y + 19, 10, P["ink"]); Hline(im, x + 8, y + 20, 8, P["ink"])


def face_zhangsanfeng(im, x, y):
    """ Elder taoist — kind slits, soft smile, white brow hint """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 7, 6, P["paper"]); Hline(im, x + 14, y + 7, 6, P["paper"])
    Hline(im, x + 4, y + 8, 6, P["ink"]); Hline(im, x + 14, y + 8, 6, P["ink"])
    Hline(im, x + 5, y + 10, 5, P["ink"]); Hline(im, x + 15, y + 10, 5, P["ink"])
    put(im, x + 6, y + 10, P["paper"]); put(im, x + 16, y + 10, P["paper"])
    Vline(im, x + 12, y + 12, 4, P["skin2"]); Hline(im, x + 11, y + 15, 3, P["skin3"])
    Hline(im, x + 8, y + 18, 8, P["ink"])
    put(im, x + 7, y + 17, P["ink"]); put(im, x + 16, y + 17, P["ink"])
    R(im, x + 9, y + 19, 6, 2, P["cinnabar"])


def face_fengqingyang(im, x, y):
    """ Lonely sword sage — cold narrow eyes, thin mouth """
    xx, w = _skull128(im, x, y, narrow=True)
    Hline(im, xx + 3, y + 7, 5, P["ink"]); Hline(im, xx + 11, y + 7, 5, P["ink"])
    Hline(im, xx + 3, y + 9, 6, P["ink"]); Hline(im, xx + 11, y + 9, 6, P["ink"])
    put(im, xx + 5, y + 9, P["paper"]); put(im, xx + 13, y + 9, P["paper"])
    Vline(im, xx + w // 2, y + 11, 4, P["skin2"])
    Hline(im, xx + 6, y + 18, 8, P["ink"])


def face_huangyaoshi(im, x, y):
    """ Eccentric scholar — raised brow, sharp eyes, thin smirk """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 5, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])  # uneven brows
    put(im, x + 9, y + 4, P["ink"])
    R(im, x + 5, y + 9, 4, 3, P["ink"]); R(im, x + 15, y + 9, 4, 2, P["ink"])
    put(im, x + 7, y + 10, P["paper"]); put(im, x + 17, y + 9, P["paper"])
    Vline(im, x + 12, y + 11, 5, P["skin2"]); Hline(im, x + 11, y + 15, 3, P["skin3"])
    Hline(im, x + 9, y + 18, 7, P["ink"]); put(im, x + 15, y + 17, P["ink"])


def face_ouyangfeng(im, x, y):
    """ Mad venom — eerie wide eyes (paper whites big), grim mouth """
    _skull128(im, x, y)
    Hline(im, x + 3, y + 6, 7, P["ink"]); Hline(im, x + 14, y + 6, 7, P["ink"])
    R(im, x + 4, y + 8, 6, 5, P["paper"]); R(im, x + 14, y + 8, 6, 5, P["paper"])
    R(im, x + 5, y + 9, 4, 3, P["ink"]); R(im, x + 15, y + 9, 4, 3, P["ink"])
    put(im, x + 6, y + 10, P["cinnabar"]); put(im, x + 16, y + 10, P["cinnabar"])
    Vline(im, x + 12, y + 13, 4, P["skin2"])
    Hline(im, x + 7, y + 19, 10, P["ink"]); Hline(im, x + 8, y + 20, 8, P["cinnabar"])


def face_hongqigong(im, x, y):
    """ Beggar elder — laugh lines, squint smile, round cheeks """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 7, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])
    Hline(im, x + 5, y + 10, 5, P["ink"]); Hline(im, x + 15, y + 10, 5, P["ink"])
    put(im, x + 6, y + 10, P["paper"]); put(im, x + 16, y + 10, P["paper"])
    put(im, x + 3, y + 11, P["skin3"]); put(im, x + 20, y + 11, P["skin3"])  # laugh lines
    Vline(im, x + 12, y + 12, 4, P["skin2"])
    R(im, x + 7, y + 18, 10, 3, P["cinnabar"])
    put(im, x + 7, y + 18, P["ink"]); put(im, x + 16, y + 18, P["ink"]); put(im, x + 11, y + 20, P["ink"])


def face_yideng(im, x, y):
    """ Monk emperor — bald serene, half-lid eyes, calm """
    _skull128(im, x, y)
    R(im, x + 2, y - 6, 20, 8, P["skin"]); R(im, x + 4, y - 10, 16, 6, P["skin2"])
    R(im, x + 6, y - 12, 12, 4, P["skin3"])
    for dx in (7, 11, 15):
        put(im, x + dx, y - 2, P["ink"])
    Hline(im, x + 4, y + 7, 6, P["ink"]); Hline(im, x + 14, y + 7, 6, P["ink"])
    Hline(im, x + 5, y + 10, 5, P["ink"]); Hline(im, x + 15, y + 10, 5, P["ink"])
    put(im, x + 6, y + 10, P["paper"]); put(im, x + 16, y + 10, P["paper"])
    Vline(im, x + 12, y + 12, 4, P["skin2"])
    Hline(im, x + 8, y + 18, 8, P["ink"])


def face_zhoubotong(im, x, y):
    """ Childlike elder — wide playful eyes, big grin """
    _skull128(im, x, y)
    Hline(im, x + 4, y + 6, 6, P["ink"]); Hline(im, x + 14, y + 6, 6, P["ink"])
    R(im, x + 4, y + 8, 6, 5, P["ink"]); R(im, x + 14, y + 8, 6, 5, P["ink"])
    R(im, x + 5, y + 9, 4, 3, P["paper"]); R(im, x + 15, y + 9, 4, 3, P["paper"])
    put(im, x + 7, y + 10, P["ink"]); put(im, x + 17, y + 10, P["ink"])
    Vline(im, x + 12, y + 13, 4, P["skin2"])
    R(im, x + 6, y + 18, 12, 4, P["cinnabar"])
    Hline(im, x + 6, y + 18, 12, P["ink"]); put(im, x + 11, y + 21, P["ink"])
    put(im, x + 6, y + 17, P["ink"]); put(im, x + 17, y + 17, P["ink"])


def face_miejueshitai(im, x, y):
    """ Stern nun — sharp brows, cold eyes, tight mouth """
    _skull128(im, x, y)
    Hline(im, x + 3, y + 6, 7, P["ink"]); Hline(im, x + 14, y + 6, 7, P["ink"])
    Hline(im, x + 3, y + 7, 7, P["ink"]); Hline(im, x + 14, y + 7, 7, P["ink"])
    put(im, x + 10, y + 5, P["ink"]); put(im, x + 13, y + 5, P["ink"])
    R(im, x + 5, y + 9, 4, 3, P["ink"]); R(im, x + 15, y + 9, 4, 3, P["ink"])
    put(im, x + 7, y + 10, P["paper"]); put(im, x + 17, y + 10, P["paper"])
    Hline(im, x + 5, y + 8, 4, P["ink"]); Hline(im, x + 15, y + 8, 4, P["ink"])
    Vline(im, x + 12, y + 11, 5, P["skin2"])
    Hline(im, x + 8, y + 18, 8, P["ink"]); Hline(im, x + 9, y + 19, 6, P["ink"])


def face128(im, x, y, *, smile=False, stern=False, bald=False, white_hair_top=False):
    """legacy fallback — prefer unique face_* """
    if bald:
        face_yideng(im, x, y)
    elif stern and smile:
        face_zhangsanfeng(im, x, y)
    elif stern:
        face_qiaofeng(im, x, y)
    elif smile:
        face_guojing(im, x, y)
    else:
        face_yangguo(im, x, y)


def hair_black_half(im, x, y, sway=0):
    """楊菓半束黑髮"""
    R(im, x + 2, y - 6, 22, 8, P["ink"])
    R(im, x + 4, y - 10, 18, 6, P["ink"])
    box(im, x + 8, y - 16, 10, 8, P["ink"])
    put(im, x + 12, y - 14, P["gold"])
    R(im, x + 22 + sway, y - 2, 6, 28, P["ink"])
    R(im, x + 24 + sway, y + 10, 5, 20, P["black3"])
    R(im, x, y, 4, 18, P["ink"])


def hair_messy(im, x, y, sway=0):
    """令狐散髮"""
    R(im, x, y - 6, 26, 10, P["ink"])
    R(im, x + 2, y - 12, 22, 8, P["ink"])
    R(im, x + 22 + sway, y - 2, 8, 32, P["ink"])
    R(im, x + 26 + sway, y + 12, 6, 22, P["shade"])
    R(im, x - 2, y, 6, 20, P["ink"])
    for i in range(0, 20, 4):
        put(im, x + 24 + sway, y + i, P["shade2"])


def hair_short_brown(im, x, y):
    R(im, x + 2, y - 6, 22, 8, P["wood3"])
    R(im, x + 4, y - 10, 18, 6, P["wood"])
    R(im, x, y, 4, 10, P["wood"])
    R(im, x + 22, y, 4, 10, P["wood"])


def hair_white_long(im, x, y, sway=0, bun=False):
    R(im, x + 2, y - 6, 22, 8, P["paper"])
    R(im, x + 4, y - 12, 18, 8, P["white2"])
    if bun:
        box(im, x + 8, y - 20, 12, 10, P["paper"])
        gold_trim(im, x + 8, y - 20, 12, 10)
        put(im, x + 13, y - 16, P["cinnabar"])
    R(im, x + 22 + sway, y - 2, 7, 36, P["paper"])
    R(im, x + 25 + sway, y + 14, 5, 28, P["white2"])
    R(im, x - 2, y, 5, 22, P["white2"])
    for i in range(0, 30, 5):
        fold_v(im, x + 24 + sway, y + i, 4, P["shade"])


def hair_wild(im, x, y, sway=0):
    """歐陽披髮"""
    R(im, x - 2, y - 8, 28, 12, P["paper"])
    R(im, x, y - 14, 24, 8, P["white2"])
    R(im, x + 22 + sway, y - 4, 10, 40, P["paper"])
    R(im, x + 28 + sway, y + 10, 8, 36, P["white2"])
    R(im, x - 6 + sway // 2, y, 8, 30, P["white2"])
    R(im, x - 8, y + 12, 6, 24, P["white3"])
    for i in range(0, 36, 6):
        put(im, x + 26 + sway + (i % 3), y + i, P["shade"])


def hair_nun(im, x, y):
    """滅絕頭巾"""
    R(im, x, y - 8, 26, 12, P["grey2"])
    R(im, x + 2, y - 12, 22, 6, P["grey"])
    box(im, x + 4, y - 16, 18, 8, P["grey3"])
    Hline(im, x + 4, y - 16, 18, P["ink"])
    # side cloth
    R(im, x - 2, y, 6, 18, P["grey2"])
    R(im, x + 22, y, 6, 18, P["grey2"])
    fold_v(im, x + 1, y, 14, P["shade"])


def beard_long_white(im, x, y):
    R(im, x + 4, y + 20, 16, 6, P["paper"])
    R(im, x + 6, y + 24, 12, 18, P["paper"])
    R(im, x + 7, y + 40, 10, 12, P["white2"])
    for i in range(0, 12, 3):
        fold_v(im, x + 7 + i, y + 26, 20, P["shade"])


def robe_torso(im, x, y, w, h, fill, shade, accent=None, dense=True):
    box(im, x, y, w, h, fill)
    R(im, x + 1, y + 1, 5, h - 2, shade)
    R(im, x + w - 6, y + 2, 4, h - 4, shade)
    if dense:
        for i in range(6, w - 4, 8):
            fold_v(im, x + i, y + 4, h - 12, shade)
        for j in range(10, h - 8, 10):
            fold_h(im, x + 6, y + j, w - 12, shade)
    if accent:
        R(im, x + 2, y + h - 7, w - 4, 4, accent)
        Hline(im, x + 2, y + h - 7, w - 4, P["ink"])


def sleeves(im, xl, xr, y, w, h, fill, shade, bob=0):
    box(im, xl, y + bob, w, h, fill)
    box(im, xr, y + bob, w, h, fill)
    R(im, xl + 1, y + bob + 1, 3, h - 2, shade)
    R(im, xr + 1, y + bob + 1, 3, h - 2, shade)
    for i in range(5, h - 3, 7):
        fold_h(im, xl + 2, y + bob + i, w - 4, shade)
        fold_h(im, xr + 2, y + bob + i, w - 4, shade)


def legs(im, x, y, fill, shade, step=0, lean=0, boot=True, pant_h=26, sole_y=120):
    """腳踩實：idle 雙腳同高貼 sole_y；walk 抬腳僅 3px"""
    boot_h = 8
    if step == 0:
        lx = lean; rx = lean; l_sole = sole_y; r_sole = sole_y
    elif step < 0:
        lx = lean - 3; rx = lean + 1; l_sole = sole_y - 3; r_sole = sole_y
    else:
        lx = lean + 1; rx = lean - 3; l_sole = sole_y; r_sole = sole_y - 3
    l_h = max(12, l_sole - boot_h - y)
    r_h = max(12, r_sole - boot_h - y)
    R(im, x + lx, y, 14, l_h, fill)
    R(im, x + lx + 1, y + 1, 3, max(4, l_h - 4), shade)
    fold_v(im, x + lx + 7, y + 2, max(4, l_h - 8), shade)
    R(im, x + 18 + rx, y, 14, r_h, fill)
    R(im, x + 19 + rx, y + 1, 3, max(4, r_h - 4), shade)
    fold_v(im, x + 25 + rx, y + 2, max(4, r_h - 8), shade)
    if boot:
        R(im, x + lx - 1, l_sole - boot_h, 15, boot_h, P["boot"])
        Hline(im, x + lx - 1, l_sole - boot_h, 15, P["ink"])
        Hline(im, x + lx - 1, l_sole - 1, 15, P["ink"])
        R(im, x + 18 + rx - 1, r_sole - boot_h, 15, boot_h, P["boot"])
        Hline(im, x + 18 + rx - 1, r_sole - boot_h, 15, P["ink"])
        Hline(im, x + 18 + rx - 1, r_sole - 1, 15, P["ink"])


def belt(im, x, y, w, jewel=True, color=None):
    color = color or P["gold"]
    R(im, x, y, w, 8, color)
    Hline(im, x, y, w, P["ink"])
    Hline(im, x, y + 7, w, P["ink"])
    Hline(im, x + 2, y + 3, w - 4, P["pale_gold"] if color == P["gold"] else P["shade"])
    bx = x + w // 2 - 4
    box(im, bx, y + 1, 8, 6, P["gold"])
    if jewel:
        put(im, bx + 3, y + 3, P["cinnabar"])


def fist(im, x, y):
    box(im, x, y, 12, 11, P["skin"])
    R(im, x + 1, y + 1, 2, 8, P["skin2"])
    for i in range(3):
        Vline(im, x + 3 + i * 3, y + 2, 6, P["ink"])


def palm(im, x, y):
    box(im, x, y, 14, 12, P["skin"])
    R(im, x + 1, y + 1, 3, 9, P["skin2"])
    for i in range(4):
        Vline(im, x + 3 + i * 3, y + 2, 7, P["ink"])
    Hline(im, x + 2, y + 9, 10, P["skin3"])


def walk_params(walk_i):
    if walk_i < 0:
        return 0, 0, 0, 0
    step = (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -2 if walk_i % 2 else 0
    sway = (walk_i % 4 - 1) * 2
    return step, lean, bob, sway


# ===================== 十二人 ===================== #

def draw_yangguo(im, walk_i=-1):
    """黑衣披風、缺右袖／義肢護臂、左掌、玉蜂囊；墨黑＋硃紅披風裏"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 50)
    legs(im, cx - 16, 82 + bob, P["black"], P["black2"], step, lean)
    # cloak back (cinnabar lining flash)
    R(im, cx - 28 + sway // 2, 36 + bob, 18, 55, P["black"])
    R(im, cx - 26 + sway // 2, 40 + bob, 6, 48, P["cinnabar"])  # lining
    fold_v(im, cx - 20 + sway // 2, 42 + bob, 40, P["black2"])
    robe_torso(im, cx - 20, 40 + bob, 40, 46, P["black3"], P["black2"], P["cinnabar"], True)
    # left sleeve only
    box(im, cx - 32, 44 + bob, 12, 34, P["black"], P["ink"])
    R(im, cx - 30, 46 + bob, 3, 28, P["black2"])
    # right prosthetic arm (no sleeve)
    box(im, cx + 18, 48 + bob, 14, 28, P["iron"])
    gold_trim(im, cx + 18, 48 + bob, 14, 28)
    R(im, cx + 20, 52 + bob, 10, 4, P["iron2"])
    R(im, cx + 20, 60 + bob, 10, 4, P["iron2"])
    R(im, cx + 20, 68 + bob, 10, 4, P["iron2"])
    put(im, cx + 24, 56 + bob, P["gold"])
    # left palm forward
    palm(im, cx - 38, 70 + bob)
    belt(im, cx - 18, 74 + bob, 36)
    # jade bee pouch
    box(im, cx + 16, 76 + bob, 12, 14, P["teal"])
    gold_trim(im, cx + 16, 76 + bob, 12, 14)
    put(im, cx + 21, 82 + bob, P["pale_gold"])
    put(im, cx + 20, 80 + bob, P["paper"])
    face_yangguo(im, cx - 12, 14 + bob)
    hair_black_half(im, cx - 12, 14 + bob, sway)
    # collar
    R(im, cx - 10, 40 + bob, 20, 4, P["cinnabar"])
    Hline(im, cx - 10, 40 + bob, 20, P["ink"])


def draw_guojing(im, walk_i=-1):
    """壯碩勁裝、雙拳、憨厚；土褐＋銅扣腰帶"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 56)
    legs(im, cx - 18, 84 + bob, P["brown2"], P["wood3"], step, lean)
    # bulky torso
    robe_torso(im, cx - 24, 38 + bob, 48, 50, P["brown3"], P["brown2"], None, True)
    sleeves(im, cx - 38, cx + 26, 42 + bob, 14, 36, P["brown"], P["brown2"])
    # wrist guards
    R(im, cx - 36, 70 + bob, 12, 8, P["wood"])
    R(im, cx + 28, 70 + bob, 12, 8, P["wood"])
    Hline(im, cx - 36, 70 + bob, 12, P["ink"])
    Hline(im, cx + 28, 70 + bob, 12, P["ink"])
    # wide belt copper buckle
    R(im, cx - 22, 76 + bob, 44, 10, P["wood2"])
    Hline(im, cx - 22, 76 + bob, 44, P["ink"])
    Hline(im, cx - 22, 85 + bob, 44, P["ink"])
    box(im, cx - 6, 77 + bob, 12, 8, P["gold"])
    put(im, cx - 1, 80 + bob, P["pale_gold"])
    put(im, cx + 1, 81 + bob, P["cinnabar"])
    # dual fists
    fist(im, cx - 42, 72 + bob)
    fist(im, cx + 32 + (2 if walk_i >= 0 else 0), 70 + bob)
    face_guojing(im, cx - 12, 12 + bob)
    hair_short_brown(im, cx - 12, 12 + bob)
    # collar
    R(im, cx - 8, 38 + bob, 16, 4, P["brown2"])


def draw_linghuzhong(im, walk_i=-1):
    """青衫負劍、酒葫蘆、散髮、衣襟鬆"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 46)
    legs(im, cx - 16, 82 + bob, P["qing2"], P["qing"], step, lean)
    robe_torso(im, cx - 20, 38 + bob, 40, 48, P["qing3"], P["qing2"], None, True)
    # loose collar
    R(im, cx - 8, 38 + bob, 10, 10, P["skin"])  # chest open
    R(im, cx - 18, 38 + bob, 12, 8, P["qing3"])
    R(im, cx + 6, 38 + bob, 12, 8, P["qing3"])
    sleeves(im, cx - 32, cx + 22, 42 + bob, 12, 32, P["qing"], P["qing2"])
    belt(im, cx - 18, 74 + bob, 36, color=P["wood"])
    # wine gourd left hip
    box(im, cx - 30, 72 + bob, 12, 16, P["wood2"])
    R(im, cx - 28, 70 + bob, 8, 4, P["wood"])
    put(im, cx - 25, 78 + bob, P["gold"])
    Hline(im, cx - 28, 80 + bob, 8, P["ink"])
    # sword on back
    sx, sy = cx + 14, 20 + bob
    for i in range(70):
        R(im, sx + i // 8, sy + i, 5, 2, P["silver"])
        put(im, sx + i // 8 + 4, sy + i, P["stone"])
    R(im, sx - 2, sy + 4, 10, 10, P["wood3"])
    Hline(im, sx - 2, sy + 4, 10, P["ink"])
    put(im, sx + 2, sy + 8, P["gold"])
    face_linghuzhong(im, cx - 12, 12 + bob)
    hair_messy(im, cx - 12, 12 + bob, sway)
    fist(im, cx - 36, 68 + bob)
    fist(im, cx + 28, 66 + bob)


def draw_qiaofeng(im, walk_i=-1):
    """高大短褐、龍抓手勢、布袋／骨飾"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 54)
    legs(im, cx - 18, 80 + bob, P["brown2"], P["wood3"], step, lean, pant_h=30)
    # tall short robe
    robe_torso(im, cx - 22, 34 + bob, 44, 50, P["brown"], P["brown2"], P["greenbag"], True)
    sleeves(im, cx - 36, cx + 24, 38 + bob, 14, 34, P["brown3"], P["brown2"])
    belt(im, cx - 20, 72 + bob, 40)
    # cloth bag
    box(im, cx + 18, 74 + bob, 14, 16, P["greenbag"])
    R(im, cx + 20, 76 + bob, 10, 10, P["greenbag2"])
    put(im, cx + 24, 80 + bob, P["gold"])
    # bone necklace
    for i, dx in enumerate((-8, -2, 4, 10)):
        R(im, cx + dx, 36 + bob, 4, 5, P["paper"])
        put(im, cx + dx + 1, 38 + bob, P["ink"])
    # dragon claw hands (open wide)
    palm(im, cx - 42, 64 + bob)
    palm(im, cx + 30 + (2 if walk_i >= 0 else 0), 62 + bob)
    # claw tip marks
    for dx in range(0, 12, 3):
        put(im, cx - 40 + dx, 63 + bob, P["ink"])
        put(im, cx + 32 + dx, 61 + bob, P["ink"])
    face_qiaofeng(im, cx - 12, 8 + bob)
    hair_short_brown(im, cx - 12, 8 + bob)
    # taller head offset already via y=8


def draw_zhangsanfeng(im, walk_i=-1):
    """道袍長鬚白髮、太極圓轉姿、拂塵可選"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 50)
    legs(im, cx - 16, 84 + bob, P["dao2"], P["dao"], step, lean)
    robe_torso(im, cx - 22, 40 + bob, 44, 48, P["dao3"], P["dao2"], P["gold"], True)
    # wide sleeves
    sleeves(im, cx - 40, cx + 28, 44 + bob, 16, 38, P["dao"], P["dao2"])
    gold_trim(im, cx - 40, 44 + bob, 16, 38)
    gold_trim(im, cx + 28, 44 + bob, 16, 38)
    belt(im, cx - 20, 76 + bob, 40)
    # taiji circle on chest (hard edge yin-yang)
    tx, ty = cx - 8, 52 + bob
    box(im, tx, ty, 16, 16, P["ink"])
    R(im, tx + 1, ty + 1, 7, 14, P["paper"])
    R(im, tx + 8, ty + 1, 7, 14, P["ink"])
    put(im, tx + 4, ty + 4, P["ink"])
    put(im, tx + 11, ty + 10, P["paper"])
    # flywhisk left
    fx = cx - 48 + sway // 2
    R(im, fx + 6, 30 + bob, 3, 50, P["wood"])
    R(im, fx, 20 + bob, 16, 14, P["paper"])
    for i in range(0, 14, 2):
        Vline(im, fx + i, 16 + bob, 12 + (i % 4), P["white2"])
    face_zhangsanfeng(im, cx - 12, 12 + bob)
    hair_white_long(im, cx - 12, 12 + bob, sway, bun=True)
    beard_long_white(im, cx - 12, 12 + bob)
    # circular arm pose hint
    palm(im, cx - 44, 68 + bob)
    palm(im, cx + 34, 66 + bob)


def draw_fengqingyang(im, walk_i=-1):
    """灰青袍白髮、長劍多在鞘、崖風披肩、草鞋"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 44)
    # straw shoes instead of boots
    legs(im, cx - 15, 84 + bob, P["grey2"], P["grey"], step, lean, boot=False)
    R(im, cx - 16 + lean + (-5 if step < 0 else 5 if step > 0 else 0),
      106 + bob + (-3 if step < 0 else 0), 14, 6, P["bamboo"] if False else P["wood2"])
    lx = lean + (-5 if step < 0 else (5 if step > 0 else 0))
    rx = lean + (5 if step < 0 else (-5 if step > 0 else 0))
    ly = -3 if step < 0 else 0
    ry = -3 if step > 0 else 0
    R(im, cx - 15 + lx, 106 + bob + ly, 14, 6, P["wood2"])
    R(im, cx + 3 + rx, 106 + bob + ry, 14, 6, P["wood2"])
    Hline(im, cx - 15 + lx, 110 + bob + ly, 14, P["ink"])
    Hline(im, cx + 3 + rx, 110 + bob + ry, 14, P["ink"])
    # cliff-wind cape
    R(im, cx - 30 + sway, 34 + bob, 16, 50, P["grey3"])
    R(im, cx - 28 + sway, 38 + bob, 5, 42, P["grey2"])
    fold_v(im, cx - 22 + sway, 40 + bob, 36, P["shade"])
    robe_torso(im, cx - 18, 38 + bob, 36, 50, P["grey"], P["grey2"], None, True)
    sleeves(im, cx - 30, cx + 20, 42 + bob, 12, 34, P["grey3"], P["grey2"])
    # cloth belt
    R(im, cx - 16, 76 + bob, 32, 6, P["wood3"])
    Hline(im, cx - 16, 76 + bob, 32, P["ink"])
    # sheathed sword at hip (mostly sheathed)
    box(im, cx + 14, 50 + bob, 8, 42, P["wood"])
    R(im, cx + 16, 52 + bob, 4, 36, P["wood3"])
    R(im, cx + 14, 48 + bob, 8, 6, P["gold"])  # guard
    R(im, cx + 16, 42 + bob, 4, 8, P["wood2"])  # hilt
    put(im, cx + 17, 44 + bob, P["pale_gold"])
    face_fengqingyang(im, cx - 12, 12 + bob)
    hair_white_long(im, cx - 12, 12 + bob, sway, bun=False)
    fist(im, cx - 34, 68 + bob)


def draw_huangyaoshi(im, walk_i=-1):
    """青綠衫執簫、袖藏棋子、桃花點克制"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 46)
    legs(im, cx - 16, 84 + bob, P["qing2"], P["qing"], step, lean)
    robe_torso(im, cx - 20, 38 + bob, 40, 50, P["qing3"], P["qing2"], P["peach"], True)
    sleeves(im, cx - 34, cx + 22, 42 + bob, 14, 36, P["qing"], P["qing2"])
    gold_trim(im, cx - 20, 38 + bob, 40, 50)
    belt(im, cx - 18, 76 + bob, 36)
    # jade flute right hand
    fx = cx + 30 + (2 if walk_i >= 0 else 0)
    R(im, fx, 40 + bob, 5, 48, P["pale_gold"])
    Vline(im, fx + 2, 40 + bob, 48, P["gold"])
    for i in range(8, 44, 7):
        put(im, fx + 1, 40 + bob + i, P["ink"])
    box(im, fx - 2, 84 + bob, 10, 8, P["skin"])  # hand
    # chess stones in left sleeve
    put(im, cx - 30, 70 + bob, P["ink"])
    put(im, cx - 28, 72 + bob, P["paper"])
    put(im, cx - 32, 74 + bob, P["ink"])
    # restrained peach petals (2–3)
    for px, py in ((20, 30), (100, 45), (30, 55)):
        put(im, px, py + bob, P["peach"])
        put(im, px + 1, py + bob, P["cinnabar"])
    face_huangyaoshi(im, cx - 12, 12 + bob)
    # scholar topknot
    R(im, cx - 10, 6 + bob, 20, 8, P["ink"])
    R(im, cx - 8, 2 + bob, 16, 6, P["ink"])
    box(im, cx - 4, -2 + bob, 10, 8, P["qing2"])
    gold_trim(im, cx - 4, max(0, -2 + bob), 10, 8)
    R(im, cx + 10, 12 + bob, 5, 18, P["ink"])
    fist(im, cx - 38, 70 + bob)


def draw_ouyangfeng(im, walk_i=-1):
    """白衣披髮蛇杖、毒囊、眼可詭異；蛇鱗綠＋梵紫"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 48)
    legs(im, cx - 16, 84 + bob, P["white2"], P["white3"], step, lean)
    robe_torso(im, cx - 20, 38 + bob, 40, 50, P["white"], P["white2"], P["purple"], True)
    # purple hem accents
    R(im, cx - 18, 82 + bob, 36, 4, P["purple"])
    sleeves(im, cx - 34, cx + 22, 42 + bob, 14, 34, P["white2"], P["white3"])
    belt(im, cx - 18, 76 + bob, 36, color=P["purple2"])
    # poison pouch
    box(im, cx - 30, 74 + bob, 12, 14, P["purple"])
    put(im, cx - 25, 80 + bob, P["snakegreen"])
    put(im, cx - 24, 78 + bob, P["gold"])
    # snake staff
    sx = cx + 28 + sway // 2
    R(im, sx, 18 + bob, 6, 90, P["wood"])
    Vline(im, sx + 2, 18 + bob, 90, P["wood3"])
    # snake head
    box(im, sx - 4, 10 + bob, 16, 14, P["snakegreen"])
    R(im, sx - 2, 12 + bob, 12, 8, P["snakegreen2"])
    put(im, sx + 2, 14 + bob, P["cinnabar"])  # eye
    put(im, sx + 8, 14 + bob, P["cinnabar"])
    put(im, sx + 10, 16 + bob, P["ink"])  # tongue tip
    # scale pattern on staff
    for i in range(20, 90, 8):
        put(im, sx + 1, 18 + bob + i, P["snakegreen"])
        put(im, sx + 4, 22 + bob + i, P["snakegreen2"])
    face_ouyangfeng(im, cx - 12, 12 + bob)
    # eerie eyes overwrite
    R(im, cx - 7, 21 + bob, 4, 3, P["paper"])
    R(im, cx + 3, 21 + bob, 4, 3, P["paper"])
    put(im, cx - 5, 22 + bob, P["purple"])
    put(im, cx + 5, 22 + bob, P["purple"])
    hair_wild(im, cx - 12, 12 + bob, sway)
    fist(im, cx - 38, 68 + bob)


def draw_hongqigong(im, walk_i=-1):
    """老丐打狗棒綠袋破衣、雞腿待機彩蛋"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 50)
    legs(im, cx - 16, 84 + bob, P["brown2"], P["wood3"], step, lean)
    robe_torso(im, cx - 20, 40 + bob, 40, 48, P["brown"], P["brown2"], None, True)
    # patches
    box(im, cx - 14, 50 + bob, 12, 10, P["wood"])
    box(im, cx + 2, 62 + bob, 10, 8, P["shade"])
    Hline(im, cx - 12, 54 + bob, 8, P["ink"])
    sleeves(im, cx - 32, cx + 22, 44 + bob, 12, 32, P["brown3"], P["brown2"])
    # rope belt
    R(im, cx - 18, 76 + bob, 36, 6, P["wood2"])
    for i in range(0, 34, 5):
        put(im, cx - 16 + i, 78 + bob, P["wood3"])
    # green bag
    box(im, cx + 16, 72 + bob, 14, 18, P["greenbag"])
    R(im, cx + 18, 74 + bob, 10, 12, P["greenbag2"])
    put(im, cx + 22, 80 + bob, P["gold"])
    # dog-beating stick
    bx = cx - 42 + (-1 if walk_i >= 0 else 0)
    R(im, bx, 24 + bob, 5, 88, P["wood"])
    Vline(im, bx + 2, 24 + bob, 88, P["wood2"])
    for i in range(10, 80, 16):
        Hline(im, bx, 24 + bob + i, 5, P["ink"])
    box(im, bx - 2, 70 + bob, 10, 10, P["skin"])  # hand
    # chicken leg easter egg (idle-ish right side)
    if walk_i < 0 or walk_i % 2 == 0:
        R(im, cx + 28, 60 + bob, 6, 16, P["wood2"])
        box(im, cx + 26, 54 + bob, 12, 10, P["brown3"])
        put(im, cx + 30, 57 + bob, P["pale_gold"])
    face_hongqigong(im, cx - 12, 14 + bob)
    # old sparse white hair
    R(im, cx - 10, 8 + bob, 20, 6, P["paper"])
    R(im, cx - 8, 4 + bob, 16, 5, P["white2"])
    R(im, cx + 10, 14 + bob, 5, 14, P["paper"])
    R(im, cx - 14, 14 + bob, 4, 10, P["white2"])


def draw_yideng(im, walk_i=-1):
    """金紅袈裟光頭念珠、指尖暖光"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 48)
    legs(im, cx - 16, 84 + bob, P["redrobe2"], P["redrobe"], step, lean)
    robe_torso(im, cx - 22, 40 + bob, 44, 48, P["redrobe3"], P["redrobe2"], P["gold"], True)
    # kasaya gold stripes
    for j in range(0, 40, 10):
        Hline(im, cx - 18, 48 + bob + j, 36, P["gold"])
        Hline(im, cx - 18, 50 + bob + j, 36, P["pale_gold"])
    sleeves(im, cx - 36, cx + 24, 44 + bob, 14, 34, P["redrobe"], P["redrobe2"])
    gold_trim(im, cx - 36, 44 + bob, 14, 34)
    gold_trim(im, cx + 24, 44 + bob, 14, 34)
    # rope / sash
    R(im, cx - 20, 76 + bob, 40, 6, P["gold"])
    Hline(im, cx - 20, 76 + bob, 40, P["ink"])
    # prayer beads
    beads = [P["wood"], P["gold"], P["cinnabar"], P["wood2"], P["pale_gold"], P["wood"]]
    for i, c in enumerate(beads * 2):
        R(im, cx - 14 + (i % 6) * 5, 38 + bob + (i // 6) * 4, 4, 4, c)
        put(im, cx - 13 + (i % 6) * 5, 39 + bob + (i // 6) * 4, P["ink"])
    face_yideng(im, cx - 12, 14 + bob)
    # finger warm light (right)
    fist(im, cx + 32, 68 + bob)
    put(im, cx + 40, 68 + bob, P["pale_gold"])
    put(im, cx + 41, 67 + bob, P["gold"])
    put(im, cx + 42, 69 + bob, P["pale_gold"])
    put(im, cx + 39, 66 + bob, P["gold"])
    fist(im, cx - 40, 70 + bob)


def draw_zhoubotong(im, walk_i=-1):
    """白髮童顏、雙臂各干、嬉笑無兵器"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 46)
    legs(im, cx - 16, 84 + bob, P["dao2"], P["dao"], step, lean)
    robe_torso(im, cx - 20, 40 + bob, 40, 48, P["dao3"], P["dao2"], None, True)
    # dual mismatched sleeves (左右互搏 hint)
    box(im, cx - 36, 42 + bob, 14, 28, P["dao"])  # left raised-ish
    R(im, cx - 34, 44 + bob, 3, 22, P["dao2"])
    box(im, cx + 22, 50 + bob, 14, 32, P["dao"])  # right lower different
    R(im, cx + 24, 52 + bob, 3, 26, P["dao2"])
    # left fist high, right palm low
    fist(im, cx - 42, 58 + bob)
    palm(im, cx + 30, 74 + bob)
    # dual afterimage dots (hard edge residual)
    for dx, dy in ((-48, 60), (-46, 64), (48, 72), (50, 76)):
        put(im, cx + dx, dy + bob, P["white2"])
        put(im, cx + dx + 1, dy + bob + 1, P["shade"])
    belt(im, cx - 18, 76 + bob, 36)
    face_zhoubotong(im, cx - 12, 12 + bob)
    hair_white_long(im, cx - 12, 12 + bob, sway, bun=False)
    # childlike rounder cheeks
    R(im, cx - 11, 28 + bob, 4, 6, P["skin2"])
    R(im, cx + 7, 28 + bob, 4, 6, P["skin2"])


def draw_miejueshitai(im, walk_i=-1):
    """青灰尼袍長劍頭巾、硃砂戒疤、嚴峻"""
    step, lean, bob, sway = walk_params(walk_i)
    cx = 64 + lean
    shadow(im, 64 + lean, 118 + bob, 46)
    legs(im, cx - 16, 84 + bob, P["grey2"], P["grey"], step, lean)
    robe_torso(im, cx - 20, 40 + bob, 40, 48, P["grey3"], P["grey2"], None, True)
    sleeves(im, cx - 32, cx + 22, 44 + bob, 12, 34, P["grey"], P["grey2"])
    # cloth belt
    R(im, cx - 18, 76 + bob, 36, 6, P["wood3"])
    Hline(im, cx - 18, 76 + bob, 36, P["ink"])
    # long sword forward-right
    sx = cx + 26 + (2 if walk_i >= 0 else 0)
    for i in range(55):
        R(im, sx + i // 10, 30 + bob + i, 4, 2, P["silver"])
        put(im, sx + i // 10 + 3, 30 + bob + i, P["stone"])
    R(im, sx - 2, 78 + bob, 10, 10, P["wood3"])  # guard
    Hline(im, sx - 2, 78 + bob, 10, P["ink"])
    R(im, sx, 86 + bob, 5, 14, P["wood"])  # hilt
    put(im, sx + 2, 90 + bob, P["gold"])
    fist(im, sx - 4, 82 + bob)
    fist(im, cx - 36, 70 + bob)
    face_miejueshitai(im, cx - 12, 14 + bob)
    hair_nun(im, cx - 12, 14 + bob)
    # vermillion scar on forehead
    R(im, cx - 2, 16 + bob, 4, 3, P["cinnabar"])
    put(im, cx - 1, 17 + bob, P["ink"])
    # collar
    R(im, cx - 8, 40 + bob, 16, 4, P["grey2"])


HEROES = [
    ("orange_yangguo", "楊菓", draw_yangguo, "黑衣披風硃紅裏、右義肢護臂、左掌、玉蜂囊"),
    ("orange_guojing", "郭靚", draw_guojing, "壯碩土褐勁裝、雙拳護腕、銅扣寬腰帶"),
    ("orange_linghuzhong", "令狐忠", draw_linghuzhong, "青衫散髮負劍、酒葫蘆、衣襟鬆開"),
    ("orange_qiaofeng", "喬風", draw_qiaofeng, "高大短褐龍抓手、綠布袋、骨項飾"),
    ("orange_zhangsanfeng", "張三風", draw_zhangsanfeng, "道袍白髮長鬚、太極胸圖、拂塵圓轉姿"),
    ("orange_fengqingyang", "風青羊", draw_fengqingyang, "灰青袍白髮、鞘中長劍、崖風披肩草鞋"),
    ("orange_huangyaoshi", "黃藥獅", draw_huangyaoshi, "青綠衫執玉簫、袖藏棋子、克制桃花點"),
    ("orange_ouyangfeng", "歐陽峰", draw_ouyangfeng, "白衣披髮蛇杖、毒囊梵紫、詭異眼"),
    ("orange_hongqigong", "洪喫公", draw_hongqigong, "老丐打狗棒綠袋破衣、雞腿待機彩蛋"),
    ("orange_yideng", "一登大師", draw_yideng, "金紅袈裟光頭念珠、指尖暖金光"),
    ("orange_zhoubotong", "周伯同", draw_zhoubotong, "白髮童顏雙臂異動、嬉笑無兵器殘影"),
    ("orange_miejueshitai", "滅絕師態", draw_miejueshitai, "青灰尼袍頭巾長劍、硃砂戒疤嚴峻"),
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
    # 2 rows × 6
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
        assert idle.size == (128, 128), idle.size
        assert walk.size == (512, 128), walk.size
        assert oc > 800, f"{hid} too sparse: {oc}"
        col, row = idx % 6, idx // 6
        roster.paste(idle, (col * SIZE, row * SIZE), idle)
        rows.append(
            f"| `{hid}` | {name} | {idle.size[0]}×{idle.size[1]} | "
            f"{walk.size[0]}×{walk.size[1]} | {feat} | "
            f"idle_bad={bad_i} walk_bad={bad_w} opaque={oc} |"
        )
        print(f"OK {hid} idle={idle.size} walk={walk.size} bad={bad_i}/{bad_w} opaque={oc}")

    p1 = f"{PREV}/orange_roster128_x1.png"
    p2 = f"{PREV}/orange_roster128_x2.png"
    roster.save(p1)
    roster.resize((roster.width * 2, roster.height * 2), Image.NEAREST).save(p2)

    md = f"""# MANIFEST — 橙階（facefix／腳形修正）十二人 128×128

生成腳本：`tools/gen_orange_heroes_128.py`
輸出目錄：`assets/art/heroes/orange/`
預覽：`assets/art/_preview/orange_roster128_x1.png`、`orange_roster128_x2.png`

## 規格
- Idle：128×128 RGBA 透明底硬邊
- Walk：512×128（4 幀 × 128）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋梵紫#5A4060 級＋skin/wood/boot/shade/robe 微調
- 解像階梯：橙＝128；Nearest 整數倍顯示
- 華麗度：高於綠64、低於紅256；技能特效今次未做

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
{chr(10).join(rows)}

## 自檢
- 尺寸正確；alpha 以 0/255 為主；非透明像素充足
- 十二剪影可辨：披風義肢／雙拳褐／青衫葫蘆／龍抓／道鬚太極／灰袍鞘劍／執簫／蛇杖／打狗棒雞腿／袈裟指光／雙臂異動／尼袍戒疤
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型；全新構圖唔 NN 放大
"""
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(md)
    print("Wrote", MANIFEST)
    print("Preview", p1, p2)


if __name__ == "__main__":
    main()
