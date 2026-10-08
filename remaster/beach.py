"""Beaches around the island: palms, umbrellas, loungers, torches, towers, rocks.

Heights come from remaster/coast.py (same formulas as the Luau terrain builder).
"""
import math

from factory import CF
from . import coast, geom
from . import palette as P

UMBRELLA_COLORS = [((255, 90, 120), (255, 255, 255)), ((40, 190, 210), (255, 255, 255)), ((255, 196, 60), (255, 120, 60)),
                   ((120, 210, 120), (255, 255, 255)), ((180, 120, 255), (255, 230, 120)), ((255, 140, 60), (255, 236, 160))]
TOWEL_COLORS = [[(255, 90, 120), (255, 255, 255), (255, 90, 120)], [(40, 170, 220), (255, 230, 90), (40, 170, 220)],
                [(255, 160, 60), (255, 255, 255), (60, 200, 160)], [(170, 110, 255), (255, 255, 255), (170, 110, 255)]]


def ground(x, z):
    h = coast.height(x, z)
    return h


def outward(x, z):
    d, px, pz = coast.nearest(x, z)
    if d < 1e-6:
        return (0.0, 1.0)
    return ((x - px) / d, (z - pz) / d)


class Scatter:
    """Rejection sampling with minimum spacing per kind and global blockers."""

    def __init__(self, ctx):
        self.ctx = ctx
        self.placed = []  # (x, z, r)

    def ok(self, x, z, r):
        for px, pz, pr in self.placed:
            if (px - x) ** 2 + (pz - z) ** 2 < (pr + r) ** 2:
                return False
        return self.ctx.is_free(x, z, r)

    def take(self, x, z, r):
        self.placed.append((x, z, r))


def band_points(step, d_lo, d_hi, rng, jitter=0.45):
    """Candidate points on a jittered grid around the island whose distance to the footprint is in [d_lo, d_hi]."""
    x0, z0, x1, z1 = -300.0, -330.0, 300.0, 850.0
    out = []
    x = x0
    while x < x1:
        z = z0
        while z < z1:
            jx = x + rng.uniform(-jitter, jitter) * step
            jz = z + rng.uniform(-jitter, jitter) * step
            d, px, pz = coast.nearest(jx, jz)
            if d_lo <= d <= d_hi:
                out.append((jx, jz, d, px, pz))
            z += step
        x += step
    rng.shuffle(out)
    return out


