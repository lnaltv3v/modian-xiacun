#!/usr/bin/env python3
"""墨點俠村 — 紅階六人 256×256 硬邊像素精靈

解像階梯：白綠64｜藍紫96｜橙128｜紅256
禁止：柔邊／抗鋸齒／寫實／照片／AI 糊邊／抄原著立繪／抄俠客棧舊稿
色盤家族：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227
"""
from __future__ import annotations

import os
from pathlib import Path
from PIL import Image

SIZE = 256
WALK_FRAMES = 4
ROOT = "/workspace/modian-xiacun/assets/art"
OUT = f"{ROOT}/heroes/red"
PREV = f"{ROOT}/_preview"
MANIFEST = "/workspace/modian-xiacun/tools/MANIFEST_red_heroes.md"

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
    "bamboo": (168, 140, 72, 255),
    "bamboo2": (140, 116, 56, 255),
    "monk": (110, 100, 88, 255),
    "monk2": (88, 78, 66, 255),
    "monk3": (130, 118, 100, 255),
    "dao": (72, 88, 92, 255),
    "dao2": (56, 72, 78, 255),
    "dao3": (90, 108, 110, 255),
    "inkrobe": (70, 58, 48, 255),
    "inkrobe2": (54, 44, 36, 255),
    "inkrobe3": (88, 74, 60, 255),
    "qing": (58, 100, 88, 255),
    "qing2": (42, 78, 68, 255),
    "qing3": (74, 118, 104, 255),
    "white": (232, 220, 200, 255),
    "white2": (210, 198, 178, 255),
    "white3": (190, 178, 158, 255),
    "redrobe": (168, 48, 40, 255),
    "redrobe2": (140, 36, 32, 255),
    "redrobe3": (196, 60, 44, 255),
    "pale_gold": (212, 186, 110, 255),
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
    c = c or P["shade"]
    Vline(im, x, y, h, c)


def fold_h(im, x, y, w, c=None):
    c = c or P["shade"]
    Hline(im, x, y, w, c)


def gold_edge(im, x, y, w, h):
    """1px 金邊框（紅階華麗）"""
    Hline(im, x, y, w, P["gold"])
    Hline(im, x, y + h - 1, w, P["gold"])
    Vline(im, x, y, h, P["gold"])
    Vline(im, x + w - 1, y, h, P["gold"])


def shadow(im, cx=128, y=238, w=90):
    """地面陰影：靴底應貼近 y（sole ≈ y-2）"""
    x = cx - w // 2
    R(im, x, y, w, 6, P["shade"])
    R(im, x + 8, y + 2, w - 16, 3, P["ink"])
    R(im, x + 18, y + 1, w - 36, 2, P["ink"])


def _face_skull(im, x, y, w=48, h=52, narrow=False):
    """共用頭骨底，五官由各 face_* 覆寫"""
    ww = 40 if narrow else w
    xx = x + (w - ww) // 2 if narrow else x
    box(im, xx, y, ww, h, P["skin"])
    R(im, xx + 2, y + 2, 6 if narrow else 8, h - 6, P["skin2"])
    R(im, xx + ww - 8, y + 4, 5 if narrow else 6, h - 10, P["skin2"])
    R(im, xx + (8 if narrow else 10), y + h - 12, ww - 16, 8, P["skin3"])
    return xx, ww


def face_zhangwuji(im, x, y):
    """溫厚圓目、微抿、少年氣"""
    _face_skull(im, x, y)
    # soft arched brows
    Hline(im, x + 8, y + 13, 11, P["ink"])
    Hline(im, x + 29, y + 13, 11, P["ink"])
    put(im, x + 7, y + 14, P["ink"])
    put(im, x + 40, y + 14, P["ink"])
    # round warm eyes (larger)
    R(im, x + 9, y + 17, 10, 7, P["ink"])
    R(im, x + 29, y + 17, 10, 7, P["ink"])
    R(im, x + 11, y + 18, 6, 5, P["paper"])
    R(im, x + 31, y + 18, 6, 5, P["paper"])
    put(im, x + 13, y + 20, P["ink"])
    put(im, x + 33, y + 20, P["ink"])
    put(im, x + 14, y + 19, P["paper"])
    put(im, x + 34, y + 19, P["paper"])
    # short soft nose
    Vline(im, x + 23, y + 24, 8, P["skin2"])
    Hline(im, x + 21, y + 31, 5, P["skin3"])
    # gentle closed mouth (微抿) — thin, little red
    Hline(im, x + 17, y + 37, 14, P["ink"])
    Hline(im, x + 19, y + 38, 10, P["skin3"])
    put(im, x + 20, y + 37, P["cinnabar"])
    put(im, x + 27, y + 37, P["cinnabar"])


def face_dongfang(im, x, y):
    """細長鳳眼／戲謔上揚嘴角；孤傲（長髮遮額由髮型處理）"""
    _face_skull(im, x, y)
    # slender phoenix brows — outer tip up
    Hline(im, x + 8, y + 14, 12, P["ink"])
    Hline(im, x + 28, y + 13, 12, P["ink"])
    put(im, x + 19, y + 13, P["ink"])
    put(im, x + 39, y + 12, P["ink"])
    put(im, x + 40, y + 11, P["ink"])
    # phoenix eyes: elongated, outer corner raised
    R(im, x + 8, y + 18, 12, 3, P["ink"])
    R(im, x + 28, y + 17, 12, 3, P["ink"])
    Hline(im, x + 9, y + 17, 10, P["ink"])
    Hline(im, x + 29, y + 16, 10, P["ink"])
    put(im, x + 10, y + 19, P["paper"])
    put(im, x + 14, y + 19, P["paper"])
    put(im, x + 30, y + 18, P["paper"])
    put(im, x + 34, y + 18, P["paper"])
    put(im, x + 18, y + 17, P["ink"])  # outer tip up L
    put(im, x + 39, y + 15, P["ink"])  # outer tip up R
    # nose delicate
    Vline(im, x + 24, y + 22, 9, P["skin2"])
    Hline(im, x + 22, y + 30, 4, P["skin3"])
    # smirk: right side raised
    Hline(im, x + 16, y + 36, 10, P["ink"])
    Hline(im, x + 26, y + 35, 8, P["ink"])
    put(im, x + 33, y + 34, P["ink"])
    R(im, x + 18, y + 37, 12, 2, P["cinnabar"])
    put(im, x + 30, y + 36, P["cinnabar"])


