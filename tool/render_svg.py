#!/usr/bin/env python3
"""Rasterize a simple (path-only, fill) SVG to a square PNG.

Handles the subset of SVG path grammar used by the app logo:
  M/m moveto, L/l lineto, H/h, V/v, C/c cubic bezier, Z/z close.
Applies the outer <g transform="translate(...) scale(...)"> if present.
Cubic beziers are flattened; polygons are filled with even-odd winding
(so holes/counters render correctly), then downsampled for AA.

Usage: render_svg.py <in.svg> <out.png> <size> <bg: white|none>
"""
import re
import sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw


def tokenize_path(d):
    # split into commands + numbers
    tokens = re.findall(r"[MmLlHhVvCcSsQqTtAaZz]|-?\d*\.?\d+(?:e[-+]?\d+)?", d)
    return tokens


def parse_path(d):
    """Return a list of subpaths, each a list of (x, y) points (beziers flattened)."""
    toks = tokenize_path(d)
    i = 0
    cx = cy = 0.0          # current point
    sx = sy = 0.0          # subpath start
    cmd = None
    subpaths = []
    cur = []

    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v

    def flatten_cubic(p0, p1, p2, p3, steps=24):
        pts = []
        for s in range(1, steps + 1):
            t = s / steps
            mt = 1 - t
            x = (mt**3)*p0[0] + 3*(mt**2)*t*p1[0] + 3*mt*(t**2)*p2[0] + (t**3)*p3[0]
            y = (mt**3)*p0[1] + 3*(mt**2)*t*p1[1] + 3*mt*(t**2)*p2[1] + (t**3)*p3[1]
            pts.append((x, y))
        return pts

    while i < len(toks):
        t = toks[i]
        if re.match(r"[A-Za-z]", t):
            cmd = t; i += 1
        rel = cmd.islower()
        c = cmd.upper()

        if c == "M":
            x = num(); y = num()
            if rel: x += cx; y += cy
            if cur: subpaths.append(cur)
            cur = [(x, y)]
            cx, cy = x, y
            sx, sy = x, y
            cmd = "l" if rel else "L"   # subsequent pairs are lineto
        elif c == "L":
            x = num(); y = num()
            if rel: x += cx; y += cy
            cur.append((x, y)); cx, cy = x, y
        elif c == "H":
            x = num()
            if rel: x += cx
            cur.append((x, cy)); cx = x
        elif c == "V":
            y = num()
            if rel: y += cy
            cur.append((cx, y)); cy = y
        elif c == "C":
            x1 = num(); y1 = num(); x2 = num(); y2 = num(); x = num(); y = num()
            if rel:
                x1 += cx; y1 += cy; x2 += cx; y2 += cy; x += cx; y += cy
            cur.extend(flatten_cubic((cx, cy), (x1, y1), (x2, y2), (x, y)))
            cx, cy = x, y
        elif c == "Z":
            if cur:
                cur.append((sx, sy))
                subpaths.append(cur)
                cur = []
            cx, cy = sx, sy
        else:
            # unsupported command: skip a token to avoid infinite loop
            i += 1
    if cur:
        subpaths.append(cur)
    return subpaths


def get_group_transform(g):
    tr = g.get("transform", "")
    tx = ty = 0.0
    sxf = syf = 1.0
    m = re.search(r"translate\(([-\d.]+)[ ,]+([-\d.]+)\)", tr)
    if m:
        tx, ty = float(m.group(1)), float(m.group(2))
    m = re.search(r"scale\(([-\d.]+)(?:[ ,]+([-\d.]+))?\)", tr)
    if m:
        sxf = float(m.group(1))
        syf = float(m.group(2)) if m.group(2) else sxf
    return tx, ty, sxf, syf


def main():
    src, out = sys.argv[1], sys.argv[2]
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
    bg = sys.argv[4] if len(sys.argv) > 4 else "white"
    # fraction of the canvas the artwork should occupy (for adaptive-icon padding)
    content = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0

    ns = {"svg": "http://www.w3.org/2000/svg"}
    tree = ET.parse(src)
    root = tree.getroot()

    # viewBox
    vb = root.get("viewBox")
    if vb:
        _, _, vbw, vbh = [float(v) for v in vb.split()]
    else:
        vbw = vbh = 1200.0

    # collect paths with their group transform
    polys = []  # list of subpaths in viewBox space
    for g in root.iter():
        if g.tag.endswith("}g") or g.tag == "g":
            tx, ty, sxf, syf = get_group_transform(g)
            for p in g:
                if p.tag.endswith("}path") or p.tag == "path":
                    for sp in parse_path(p.get("d", "")):
                        polys.append([(tx + x * sxf, ty + y * syf) for (x, y) in sp])

    if not polys:
        # paths might be direct children
        for p in root.iter():
            if p.tag.endswith("}path") or p.tag == "path":
                for sp in parse_path(p.get("d", "")):
                    polys.append(sp)

    ss = 4
    target = size * ss

    # Compute the true bounding box of the drawn geometry (the viewBox often
    # has empty margins), then fit *that* into the square so the coin is
    # visually centered.
    xs = [pt[0] for sp in polys for pt in sp]
    ys = [pt[1] for sp in polys for pt in sp]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    bw = maxx - minx
    bh = maxy - miny

    scale = min(target / bw, target / bh) * content
    ox = (target - bw * scale) / 2 - minx * scale
    oy = (target - bh * scale) / 2 - miny * scale

    def tf(pt):
        return (ox + pt[0] * scale, oy + pt[1] * scale)

    # Even-odd fill: paint each subpath with XOR so counters become holes.
    ink = Image.new("L", (target, target), 0)
    for sp in polys:
        if len(sp) < 3:
            continue
        layer = Image.new("L", (target, target), 0)
        ld = ImageDraw.Draw(layer)
        ld.polygon([tf(pt) for pt in sp], fill=255)
        # XOR into accumulator (even-odd across subpaths)
        from PIL import ImageChops
        ink = ImageChops.difference(ink, layer)

    canvas = Image.new("RGBA", (target, target),
                       (255, 255, 255, 255) if bg == "white" else (0, 0, 0, 0))
    black = Image.new("RGBA", (target, target), (17, 17, 17, 255))
    canvas = Image.composite(black, canvas, ink)

    canvas = canvas.resize((size, size), Image.LANCZOS)
    canvas.save(out)
    print(f"wrote {out} ({size}x{size}) bg={bg} content={content} subpaths={len(polys)}")


if __name__ == "__main__":
    main()
