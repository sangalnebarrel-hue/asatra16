#!/usr/bin/env python3
"""Preview renders of a place (approximate Roblox look: sun + sky + shadows + neon bloom).

    preview.py PLACE.rbxl OUT_PREFIX [--night] [--views name,name] [--size 1280x720]

Views are defined in VIEWS below (eye, target). The rasterizer binary is built on demand.
"""
import math
import os
import struct
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import rbxl  # noqa: E402
import scene  # noqa: E402

RASTER = os.environ.get("RASTER_BIN", os.path.join(os.environ.get("TMPDIR", "/tmp"), "dogrots_raster"))

VIEWS = {
    "overview": ((-330, 260, 980), (0, 0, 180)),
    "overview_n": ((260, 240, -620), (0, 0, 100)),
    "yards": ((-120, 60, 180), (0, 10, -60)),
    "factory": ((0, 40, 40), (0, 30, -200)),
    "boulevard": ((0, 14, 760), (0, 8, 300)),
    "hub": ((60, 30, 470), (-20, 10, 300)),
    "museum": ((40, 40, 600), (-110, 25, 480)),
    "south": ((160, 90, 820), (-40, 0, 560)),
    "yard_close": ((-60, 25, -10), (-130, 8, -90)),
}


def box_tris(cf, s):
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    c = [cf * (x, y, z) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]
    # index = xi*4 + yi*2 + zi
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    out = []
    for a, b, cc, d in faces:
        out.append((c[a], c[b], c[cc]))
        out.append((c[a], c[cc], c[d]))
    return out


def wedge_tris(cf, s):
    # Roblox wedge: slope rises from front (-Z... ) : full height at back (+Z), zero at front (-Z)
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    P = lambda x, y, z: cf * (x, y, z)  # noqa: E731
    b0, b1, b2, b3 = P(-hx, -hy, -hz), P(hx, -hy, -hz), P(hx, -hy, hz), P(-hx, -hy, hz)
    t2, t3 = P(hx, hy, hz), P(-hx, hy, hz)
    return [(b0, b1, b2), (b0, b2, b3),            # bottom
            (b3, b2, t2), (b3, t2, t3),            # back
            (b0, t3, t2), (b0, t2, b1),            # slope
            (b0, b3, t3), (b1, t2, b2)]            # sides


def corner_tris(cf, s):
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    P = lambda x, y, z: cf * (x, y, z)  # noqa: E731
    top = P(hx, hy, -hz)
    b = [P(-hx, -hy, -hz), P(hx, -hy, -hz), P(hx, -hy, hz), P(-hx, -hy, hz)]
    return [(b[0], b[1], b[2]), (b[0], b[2], b[3]), (b[0], top, b[1]), (b[1], top, b[2]), (b[2], top, b[3]), (b[3], top, b[0])]


def cyl_tris(cf, s, seg=14):
    # axis along X
    hx = s[0] / 2
    ry, rz = s[1] / 2, s[2] / 2
    r = min(ry, rz)
    ring = [(math.cos(2 * math.pi * i / seg) * r, math.sin(2 * math.pi * i / seg) * r) for i in range(seg)]
    out = []
    a0, a1 = cf * (-hx, 0, 0), cf * (hx, 0, 0)
    for i in range(seg):
        y0, z0 = ring[i]
        y1, z1 = ring[(i + 1) % seg]
        p0, p1 = cf * (-hx, y0, z0), cf * (-hx, y1, z1)
        q0, q1 = cf * (hx, y0, z0), cf * (hx, y1, z1)
        out += [(p0, q0, q1), (p0, q1, p1), (a0, p1, p0), (a1, q0, q1)]
    return out


def ball_tris(cf, s, seg=10):
    r = min(s) / 2
    out = []
    for i in range(seg):
        t0, t1 = math.pi * i / seg, math.pi * (i + 1) / seg
        for j in range(seg * 2):
            p0, p1 = 2 * math.pi * j / (seg * 2), 2 * math.pi * (j + 1) / (seg * 2)

            def v(t, p):
                return cf * (r * math.sin(t) * math.cos(p), r * math.cos(t), r * math.sin(t) * math.sin(p))
            a, b, c, d = v(t0, p0), v(t0, p1), v(t1, p1), v(t1, p0)
            out += [(a, b, c), (a, c, d)]
    return out


MAT_SPEC = {"Glass": 0.8, "SmoothPlastic": 0.25, "Metal": 0.5, "Marble": 0.35, "Neon": 0.0, "Foil": 0.6, "DiamondPlate": 0.4}


def tris_for(p):
    if p.shape in ("Block", "Mesh"):
        return box_tris(p.cf, p.size if p.shape == "Block" else tuple(v * 0.85 for v in p.size))
    if p.shape == "Wedge":
        return wedge_tris(p.cf, p.size)
    if p.shape == "CornerWedge":
        return corner_tris(p.cf, p.size)
    if p.shape == "Cylinder":
        return cyl_tris(p.cf, p.size)
    if p.shape == "Ball":
        return ball_tris(p.cf, p.size)
    return box_tris(p.cf, p.size)


def srgb_to_lin(c):
    return tuple(v ** 2.2 for v in c)