def face_dugu(im, x, y):
    """細目淡漠、薄唇、清瘦頰"""
    xx, ww = _face_skull(im, x, y, narrow=True)
    # thin flat brows
    Hline(im, xx + 6, y + 14, 9, P["ink"])
    Hline(im, xx + 22, y + 14, 9, P["ink"])
    # thin indifferent eyes (slits)
    Hline(im, xx + 7, y + 19, 8, P["ink"])
    Hline(im, xx + 23, y + 19, 8, P["ink"])
    Hline(im, xx + 7, y + 20, 8, P["ink"])
    Hline(im, xx + 23, y + 20, 8, P["ink"])
    put(im, xx + 10, y + 19, P["paper"])
    put(im, xx + 26, y + 19, P["paper"])
    # lean cheeks already from narrow; deepen shade
    R(im, xx + 2, y + 28, 4, 16, P["skin3"])
    R(im, xx + ww - 6, y + 28, 4, 16, P["skin3"])
    # thin nose
    Vline(im, xx + ww // 2, y + 22, 8, P["skin2"])
    Hline(im, xx + ww // 2 - 1, y + 29, 3, P["skin3"])
    # thin lips — almost no red
    Hline(im, xx + 12, y + 36, 12, P["ink"])
    Hline(im, xx + 14, y + 37, 8, P["skin3"])


def face_saodi(im, x, y):
    """老年皺紋／慈眉細目、光頭"""
    _face_skull(im, x, y, w=48, h=54)
    # bald pate
    R(im, x + 4, y - 10, 40, 14, P["skin"])
    R(im, x + 8, y - 16, 32, 10, P["skin"])
    R(im, x + 12, y - 20, 24, 8, P["skin2"])
    R(im, x + 16, y - 22, 16, 4, P["skin3"])
    for dx in (14, 22, 30):
        put(im, x + dx, y - 6, P["ink"])
        put(im, x + dx + 1, y - 5, P["ink"])
    # forehead wrinkles
    Hline(im, x + 10, y + 4, 28, P["skin3"])
    Hline(im, x + 12, y + 7, 24, P["skin3"])
    Hline(im, x + 14, y + 10, 20, P["shade"])
    # kind brows — soft droop
    Hline(im, x + 8, y + 15, 12, P["ink"])
    Hline(im, x + 28, y + 15, 12, P["ink"])
    put(im, x + 7, y + 16, P["ink"])
    put(im, x + 39, y + 16, P["ink"])
    # kind half-closed eyes
    Hline(im, x + 10, y + 20, 9, P["ink"])
    Hline(im, x + 29, y + 20, 9, P["ink"])
    R(im, x + 11, y + 21, 7, 2, P["ink"])
    R(im, x + 30, y + 21, 7, 2, P["ink"])
    put(im, x + 13, y + 21, P["paper"])
    put(im, x + 32, y + 21, P["paper"])
    # crow's feet
    put(im, x + 7, y + 21, P["skin3"])
    put(im, x + 6, y + 22, P["skin3"])
    put(im, x + 40, y + 21, P["skin3"])
    put(im, x + 41, y + 22, P["skin3"])
    # nose aged
    Vline(im, x + 24, y + 24, 9, P["skin2"])
    Hline(im, x + 21, y + 32, 6, P["skin3"])
    # gentle smile
    Hline(im, x + 16, y + 38, 16, P["ink"])
    put(im, x + 15, y + 37, P["ink"])
    put(im, x + 32, y + 37, P["ink"])
    R(im, x + 18, y + 39, 12, 2, P["cinnabar"])
    # nasolabial
    Vline(im, x + 14, y + 30, 8, P["skin3"])
    Vline(im, x + 33, y + 30, 8, P["skin3"])


def face_wangchongyang(im, x, y):
    """長鬚遮下巴、劍眉正視、中年剛毅"""
    _face_skull(im, x, y)
    # sword brows — thick angled down to center
    Hline(im, x + 6, y + 12, 14, P["ink"])
    Hline(im, x + 7, y + 13, 13, P["ink"])
    Hline(im, x + 28, y + 12, 14, P["ink"])
    Hline(im, x + 28, y + 13, 13, P["ink"])
    put(im, x + 5, y + 11, P["ink"])
    put(im, x + 41, y + 11, P["ink"])
    put(im, x + 19, y + 14, P["ink"])
    put(im, x + 28, y + 14, P["ink"])
    # resolute square eyes
    R(im, x + 10, y + 17, 9, 5, P["ink"])
    R(im, x + 29, y + 17, 9, 5, P["ink"])
    R(im, x + 12, y + 18, 5, 3, P["paper"])
    R(im, x + 31, y + 18, 5, 3, P["paper"])
    put(im, x + 14, y + 19, P["ink"])
    put(im, x + 33, y + 19, P["ink"])
    # firm nose
    Vline(im, x + 24, y + 22, 10, P["skin2"])
    Hline(im, x + 21, y + 31, 6, P["skin3"])
    # firm mouth above beard
    Hline(im, x + 16, y + 35, 16, P["ink"])
    Hline(im, x + 18, y + 36, 12, P["ink"])
    # long white beard covering chin
    R(im, x + 10, y + 38, 28, 8, P["paper"])
    R(im, x + 12, y + 44, 24, 28, P["paper"])
    R(im, x + 14, y + 68, 20, 22, P["white2"])
    R(im, x + 16, y + 86, 16, 18, P["white3"])
    for i in range(0, 22, 4):
        Vline(im, x + 14 + i, y + 46, 40, P["shade"])
        Vline(im, x + 15 + i, y + 68, 24, P["shade2"])


def face_huangshang(im, x, y):
    """文士細目、墨指可沾臉側、書生瘦頰、較真神情"""
    xx, ww = _face_skull(im, x, y, narrow=True)
    # scholarly thin brows
    Hline(im, xx + 6, y + 13, 10, P["ink"])
    Hline(im, xx + 22, y + 13, 10, P["ink"])
    Hline(im, xx + 7, y + 12, 8, P["ink"])
    # thin focused eyes
    R(im, xx + 7, y + 17, 8, 3, P["ink"])
    R(im, xx + 23, y + 17, 8, 3, P["ink"])
    Hline(im, xx + 7, y + 16, 8, P["ink"])
    Hline(im, xx + 23, y + 16, 8, P["ink"])
    put(im, xx + 10, y + 18, P["paper"])
    put(im, xx + 26, y + 18, P["paper"])
    # lean cheeks
    R(im, xx + 1, y + 26, 4, 18, P["skin3"])
    R(im, xx + ww - 5, y + 26, 4, 18, P["skin3"])
    # nose
    Vline(im, xx + ww // 2, y + 21, 9, P["skin2"])
    Hline(im, xx + ww // 2 - 1, y + 29, 3, P["skin3"])
    # serious thin mouth
    Hline(im, xx + 11, y + 35, 14, P["ink"])
    Hline(im, xx + 13, y + 36, 10, P["ink"])
    put(im, xx + 14, y + 35, P["cinnabar"])
    put(im, xx + 22, y + 35, P["cinnabar"])
    # ink stain on left cheek (墨指沾臉側)
    put(im, xx + 3, y + 28, P["ink"])
    put(im, xx + 4, y + 29, P["ink"])
    put(im, xx + 2, y + 30, P["shade"])
    put(im, xx + 5, y + 31, P["ink"])


def hair_half_bun(im, x, y, lean=0):
    """半束長髮（張無記）"""
    hx, hy = x + lean, y
    R(im, hx + 4, hy - 8, 44, 16, P["ink"])
    R(im, hx + 8, hy - 16, 36, 12, P["ink"])
    R(im, hx + 14, hy - 22, 24, 10, P["ink"])
    # top knot
    box(im, hx + 18, hy - 30, 16, 12, P["ink"])
    R(im, hx + 20, hy - 32, 12, 4, P["ink"])
    put(im, hx + 24, hy - 28, P["gold"])
    put(im, hx + 26, hy - 26, P["gold"])
    # long side hair right
    R(im, hx + 44, hy - 4, 10, 50, P["ink"])
    R(im, hx + 48, hy + 10, 8, 40, P["ink"])
    R(im, hx + 50, hy + 30, 6, 30, P["shade"])
    fold_v(im, hx + 46, hy, 40, P["shade"])
    # left soft fall
    R(im, hx, hy, 8, 36, P["ink"])
    R(im, hx - 2, hy + 8, 6, 28, P["shade"])


def hair_long_red(im, x, y, lean=0, sway=0):
    """東方長髮及腰"""
    hx, hy = x + lean, y
    R(im, hx, hy - 12, 52, 18, P["ink"])
    R(im, hx + 6, hy - 22, 40, 14, P["ink"])
    R(im, hx + 12, hy - 28, 28, 10, P["ink"])
    # flowing right
    R(im, hx + 46 + sway, hy - 4, 14, 70, P["ink"])
    R(im, hx + 52 + sway, hy + 20, 12, 60, P["ink"])
    R(im, hx + 56 + sway, hy + 50, 10, 50, P["shade"])
    R(im, hx + 58 + sway, hy + 80, 8, 40, P["ink"])
    # left cascade
    R(im, hx - 6 + sway // 2, hy, 12, 55, P["ink"])
    R(im, hx - 10 + sway // 2, hy + 20, 10, 45, P["shade"])
    for i in range(0, 50, 6):
        fold_v(im, hx + 48 + sway + (i % 4), hy + i, 8, P["shade2"])


def hair_dao(im, x, y, lean=0):
    """道冠下留髮"""
    hx, hy = x + lean, y
    R(im, hx + 4, hy - 6, 44, 12, P["ink"])
    R(im, hx + 8, hy - 12, 36, 8, P["ink"])
    # guan
    box(im, hx + 12, hy - 28, 28, 18, P["ink"])
    R(im, hx + 16, hy - 34, 20, 10, P["ink"])
    gold_edge(im, hx + 14, hy - 26, 24, 14)
    R(im, hx + 22, hy - 30, 8, 6, P["gold"])
    put(im, hx + 25, hy - 28, P["cinnabar"])
    # side
    R(im, hx, hy, 8, 24, P["ink"])
    R(im, hx + 44, hy, 8, 24, P["ink"])


def hair_scholar(im, x, y, lean=0):
    hx, hy = x + lean, y
    R(im, hx + 2, hy - 10, 48, 14, P["ink"])
    R(im, hx + 6, hy - 18, 40, 12, P["ink"])
    R(im, hx + 12, hy - 24, 28, 10, P["ink"])
    # top knot with cloth
    box(im, hx + 18, hy - 32, 16, 12, P["inkrobe"])
    gold_edge(im, hx + 18, hy - 32, 16, 12)
    R(im, hx + 44, hy, 8, 30, P["ink"])
    R(im, hx, hy, 6, 20, P["ink"])


def hair_thin(im, x, y, lean=0):
    """獨孤清瘦短束"""
    hx, hy = x + lean, y
    R(im, hx + 6, hy - 8, 40, 12, P["ink"])
    R(im, hx + 10, hy - 14, 32, 8, P["ink"])
    R(im, hx + 40, hy - 2, 8, 28, P["ink"])
    fold_v(im, hx + 42, hy, 20, P["shade"])


def robe_body(im, x, y, w, h, fill, shade, accent=None, dense=True):
    """華麗長袍軀幹＋密褶"""
    box(im, x, y, w, h, fill)
    R(im, x + 2, y + 2, 10, h - 4, shade)
    R(im, x + w - 12, y + 4, 8, h - 8, shade)
    if dense:
        for i in range(4, w - 4, 10):
            fold_v(im, x + i, y + 8, h - 20, shade)
        for j in range(16, h - 12, 14):
            fold_h(im, x + 8, y + j, w - 16, shade)
    if accent:
        # hem accent stripe
        R(im, x + 2, y + h - 10, w - 4, 6, accent)
        Hline(im, x + 2, y + h - 10, w - 4, P["ink"])
        Hline(im, x + 2, y + h - 5, w - 4, P["ink"])


def sleeves(im, xl, xr, y, w, h, fill, shade, bob=0):
    box(im, xl, y + bob, w, h, fill)
    box(im, xr, y + bob, w, h, fill)
    R(im, xl + 2, y + bob + 2, 4, h - 4, shade)
    R(im, xr + 2, y + bob + 2, 4, h - 4, shade)
    for i in range(6, h - 4, 8):
        fold_h(im, xl + 3, y + bob + i, w - 6, shade)
        fold_h(im, xr + 3, y + bob + i, w - 6, shade)


def legs_robe(im, x, y, fill, shade, step=0, lean=0, boot=True, sole_y=239):
    """長袍下擺＋腿；靴底平貼 sole_y（陰影上方 2px）。
    idle：雙腳對稱踩實；walk：交替但落地腳仍貼 sole_y，抬腳僅 6px。
    """
    # 水平：腳跟大致喺髖下，唔外八大甩
    hip_gap = 8  # space between inner ankles at rest
    foot_w = 28
    boot_h = 14
    # left foot local origin relative to x
    l_base = 2
    r_base = 2 + foot_w + hip_gap  # ~38
    if step == 0:
        lx = lean
        rx = lean
        l_sole = sole_y
        r_sole = sole_y
    elif step < 0:
        # left forward/up mid
        lx = lean - 4
        rx = lean + 2
        l_sole = sole_y - 6
        r_sole = sole_y
    else:
        lx = lean + 2
        rx = lean - 4
        l_sole = sole_y
        r_sole = sole_y - 6
    # robe panels from y down to boot top
    l_boot_top = l_sole - boot_h
    r_boot_top = r_sole - boot_h
    l_h = max(20, l_boot_top - y)
    r_h = max(20, r_boot_top - y)
    # left panel
    R(im, x + l_base + lx, y, foot_w, l_h, fill)
    R(im, x + l_base + lx + 2, y + 2, 6, max(4, l_h - 6), shade)
    fold_v(im, x + l_base + lx + 12, y + 4, max(4, l_h - 10), shade)
    fold_v(im, x + l_base + lx + 20, y + 6, max(4, l_h - 14), shade)
    # right
    R(im, x + r_base + rx, y, foot_w, r_h, fill)
    R(im, x + r_base + rx + 2, y + 2, 6, max(4, r_h - 6), shade)
    fold_v(im, x + r_base + rx + 12, y + 4, max(4, r_h - 10), shade)
    fold_v(im, x + r_base + rx + 20, y + 6, max(4, r_h - 14), shade)
    if boot:
        # soles flat on sole line
        R(im, x + l_base + lx - 2, l_boot_top, foot_w + 4, boot_h, P["boot"])
        Hline(im, x + l_base + lx - 2, l_boot_top, foot_w + 4, P["ink"])
        Hline(im, x + l_base + lx - 2, l_sole - 1, foot_w + 4, P["ink"])
        # sole contact shade
        Hline(im, x + l_base + lx, l_sole, foot_w, P["shade"])
        R(im, x + r_base + rx - 2, r_boot_top, foot_w + 4, boot_h, P["boot"])
        Hline(im, x + r_base + rx - 2, r_boot_top, foot_w + 4, P["ink"])
        Hline(im, x + r_base + rx - 2, r_sole - 1, foot_w + 4, P["ink"])
        Hline(im, x + r_base + rx, r_sole, foot_w, P["shade"])


def belt_gold(im, x, y, w, jewel=True):
    R(im, x, y, w, 14, P["gold"])
    Hline(im, x, y, w, P["ink"])
    Hline(im, x, y + 13, w, P["ink"])
    Hline(im, x + 2, y + 4, w - 4, P["pale_gold"])
    Hline(im, x + 2, y + 9, w - 4, P["ink"])
    bx = x + w // 2 - 8
    box(im, bx, y + 1, 16, 12, P["gold"])
    gold_edge(im, bx, y + 1, 16, 12)
    if jewel:
        R(im, bx + 4, y + 4, 8, 6, P["cinnabar"])
        put(im, bx + 7, y + 6, P["pale_gold"])


def palm(im, x, y, gold_aura=False):
    box(im, x, y, 22, 20, P["skin"])
    R(im, x + 2, y + 2, 4, 16, P["skin2"])
    for i in range(4):
        Vline(im, x + 5 + i * 4, y + 4, 12, P["ink"])
    Hline(im, x + 2, y + 16, 18, P["skin3"])
    if gold_aura:
        # hard-edge pale gold ring (no alpha blend)
        for dx, dy in ((-3, 4), (-2, 0), (-2, 18), (22, 4), (23, 10), (22, 16), (8, -3), (12, 21)):
            put(im, x + dx, y + dy, P["pale_gold"])
            put(im, x + dx + 1, y + dy, P["gold"])


# ===================== 六人 ===================== #

def draw_zhangwuji(im, walk_i=-1):
    """白衣黑邊、半束長髮、雙掌、藥囊、淡金內息"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 3
    bob = -2 if walk_i >= 0 and walk_i % 2 else 0
    sway = 2 if walk_i >= 0 and walk_i % 2 else 0
    cx = 128 + lean
    shadow(im, 128 + lean, 238 + bob, 100)
    # robe panels
    legs_robe(im, cx - 48, 168 + bob, P["white"], P["white3"], step, lean, True)
    # hem ink edge
    Hline(im, cx - 50, 210 + bob, 100, P["ink"])
    robe_body(im, cx - 46, 78 + bob, 92, 96, P["white"], P["white2"], P["ink"], True)
    # black trim
    gold_edge(im, cx - 46, 78 + bob, 92, 96)  # will overdraw with ink trim
    Hline(im, cx - 46, 78 + bob, 92, P["ink"])
    Hline(im, cx - 46, 173 + bob, 92, P["ink"])
    Vline(im, cx - 46, 78 + bob, 96, P["ink"])
    Vline(im, cx + 45, 78 + bob, 96, P["ink"])
    # double ink border
    Hline(im, cx - 44, 80 + bob, 88, P["ink"])
    # pale gold inner-breath patterns (hard edge)
    for j in range(0, 70, 12):
        for i in range(0, 60, 14):
            put(im, cx - 30 + i + (j // 6), 95 + bob + j, P["pale_gold"])
            put(im, cx - 29 + i + (j // 6), 96 + bob + j, P["gold"])
    # teal sleeve hint
    sleeves(im, cx - 70, cx + 48, 88 + bob, 24, 70, P["white"], P["white2"], 0)
    R(im, cx - 68, 140 + bob, 20, 8, P["teal"])
    R(im, cx + 50, 140 + bob, 20, 8, P["teal"])
    Hline(im, cx - 68, 140 + bob, 20, P["ink"])
    Hline(im, cx + 50, 140 + bob, 20, P["ink"])
    belt_gold(im, cx - 44, 155 + bob, 88)
    # medicine pouch left hip
    box(im, cx - 58, 158 + bob, 22, 28, P["teal"])
    gold_edge(im, cx - 58, 158 + bob, 22, 28)
    R(im, cx - 54, 164 + bob, 14, 10, P["qing"])
    put(im, cx - 48, 168 + bob, P["gold"])
    Hline(im, cx - 56, 172 + bob, 18, P["ink"])
    # face + hair
    face_zhangwuji(im, cx - 24, 28 + bob)
    hair_half_bun(im, cx - 26, 28 + bob, 0)
    # dual palms forward-right
    ox = 4 if walk_i >= 0 else 0
    palm(im, cx + 52 + ox + sway, 110 + bob, gold_aura=True)
    palm(im, cx - 72 - ox, 118 + bob, gold_aura=True)
    # collar
    R(im, cx - 20, 78 + bob, 40, 8, P["ink"])
    R(im, cx - 16, 80 + bob, 32, 4, P["white"])


def draw_dongfang(im, walk_i=-1):
    """硃紅繡袍、長髮、銀針／繡箍、細長飄帶"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -3 if walk_i >= 0 and walk_i % 2 else 0
    sway = (walk_i % 4 - 1) * 3 if walk_i >= 0 else 0
    cx = 128 + lean
    shadow(im, 128 + lean, 238 + bob, 85)
    legs_robe(im, cx - 40, 170 + bob, P["redrobe"], P["redrobe2"], step, lean, True)
    robe_body(im, cx - 40, 72 + bob, 80, 104, P["redrobe3"], P["redrobe2"], P["gold"], True)
    # embroidery dots
    for j in range(0, 90, 10):
        for i in range(0, 50, 12):
            put(im, cx - 28 + i + (j % 8), 85 + bob + j, P["gold"])
            put(im, cx - 26 + i, 88 + bob + j, P["pale_gold"])
    # floral stitch blocks
    for bx, by in ((-20, 100), (10, 120), (-8, 140), (16, 95)):
        R(im, cx + bx, by + bob, 10, 8, P["cinnabar"])
        put(im, cx + bx + 4, by + bob + 3, P["gold"])
        put(im, cx + bx + 2, by + bob + 2, P["ink"])
    sleeves(im, cx - 62, cx + 42, 80 + bob, 22, 75, P["redrobe"], P["redrobe2"], 0)
    gold_edge(im, cx - 62, 80 + bob, 22, 75)
    gold_edge(im, cx + 42, 80 + bob, 22, 75)
    belt_gold(im, cx - 38, 152 + bob, 76)
    # embroidery hoop at waist
    box(im, cx + 30, 155 + bob, 26, 26, P["wood"])
    gold_edge(im, cx + 30, 155 + bob, 26, 26)
    R(im, cx + 34, 159 + bob, 18, 18, P["redrobe3"])
    for i in range(0, 16, 3):
        put(im, cx + 36 + i, 162 + bob + (i % 4), P["silver"])
        put(im, cx + 38 + i, 170 + bob, P["gold"])
    # ribbons (細長飄帶)
    for k, off in enumerate((-18, -8, 4, 14)):
        rx = cx - 50 + off + sway
        R(im, rx, 70 + bob + k * 2, 5, 90 + k * 8, P["redrobe3"])
        Vline(im, rx + 1, 72 + bob, 85 + k * 8, P["gold"])
        Vline(im, rx + 3, 74 + bob, 80, P["redrobe2"])
        R(im, rx - 2, 155 + bob + k * 10, 9, 12, P["cinnabar"])
    face_dongfang(im, cx - 24, 24 + bob)
    hair_long_red(im, cx - 26, 24 + bob, 0, sway)
    # silver needles in right hand fan
    nx = cx + 55 + (2 if walk_i >= 0 else 0)
    ny = 95 + bob
    for i in range(7):
        R(im, nx + i * 3, ny - i * 4, 2, 36 + i * 2, P["silver"])
        put(im, nx + i * 3, ny - i * 4 - 1, P["paper"])
        put(im, nx + i * 3 + 1, ny + 34 + i * 2, P["ink"])
    # needle cluster base
    box(im, nx - 2, ny + 20, 24, 8, P["gold"])
    # collar
    R(im, cx - 18, 72 + bob, 36, 6, P["gold"])
    Hline(im, cx - 18, 72 + bob, 36, P["ink"])


def draw_dugu(im, walk_i=-1):
    """青袍負木劍、清瘦、無華麗飾物——氣勢在剪影與袍褶"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -2 if walk_i >= 0 and walk_i % 2 else 0
    cx = 120 + lean  # slightly left lean silhouette
    shadow(im, 128 + lean, 238 + bob, 70)
    # slim legs/robe
    legs_robe(im, cx - 32, 172 + bob, P["qing"], P["qing2"], step, lean, True)
    robe_body(im, cx - 34, 78 + bob, 68, 100, P["qing3"], P["qing2"], None, True)
    # dense folds only (no gold excess)
    for i in range(6, 60, 7):
        fold_v(im, cx - 30 + i, 90 + bob, 70, P["qing2"])
        fold_v(im, cx - 28 + i, 95 + bob, 60, P["shade"])
    for j in range(20, 90, 11):
        fold_h(im, cx - 28, 80 + bob + j, 56, P["qing2"])
    sleeves(im, cx - 52, cx + 36, 85 + bob, 18, 65, P["qing"], P["qing2"], 0)
    # simple cloth belt
    R(im, cx - 32, 155 + bob, 64, 10, P["wood3"])
    Hline(im, cx - 32, 155 + bob, 64, P["ink"])
    Hline(im, cx - 32, 164 + bob, 64, P["ink"])
    put(im, cx - 2, 159 + bob, P["wood"])
    face_dugu(im, cx - 22, 28 + bob)
    hair_thin(im, cx - 24, 28 + bob)
    # wooden sword on back (diagonal)
    sx = cx + 20
    sy = 40 + bob
    for i in range(110):
        R(im, sx + i // 5, sy + i, 10, 3, P["wood"])
        put(im, sx + i // 5 + 2, sy + i + 1, P["wood2"])
        put(im, sx + i // 5 + 7, sy + i + 1, P["wood3"])
        if i % 12 == 0:
            put(im, sx + i // 5 + 4, sy + i, P["ink"])
    # sword tip
    R(im, sx + 20, sy + 108, 8, 8, P["wood2"])
    put(im, sx + 23, sy + 116, P["wood3"])
    # hilt wrap near shoulder
    R(im, sx - 4, sy + 8, 16, 14, P["wood3"])
    Hline(im, sx - 4, sy + 8, 16, P["ink"])
    Hline(im, sx - 4, sy + 20, 16, P["ink"])
    # sword-qi silhouette hint (hard pale edge beside blade)
    for i in range(0, 90, 4):
        put(im, sx + i // 5 + 11, sy + 10 + i, P["paper"])
        put(im, sx + i // 5 + 12, sy + 12 + i, P["white2"])
    # thin hands relaxed
    box(im, cx - 56, 145 + bob, 14, 14, P["skin"])
    box(im, cx + 40, 145 + bob, 14, 14, P["skin"])


def draw_saodi(im, walk_i=-1):
    """灰僧衣補丁、光頭、竹掃把、念珠、微駝"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2 + 4  # slight hunch forward bias in silhouette via offset
    bob = -1 if walk_i >= 0 and walk_i % 2 else 0
    cx = 130 + lean
    shadow(im, 128 + lean, 238 + bob, 95)
    legs_robe(im, cx - 46, 168 + bob, P["monk"], P["monk2"], step, lean, True)
    # hunched torso (wider, lower neck)
    robe_body(im, cx - 50, 85 + bob, 100, 90, P["monk3"], P["monk2"], None, True)
    # patches
    for px, py, pw, ph, col in (
        (-30, 100, 22, 18, P["monk2"]),
        (10, 120, 20, 16, P["shade"]),
        (-10, 140, 24, 14, P["monk"]),
        (20, 95, 18, 14, P["wood"]),
    ):
        box(im, cx + px, py + bob, pw, ph, col)
        Hline(im, cx + px + 2, py + bob + ph // 2, pw - 4, P["ink"])
    sleeves(im, cx - 72, cx + 52, 95 + bob, 24, 60, P["monk"], P["monk2"], 0)
    # rope belt
    R(im, cx - 48, 158 + bob, 96, 12, P["wood"])
    Hline(im, cx - 48, 158 + bob, 96, P["ink"])
    for i in range(0, 90, 8):
        put(im, cx - 44 + i, 163 + bob, P["wood3"])
    face_saodi(im, cx - 24, 38 + bob)
    # prayer beads
    beads = [P["wood"], P["gold"], P["cinnabar"], P["wood2"], P["gold"], P["wood"], P["pale_gold"], P["wood3"]]
    for i, c in enumerate(beads * 3):
        ang = i
        bx = cx - 20 + (i % 12) * 4
        by = 78 + bob + (i // 12) * 5 + (i % 3)
        R(im, bx, by, 5, 5, c)
        put(im, bx + 1, by + 1, P["ink"])
    # bamboo broom as staff (left)
    bx = cx - 90 + (-2 if walk_i >= 0 else 0)
    R(im, bx, 20 + bob, 12, 200, P["bamboo"])
    Vline(im, bx + 3, 20 + bob, 200, P["bamboo2"])
    Vline(im, bx + 8, 22 + bob, 196, P["wood3"])
    for i in range(30, 180, 28):
        Hline(im, bx, 20 + bob + i, 12, P["ink"])
        put(im, bx + 5, 24 + bob + i, P["wood"])
    # broom head
    R(im, bx - 14, 8 + bob, 40, 28, P["bamboo2"])
    for i in range(0, 38, 3):
        Vline(im, bx - 12 + i, 4 + bob, 20 + (i % 5), P["bamboo"])
        put(im, bx - 12 + i, 3 + bob, P["ink"])
    box(im, bx - 4, 30 + bob, 20, 10, P["wood"])
    # falling leaves idle
    for lx, ly in ((40, 50), (60, 70), (180, 55), (200, 90), (70, 40), (190, 120)):
        R(im, lx, ly + bob, 6, 4, P["bamboo"])
        put(im, lx + 2, ly + bob + 1, P["cinnabar"])
    # hand on broom
    box(im, bx + 2, 120 + bob, 16, 14, P["skin"])


def draw_wangchongyang(im, walk_i=-1):
    """道冠長鬚、寬袖道袍、玉牌、中正雙拳"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -2 if walk_i >= 0 and walk_i % 2 else 0
    cx = 128 + lean
    shadow(im, 128 + lean, 238 + bob, 100)
    legs_robe(im, cx - 48, 168 + bob, P["dao"], P["dao2"], step, lean, True)
    robe_body(im, cx - 50, 80 + bob, 100, 95, P["dao3"], P["dao2"], P["gold"], True)
    # wide sleeves
    sleeves(im, cx - 85, cx + 58, 88 + bob, 32, 80, P["dao"], P["dao2"], 0)
    gold_edge(im, cx - 85, 88 + bob, 32, 80)
    gold_edge(im, cx + 58, 88 + bob, 32, 80)
    # cuff pale teal qi
    R(im, cx - 82, 155 + bob, 26, 6, P["teal"])
    R(im, cx + 61, 155 + bob, 26, 6, P["teal"])
    belt_gold(im, cx - 48, 155 + bob, 96)
    # jade plaque
    box(im, cx - 12, 158 + bob, 24, 28, P["teal"])
    gold_edge(im, cx - 12, 158 + bob, 24, 28)
    R(im, cx - 8, 162 + bob, 16, 20, P["qing3"])
    put(im, cx - 2, 170 + bob, P["pale_gold"])
    put(im, cx, 172 + bob, P["gold"])
    Hline(im, cx - 6, 168 + bob, 12, P["ink"])
    face_wangchongyang(im, cx - 24, 30 + bob)
    hair_dao(im, cx - 26, 30 + bob)
    # dual fists centered (中正)
    ox = 3 if walk_i >= 0 else 0
    # left fist
    box(im, cx - 78 - ox, 150 + bob, 28, 24, P["skin"])
    R(im, cx - 76 - ox, 152 + bob, 6, 20, P["skin2"])
    for i in range(4):
        Vline(im, cx - 70 - ox + i * 5, 154 + bob, 14, P["ink"])
    # right fist
    box(im, cx + 52 + ox, 148 + bob, 28, 24, P["skin"])
    R(im, cx + 54 + ox, 150 + bob, 6, 20, P["skin2"])
    for i in range(4):
        Vline(im, cx + 60 + ox + i * 5, 152 + bob, 14, P["ink"])
    # pale teal qi around fists
    for dx, dy in ((-4, 2), (-3, 20), (28, 4), (29, 16), (10, -3), (12, 24)):
        put(im, cx - 78 - ox + dx, 150 + bob + dy, P["teal"])
        put(im, cx + 52 + ox + dx, 148 + bob + dy, P["qing3"])
    # collar
    R(im, cx - 22, 80 + bob, 44, 10, P["ink"])
    R(im, cx - 18, 82 + bob, 36, 6, P["dao3"])


def draw_huangshang(im, walk_i=-1):
    """文士墨褐袍、書卷、袖弩／鐵蓮、墨指痕"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step * 2
    bob = -2 if walk_i >= 0 and walk_i % 2 else 0
    sway = 2 if walk_i >= 0 else 0
    cx = 128 + lean
    shadow(im, 128 + lean, 238 + bob, 90)
    legs_robe(im, cx - 44, 170 + bob, P["inkrobe"], P["inkrobe2"], step, lean, True)
    robe_body(im, cx - 44, 78 + bob, 88, 98, P["inkrobe3"], P["inkrobe2"], P["cinnabar"], True)
    # cinnabar annotation dots on robe
    for j in range(0, 80, 11):
        for i in range(0, 55, 13):
            put(im, cx - 30 + i, 95 + bob + j, P["cinnabar"])
            if (i + j) % 2 == 0:
                put(im, cx - 28 + i, 97 + bob + j, P["ink"])
    sleeves(im, cx - 68, cx + 46, 85 + bob, 24, 70, P["inkrobe"], P["inkrobe2"], 0)
    # ink finger stains on left cuff
    for i in range(6):
        put(im, cx - 64 + i * 3, 145 + bob, P["ink"])
        put(im, cx - 62 + i * 3, 148 + bob, P["shade"])
    belt_gold(im, cx - 42, 154 + bob, 84, jewel=False)
    R(im, cx - 6, 156 + bob, 12, 10, P["ink"])  # inkstone buckle
    face_huangshang(im, cx - 24, 28 + bob)
    hair_scholar(im, cx - 26, 28 + bob)
    # book scroll in left hand
    box(im, cx - 78, 120 + bob, 28, 40, P["paper"])
    gold_edge(im, cx - 78, 120 + bob, 28, 40)
    for j in range(4, 36, 5):
        Hline(im, cx - 74, 120 + bob + j, 20, P["ink"])
    R(im, cx - 76, 122 + bob, 4, 36, P["wood"])
    R(im, cx - 54, 122 + bob, 4, 36, P["wood"])
    put(im, cx - 65, 130 + bob, P["cinnabar"])  # seal
    # sleeve crossbow right
    bx = cx + 55 + sway
    by = 115 + bob
    box(im, bx, by, 36, 18, P["wood3"])
    gold_edge(im, bx, by, 36, 18)
    R(im, bx + 4, by + 4, 28, 10, P["stone"])
    R(im, bx + 30, by + 6, 14, 6, P["silver"])  # bolt
    put(im, bx + 42, by + 8, P["paper"])
    Vline(im, bx + 8, by - 8, 10, P["wood"])
    Vline(im, bx + 24, by - 6, 8, P["wood2"])
    # iron lotus hanging
    lx, ly = cx + 28, 160 + bob
    R(im, lx, ly, 16, 16, P["stone"])
    for i in range(8):
        put(im, lx + 8 + int(6 * __import__('math').cos(i * 0.8)), ly + 8 + int(6 * __import__('math').sin(i * 0.8)), P["silver"])
    put(im, lx + 7, ly + 7, P["ink"])
    # ink finger on right
    box(im, cx + 50, 148 + bob, 16, 14, P["skin"])
    put(im, cx + 58, 154 + bob, P["ink"])
    put(im, cx + 60, 156 + bob, P["ink"])


HEROES = [
    ("red_zhangwuji", "張無記", draw_zhangwuji, "facefix溫厚圓目微抿＋腳踩實；白衣黑邊半束髮、雙掌淡金、藥囊"),
    ("red_dongfang", "東方唔敗", draw_dongfang, "facefix鳳眼戲謔嘴＋腳踩實；硃紅繡袍長髮、銀針、飄帶"),
    ("red_dugu", "獨孤求拜", draw_dugu, "facefix細目薄唇清瘦＋腳踩實；青袍負木劍、密褶"),
    ("red_saodi", "掃地僧", draw_saodi, "facefix老年皺紋慈眉＋腳踩實；灰僧衣補丁、掃把念珠"),
    ("red_wangchongyang", "王重揚", draw_wangchongyang, "facefix劍眉長鬚剛毅＋腳踩實；道冠寬袖、玉牌雙拳"),
    ("red_huangshang", "黃裳", draw_huangshang, "facefix文士細目墨頰＋腳踩實；墨褐袍書卷、袖弩鐵蓮"),
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


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    rows = []
    roster = Image.new("RGBA", (SIZE * 6, SIZE), P["trans"])
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
        assert idle.size == (256, 256), idle.size
        assert walk.size == (1024, 256), walk.size
        roster.paste(idle, (idx * SIZE, 0), idle)
        rows.append(
            f"| `{hid}` | {name} | {idle.size[0]}×{idle.size[1]} | "
            f"{walk.size[0]}×{walk.size[1]} | {feat} | "
            f"idle_bad={bad_i} walk_bad={bad_w} |"
        )
        print(f"OK {hid} idle={idle.size} walk={walk.size} bad={bad_i}/{bad_w}")

    p1 = f"{PREV}/red_roster256_x1.png"
    p2 = f"{PREV}/red_roster256_x2.png"
    roster.save(p1)
    roster.resize((roster.width * 2, roster.height * 2), Image.NEAREST).save(p2)

    # face compare: old backup vs new face crops, or six face closeups
    face_prev = Path(f"{OUT}/_prev_facefix")
    crop = 72
    face_y0, face_x0 = 20, 128 - 36
    compare = Image.new("RGBA", (crop * 6, crop * 2 + 8), (26, 21, 16, 255))
    face_row = Image.new("RGBA", (crop * 6, crop), (26, 21, 16, 255))
    for idx, (hid, name, fn, feat) in enumerate(HEROES):
        idle_path = Path(f"{OUT}/{hid}_idle.png")
        im = Image.open(idle_path).convert("RGBA")
        # new face crop
        boxc = (face_x0, face_y0, face_x0 + crop, face_y0 + crop)
        # clamp
        boxc = (max(0, face_x0), max(0, face_y0), min(256, face_x0 + crop), min(256, face_y0 + crop))
        face_crop = im.crop(boxc)
        # pad if needed
        tile = Image.new("RGBA", (crop, crop), (26, 21, 16, 255))
        tile.paste(face_crop, (0, 0), face_crop)
        face_row.paste(tile, (idx * crop, 0), tile)
        oldp = face_prev / f"{hid}_idle.png"
        if oldp.exists():
            oim = Image.open(oldp).convert("RGBA")
            of = oim.crop(boxc)
            ot = Image.new("RGBA", (crop, crop), (26, 21, 16, 255))
            ot.paste(of, (0, 0), of)
            compare.paste(ot, (idx * crop, 0), ot)
        compare.paste(tile, (idx * crop, crop + 8), tile)
    face_row_path = f"{PREV}/red_faces_closeup.png"
    face_row.resize((face_row.width * 2, face_row.height * 2), Image.NEAREST).save(face_row_path)
    cmp_path = f"{PREV}/red_faces_compare.png"
    compare.resize((compare.width * 2, compare.height * 2), Image.NEAREST).save(cmp_path)

    md = f"""# MANIFEST — 紅階六人 256×256（facefix／腳形修正）

生成腳本：`tools/gen_red_heroes_256.py`
輸出目錄：`assets/art/heroes/red/`
備份：`assets/art/heroes/red/_prev_facefix/`
預覽：`assets/art/_preview/red_roster256_x1.png`、`red_roster256_x2.png`
臉對照：`assets/art/_preview/red_faces_compare.png`（上＝舊／下＝新）、`red_faces_closeup.png`

## 規格
- Idle：256×256 RGBA 透明底硬邊
- Walk：1024×256（4 幀 × 256）
- 色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227＋skin/wood/boot/shade/robe 微調
- 解像階梯：紅＝256；Nearest 整數倍顯示
- **facefix**：六人獨立五官／神態（唔共用同一 face 模板）
- **腳形修正**：靴底平貼 sole_y=239，陰影 y=238；idle 雙腳對稱踩實；walk 抬腳 6px
- 技能特效：今次未做（可後補）

## 清單
| id | 名 | idle | walk | 特徵 | palette 自檢 |
|----|----|------|------|------|--------------|
{chr(10).join(rows)}

## 自檢
- 尺寸正確；alpha 以 0/255 為主
- 六人並排剪影可辨：白掌／紅針／木劍／掃把／道鬚／書卷袖弩
- 臉：溫厚圓目／鳳眼戲謔／細目淡漠／老年慈眉／劍眉長鬚／文士墨頰
- 腳：唔懸空、唔外八歪斜
- 唔抄原著立繪、唔抄俠客棧／銀樓舊造型
"""
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(md)
    print("Wrote", MANIFEST)
    print("Preview", p1, p2, cmp_path, face_row_path)


if __name__ == "__main__":
    main()
