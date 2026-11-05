#!/usr/bin/env python3
"""墨點俠村 P1 — 六綠俠 + 狼／野豬／山賊 硬邊像素精靈（64×64）

解像階梯（Lemon 最高標準，寫入註解）：
  白／綠  → 64×64   （本腳本：開局六綠俠＋通用怪）
  藍／紫  → 96×96
  橙      → 128×128
  紅      → 256×256
顯示整數倍 Nearest；唔用柔邊放大充解像。
橙／紅以後另腳本；今次綠俠細節要比舊 48 明顯密（衣褶／腰帶／武器邊緣／硬邊陰影）。

禁止：柔邊／寫實／AI／抄 IP／原著立繪。
色盤：墨黑#1A1510／宣紙#E8DCC8／硃紅#C43C2C／青綠#2F6B5A／金邊#C9A227
      + skin/wood/boot/shade 家族。
"""
from __future__ import annotations

import os
from PIL import Image

SIZE = 64
WALK_FRAMES = 4
ROOT = "/workspace/modian-xiacun/assets/art"
HERO_DIR = f"{ROOT}/heroes"
MON_DIR = f"{ROOT}/monsters"
PREV_DIR = f"{ROOT}/_preview"
MANIFEST = "/workspace/modian-xiacun/tools/MANIFEST_p1_sprites.md"

# 嚴格色盤家族（主色 + 同源微調）
P = {
    "ink": (26, 21, 16, 255),       # #1A1510
    "paper": (232, 220, 200, 255),  # #E8DCC8
    "cinnabar": (196, 60, 44, 255), # #C43C2C
    "teal": (47, 107, 90, 255),     # #2F6B5A
    "gold": (201, 162, 39, 255),    # #C9A227
    "skin": (200, 170, 140, 255),
    "skin2": (184, 148, 116, 255),
    "wood": (90, 64, 48, 255),
    "wood2": (112, 80, 56, 255),
    "boot": (58, 40, 32, 255),
    "shade": (74, 64, 52, 255),
    "stone": (106, 96, 85, 255),
    "cloth_g": (58, 122, 106, 255),
    "cloth_d": (42, 86, 74, 255),
    "cloth_b": (56, 72, 88, 255),
    "cloth_r": (140, 56, 48, 255),
    "cloth_o": (120, 88, 56, 255),
    "cloth_y": (168, 140, 72, 255),
    "fur": (138, 126, 110, 255),
    "fur_d": (90, 78, 64, 255),
    "boar": (96, 72, 56, 255),
    "trans": (0, 0, 0, 0),
}

ALLOWED_RGB = {(c[0], c[1], c[2]) for c in P.values() if c[3] > 0}


def nf() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), P["trans"])


def put(im: Image.Image, x: int, y: int, c: tuple) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE and c[3]:
        im.putpixel((x, y), c)


def R(im: Image.Image, x: int, y: int, w: int, h: int, c: tuple) -> None:
    for j in range(max(0, h)):
        for i in range(max(0, w)):
            put(im, x + i, y + j, c)


def box(im: Image.Image, x: int, y: int, w: int, h: int, fill: tuple, edge=None) -> None:
    edge = edge or P["ink"]
    R(im, x, y, w, h, fill)
    for i in range(w):
        put(im, x + i, y, edge)
        put(im, x + i, y + h - 1, edge)
    for j in range(h):
        put(im, x, y + j, edge)
        put(im, x + w - 1, y + j, edge)


def shadow(im: Image.Image, x: int = 18, y: int = 58, w: int = 28) -> None:
    """硬邊兩層陰影（shade 外圈 + ink 內線），唔用半透明柔邊。"""
    R(im, x, y, w, 3, P["shade"])
    R(im, x + 3, y + 1, max(1, w - 6), 1, P["ink"])
    R(im, x + 5, y, max(1, w - 10), 1, P["ink"])


