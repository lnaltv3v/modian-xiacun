#!/usr/bin/env python3
"""墨點俠村 P1 — 六綠俠 + 狼／野豬／山賊 硬邊像素精靈（48×48）"""
from __future__ import annotations

import os
from collections import Counter
from PIL import Image

SIZE = 48
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
    "cloth_g": (58, 122, 106, 255),  # 綠稀有帶／衣微調
    "cloth_d": (42, 86, 74, 255),
    "cloth_b": (56, 72, 88, 255),    # 暗衛深藍灰（同墨系）
    "cloth_r": (140, 56, 48, 255),   # 硃紅深衣
    "cloth_o": (120, 88, 56, 255),   # 僧褐
    "cloth_y": (168, 140, 72, 255),  # 拳師土黄
    "fur": (138, 126, 110, 255),
    "fur_d": (90, 78, 64, 255),
    "boar": (96, 72, 56, 255),
    "trans": (0, 0, 0, 0),
    "shadow": (26, 21, 16, 90),      # 硬邊少層級陰影
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


def shadow(im: Image.Image, x: int = 14, y: int = 44, w: int = 20) -> None:
    # 硬邊少層級：外圈 shade、內點 ink，唔用半透明柔邊
    R(im, x, y, w, 2, P["shade"])
    R(im, x + 2, y, max(1, w - 4), 1, P["ink"])


def face(im: Image.Image, x: int, y: int, look_right: bool = True) -> None:
    box(im, x, y, 12, 11, P["skin"])
    R(im, x + 1, y + 1, 2, 9, P["skin2"])
    # eyes
    put(im, x + 3, y + 4, P["ink"])
    put(im, x + 8, y + 4, P["ink"])
    if look_right:
        put(im, x + 4, y + 4, P["paper"])
        put(im, x + 9, y + 4, P["paper"])
    R(im, x + 4, y + 7, 4, 2, P["cinnabar"])
    # brows
    R(im, x + 2, y + 2, 3, 1, P["ink"])
    R(im, x + 7, y + 2, 3, 1, P["ink"])


def legs(im: Image.Image, x: int, y: int, robe: tuple, lean: int = 0, step: int = 0) -> None:
    # step: -1 left forward, 0 idle, +1 right forward
    lx = lean + (-2 if step < 0 else (2 if step > 0 else 0))
    rx = lean + (2 if step < 0 else (-2 if step > 0 else 0))
    ly = -1 if step != 0 else 0
    ry = 0 if step != 0 else 0
    if step > 0:
        ly, ry = 0, -1
    R(im, x + lx, y + ly, 6, 8, robe)
    R(im, x + 10 + rx, y + ry, 6, 8, robe)
    R(im, x - 1 + lx, y + 7 + ly, 7, 4, P["boot"])
    R(im, x + 10 + rx, y + 7 + ry, 7, 4, P["boot"])
    R(im, x - 1 + lx, y + 7 + ly, 7, 1, P["ink"])
    R(im, x + 10 + rx, y + 7 + ry, 7, 1, P["ink"])