def run(ctx):
    rng = ctx.rng
    sc = Scatter(ctx)
    root = ctx.group("Coast")
    # the pier, beach bar and docks reserve their ground first (see landmarks)
    palms = ctx.group("Coast/Palms")
    deco = ctx.group("Coast/BeachLife")
    rocks = ctx.group("Coast/Rocks")
    torches = ctx.group("Coast/Torches")
    n_palm = n_umb = n_rock = n_torch = 0

    # tiki torches along the top of the beaches
    for x, z, d, px, pz in coast.perimeter_points(24, 7.0, 10.0, rng):
        if coast.beach_weight(px, pz) < 0.8:
            continue
        h = ground(x, z)
        if h is None or h < coast.SEA + 1.5:
            continue
        if not sc.ok(x, z, 2.5):
            continue
        sc.take(x, z, 2.5)
        geom.tiki_torch(ctx, torches, (x, h - 0.2, z), light=(n_torch % 2 == 0))
        n_torch += 1

    # umbrella + loungers + towels clusters on the wide dry beach
    for x, z, d, px, pz in coast.perimeter_points(16, 14, 30, rng):
        if coast.beach_weight(px, pz) < 0.9:
            continue
        h = ground(x, z)
        if h is None or h < coast.SEA + 1.0:
            continue
        if not sc.ok(x, z, 7):
            continue
        sc.take(x, z, 7)
        cols = UMBRELLA_COLORS[n_umb % len(UMBRELLA_COLORS)]
        geom.umbrella(ctx, deco, (x, h - 0.3, z), cols)
        ox, oz = outward(x, z)
        face = math.atan2(ox, oz)  # loungers look out to sea (local +Z = outward)
        rot = CF.angles(0, face, 0)
        for side in (-1, 1):
            lx, lz = x + math.cos(face) * side * 2.2, z - math.sin(face) * side * 2.2
            lh = ground(lx, lz) or h
            geom.lounger(ctx, deco, CF((lx, lh - 0.25, lz)) * rot, cols[0])
        if n_umb % 2 == 0:
            tx, tz = x + ox * 7, z + oz * 7
            th = ground(tx, tz)
            if th is not None and th > coast.SEA + 0.6:
                geom.towel(ctx, deco, CF((tx, th - 0.05, tz)) * CF.angles(0, face + rng.uniform(-0.4, 0.4), 0),
                           TOWEL_COLORS[n_umb % len(TOWEL_COLORS)])
        n_umb += 1

    # palms on dry sand, leaning to the sea
    for x, z, d, px, pz in coast.perimeter_points(7, 8, 30, rng):
        if coast.beach_weight(px, pz) < 0.6:
            continue
        h = ground(x, z)
        if h is None or h < coast.SEA + 0.8:
            continue
        if not sc.ok(x, z, 4.5):
            continue
        if rng.random() < 0.25:
            continue
        sc.take(x, z, 4.5)
        ox, oz = outward(x, z)
        lean = rng.uniform(0.12, 0.32)
        geom.palm(ctx, palms, (x, h - 0.4, z), height=rng.uniform(17, 26), lean=(ox * lean, oz * lean), seed=n_palm,
                  scale=rng.uniform(0.9, 1.15))
        n_palm += 1

    # surfboards, sandcastles, starfish
    n_extra = 0
    for x, z, d, px, pz in coast.perimeter_points(28, 10, 34, rng):
        if coast.beach_weight(px, pz) < 0.85:
            continue
        h = ground(x, z)
        if h is None or h < coast.SEA + 0.5 or not sc.ok(x, z, 4):
            continue
        sc.take(x, z, 4)
        kind = n_extra % 3
        ox, oz = outward(x, z)
        face = math.atan2(ox, oz)
        if kind == 0:
            for i in range(3):
                geom.surfboard(ctx, deco, CF((x + i * 2.4 * math.cos(face), h - 1.0, z - i * 2.4 * math.sin(face)))
                               * CF.angles(0, face, rng.uniform(-0.15, 0.15)), rng.choice(P.NEONS), P.WHITE)
        elif kind == 1:
            geom.sandcastle(ctx, deco, CF((x, h - 0.2, z)) * CF.angles(0, face, 0))
        else:
            for i in range(3):
                sx, sz = x + rng.uniform(-4, 4), z + rng.uniform(-4, 4)
                sh = ground(sx, sz)
                if sh is not None:
                    geom.starfish(ctx, deco, (sx, sh - 0.1, sz), rng.choice([(255, 120, 90), (255, 170, 60), (240, 90, 140)]))
        n_extra += 1

    # rocky shores: boulders half in the water
    for x, z, d, px, pz in coast.perimeter_points(6, 2, 40, rng):
        if coast.beach_weight(px, pz) > 0.5:
            continue
        h = ground(x, z)
        if h is None or h < -16:
            continue
        if not sc.ok(x, z, 4):
            continue
        sc.take(x, z, 4)
        size = rng.uniform(5, 12) * (1.3 if d < 15 else 1.0)
        geom.boulder(ctx, rocks, (x, h - size * 0.25, z), size=size, color=P.ROCK if rng.random() < 0.6 else P.ROCK_DARK)
        n_rock += 1

    ctx.note("coast: %d palms, %d umbrella sets, %d torches, %d boulders, %d extras" % (n_palm, n_umb, n_torch, n_rock, n_extra))
    return sc