def face(im: Image.Image, x: int, y: int, look_right: bool = True) -> None:
    """16×14 臉：硬邊陰影、眉、眼高光、硃紅唇。"""
    box(im, x, y, 16, 14, P["skin"])
    R(im, x + 1, y + 1, 3, 12, P["skin2"])  # 左臉陰影
    R(im, x + 12, y + 2, 2, 10, P["skin2"])  # 右頰微影
    # eyes
    put(im, x + 4, y + 5, P["ink"])
    put(im, x + 11, y + 5, P["ink"])
    if look_right:
        put(im, x + 5, y + 5, P["paper"])
        put(im, x + 12, y + 5, P["paper"])
    # brows
    R(im, x + 3, y + 3, 4, 1, P["ink"])
    R(im, x + 10, y + 3, 4, 1, P["ink"])
    # mouth
    R(im, x + 5, y + 9, 6, 2, P["cinnabar"])
    put(im, x + 5, y + 9, P["ink"])
    put(im, x + 10, y + 9, P["ink"])
    # nose hint
    put(im, x + 8, y + 7, P["skin2"])


def legs(im: Image.Image, x: int, y: int, robe: tuple, lean: int = 0, step: int = 0) -> None:
    """腿＋靴：衣褶線、靴底硬邊。"""
    lx = lean + (-3 if step < 0 else (3 if step > 0 else 0))
    rx = lean + (3 if step < 0 else (-3 if step > 0 else 0))
    ly = -2 if step < 0 else 0
    ry = -2 if step > 0 else 0
    # left leg
    R(im, x + lx, y + ly, 8, 12, robe)
    R(im, x + lx + 1, y + ly + 2, 1, 8, P["shade"])  # 褶
    R(im, x + lx + 5, y + ly + 1, 1, 6, P["shade"])
    R(im, x - 1 + lx, y + 10 + ly, 9, 5, P["boot"])
    R(im, x - 1 + lx, y + 10 + ly, 9, 1, P["ink"])
    R(im, x - 1 + lx, y + 14 + ly, 9, 1, P["ink"])  # 靴底
    # right leg
    R(im, x + 12 + rx, y + ry, 8, 12, robe)
    R(im, x + 13 + rx, y + ry + 2, 1, 8, P["shade"])
    R(im, x + 17 + rx, y + ry + 1, 1, 6, P["shade"])
    R(im, x + 12 + rx, y + 10 + ry, 9, 5, P["boot"])
    R(im, x + 12 + rx, y + 10 + ry, 9, 1, P["ink"])
    R(im, x + 12 + rx, y + 14 + ry, 9, 1, P["ink"])


