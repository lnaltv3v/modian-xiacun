#!/usr/bin/env python3
"""Postprocess GenerateImage raws into transparent game sprites (MHS density path)."""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

def remove_bg(rgb: np.ndarray, mode: str = "auto") -> np.ndarray:
    """Return RGBA with bg removed. mode: light|dark|auto"""
    h, w = rgb.shape[:2]
    # sample corners for bg guess
    corners = np.stack([
        rgb[2, 2], rgb[2, w-3], rgb[h-3, 2], rgb[h-3, w-3],
        rgb[2, w//2], rgb[h-3, w//2], rgb[h//2, 2], rgb[h//2, w-3],
    ]).astype(np.float32)
    mean_c = corners.mean(axis=0)
    lum = mean_c.mean()
    if mode == "auto":
        mode = "light" if lum > 140 else "dark"
    arr = rgb.astype(np.float32)
    if mode == "light":
        # distance from near-white / light gray
        # also catch checker-like mid-grays near corners
        dist = np.linalg.norm(arr - mean_c, axis=2)
        # light pixels: high luminance and close to bg
        lum_map = arr.mean(axis=2)
        alpha = np.ones((h, w), dtype=np.uint8) * 255
        # strong light bg
        alpha[(lum_map > 210) & (dist < 55)] = 0
        alpha[(lum_map > 235) & (dist < 90)] = 0
        # soft edge near bg
        soft = (lum_map > 185) & (dist < 35)
        alpha[soft] = 0
    else:
        # dark bg
        lum_map = arr.mean(axis=2)
        alpha = np.ones((h, w), dtype=np.uint8) * 255
        alpha[lum_map < 12] = 0
        alpha[(lum_map < 28) & (np.abs(arr[:,:,0]-arr[:,:,1]) < 8) & (np.abs(arr[:,:,1]-arr[:,:,2]) < 8)] = 0
    rgba = np.dstack([rgb, alpha])
    return rgba

def bbox_opaque(rgba: np.ndarray, thr: int = 16):
    a = rgba[:, :, 3]
    ys, xs = np.where(a > thr)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())

def fit_square(rgba: np.ndarray, size: int, pad_frac: float = 0.06) -> Image.Image:
    bb = bbox_opaque(rgba)
    if bb is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x0, y0, x1, y1 = bb
    crop = rgba[y0:y1+1, x0:x1+1]
    ch, cw = crop.shape[:2]
    side = int(max(cw, ch) * (1.0 + pad_frac))
    canvas = np.zeros((side, side, 4), dtype=np.uint8)
    ox = (side - cw) // 2
    oy = (side - ch) // 2
    canvas[oy:oy+ch, ox:ox+cw] = crop
    im = Image.fromarray(canvas, "RGBA")
    # High-quality downscale keeps density; slight sharpen via BOX then NEAREST not needed
    im = im.resize((size, size), Image.Resampling.LANCZOS)
    return im

def process_idle(src: Path, dst: Path, size: int):
    rgb = np.array(Image.open(src).convert("RGB"))
    rgba = remove_bg(rgb, "auto")
    # If mostly transparent, try other mode
    if (rgba[:,:,3] > 16).sum() < 500:
        rgba = remove_bg(rgb, "dark" if remove_bg(rgb,"light")[:,:,3].mean() < 10 else "light")
    out = fit_square(rgba, size)
    dst.parent.mkdir(parents=True, exist_ok=True)
    out.save(dst)
    return out

def split_strip_frames(rgb: np.ndarray, n: int = 4):
    """Split a horizontal strip image into n frames by content columns."""
    h, w = rgb.shape[:2]
    lum = rgb.mean(axis=2)
    # content mask: not near-black and not near-white uniform
    dark = lum < 14
    light = lum > 240
    content = ~(dark | light)
    # also treat near-uniform light gray as bg
    grayish = (np.abs(rgb[:,:,0].astype(int)-rgb[:,:,1].astype(int)) < 10) & (np.abs(rgb[:,:,1].astype(int)-rgb[:,:,2].astype(int)) < 10) & (lum > 200)
    content = content & ~grayish
    cols = np.where(content.any(axis=0))[0]
    if len(cols) < 10:
        # fallback equal split
        fw = w // n
        return [rgb[:, i*fw:(i+1)*fw] for i in range(n)]
    x0, x1 = cols[0], cols[-1]
    # find gaps between characters
    col_has = content.any(axis=0)
    # smooth
    # manual gap find (no scipy)
    regions = []
    in_run = False
    start = 0
    for i in range(x0, x1+1):
        if col_has[i] and not in_run:
            in_run = True
            start = i
        elif not col_has[i] and in_run:
            in_run = False
            regions.append((start, i-1))
    if in_run:
        regions.append((start, x1))
    # merge tiny gaps
    merged = []
    for s,e in regions:
        if not merged:
            merged.append([s,e])
        else:
            if s - merged[-1][1] < max(8, w//80):
                merged[-1][1] = e
            else:
                merged.append([s,e])
    if len(merged) == n:
        frames = [rgb[:, s:e+1] for s,e in merged]
    else:
        # equal divide content span
        span = x1 - x0 + 1
        fw = span // n
        frames = [rgb[:, x0+i*fw:x0+(i+1)*fw] for i in range(n)]
    return frames

def process_strip(src: Path, dst: Path, frame_size: int, n: int = 4):
    rgb = np.array(Image.open(src).convert("RGB"))
    # Prefer dark bg for strips (red walk raws used black)
    frames_rgb = split_strip_frames(rgb, n)
    outs = []
    for fr in frames_rgb:
        rgba = remove_bg(fr, "auto")
        if (rgba[:,:,3] > 16).sum() < 200:
            rgba = remove_bg(fr, "dark")
        outs.append(fit_square(rgba, frame_size))
    sheet = Image.new("RGBA", (frame_size * n, frame_size), (0, 0, 0, 0))
    for i, im in enumerate(outs):
        sheet.paste(im, (i * frame_size, 0), im)
    dst.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dst)
    return sheet

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("kind", choices=["idle", "strip"])
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--size", type=int, required=True)
    args = ap.parse_args()
    if args.kind == "idle":
        process_idle(Path(args.src), Path(args.dst), args.size)
    else:
        process_strip(Path(args.src), Path(args.dst), args.size)
    print("ok", args.dst)

if __name__ == "__main__":
    main()