def torso(im: Image.Image, x: int, y: int, w: int, h: int, robe: tuple, belt: tuple = None) -> None:
    belt = belt or P["gold"]
    box(im, x, y, w, h, robe)
    R(im, x + 1, y + 1, 2, h - 2, P["shade"])
    R(im, x, y + h - 5, w, 4, belt)
    put(im, x + w // 2, y + h - 3, P["teal"])  # 綠稀有小標記
    R(im, x, y + h - 5, w, 1, P["ink"])


def arms(im: Image.Image, x_l: int, x_r: int, y: int, lean: int = 0, bob: int = 0) -> None:
    R(im, x_l + lean, y + bob, 4, 7, P["stone"])
    R(im, x_r + lean, y + bob, 4, 7, P["stone"])
    put(im, x_l + lean, y + bob, P["ink"])
    put(im, x_r + lean + 3, y + bob, P["ink"])


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
    shadow(im, 13 + lean, 44 + bob, 20)
    legs(im, 16, 34 + bob, robe, lean, step)
    torso(im, 14 + lean, 18 + bob, 20, 18, robe)
    face(im, 18 + lean, 7 + bob)
    arms(im, 12, 32, 19, lean, bob)
    if bald:
        R(im, 20 + lean, 4 + bob, 10, 4, P["skin"])
        R(im, 22 + lean, 3 + bob, 6, 2, P["skin"])
        put(im, 24 + lean, 5 + bob, P["ink"])  # 戒疤
    elif hair:
        R(im, 17 + lean, 4 + bob, 14, 4, hair)
        R(im, 19 + lean, 2 + bob, 10, 3, hair)
        R(im, 30 + lean, 6 + bob, 4, 8, hair)  # 右側馬尾／束髮
    if mask:
        R(im, 18 + lean, 12 + bob, 12, 4, P["ink"])
        put(im, 21 + lean, 13 + bob, P["paper"])
        put(im, 26 + lean, 13 + bob, P["paper"])


# —— 六俠 —— #

def hero_dao_atie(im: Image.Image, walk_i: int = -1) -> None:
    """刀客阿鐵 — 寬刀剪影"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_r"], lean, bob, step, hair=P["ink"])
    # 寬刀（右手側，朝右）——厚背薄刃剪影
    wx = 33 + lean + (2 if walk_i >= 0 else 0)
    wy = 10 + bob
    R(im, wx, wy + 4, 5, 24, P["stone"])       # 刀背
    R(im, wx + 4, wy + 6, 3, 20, P["paper"])    # 刃面
    R(im, wx + 5, wy + 8, 2, 14, P["paper"])
    put(im, wx + 6, wy + 5, P["paper"])         # 刀尖略弧
    put(im, wx + 7, wy + 7, P["paper"])
    R(im, wx - 1, wy + 1, 4, 5, P["wood"])      # 柄
    R(im, wx - 2, wy + 14, 9, 3, P["gold"])     # 護手
    R(im, wx - 1, wy + 13, 7, 1, P["ink"])


def hero_jian_aqing(im: Image.Image, walk_i: int = -1) -> None:
    """劍客阿青 — 細長劍"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_g"], lean, bob, step, hair=P["teal"])
    # 青絲長髮
    R(im, 16 + lean, 5 + bob, 16, 3, P["teal"])
    R(im, 30 + lean, 8 + bob, 3, 12, P["teal"])
    wx = 35 + lean + (1 if walk_i >= 0 else 0)
    wy = 10 + bob
    R(im, wx, wy, 2, 26, P["paper"])
    R(im, wx - 1, wy - 1, 4, 2, P["ink"])
    R(im, wx - 2, wy + 8, 6, 2, P["gold"])
    put(im, wx, wy - 2, P["gold"])


def hero_qiang_achang(im: Image.Image, walk_i: int = -1) -> None:
    """槍客阿長 — 長槍超出身高"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_d"], lean, bob, step, hair=P["ink"])
    # 頭巾
    R(im, 17 + lean, 3 + bob, 14, 4, P["cinnabar"])
    R(im, 19 + lean, 2 + bob, 10, 2, P["cinnabar"])
    # 長槍：桿 + 槍尖
    wx = 36 + lean
    R(im, wx, 2 + bob, 3, 40, P["wood"])
    R(im, wx + 1, 2 + bob, 1, 40, P["wood2"])
    # 槍尖朝上偏右
    R(im, wx - 1, 0 + bob, 5, 5, P["stone"])
    R(im, wx, -1 + bob, 3, 3, P["paper"])
    put(im, wx + 1, -2 + bob, P["paper"])
    R(im, wx - 2, 18 + bob, 7, 2, P["gold"])


def hero_gun_dali(im: Image.Image, walk_i: int = -1) -> None:
    """棍僧大力 — 光頭＋木棍"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_o"], lean, bob, step, bald=True)
    # 僧袍金邊袖
    R(im, 12 + lean, 20 + bob, 3, 12, P["gold"])
    R(im, 33 + lean, 20 + bob, 3, 12, P["gold"])
    # 木棍在左側直立
    sx = 6 + lean + (-1 if walk_i >= 0 else 0)
    R(im, sx, 4 + bob, 4, 36, P["wood"])
    R(im, sx + 1, 4 + bob, 1, 36, P["wood2"])
    box(im, sx - 2, 2 + bob, 8, 5, P["gold"])
    R(im, sx, 3 + bob, 4, 2, P["paper"])