def torso(im: Image.Image, x: int, y: int, w: int, h: int, robe: tuple, belt: tuple = None) -> None:
    """軀幹：左緣硬邊陰影、衣褶、金腰帶＋綠稀有珠。"""
    belt = belt or P["gold"]
    box(im, x, y, w, h, robe)
    R(im, x + 1, y + 1, 3, h - 2, P["shade"])  # 左陰影
    # 衣褶（硬邊豎線）
    R(im, x + w // 3, y + 3, 1, h - 10, P["shade"])
    R(im, x + 2 * w // 3, y + 4, 1, h - 12, P["shade"])
    # 橫衣紋
    R(im, x + 4, y + h // 3, w - 8, 1, P["shade"])
    # belt
    R(im, x, y + h - 7, w, 5, belt)
    R(im, x, y + h - 7, w, 1, P["ink"])
    R(im, x, y + h - 3, w, 1, P["ink"])
    # buckle + 綠稀有小標記
    bx = x + w // 2 - 2
    box(im, bx, y + h - 6, 5, 4, P["gold"])
    put(im, bx + 2, y + h - 4, P["teal"])


def arms(im: Image.Image, x_l: int, x_r: int, y: int, lean: int = 0, bob: int = 0) -> None:
    R(im, x_l + lean, y + bob, 5, 10, P["stone"])
    R(im, x_r + lean, y + bob, 5, 10, P["stone"])
    R(im, x_l + lean, y + bob, 5, 1, P["ink"])
    R(im, x_r + lean, y + bob, 5, 1, P["ink"])
    R(im, x_l + lean + 1, y + bob + 2, 1, 6, P["shade"])
    R(im, x_r + lean + 1, y + bob + 2, 1, 6, P["shade"])


def base_hero(
    im: Image.Image,
    robe: tuple,
    lean: int = 0,
    bob: int = 0,
    step: int = 0,
    bald: bool = False,
    hair: tuple = None,
    mask: bool = False,
) -> None:
    shadow(im, 17 + lean, 58 + bob, 28)
    legs(im, 20, 44 + bob, robe, lean, step)
    torso(im, 18 + lean, 22 + bob, 26, 24, robe)
    face(im, 22 + lean, 8 + bob)
    arms(im, 14, 42, 24, lean, bob)
    if bald:
        R(im, 24 + lean, 5 + bob, 14, 5, P["skin"])
        R(im, 26 + lean, 3 + bob, 10, 3, P["skin"])
        R(im, 28 + lean, 2 + bob, 6, 2, P["skin2"])
        # 戒疤三點
        put(im, 28 + lean, 6 + bob, P["ink"])
        put(im, 31 + lean, 5 + bob, P["ink"])
        put(im, 34 + lean, 6 + bob, P["ink"])
    elif hair:
        R(im, 21 + lean, 4 + bob, 18, 5, hair)
        R(im, 23 + lean, 2 + bob, 14, 3, hair)
        R(im, 25 + lean, 1 + bob, 10, 2, hair)
        R(im, 38 + lean, 6 + bob, 5, 12, hair)  # 右側束髮／馬尾
        R(im, 39 + lean, 8 + bob, 1, 8, P["shade"])
    if mask:
        R(im, 22 + lean, 14 + bob, 16, 5, P["ink"])
        put(im, 26 + lean, 16 + bob, P["paper"])
        put(im, 33 + lean, 16 + bob, P["paper"])
        R(im, 22 + lean, 14 + bob, 16, 1, P["shade"])


# —— 六俠（64 細節密度）—— #

def hero_dao_atie(im: Image.Image, walk_i: int = -1) -> None:
    """刀客阿鐵 — 寬刀剪影（厚背薄刃＋金護手）"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_r"], lean, bob, step, hair=P["ink"])
    # 寬刀（右手側朝右）
    wx = 44 + lean + (2 if walk_i >= 0 else 0)
    wy = 12 + bob
    R(im, wx, wy + 5, 6, 32, P["stone"])       # 刀背
    R(im, wx + 1, wy + 6, 1, 30, P["ink"])      # 背脊線
    R(im, wx + 5, wy + 8, 4, 26, P["paper"])    # 刃面
    R(im, wx + 7, wy + 10, 2, 20, P["paper"])
    put(im, wx + 8, wy + 7, P["paper"])         # 刀尖
    put(im, wx + 9, wy + 9, P["paper"])
    put(im, wx + 8, wy + 11, P["ink"])          # 刃口硬邊
    R(im, wx - 2, wy + 1, 5, 7, P["wood"])      # 柄
    R(im, wx - 1, wy + 2, 1, 5, P["wood2"])
    R(im, wx - 3, wy + 18, 12, 4, P["gold"])    # 護手
    R(im, wx - 2, wy + 17, 10, 1, P["ink"])
    R(im, wx - 2, wy + 21, 10, 1, P["ink"])
    put(im, wx + 2, wy + 19, P["teal"])         # 護手綠珠
    # 刀穗（硬邊珠串）
    for i, c in enumerate((P["gold"], P["cinnabar"], P["paper"], P["gold"])):
        put(im, wx - 4 + i // 2, wy + 22 + i, c)


def hero_jian_aqing(im: Image.Image, walk_i: int = -1) -> None:
    """劍客阿青 — 細長劍＋青絲"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_g"], lean, bob, step, hair=P["teal"])
    # 加長青絲
    R(im, 20 + lean, 5 + bob, 20, 4, P["teal"])
    R(im, 38 + lean, 8 + bob, 4, 16, P["teal"])
    R(im, 39 + lean, 10 + bob, 1, 12, P["cloth_d"])
    R(im, 40 + lean, 18 + bob, 3, 8, P["teal"])
    # 細劍
    wx = 46 + lean + (1 if walk_i >= 0 else 0)
    wy = 10 + bob
    R(im, wx, wy, 2, 36, P["paper"])
    R(im, wx + 1, wy + 1, 1, 34, P["ink"])  # 中脊
    R(im, wx - 1, wy - 1, 4, 3, P["ink"])   # 劍尖／鍔上
    R(im, wx - 3, wy + 10, 8, 3, P["gold"]) # 護手
    R(im, wx - 2, wy + 9, 6, 1, P["ink"])
    put(im, wx, wy - 2, P["gold"])
    R(im, wx - 1, wy + 13, 4, 8, P["wood"]) # 柄
    put(im, wx, wy + 16, P["wood2"])


def hero_qiang_achang(im: Image.Image, walk_i: int = -1) -> None:
    """槍客阿長 — 長槍超出身高"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_d"], lean, bob, step, hair=P["ink"])
    # 硃紅頭巾
    R(im, 21 + lean, 3 + bob, 18, 5, P["cinnabar"])
    R(im, 23 + lean, 1 + bob, 14, 3, P["cinnabar"])
    R(im, 24 + lean, 2 + bob, 12, 1, P["ink"])
    put(im, 38 + lean, 6 + bob, P["gold"])  # 巾結
    # 長槍：桿 + 槍尖
    wx = 48 + lean
    R(im, wx, 2 + bob, 3, 52, P["wood"])
    R(im, wx + 1, 2 + bob, 1, 52, P["wood2"])
    R(im, wx, 2 + bob, 3, 1, P["ink"])
    # 槍尖朝上
    R(im, wx - 2, 0 + bob, 7, 6, P["stone"])
    R(im, wx - 1, -1 + bob, 5, 4, P["paper"])
    put(im, wx + 1, -2 + bob, P["paper"])
    put(im, wx + 1, 0 + bob, P["ink"])
    R(im, wx - 3, 22 + bob, 9, 3, P["gold"])  # 紅纓座／金箍
    R(im, wx - 2, 21 + bob, 7, 1, P["ink"])
    # 紅纓硬邊絲
    for i in range(5):
        put(im, wx - 4 - i // 2, 24 + bob + i, P["cinnabar"])
        put(im, wx + 5 + i // 2, 24 + bob + i, P["cinnabar"])


def hero_gun_dali(im: Image.Image, walk_i: int = -1) -> None:
    """棍僧大力 — 光頭＋木棍＋金邊袖"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_o"], lean, bob, step, bald=True)
    # 僧袍金邊袖
    R(im, 14 + lean, 24 + bob, 4, 14, P["gold"])
    R(im, 43 + lean, 24 + bob, 4, 14, P["gold"])
    R(im, 14 + lean, 24 + bob, 4, 1, P["ink"])
    R(im, 43 + lean, 24 + bob, 4, 1, P["ink"])
    # 木棍左側直立
    sx = 6 + lean + (-1 if walk_i >= 0 else 0)
    R(im, sx, 4 + bob, 5, 48, P["wood"])
    R(im, sx + 1, 4 + bob, 1, 48, P["wood2"])
    R(im, sx + 3, 4 + bob, 1, 48, P["shade"])
    box(im, sx - 2, 2 + bob, 9, 6, P["gold"])
    R(im, sx, 3 + bob, 5, 2, P["paper"])
    # 棍身節疤
    put(im, sx + 2, 16 + bob, P["ink"])
    put(im, sx + 2, 32 + bob, P["ink"])
    put(im, sx + 1, 40 + bob, P["ink"])


