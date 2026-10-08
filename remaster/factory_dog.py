"""The giant dog head gets its holiday look: sunglasses pushed up on the forehead, a flower
crown, a marquee DOGROTS sign mounted on its head and searchlights sweeping the night sky.
Nothing of THE_DOG itself is changed (secret arrivals animate its eyes)."""
import math

from factory import CF, beam_cf
from . import geom
from . import palette as P
from .geom import Builder, T, yaw

FONT = {
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
}
LETTER_COLORS = [(255, 70, 160), (255, 140, 50), (255, 226, 70), (120, 240, 110), (50, 220, 255), (170, 100, 255), (255, 70, 160)]


def head_surface(ctx):
    """Top surface height of the head voxels by (x, z) column (4-stud grid)."""
    top = {}
    for p in ctx.parts():
        if p.name == "FurVoxel":
            k = (round(p.cf.p[0] / 4), round(p.cf.p[2] / 4))
            top[k] = max(top.get(k, -1e9), p.cf.p[1] + p.size[1] / 2)
    return top


def surface_y(top, x, z, default=80.0):
    k = (round(x / 4), round(z / 4))
    best = top.get(k)
    if best is None:
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                v = top.get((k[0] + dx, k[1] + dz))
                if v is not None:
                    best = v if best is None else max(best, v)
    return default if best is None else best


def sunglasses(ctx, parent):
    m = ctx.fac.model(parent, "GiantSunglasses", pivot=CF((0, 72, -157)))
    tilt = math.radians(-37)
    base = CF((0, 71.5, -157.5)) * CF.angles(tilt, 0, 0)
    b = Builder(ctx, m, base)
    frame = (255, 70, 160)
    for side in (-1, 1):
        x = side * 11.5
        b.box("Lens", (17, 10, 1.0), T(x, 0, 0), (24, 18, 40), "Glass", reflectance=0.35, transparency=0.15)
        b.box("LensShine", (6, 1.0, 1.1), T(x - side * 3, 2.6, 0.1) * CF.angles(0, 0, side * 0.5), (255, 255, 255), "Neon",
              transparency=0.55, collide=False, shadow=False)
        for dy in (-5.4, 5.4):
            b.box("FrameBar", (18.2, 1.2, 1.6), T(x, dy, 0), frame, "Neon", collide=False)
        for dx in (-8.9, 8.9):
            b.box("FrameBar", (1.2, 11.6, 1.6), T(x + dx, 0, 0), frame, "Neon", collide=False)
    b.box("Bridge", (6, 1.4, 1.6), T(0, 3.0, 0), frame, "Neon", collide=False)
    # temple arms along the sides of the head
    for side in (-1, 1):
        a = b.at(T(side * 20.8, 4.5, 0)).p
        c = (side * 27.5, 74.0, -196.0)
        cf, ln = beam_cf(a, c)
        ctx.fac.part(m, "TempleArm", (1.4, 1.4, ln), cf, frame, "Neon", collide=False)
    return m


def flower_crown(ctx, parent):
    """Ring of tropical blossoms around the crown of the head."""
    top = head_surface(ctx)
    m = ctx.fac.model(parent, "FlowerCrown", pivot=CF((0, 86, -190)))
    cx, cz = 0.0, -190.0
    n = 26
    colors = [(255, 92, 150), (255, 210, 70), (255, 255, 255), (255, 130, 70), (200, 110, 255), (255, 70, 100)]
    for i in range(n):
        a = 2 * math.pi * i / n
        rx, rz = 25.0, 22.0
        x, z = cx + math.cos(a) * rx, cz + math.sin(a) * rz
        y = surface_y(top, x, z) + 1.6
        col = colors[i % len(colors)]
        center = CF((x, y, z))
        ctx.fac.part(m, "Blossom", (4.6, 4.6, 4.6), center, col, "SmoothPlastic", shape="Ball", collide=False)
        for k in range(5):
            pa = 2 * math.pi * k / 5 + i
            ctx.fac.part(m, "Petal", (2.8, 2.8, 2.8), center * T(math.cos(pa) * 2.6, 0.8, math.sin(pa) * 2.6), col,
                         "SmoothPlastic", shape="Ball", collide=False, shadow=False)
        ctx.fac.part(m, "BlossomHeart", (1.6, 1.6, 1.6), center * T(0, 2.2, 0), (255, 236, 120), "SmoothPlastic", shape="Ball",
                     collide=False, shadow=False)
        # a leaf between blossoms
        a2 = a + math.pi / n
        lx, lz = cx + math.cos(a2) * 25.5, cz + math.sin(a2) * 22.5
        ly = surface_y(top, lx, lz) + 0.8
        ctx.fac.part(m, "CrownLeaf", (2.6, 0.5, 6.0), CF((lx, ly, lz)) * yaw(-a2) * CF.angles(0.25, 0, 0), (60, 160, 70),
                     "SmoothPlastic", collide=False, shadow=False)
    return m


