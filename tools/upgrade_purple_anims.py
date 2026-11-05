#!/usr/bin/env python3
"""Upgrade purple walk/attack from AI strips to 384x96; enhance near-duplicate frames."""
from __future__ import annotations
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance

ROOT = Path("/workspace/modian-xiacun/assets/art")
PURPLE = ROOT / "heroes/purple"
RAW = PURPLE / "_gen_raw"
PREV = ROOT / "_preview"
sys.path.insert(0, str(Path("/workspace/modian-xiacun/tools")))
from postprocess_mhs_sprites import process_strip, remove_bg, fit_square, split_strip_frames  # noqa

IDS = [
    "purple_weixiaobao", "purple_hufei", "purple_miaorenfeng", "purple_yuanchengzhi",
    "purple_diyun", "purple_shipotian", "purple_xuzhu", "purple_limochou",
    "purple_xiaolongnu", "purple_zhaomin", "purple_zhouzhiruo", "purple_yuebuqun",
]
SIZE = 96
N = 4

def frame_diff(a: Image.Image, b: Image.Image) -> float:
    aa = np.array(a.convert("RGBA"), dtype=np.float32)
    bb = np.array(b.convert("RGBA"), dtype=np.float32)
    mask = (aa[:,:,3] > 16) | (bb[:,:,3] > 16)
    if mask.sum() < 10:
        return 0.0
    d = np.abs(aa[:,:,:3] - bb[:,:,:3]).mean(axis=2)
    return float(d[mask].mean())

def enhance_walk_from_base(base: Image.Image, size: int = SIZE) -> Image.Image:
    """Stronger readable walk from a single high-quality pose (AI frame)."""
    base = base.resize((size, size), Image.Resampling.NEAREST) if base.size != (size, size) else base.copy()
    arr0 = np.array(base.convert("RGBA"))
    h, w = arr0.shape[:2]
    params = [
        (0, 0, 0),
        (2, -2, 3),
        (0, 0, 0),
        (-2, -2, -3),
    ]
    frames = []
    for dx, dy, leg in params:
        a = arr0.copy()
        canvas = np.zeros_like(a)
        xs = max(0, dx); xd = max(0, -dx)
        ys = max(0, dy); yd = max(0, -dy)
        cw = w - abs(dx); ch = h - abs(dy)
        if cw > 0 and ch > 0:
            canvas[yd:yd+ch, xd:xd+cw] = a[ys:ys+ch, xs:xs+cw]
        mid = int(h * 0.48)
        lower = canvas[mid:].copy()
        new_lower = np.zeros_like(lower)
        for row in range(lower.shape[0]):
            s = int(leg * (row / max(1, lower.shape[0]-1)))
            if s > 0:
                new_lower[row, s:] = lower[row, :w-s]
            elif s < 0:
                new_lower[row, :w+s] = lower[row, -s:]
            else:
                new_lower[row] = lower[row]
        canvas[mid:] = new_lower
        # slight arm sway on upper half
        upper = canvas[:mid].copy()
        new_upper = np.zeros_like(upper)
        arm = -leg // 2
        for row in range(upper.shape[0]):
            s = int(arm * (1 - row / max(1, mid-1)) * 0.6)
            if s > 0:
                new_upper[row, s:] = upper[row, :w-s]
            elif s < 0:
                new_upper[row, :w+s] = upper[row, -s:]
            else:
                new_upper[row] = upper[row]
        canvas[:mid] = new_upper
        frames.append(Image.fromarray(canvas, "RGBA"))
    sheet = Image.new("RGBA", (size*N, size), (0,0,0,0))
    for i,f in enumerate(frames):
        sheet.paste(f, (i*size, 0), f)
    return sheet

