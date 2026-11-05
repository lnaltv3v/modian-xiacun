#!/usr/bin/env python3
"""Synthesize 4-frame walk/attack sheets from a single idle sprite (pixel-safe)."""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, ImageChops

def to_arr(im):
    return np.array(im.convert('RGBA'))

def from_arr(a):
    return Image.fromarray(a.astype(np.uint8), 'RGBA')

def shift(im, dx, dy):
    return ImageChops.offset(im, dx, dy)

def bob_walk(idle: Image.Image, size: int) -> Image.Image:
    """Create walk sheet: slight vertical bob + horizontal sway + lower-body squash feel."""
    base = idle.resize((size, size), Image.Resampling.NEAREST) if idle.size != (size, size) else idle.copy()
    frames = []
    # offsets mimicking stride
    params = [
        (0, 0, 0),     # plant
        (1, -1, 1),    # lift
        (0, 0, 0),     # plant other
        (-1, -1, -1),  # lift other
    ]
    arr0 = to_arr(base)
    h, w = arr0.shape[:2]
    for dx, dy, leg in params:
        a = arr0.copy()
        # shift whole body slightly
        canvas = np.zeros_like(a)
        xs = max(0, dx); xd = max(0, -dx)
        ys = max(0, dy); yd = max(0, -dy)
        cw = w - abs(dx); ch = h - abs(dy)
        if cw > 0 and ch > 0:
            canvas[yd:yd+ch, xd:xd+cw] = a[ys:ys+ch, xs:xs+cw]
        # lower half horizontal shear for stride illusion
        mid = h // 2
        lower = canvas[mid:].copy()
        shear = leg * 2
        new_lower = np.zeros_like(lower)
        for row in range(lower.shape[0]):
            s = int(shear * (row / max(1, lower.shape[0]-1)))
            if s >= 0:
                new_lower[row, s:] = lower[row, :w-s] if s < w else 0
            else:
                new_lower[row, :w+s] = lower[row, -s:]
        canvas[mid:] = new_lower
        frames.append(from_arr(canvas))
    sheet = Image.new('RGBA', (size*4, size), (0,0,0,0))
    for i,f in enumerate(frames):
        sheet.paste(f, (i*size, 0), f)
    return sheet

def bob_attack(idle: Image.Image, size: int) -> Image.Image:
    """Attack: wind-up, lunge, impact flash-ish, recover."""
    base = idle.resize((size, size), Image.Resampling.NEAREST) if idle.size != (size, size) else idle.copy()
    arr0 = to_arr(base)
    h, w = arr0.shape[:2]
    frames = []
    # (dx, dy, scale_x_pct, bright)
    params = [
        (-3, 1, 0.96, 1.0),   # windup back
        (4, -1, 1.04, 1.05),  # lunge
        (6, 0, 1.08, 1.15),   # impact
        (1, 0, 1.0, 1.0),     # recover
    ]
    for dx, dy, sx, br in params:
        im = from_arr(arr0)
        nw = max(1, int(w * sx)); nh = h
        im2 = im.resize((nw, nh), Image.Resampling.NEAREST)
        canvas = Image.new('RGBA', (w, h), (0,0,0,0))
        ox = (w - nw)//2 + dx
        oy = dy
        canvas.paste(im2, (ox, oy), im2)
        if br != 1.0:
            # brighten opaque pixels
            a = to_arr(canvas).astype(np.float32)
            mask = a[:,:,3] > 0
            a[mask,0:3] = np.clip(a[mask,0:3] * br, 0, 255)
            canvas = from_arr(a)
        frames.append(canvas)
    sheet = Image.new('RGBA', (size*4, size), (0,0,0,0))
    for i,f in enumerate(frames):
        sheet.paste(f, (i*size, 0), f)
    return sheet

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('kind', choices=['walk','attack'])
    ap.add_argument('idle')
    ap.add_argument('dst')
    ap.add_argument('--size', type=int, required=True)
    args = ap.parse_args()
    idle = Image.open(args.idle).convert('RGBA')
    out = bob_walk(idle, args.size) if args.kind=='walk' else bob_attack(idle, args.size)
    Path(args.dst).parent.mkdir(parents=True, exist_ok=True)
    out.save(args.dst)
    print('ok', args.dst)

if __name__ == '__main__':
    main()