def hero_anqi_azhen(im: Image.Image, walk_i: int = -1) -> None:
    """暗衛阿針 — 面具＋雙刺／飛針"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step + (1 if walk_i >= 0 else 0)
    bob = -2 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_b"], lean, bob, step, hair=P["ink"], mask=True)
    # 斗篷側影
    R(im, 10 + lean, 20 + bob, 7, 24, P["ink"])
    R(im, 11 + lean, 22 + bob, 4, 20, P["shade"])
    R(im, 12 + lean, 24 + bob, 1, 16, P["cloth_b"])
    # 斗篷下擺褶
    put(im, 11 + lean, 42 + bob, P["shade"])
    put(im, 14 + lean, 43 + bob, P["shade"])
    # 雙短刺
    wx = 46 + lean
    R(im, wx, 16 + bob, 2, 18, P["paper"])
    R(im, wx + 1, 16 + bob, 1, 18, P["ink"])
    R(im, wx - 1, 14 + bob, 4, 3, P["gold"])
    R(im, 8 + lean, 22 + bob, 2, 16, P["paper"])
    R(im, 9 + lean, 22 + bob, 1, 16, P["ink"])
    R(im, 7 + lean, 20 + bob, 4, 3, P["gold"])
    # 飛針軌跡（walk）
    if walk_i >= 0:
        put(im, 54, 18 + bob, P["paper"])
        put(im, 56, 20 + bob, P["paper"])
        put(im, 58, 22 + bob, P["gold"])
        put(im, 60, 24 + bob, P["paper"])


def hero_quan_aniu(im: Image.Image, walk_i: int = -1) -> None:
    """拳師阿牛 — 無長兵器，粗臂握拳"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_y"], lean, bob, step, hair=P["ink"])
    # 硃紅頭巾
    R(im, 21 + lean, 3 + bob, 18, 5, P["cinnabar"])
    R(im, 23 + lean, 2 + bob, 14, 2, P["ink"])
    put(im, 38 + lean, 6 + bob, P["gold"])
    # 粗右臂＋握拳前伸
    fx = 3 if walk_i >= 0 else 1
    R(im, 42 + lean + fx, 20 + bob, 9, 14, P["skin"])
    R(im, 43 + lean + fx, 21 + bob, 2, 12, P["skin2"])
    box(im, 46 + lean + fx, 30 + bob, 12, 10, P["skin2"])
    R(im, 47 + lean + fx, 31 + bob, 10, 8, P["skin"])
    # 指縫
    R(im, 48 + lean + fx, 32 + bob, 2, 6, P["ink"])
    R(im, 52 + lean + fx, 32 + bob, 2, 6, P["ink"])
    R(im, 55 + lean + fx, 33 + bob, 1, 5, P["ink"])
    # 左護腕＋收腰拳
    R(im, 10 + lean, 24 + bob, 8, 10, P["wood"])
    R(im, 10 + lean, 24 + bob, 8, 1, P["gold"])
    R(im, 10 + lean, 28 + bob, 8, 1, P["gold"])
    box(im, 9 + lean, 32 + bob, 9, 8, P["skin2"])
    R(im, 10 + lean, 33 + bob, 7, 6, P["skin"])
    # 胸前布帶交叉
    R(im, 22 + lean, 24 + bob, 16, 2, P["ink"])
    R(im, 24 + lean, 28 + bob, 12, 2, P["ink"])
    put(im, 30 + lean, 26 + bob, P["gold"])