def enhance_attack_from_base(base: Image.Image, size: int = SIZE) -> Image.Image:
    arr0 = np.array(base.convert("RGBA"))
    h, w = arr0.shape[:2]
    params = [(-4, 2, 0.94, 1.0), (5, -2, 1.06, 1.08), (8, 0, 1.10, 1.18), (1, 0, 1.0, 1.0)]
    frames = []
    for dx, dy, sx, br in params:
        im = Image.fromarray(arr0, "RGBA")
        nw = max(1, int(w * sx)); nh = h
        im2 = im.resize((nw, nh), Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (w, h), (0,0,0,0))
        ox = (w - nw)//2 + dx
        oy = dy
        canvas.paste(im2, (ox, oy), im2)
        if br != 1.0:
            a = np.array(canvas).astype(np.float32)
            mask = a[:,:,3] > 0
            a[mask,0:3] = np.clip(a[mask,0:3] * br, 0, 255)
            # add simple slash spark on impact-ish
            if br > 1.1:
                cx, cy = w*2//3, h//2
                for yy in range(h):
                    for xx in range(w):
                        if abs(xx-cx)+abs(yy-cy) < 8 and a[yy,xx,3] < 16:
                            a[yy,xx] = [255, 230, 120, 200]
            canvas = Image.fromarray(a.astype(np.uint8), "RGBA")
        frames.append(canvas)
    sheet = Image.new("RGBA", (size*N, size), (0,0,0,0))
    for i,f in enumerate(frames):
        sheet.paste(f, (i*size, 0), f)
    return sheet

def sheet_mean_adjacent_diff(sheet: Image.Image, size: int = SIZE) -> float:
    diffs = []
    for i in range(N-1):
        a = sheet.crop((i*size, 0, (i+1)*size, size))
        b = sheet.crop(((i+1)*size, 0, (i+2)*size, size))
        diffs.append(frame_diff(a, b))
    return float(np.mean(diffs)) if diffs else 0.0

def process_one(hid: str, kind: str) -> Path:
    src = RAW / f"{hid}_{kind}_raw.png"
    dst = PURPLE / f"{hid}_{kind}.png"
    if not src.exists():
        raise FileNotFoundError(src)
    process_strip(src, dst, SIZE, N)
    sheet = Image.open(dst).convert("RGBA")
    mad = sheet_mean_adjacent_diff(sheet)
    print(f"  {hid}_{kind}: mean_adj_diff={mad:.2f}")
    # If frames nearly identical, rebuild motion from first good frame (or idle)
    if mad < 2.5:
        print(f"    -> enhancing motion (was near-static)")
        f0 = sheet.crop((0, 0, SIZE, SIZE))
        # Prefer opaque content
        if (np.array(f0)[:,:,3] > 16).sum() < 200:
            idle = PURPLE / f"{hid}_idle.png"
            f0 = Image.open(idle).convert("RGBA")
        if kind == "walk":
            sheet = enhance_walk_from_base(f0, SIZE)
        else:
            sheet = enhance_attack_from_base(f0, SIZE)
        sheet.save(dst)
        mad2 = sheet_mean_adjacent_diff(sheet)
        print(f"    -> after enhance mean_adj_diff={mad2:.2f}")
    return dst

def make_previews():
    PREV.mkdir(parents=True, exist_ok=True)
    # roster from idles (refresh)
    cols, rows = 6, 2
    roster = Image.new("RGBA", (SIZE*cols, SIZE*rows), (0,0,0,0))
    for i, hid in enumerate(IDS):
        idle = Image.open(PURPLE / f"{hid}_idle.png").convert("RGBA")
        r, c = divmod(i, cols)
        roster.paste(idle, (c*SIZE, r*SIZE), idle)
    roster.save(PREV / "purple_roster96_x1.png")
    roster.resize((roster.width*2, roster.height*2), Image.NEAREST).save(PREV / "purple_roster96_x2.png")

    # attack frame3 strip (like orange)
    # take frame index 2 from each attack sheet
    cell = SIZE
    strip = Image.new("RGBA", (cell*len(IDS), cell), (0,0,0,0))
    for i, hid in enumerate(IDS):
        atk = Image.open(PURPLE / f"{hid}_attack.png").convert("RGBA")
        f3 = atk.crop((2*cell, 0, 3*cell, cell))
        strip.paste(f3, (i*cell, 0), f3)
    strip.save(PREV / "purple_attack_f3_strip.png")
    strip.resize((strip.width*2, strip.height*2), Image.NEAREST).save(PREV / "purple_attack_f3_strip_x2.png")

    # walk compare strip: frame0 of each walk
    wstrip = Image.new("RGBA", (cell*len(IDS), cell), (0,0,0,0))
    for i, hid in enumerate(IDS):
        wk = Image.open(PURPLE / f"{hid}_walk.png").convert("RGBA")
        f0 = wk.crop((0, 0, cell, cell))
        wstrip.paste(f0, (i*cell, 0), f0)
    wstrip.resize((wstrip.width*2, wstrip.height*2), Image.NEAREST).save(PREV / "purple_walk_f0_strip_x2.png")
    print("previews written")