def marquee(ctx, parent, text="DOGROTS", center=(0.0, 104.0, -200.0), pitch=2.45, ball=2.15):
    """Neon bulb letters on a white truss frame mounted on the head."""
    m = ctx.fac.model(parent, "MarqueeSign", pivot=CF(center), attrs={"NightGlow": True}, stream_mode=2)
    b = Builder(ctx, m)
    letter_w = 5 * pitch
    gap = 1.6 * pitch
    width = len(text) * letter_w + (len(text) - 1) * gap
    x0 = center[0] - width / 2
    height = 7 * pitch
    y0 = center[1] - height / 2
    z = center[2]
    # backing frame
    b.box("SignBacking", (width + 6, height + 6, 1.2), T(center[0], center[1], z - 1.6), (30, 22, 48), "SmoothPlastic")
    for dy in (-(height / 2 + 3), height / 2 + 3):
        b.box("SignRail", (width + 7, 1.2, 1.6), T(center[0], center[1] + dy, z - 1.2), P.WHITE, "Metal")
    for dx in (-(width / 2 + 3), width / 2 + 3):
        b.box("SignRail", (1.2, height + 7, 1.6), T(center[0] + dx, center[1], z - 1.2), P.WHITE, "Metal")
    count = 0
    for li, ch in enumerate(text):
        rows = FONT[ch]
        col = LETTER_COLORS[li % len(LETTER_COLORS)]
        lx = x0 + li * (letter_w + gap)
        for r, row in enumerate(rows):
            for c, cell in enumerate(row):
                if cell == "#":
                    x = lx + (c + 0.5) * pitch
                    y = y0 + (6 - r + 0.5) * pitch
                    ctx.fac.part(m, "Bulb", (ball, ball, ball), CF((x, y, z)), col, "Neon", shape="Ball", collide=False,
                                 shadow=False)
                    count += 1
    # masts down to the head
    for x in (-24.0, 24.0):
        b.rod("SignMast", (x, 84.0, -196.0), (x, y0 - 3.0, z - 1.6), 1.4, P.WHITE, "Metal")
        b.rod("SignBrace", (x, 84.0, -196.0), (x * 0.4, y0 - 3.0, z - 1.6), 0.7, P.WHITE, "Metal", collide=False)
    ctx.note("marquee: %d bulbs" % count)
    return m


def searchlight(ctx, parent, x, z, y, phase, speed):
    m = ctx.fac.model(parent, "Searchlight", pivot=CF((x, y + 3.5, z)),
                      attrs={"Motion": "LighthouseBeam", "AngularSpeed": speed, "Phase": phase})
    b = Builder(ctx, m, CF((x, y + 3.5, z)) * yaw(phase))
    beam_len = 160.0
    tilt = math.radians(28)  # from vertical
    d = (math.sin(tilt), math.cos(tilt))
    mid = (d[0] * beam_len / 2, d[1] * beam_len / 2)
    b.box("SearchBeam", (5.5, beam_len, 5.5), T(0, mid[1], mid[0]) * CF.angles(tilt, 0, 0), (220, 236, 255), "Neon",
          transparency=0.86, collide=False, shadow=False, query=False, attrs={"NightOnlyBeam": True})
    b.vcyl("SearchLamp", 2.2, 4.6, T(0, 0.6, 0) * CF.angles(tilt, 0, 0), (40, 40, 48), "Metal", collide=False)
    lens = b.box("SearchLens", (3.8, 0.4, 3.8), T(d[0] * 1.8, 1.8, 0) * CF.angles(tilt, 0, 0), (255, 255, 230), "Neon", collide=False)
    base = Builder(ctx, parent, CF((x, y, z)))
    base.box("SearchlightBase", (6, 2.2, 6), T(0, 1.1, 0), P.WHITE, "Metal")
    return m


def gardens(ctx, parent):
    """Palms and tiki torches lining the mouth gardens."""
    rng = ctx.rng
    for x in (-34.0, 34.0):
        for z in (-150.0, -128.0, -106.0):
            if ctx.is_free(x, z, 2.5, ymax=0.9):
                geom.palm(ctx, parent, (x, 0.2, z), height=rng.uniform(18, 24), lean=((0.15 if x > 0 else -0.15), 0.05))
                ctx.block(x - 2, z - 2, x + 2, z + 2, 30, "factory palm")
    for x in (-24.0, 24.0):
        for z in (-140.0, -118.0, -96.0, -74.0):
            if ctx.is_free(x, z, 1.5, ymax=0.9):
                geom.tiki_torch(ctx, parent, (x, 0.2, z), light=(z % 44 == 0))
                ctx.block(x - 1, z - 1, x + 1, z + 1, 9, "factory torch")


def run(ctx):
    root = ctx.group("Districts/HolidayDog")
    sunglasses(ctx, root)
    flower_crown(ctx, root)
    marquee(ctx, root)
    spots = [(-74.0, -222.0), (74.0, -222.0), (-112.0, -196.0), (112.0, -196.0), (-150.0, -170.0), (150.0, -170.0)]
    placed = 0
    for i, (x, z) in enumerate(spots):
        if placed >= 4 or not ctx.is_free(x, z, 3.5, ymax=0.9):
            continue
        searchlight(ctx, root, x, z, 0.4, phase=i * 1.7, speed=0.35 if i % 2 else -0.3)
        ctx.block(x - 3, z - 3, x + 3, z + 3, 4, "searchlight")
        placed += 1
    ctx.note("factory: %d searchlights" % placed)
    gardens(ctx, root)
