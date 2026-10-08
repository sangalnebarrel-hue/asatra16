#!/usr/bin/env python3
"""Top-down map render of a place (PNG). Usage: topdown.py PLACE OUT.png [x0 z0 x1 z1 px_per_stud] [--labels]"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxl  # noqa: E402
import scene  # noqa: E402


def corners(p):
    hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
    out = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                out.append(p.cf * (sx * hx, sy * hy, sz * hz))
    return out


def hull(pts):
    pts = sorted(set(pts))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, hi = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
            hi.pop()
        hi.append(p)
    return lo[:-1] + hi[:-1]


def render(doc, out, x0, z0, x1, z1, ppx, labels=False, ymax=None):
    W, H = int((x1 - x0) * ppx), int((z1 - z0) * ppx)
    img = Image.new("RGB", (W, H), (40, 70, 110))
    dr = ImageDraw.Draw(img)
    ps = [p for p in scene.parts(doc) if p.transp < 0.95]
    items = []
    for p in ps:
        cs = corners(p)
        top = max(c[1] for c in cs)
        if ymax is not None and top > ymax:
            continue
        if p.shape == "Ball" or p.shape == "Cylinder":
            pass
        items.append((top, p, cs))
    items.sort(key=lambda t: t[0])
    for top, p, cs in items:
        pts = hull([(round((c[0] - x0) * ppx, 1), round((c[2] - z0) * ppx, 1)) for c in cs])
        if len(pts) < 3:
            continue
        shade = max(0.55, min(1.15, 0.75 + top / 120))
        col = tuple(int(max(0, min(255, v * 255 * shade))) for v in p.color)
        if p.mat == "Neon":
            col = tuple(min(255, int(v * 255 * 1.3)) for v in p.color)
        if p.transp > 0.3:
            col = tuple(int(c * (1 - p.transp * 0.6) + 120 * p.transp * 0.6) for c in col)
        dr.polygon(pts, fill=col)
    # grid every 50 studs
    for gx in range(int(math.ceil(x0 / 50)) * 50, int(x1), 50):
        X = (gx - x0) * ppx
        dr.line([(X, 0), (X, H)], fill=(255, 255, 255) if gx == 0 else (90, 90, 90), width=1)
        dr.text((X + 2, 2), str(gx), fill=(255, 255, 0))
    for gz in range(int(math.ceil(z0 / 50)) * 50, int(z1), 50):
        Z = (gz - z0) * ppx
        dr.line([(0, Z), (W, Z)], fill=(255, 255, 255) if gz == 0 else (90, 90, 90), width=1)
        dr.text((2, Z + 2), str(gz), fill=(255, 255, 0))
    if labels:
        district = doc.find_path("Workspace/DOGROTS_District")
        for k in doc.kids(district):
            ps2 = [p for p in ps if p.area == doc.name(k)]
            if not ps2:
                continue
            cx = sum(p.cf.p[0] for p in ps2) / len(ps2)
            cz = sum(p.cf.p[2] for p in ps2) / len(ps2)
            X, Z = (cx - x0) * ppx, (cz - z0) * ppx
            dr.text((X, Z), doc.name(k), fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
    img.save(out)
    print("wrote", out, W, H)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    doc = rbxl.Doc.load(args[0])
    x0, z0, x1, z1, ppx = (float(v) for v in args[2:7]) if len(args) >= 7 else (-240, -380, 240, 800, 1.5)
    ymax = float(args[7]) if len(args) >= 8 else None
    render(doc, args[1], x0, z0, x1, z1, ppx, "--labels" in sys.argv, ymax)