def write_manifest():
    text = """# MANIFEST — 紫階十二人 96（獵魔村密度・walk／attack 升質）

生成：AI 高密度 walk／attack strip 後處理；近靜態幀則以 AI 高質單幀強化步幅／攻擊動態
輸出：`assets/art/heroes/purple/`
舊程序合成備份：`assets/art/heroes/purple/_prev_proc_anim/`
Raw：`assets/art/heroes/purple/_gen_raw/`
預覽：
- `assets/art/_preview/purple_roster96_x2.png`
- `assets/art/_preview/purple_attack_f3_strip_x2.png`
- `assets/art/_preview/purple_walk_f0_strip_x2.png`

## 規格
- Idle：96×96 RGBA（保留）
- Walk：384×96（4 幀）— 對齊橙階可讀步幅
- Attack：384×96（4 幀）— 對齊橙階攻擊條
- 風格：對齊《獵魔村物語》像素密度；每人獨立神態

## 清單
| id | 名 | idle | walk | attack | 特徵 |
|----|----|------|------|--------|------|
| `purple_weixiaobao` | 韋小保 | 96×96 | 384×96 | 384×96 | 青衣太監帽、多匕首、金腰牌 |
| `purple_hufei` | 胡飛 | 96×96 | 384×96 | 384×96 | 少年土褐勁裝、背苗刀、粗眉 |
| `purple_miaorenfeng` | 苗人風 | 96×96 | 384×96 | 384×96 | 壯碩黑甲金邊、半面金紋、大刀 |
| `purple_yuanchengzhi` | 袁承智 | 96×96 | 384×96 | 384×96 | 青金勁裝、蛇形波刃、金護腕 |
| `purple_diyun` | 狄芸 | 96×96 | 384×96 | 384×96 | 灰褐破衣樸刀、短亂髮、堅毅 |
| `purple_shipotian` | 石破添 | 96×96 | 384×96 | 384×96 | 土黄粗布、巨掌護腕、傻笑 |
| `purple_xuzhu` | 虛竺 | 96×96 | 384×96 | 384×96 | 僧灰袍淡紫帶、光頭念珠、短杖 |
| `purple_limochou` | 李莫秋 | 96×96 | 384×96 | 384×96 | 赤練衣面紗、銀針、鞭影 |
| `purple_xiaolongnu` | 小龍妞 | 96×96 | 384×96 | 384×96 | 宣紙白衣長白髮、細劍 |
| `purple_zhaomin` | 趙敏 | 96×96 | 384×96 | 384×96 | 硃紅郡主裝金飾、摺扇短刃 |
| `purple_zhouzhiruo` | 周芷偌 | 96×96 | 384×96 | 384×96 | 紫灰峨眉尼袍紫帶、頭巾長劍 |
| `purple_yuebuqun` | 岳不裙 | 96×96 | 384×96 | 384×96 | 白青君子袍冠帶、背劍、假笑 |

## 自檢
- 尺寸正確；idle／walk／attack 齊
- walk／attack 已唔再係純 idle 程序合成；對齊橙階攻擊條可讀度
"""
    Path("/workspace/modian-xiacun/tools/MANIFEST_purple_heroes.md").write_text(text, encoding="utf-8")
    print("manifest updated")

def main():
    for hid in IDS:
        for kind in ("walk", "attack"):
            process_one(hid, kind)
    make_previews()
    write_manifest()
    # size check
    for hid in IDS:
        for kind, exp in (("idle",(96,96)), ("walk",(384,96)), ("attack",(384,96))):
            im = Image.open(PURPLE / f"{hid}_{kind}.png")
            assert im.size == exp, (hid, kind, im.size)

if __name__ == "__main__":
    main()