def build_scene(doc, extra_parts=()):
    ps = scene.parts(doc) + list(extra_parts)
    tri_rec = []
    for p in ps:
        if p.transp >= 0.98:
            continue
        col = srgb_to_lin(p.color)
        em = 1.0 if p.mat == "Neon" else 0.0
        alpha = 1.0 - p.transp
        if p.mat == "Glass":
            alpha = min(alpha, 0.55)
        spec = MAT_SPEC.get(p.mat, 0.05)
        for t in tris_for(p):
            tri_rec.append((t, col, em, alpha, spec))
    lights = []
    for cname in ("PointLight", "SpotLight", "SurfaceLight"):
        cid = doc.by_name.get(cname)
        if cid is None:
            continue
        for ref in doc.classes[cid].refs:
            par = doc.parent[ref]
            if par == -1 or doc.cls(par) not in scene.PART_CLASSES:
                continue
            if not doc.get(ref, "Enabled", True):
                continue
            pos = doc.get(par, "CFrame").p
            c = doc.get(ref, "Color")
            lights.append((pos, srgb_to_lin(c), doc.get(ref, "Range", 8), doc.get(ref, "Brightness", 1)))
    return tri_rec, lights


def pack(tri_rec, lights, W, H, eye, target, fov, night):
    cf = rbxl.CF.look_at(eye, target)
    if night:
        sun = (-0.3, 0.55, -0.4)
        sunC = (0.10, 0.12, 0.22)
        ambS, ambG = (0.10, 0.11, 0.20), (0.05, 0.05, 0.08)
        fogC, fogS, fogE = (0.04, 0.05, 0.10), 300, 2600
        skyT, skyH = (0.01, 0.01, 0.04), (0.06, 0.06, 0.14)
    else:
        sun = (0.45, 0.62, 0.35)
        sunC = (1.25, 1.12, 0.95)
        ambS, ambG = (0.42, 0.48, 0.60), (0.22, 0.20, 0.17)
        fogC, fogS, fogE = (0.62, 0.72, 0.86), 500, 4200
        skyT, skyH = (0.18, 0.38, 0.85), (0.70, 0.80, 0.92)
    head = struct.pack("<2i", W, H) + struct.pack("<12f", *cf.p, *cf.r) + struct.pack("<f", fov)
    head += struct.pack("<3f", *sun) + struct.pack("<3f", *sunC) + struct.pack("<3f", *ambS) + struct.pack("<3f", *ambG)
    head += struct.pack("<3f", *fogC) + struct.pack("<2f", fogS, fogE) + struct.pack("<3f", *skyT) + struct.pack("<3f", *skyH)
    head += struct.pack("<3i", 4096, len(tri_rec), len(lights))
    arr = np.zeros((len(tri_rec), 15), dtype=np.float32)
    for i, (t, col, em, alpha, spec) in enumerate(tri_rec):
        arr[i, 0:3], arr[i, 3:6], arr[i, 6:9] = t[0], t[1], t[2]
        arr[i, 9:12] = col
        arr[i, 12], arr[i, 13], arr[i, 14] = em, alpha, spec
    larr = np.zeros((len(lights), 8), dtype=np.float32)
    for i, (pos, c, rng, br) in enumerate(lights):
        larr[i] = (*pos, *c, rng, br * (1.0 if night else 0.25))
    return head + arr.tobytes() + larr.tobytes()


def ensure_raster():
    src = os.path.join(HERE, "raster.c")
    if not os.path.exists(RASTER) or os.path.getmtime(RASTER) < os.path.getmtime(src):
        subprocess.check_call(["gcc", "-O3", "-march=native", "-o", RASTER, src, "-lm"], stderr=subprocess.DEVNULL)


def render(tri_rec, lights, out_png, eye, target, W=1280, H=720, fov=70, night=False):
    ensure_raster()
    data = pack(tri_rec, lights, W, H, eye, target, fov, night)
    tmp_in, tmp_out = out_png + ".in", out_png + ".raw"
    with open(tmp_in, "wb") as f:
        f.write(data)
    subprocess.check_call([RASTER, tmp_in, tmp_out])
    raw = np.fromfile(tmp_out, dtype=np.float32)
    col = raw[:W * H * 3].reshape(H, W, 3)
    em = raw[W * H * 3:].reshape(H, W)
    os.remove(tmp_in)
    os.remove(tmp_out)
    # bloom from emissive + very bright pixels
    glow = col * em[..., None]
    bright = np.clip(col - 1.0, 0, None)
    src = glow * 0.9 + bright
    blur = src.copy()
    for rad in (2, 5, 11):
        k = np.ones(rad * 2 + 1, dtype=np.float32) / (rad * 2 + 1)
        b = np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 1, src)
        b = np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 0, b)
        blur += b * 0.8
    col = col + blur * (0.55 if night else 0.3)
    # tone map + gamma
    col = col / (1 + col * 0.25)
    col = np.clip(col * 1.12, 0, 1) ** (1 / 2.2)
    Image.fromarray((col * 255).astype(np.uint8)).save(out_png)
    print("wrote", out_png)


def main():
    args = sys.argv[1:]
    place, prefix = args[0], args[1]
    night = "--night" in args
    views = list(VIEWS)
    size = (1280, 720)
    for i, a in enumerate(args):
        if a == "--views":
            views = args[i + 1].split(",")
        if a == "--size":
            size = tuple(int(v) for v in args[i + 1].split("x"))
    doc = rbxl.Doc.load(place)
    tri_rec, lights = build_scene(doc)
    print("triangles", len(tri_rec), "lights", len(lights))
    for v in views:
        eye, target = VIEWS[v]
        render(tri_rec, lights, "%s_%s%s.png" % (prefix, v, "_night" if night else ""), eye, target, size[0], size[1], night=night)


if __name__ == "__main__":
    main()