# —— 怪物 —— #

def monster_wolf(im: Image.Image, attack: bool = False) -> None:
    ox = 4 if attack else 0
    shadow(im, 14 + ox, 58, 32)
    # 身
    box(im, 12 + ox, 28, 34, 22, P["fur"])
    R(im, 14 + ox, 30, 30, 18, P["fur_d"])
    R(im, 16 + ox, 32, 1, 14, P["shade"])  # 肋褶
    R(im, 28 + ox, 34, 1, 10, P["shade"])
    # 頭
    box(im, 36 + ox, 16, 18, 16, P["fur"])
    R(im, 38 + ox, 18, 14, 12, P["fur_d"])
    put(im, 44 + ox, 22, P["ink"])
    put(im, 50 + ox, 22, P["cinnabar"])
    put(im, 45 + ox, 22, P["paper"])
    # 耳
    R(im, 38 + ox, 10, 5, 7, P["fur"])
    R(im, 48 + ox, 10, 5, 7, P["fur"])
    R(im, 39 + ox, 11, 3, 4, P["ink"])
    R(im, 49 + ox, 11, 3, 4, P["ink"])
    # 嘴／牙
    R(im, 48 + ox, 28, 8, 4, P["ink"])
    put(im, 50 + ox, 29, P["paper"])
    put(im, 52 + ox, 29, P["paper"])
    put(im, 54 + ox, 30, P["paper"])
    # 腿
    for lx, ly in ((14, 48), (24, 48), (34, 48), (42, 46)):
        R(im, lx + ox, ly, 5, 10, P["fur_d"])
        R(im, lx + ox, ly + 9, 5, 1, P["ink"])
    # 尾
    R(im, 6 + ox, 32, 8, 5, P["fur"])
    R(im, 4 + ox, 30, 5, 4, P["fur_d"])
    R(im, 3 + ox, 28, 3, 3, P["fur"])
    if attack:
        R(im, 52 + ox, 24, 8, 5, P["fur"])
        R(im, 54 + ox, 22, 5, 3, P["paper"])
        R(im, 46 + ox, 42, 10, 4, P["ink"])
        put(im, 54 + ox, 41, P["cinnabar"])