def hero_anqi_azhen(im: Image.Image, walk_i: int = -1) -> None:
    """暗衛阿針 — 面具＋飛針／短刺"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step + (1 if walk_i >= 0 else 0)
    bob = -2 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_b"], lean, bob, step, hair=P["ink"], mask=True)
    # 斗篷側影
    R(im, 10 + lean, 16 + bob, 5, 18, P["ink"])
    R(im, 11 + lean, 18 + bob, 3, 14, P["shade"])
    # 雙短刺／飛針
    wx = 34 + lean
    R(im, wx, 14 + bob, 2, 14, P["paper"])
    R(im, wx - 1, 12 + bob, 4, 2, P["gold"])
    R(im, 8 + lean, 18 + bob, 2, 12, P["paper"])
    R(im, 7 + lean, 16 + bob, 4, 2, P["gold"])
    # 飛針軌跡點（walk 時更明顯）
    if walk_i >= 0:
        put(im, 42, 16 + bob, P["paper"])
        put(im, 44, 18 + bob, P["paper"])
        put(im, 46, 20 + bob, P["gold"])


def hero_quan_aniu(im: Image.Image, walk_i: int = -1) -> None:
    """拳師阿牛 — 無長兵器，粗臂握拳"""
    step = 0 if walk_i < 0 else (-1, 0, 1, 0)[walk_i % 4]
    lean = step
    bob = -1 if walk_i >= 0 and walk_i % 2 == 1 else 0
    base_hero(im, P["cloth_y"], lean, bob, step, hair=P["ink"])
    # 頭巾束髮
    R(im, 17 + lean, 3 + bob, 14, 4, P["cinnabar"])
    # 粗臂＋握拳（右側前伸，無長兵器）
    fx = 3 if walk_i >= 0 else 1
    R(im, 31 + lean + fx, 16 + bob, 7, 12, P["skin"])
    box(im, 34 + lean + fx, 24 + bob, 10, 9, P["skin2"])
    R(im, 35 + lean + fx, 25 + bob, 8, 7, P["skin"])
    R(im, 36 + lean + fx, 26 + bob, 2, 5, P["ink"])  # 指縫
    R(im, 39 + lean + fx, 26 + bob, 2, 5, P["ink"])
    # 左側護腕
    R(im, 9 + lean, 20 + bob, 6, 8, P["wood"])
    R(im, 9 + lean, 20 + bob, 6, 1, P["gold"])
    box(im, 8 + lean, 26 + bob, 7, 6, P["skin2"])  # 左拳收腰
    # 胸前布帶
    R(im, 18 + lean, 20 + bob, 12, 2, P["ink"])


# —— 怪物 —— #

def monster_wolf(im: Image.Image, attack: bool = False) -> None:
    ox = 3 if attack else 0
    shadow(im, 12 + ox, 44, 24)
    # 身
    box(im, 10 + ox, 22, 26, 16, P["fur"])
    R(im, 12 + ox, 24, 22, 12, P["fur_d"])
    # 頭
    box(im, 28 + ox, 14, 14, 12, P["fur"])
    R(im, 30 + ox, 16, 10, 8, P["fur_d"])
    put(im, 36 + ox, 18, P["ink"])
    put(im, 40 + ox, 18, P["cinnabar"])
    # 耳
    R(im, 30 + ox, 10, 4, 5, P["fur"])
    R(im, 38 + ox, 10, 4, 5, P["fur"])
    R(im, 31 + ox, 11, 2, 3, P["ink"])
    R(im, 39 + ox, 11, 2, 3, P["ink"])
    # 嘴／牙
    R(im, 38 + ox, 22, 6, 3, P["ink"])
    put(im, 40 + ox, 23, P["paper"])
    put(im, 42 + ox, 23, P["paper"])
    # 腿
    R(im, 12 + ox, 36, 4, 8, P["fur_d"])
    R(im, 20 + ox, 36, 4, 8, P["fur_d"])
    R(im, 28 + ox, 36, 4, 8, P["fur_d"])
    R(im, 34 + ox, 34, 4, 8, P["fur_d"])
    # 尾
    R(im, 6 + ox, 26, 6, 4, P["fur"])
    R(im, 4 + ox, 24, 4, 3, P["fur_d"])
    if attack:
        # 撲咬：頭更前、爪
        R(im, 40 + ox, 20, 6, 4, P["fur"])
        R(im, 42 + ox, 18, 4, 2, P["paper"])
        R(im, 36 + ox, 32, 8, 3, P["ink"])
        put(im, 42 + ox, 31, P["cinnabar"])


def monster_boar(im: Image.Image, attack: bool = False) -> None:
    ox = 4 if attack else 0
    shadow(im, 10 + ox, 44, 26)
    box(im, 8 + ox, 20, 28, 18, P["boar"])
    R(im, 10 + ox, 22, 24, 14, P["wood"])
    # 頭
    box(im, 28 + ox, 18, 14, 14, P["boar"])
    R(im, 30 + ox, 20, 10, 10, P["wood"])
    put(im, 36 + ox, 22, P["ink"])
    put(im, 40 + ox, 22, P["ink"])
    # 獠牙
    R(im, 38 + ox, 28, 3, 5, P["paper"])
    R(im, 34 + ox, 30, 3, 4, P["paper"])
    put(im, 39 + ox, 27, P["ink"])
    put(im, 35 + ox, 29, P["ink"])
    # 鼻
    R(im, 40 + ox, 26, 4, 3, P["ink"])
    # 腿
    for lx in (10, 18, 26, 32):
        R(im, lx + ox, 36, 5, 8, P["boot"])
    # 鬃
    R(im, 14 + ox, 16, 16, 5, P["ink"])
    R(im, 16 + ox, 14, 12, 3, P["shade"])
    if attack:
        R(im, 42 + ox, 24, 6, 6, P["boar"])
        R(im, 44 + ox, 26, 3, 5, P["paper"])
        R(im, 40 + ox, 30, 6, 3, P["cinnabar"])


def monster_bandit(im: Image.Image, attack: bool = False) -> None:
    lean = 3 if attack else 0
    bob = -1 if attack else 0
    shadow(im, 13 + lean, 44 + bob, 20)
    legs(im, 16, 34 + bob, P["shade"], lean, 1 if attack else 0)
    torso(im, 14 + lean, 18 + bob, 20, 18, P["cloth_r"], P["ink"])
    face(im, 18 + lean, 7 + bob)
    # 頭巾／面罩
    R(im, 17 + lean, 4 + bob, 14, 5, P["ink"])
    R(im, 18 + lean, 12 + bob, 12, 3, P["ink"])
    put(im, 21 + lean, 13 + bob, P["cinnabar"])
    put(im, 26 + lean, 13 + bob, P["cinnabar"])
    arms(im, 12, 32, 19, lean, bob)
    # 破刀
    wx = 34 + lean + (4 if attack else 0)
    wy = 12 + bob + (-4 if attack else 0)
    R(im, wx, wy, 3, 20, P["stone"])
    R(im, wx + 1, wy - 1, 1, 2, P["paper"])
    R(im, wx - 1, wy + 8, 5, 2, P["wood"])
    if attack:
        R(im, wx + 2, wy + 2, 8, 3, P["cinnabar"])


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
        # 直接覆寫像素，避免 RGBA paste+mask 把陰影 alpha 合成壞色
        sheet.paste(fr, (i * SIZE, 0))
    return sheet


def opaque_count(im: Image.Image) -> int:
    return sum(1 for px in im.getdata() if px[3] > 0)


def sample_palette_ok(im: Image.Image, tol: int = 8) -> tuple[bool, list]:
    """抽樣：非透明像素 RGB 須接近允許色盤（±tol）。"""
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


def make_preview_board(paths: list[str], out: str, cols: int = 6) -> None:
    ims = [Image.open(p) for p in paths]
    # normalize to first frame size for sheets: take left SIZE crop
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
    save(board.resize((board.width * 4, board.height * 4), Image.NEAREST), out.replace(".png", "_x4.png"))


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
        assert opaque_count(idle) > 50, f"{key} idle empty"
        ok, bad = sample_palette_ok(idle)
        checks.append(f"- {key}_idle: px={opaque_count(idle)} palette_ok={ok}" + (f" bad={bad}" if not ok else ""))

        sheet = walk_sheet(fn)
        wp = f"{HERO_DIR}/{key}_walk.png"
        save(sheet, wp)
        files.append(wp)
        assert sheet.size == (SIZE * WALK_FRAMES, SIZE)
        assert opaque_count(sheet) > 50
        checks.append(f"- {key}_walk: {WALK_FRAMES}f {sheet.size[0]}×{sheet.size[1]} px={opaque_count(sheet)}")

    for key, name, fn in MONSTERS:
        idle = nf()
        fn(idle, False)
        ip = f"{MON_DIR}/{key}_idle.png"
        save(idle, ip)
        files.append(ip)
        assert opaque_count(idle) > 50
        ok, bad = sample_palette_ok(idle)
        checks.append(f"- {key}_idle: px={opaque_count(idle)} palette_ok={ok}" + (f" bad={bad}" if not ok else ""))

        atk = nf()
        fn(atk, True)
        ap = f"{MON_DIR}/{key}_attack.png"
        save(atk, ap)
        files.append(ap)
        assert opaque_count(atk) > 50
        checks.append(f"- {key}_attack: px={opaque_count(atk)}")

    # previews
    hero_prev = [f"{HERO_DIR}/{k}_idle.png" for k, _, _ in HEROES]
    mon_prev = [f"{MON_DIR}/{k}_idle.png" for k, _, _ in MONSTERS]
    make_preview_board(hero_prev + mon_prev, f"{PREV_DIR}/p1_roster.png", cols=6)
    # walk strip preview (first hero)
    for key, _, _ in HEROES:
        w = Image.open(f"{HERO_DIR}/{key}_walk.png")
        save(w.resize((w.width * 4, w.height * 4), Image.NEAREST), f"{PREV_DIR}/{key}_walk_x4.png")

    lines = [
        "# 墨點俠村 P1 精靈 MANIFEST",
        "",
        f"- 統一幀尺寸：`{SIZE}×{SIZE}`",
        f"- Walk sheet：`{WALK_FRAMES}` 幀橫向（{SIZE * WALK_FRAMES}×{SIZE}）",
        "- 風格：硬邊 putpixel／box，Nearest；透明底 PNG",
        "- 色盤：墨黑 #1A1510／宣紙 #E8DCC8／硃紅 #C43C2C／青綠 #2F6B5A／金邊 #C9A227 + skin/wood/boot/shade/stone 家族微調",
        "- 面向：右／¾ 右",
        "",
        "## Heroes",
    ]
    for key, name, _ in HEROES:
        lines.append(f"- **{name}** `{key}_idle.png` / `{key}_walk.png`（{WALK_FRAMES}f）")
    lines += ["", "## Monsters"]
    for key, name, _ in MONSTERS:
        lines.append(f"- **{name}** `{key}_idle.png` / `{key}_attack.png`")
    lines += ["", "## 自檢", *checks, "", f"腳本：`tools/gen_p1_sprites.py`", f"預覽：`assets/art/_preview/p1_roster_x4.png`"]
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("OK", len(files), "files")
    for p in files:
        print(p)


if __name__ == "__main__":
    main()