def monster_boar(im: Image.Image, attack: bool = False) -> None:
    ox = 5 if attack else 0
    shadow(im, 12 + ox, 58, 34)
    box(im, 10 + ox, 26, 36, 24, P["boar"])
    R(im, 12 + ox, 28, 32, 20, P["wood"])
    R(im, 14 + ox, 30, 1, 16, P["shade"])
    R(im, 30 + ox, 32, 1, 12, P["shade"])
    # 頭
    box(im, 36 + ox, 22, 18, 18, P["boar"])
    R(im, 38 + ox, 24, 14, 14, P["wood"])
    put(im, 44 + ox, 28, P["ink"])
    put(im, 50 + ox, 28, P["ink"])
    # 獠牙
    R(im, 48 + ox, 36, 4, 7, P["paper"])
    R(im, 42 + ox, 38, 4, 6, P["paper"])
    put(im, 49 + ox, 35, P["ink"])
    put(im, 43 + ox, 37, P["ink"])
    # 鼻
    R(im, 50 + ox, 34, 5, 4, P["ink"])
    put(im, 51 + ox, 35, P["shade"])
    put(im, 53 + ox, 35, P["shade"])
    # 腿
    for lx in (12, 22, 32, 40):
        R(im, lx + ox, 48, 6, 10, P["boot"])
        R(im, lx + ox, 57, 6, 1, P["ink"])
    # 鬃
    R(im, 16 + ox, 20, 20, 7, P["ink"])
    R(im, 18 + ox, 18, 16, 4, P["shade"])
    for i in range(0, 16, 3):
        put(im, 18 + ox + i, 17, P["ink"])
    if attack:
        R(im, 54 + ox, 30, 8, 8, P["boar"])
        R(im, 56 + ox, 32, 4, 6, P["paper"])
        R(im, 50 + ox, 38, 8, 4, P["cinnabar"])


def monster_bandit(im: Image.Image, attack: bool = False) -> None:
    lean = 4 if attack else 0
    bob = -1 if attack else 0
    shadow(im, 17 + lean, 58 + bob, 28)
    legs(im, 20, 44 + bob, P["shade"], lean, 1 if attack else 0)
    torso(im, 18 + lean, 22 + bob, 26, 24, P["cloth_r"], P["ink"])
    face(im, 22 + lean, 8 + bob)
    # 頭巾／面罩
    R(im, 21 + lean, 4 + bob, 18, 6, P["ink"])
    R(im, 22 + lean, 14 + bob, 16, 4, P["ink"])
    put(im, 26 + lean, 16 + bob, P["cinnabar"])
    put(im, 33 + lean, 16 + bob, P["cinnabar"])
    arms(im, 14, 42, 24, lean, bob)
    # 破刀
    wx = 46 + lean + (5 if attack else 0)
    wy = 14 + bob + (-5 if attack else 0)
    R(im, wx, wy, 4, 28, P["stone"])
    R(im, wx + 1, wy + 1, 1, 26, P["ink"])
    R(im, wx + 2, wy - 1, 2, 3, P["paper"])
    R(im, wx - 1, wy + 10, 6, 3, P["wood"])
    # 缺口
    put(im, wx + 3, wy + 8, P["trans"])
    put(im, wx + 3, wy + 16, P["shade"])
    if attack:
        R(im, wx + 3, wy + 2, 10, 4, P["cinnabar"])
        put(im, wx + 10, wy + 3, P["paper"])


HEROES = [
    ("hero_dao_atie", "刀客阿鐵", hero_dao_atie),
    ("hero_jian_aqing", "劍客阿青", hero_jian_aqing),
    ("hero_qiang_achang", "槍客阿長", hero_qiang_achang),
    ("hero_gun_dali", "棍僧大力", hero_gun_dali),
    ("hero_anqi_azhen", "暗衛阿針", hero_anqi_azhen),
    ("hero_quan_aniu", "拳師阿牛", hero_quan_aniu),
]

MONSTERS = [
    ("monster_wolf", "狼", monster_wolf),
    ("monster_boar", "野豬", monster_boar),
    ("monster_bandit", "山賊", monster_bandit),
]


def save(im: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)


def walk_sheet(draw_fn) -> Image.Image:
    sheet = Image.new("RGBA", (SIZE * WALK_FRAMES, SIZE), P["trans"])
    for i in range(WALK_FRAMES):
        fr = nf()
        draw_fn(fr, i)
        sheet.paste(fr, (i * SIZE, 0))
    return sheet


def opaque_count(im: Image.Image) -> int:
    return sum(1 for px in im.getdata() if px[3] > 0)


def sample_palette_ok(im: Image.Image, tol: int = 8) -> tuple[bool, list]:
    bad = []
    for px in im.getdata():
        if px[3] == 0:
            continue
        r, g, b, a = px
        if a < 255:
            bad.append(("alpha", px))
            if len(bad) > 20:
                break
            continue
        ok = any(abs(r - ar) <= tol and abs(g - ag) <= tol and abs(b - ab) <= tol for ar, ag, ab in ALLOWED_RGB)
        if not ok:
            bad.append(("rgb", px))
            if len(bad) > 20:
                break
    return len(bad) == 0, bad[:5]


def make_preview_board(paths: list[str], out: str, cols: int = 6, scale: int = 3) -> None:
    ims = [Image.open(p) for p in paths]
    tiles = []
    for im in ims:
        if im.width > SIZE:
            tiles.append(im.crop((0, 0, SIZE, SIZE)))
        else:
            tiles.append(im)
    rows = (len(tiles) + cols - 1) // cols
    board = Image.new("RGBA", (cols * SIZE, rows * SIZE), P["shade"])
    for i, t in enumerate(tiles):
        board.paste(t, ((i % cols) * SIZE, (i // cols) * SIZE), t)
    save(board, out)
    save(board.resize((board.width * scale, board.height * scale), Image.NEAREST),
         out.replace(".png", f"_x{scale}.png"))


def main() -> None:
    os.makedirs(HERO_DIR, exist_ok=True)
    os.makedirs(MON_DIR, exist_ok=True)
    os.makedirs(PREV_DIR, exist_ok=True)

    files: list[str] = []
    checks: list[str] = []

    for key, name, fn in HEROES:
        idle = nf()
        fn(idle, -1)
        ip = f"{HERO_DIR}/{key}_idle.png"
        save(idle, ip)
        files.append(ip)
        assert idle.size == (SIZE, SIZE), f"{key} idle size"
        assert opaque_count(idle) > 80, f"{key} idle empty"
        ok, bad = sample_palette_ok(idle)
        checks.append(f"- {key}_idle: {SIZE}×{SIZE} px={opaque_count(idle)} palette_ok={ok}" + (f" bad={bad}" if not ok else ""))

        sheet = walk_sheet(fn)
        wp = f"{HERO_DIR}/{key}_walk.png"
        save(sheet, wp)
        files.append(wp)
        assert sheet.size == (SIZE * WALK_FRAMES, SIZE)
        assert opaque_count(sheet) > 80
        checks.append(f"- {key}_walk: {WALK_FRAMES}f {sheet.size[0]}×{sheet.size[1]} px={opaque_count(sheet)}")

    for key, name, fn in MONSTERS:
        idle = nf()
        fn(idle, False)
        ip = f"{MON_DIR}/{key}_idle.png"
        save(idle, ip)
        files.append(ip)
        assert idle.size == (SIZE, SIZE)
        assert opaque_count(idle) > 80
        ok, bad = sample_palette_ok(idle)
        checks.append(f"- {key}_idle: {SIZE}×{SIZE} px={opaque_count(idle)} palette_ok={ok}" + (f" bad={bad}" if not ok else ""))

        atk = nf()
        fn(atk, True)
        ap = f"{MON_DIR}/{key}_attack.png"
        save(atk, ap)
        files.append(ap)
        assert opaque_count(atk) > 80
        checks.append(f"- {key}_attack: px={opaque_count(atk)}")

    hero_prev = [f"{HERO_DIR}/{k}_idle.png" for k, _, _ in HEROES]
    mon_prev = [f"{MON_DIR}/{k}_idle.png" for k, _, _ in MONSTERS]
    make_preview_board(hero_prev + mon_prev, f"{PREV_DIR}/p1_roster64.png", cols=6, scale=3)
    # also x4 alias
    board = Image.open(f"{PREV_DIR}/p1_roster64.png")
    save(board.resize((board.width * 4, board.height * 4), Image.NEAREST), f"{PREV_DIR}/p1_roster_x4.png")
    for key, _, _ in HEROES:
        w = Image.open(f"{HERO_DIR}/{key}_walk.png")
        save(w.resize((w.width * 3, w.height * 3), Image.NEAREST), f"{PREV_DIR}/{key}_walk_x3.png")

    lines = [
        "# 墨點俠村 P1 精靈 MANIFEST",
        "",
        f"- 統一幀尺寸：`{SIZE}×{SIZE}`（綠稀有正式標準；舊 48 備份於 `heroes/_prev_48/`、`monsters/_prev_48/`）",
        f"- Walk sheet：`{WALK_FRAMES}` 幀橫向（{SIZE * WALK_FRAMES}×{SIZE}）",
        "- 風格：硬邊 putpixel／box，Nearest；透明底 PNG；衣褶／腰帶／武器邊緣／硬邊陰影加厚",
        "- 色盤：墨黑 #1A1510／宣紙 #E8DCC8／硃紅 #C43C2C／青綠 #2F6B5A／金邊 #C9A227 + skin/wood/boot/shade/stone 家族微調",
        "- 面向：右／¾ 右",
        "",
        "## 解像階梯（Lemon）",
        "- 白／綠 → **64×64**（本批）",
        "- 藍／紫 → **96×96**",
        "- 橙 → **128×128**",
        "- 紅 → **256×256**",
        "- 顯示：整數倍 Nearest；唔用柔邊放大充解像",
        "",
        "## Heroes",
    ]
    for key, name, _ in HEROES:
        lines.append(f"- **{name}** `{key}_idle.png` / `{key}_walk.png`（{WALK_FRAMES}f，{SIZE}×{SIZE}）")
    lines += ["", "## Monsters"]
    for key, name, _ in MONSTERS:
        lines.append(f"- **{name}** `{key}_idle.png` / `{key}_attack.png`（{SIZE}×{SIZE}）")
    lines += [
        "",
        "## 相對舊 48 加厚重點",
        "- 臉 16×14、軀幹衣褶豎／橫線、金腰帶扣＋綠稀有珠",
        "- 靴底雙硬邊；武器刃口／中脊／護手／穗珠",
        "- 怪：肋褶、鬃刺、獠牙層次、破刀缺口",
        "",
        "## 自檢",
        *checks,
        "",
        f"腳本：`tools/gen_p1_sprites_64.py`",
        f"預覽：`assets/art/_preview/p1_roster64_x3.png`、`p1_roster_x4.png`",
    ]
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    # also update ART.md walk sheet note if present
    print("OK", len(files), "files")
    for p in files:
        print(p)


if __name__ == "__main__":
    main()
