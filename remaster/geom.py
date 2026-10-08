"""Prop builders (parts in a local frame) for the Paradise remaster."""
import math

from factory import CF, beam_cf, v_add, v_sub, v_scale, v_len, v_norm
from . import palette as P


class Builder:
    """Places parts relative to `origin` (a CF) under `parent`."""

    def __init__(self, ctx, parent, origin=None):
        self.ctx, self.fac, self.parent = ctx, ctx.fac, parent
        self.origin = origin or CF()

    def at(self, local):
        return self.origin * local

    def box(self, name, size, local, color, material="SmoothPlastic", **kw):
        return self.fac.part(self.parent, name, size, self.at(local), color, material, **kw)

    def ball(self, name, d, local, color, material="SmoothPlastic", **kw):
        return self.fac.part(self.parent, name, (d, d, d), self.at(local), color, material, shape="Ball", **kw)

    def cyl(self, name, length, d, local, color, material="SmoothPlastic", **kw):
        """Cylinder along the local X axis of `local`."""
        return self.fac.part(self.parent, name, (length, d, d), self.at(local), color, material, shape="Cylinder", **kw)

    def vcyl(self, name, height, d, local, color, material="SmoothPlastic", **kw):
        """Upright cylinder (axis = local Y)."""
        return self.cyl(name, height, d, local * CF.angles(0, 0, math.pi / 2), color, material, **kw)

    def wedge(self, name, size, local, color, material="SmoothPlastic", **kw):
        return self.fac.wedge(self.parent, name, size, self.at(local), color, material, **kw)

    def rod(self, name, a, b, d, color, material="SmoothPlastic", shape="Block", **kw):
        """World-space rod from a to b (square or round section)."""
        cf, length = beam_cf(a, b)
        if shape == "Cylinder":
            return self.fac.part(self.parent, name, (length, d, d), cf * CF.angles(0, math.pi / 2, 0), color, material,
                                 shape="Cylinder", **kw)
        return self.fac.part(self.parent, name, (d, d, length), cf, color, material, **kw)


def yaw(a):
    return CF.angles(0, a, 0)


def T(x, y, z):
    return CF((x, y, z))


# ---------------------------------------------------------------------------- vegetation
def palm(ctx, parent, base, height=22.0, lean=(0.0, 0.0), seed=0, scale=1.0, collide=True):
    """Curved palm: trunk of cylinder segments, drooping fronds, coconuts. base = (x, y, z)."""
    rng = ctx.rng
    m = ctx.fac.model(parent, "PalmTree", pivot=CF(base))
    b = Builder(ctx, m)
    h = height * scale
    segs = 7
    lx, lz = lean
    pts = []
    for i in range(segs + 1):
        t = i / segs
        bend = t * t
        pts.append((base[0] + lx * bend * h, base[1] + t * h, base[2] + lz * bend * h))
    for i in range(segs):
        d = (1.25 - 0.45 * i / segs) * scale
        color = P.PALM_TRUNK if i % 2 == 0 else P.PALM_RING
        b.rod("Trunk", pts[i], v_add(pts[i + 1], v_scale(v_norm(v_sub(pts[i + 1], pts[i])), 0.3 * scale)), d, color,
              "Wood", shape="Cylinder", collide=collide, shadow=True)
    top = pts[-1]
    b.ball("CrownCore", 1.9 * scale, CF(top), P.PALM_RING, "Wood", collide=False)
    n = 8
    a0 = rng.random() * math.pi * 2
    for i in range(n):
        a = a0 + i * 2 * math.pi / n + rng.uniform(-0.18, 0.18)
        dx, dz = math.cos(a), math.sin(a)
        length = rng.uniform(6.5, 8.5) * scale
        col = P.PALM_LEAF[(i + seed) % len(P.PALM_LEAF)]
        # frond: rises then droops (two segments)
        p0 = top
        p1 = (top[0] + dx * length * 0.55, top[1] + 1.2 * scale, top[2] + dz * length * 0.55)
        p2 = (top[0] + dx * length, top[1] - rng.uniform(2.2, 3.6) * scale, top[2] + dz * length)
        for (a_, b_, w) in ((p0, p1, 2.4), (p1, p2, 1.9)):
            cf, ln = beam_cf(a_, b_)
            # flatten: frond plane horizontal-ish
            ctx.fac.part(m, "Frond", (w * scale, 0.18 * scale, ln + 0.4 * scale), cf, col, "SmoothPlastic",
                         collide=False, shadow=True)
    for i in range(3):
        a = a0 + i * 2.1
        b.ball("Coconut", 0.95 * scale, CF((top[0] + math.cos(a) * 0.9 * scale, top[1] - 0.9 * scale,
                                              top[2] + math.sin(a) * 0.9 * scale)), P.COCONUT, "Wood", collide=False)
    return m


def bush(ctx, parent, base, size=3.0, color=None, flowers=0):
    rng = ctx.rng
    m = ctx.fac.model(parent, "TropicalBush", pivot=CF(base))
    b = Builder(ctx, m)
    col = color or rng.choice(P.LEAVES)
    for i in range(3):
        a = rng.random() * 6.28
        r = size * 0.35
        d = size * rng.uniform(0.7, 1.0)
        b.ball("Leaves", d, T(base[0] + math.cos(a) * r, base[1] + d * 0.35, base[2] + math.sin(a) * r),
               P.lerp(col, (30, 90, 50), rng.random() * 0.25), "LeafyGrass", collide=False)
    for i in range(flowers):
        a = rng.random() * 6.28
        r = size * rng.uniform(0.3, 0.55)
        b.ball("Flower", 0.55, T(base[0] + math.cos(a) * r, base[1] + size * rng.uniform(0.45, 0.8), base[2] + math.sin(a) * r),
               rng.choice(P.FLOWERS), "SmoothPlastic", collide=False, shadow=False)
    return m


def boulder(ctx, parent, base, size=4.0, color=None, collide=True):
    rng = ctx.rng
    m = ctx.fac.model(parent, "Boulder", pivot=CF(base))
    col = color or P.ROCK
    n = 3 if size < 5 else 4
    for i in range(n):
        s = size * rng.uniform(0.55, 1.0)
        sz = (s * rng.uniform(0.8, 1.3), s * rng.uniform(0.6, 0.9), s * rng.uniform(0.8, 1.2))
        off = (rng.uniform(-0.35, 0.35) * size, sz[1] * 0.3, rng.uniform(-0.35, 0.35) * size)
        cf = CF(v_add(base, off)) * CF.angles(rng.uniform(-0.4, 0.4), rng.uniform(0, 6.28), rng.uniform(-0.4, 0.4))
        ctx.fac.part(m, "Rock", sz, cf, P.lerp(col, (70, 64, 60), rng.random() * 0.4), "Rock", collide=collide)
    return m


# ---------------------------------------------------------------------------- beach props
def umbrella(ctx, parent, base, colors, tilt=0.12):
    rng = ctx.rng
    m = ctx.fac.model(parent, "BeachUmbrella", pivot=CF(base))
    b = Builder(ctx, m, CF(base) * yaw(rng.random() * 6.28) * CF.angles(tilt, 0, 0))
    b.vcyl("Pole", 9, 0.35, T(0, 4.3, 0), P.WHITE, "Metal", collide=False)
    b.vcyl("Canopy", 0.5, 9.5, T(0, 8.5, 0), colors[0], "Fabric", collide=False)
    b.vcyl("CanopyStripe", 0.55, 6.2, T(0, 8.62, 0), colors[1], "Fabric", collide=False)
    b.vcyl("CanopyTop", 0.6, 2.6, T(0, 8.85, 0), colors[0], "Fabric", collide=False)
    b.ball("Finial", 0.6, T(0, 9.2, 0), P.WHITE, collide=False)
    return m


def lounger(ctx, parent, cf, color):
    m = ctx.fac.model(parent, "SunLounger", pivot=cf)
    b = Builder(ctx, m, cf)
    b.box("Frame", (2.6, 0.35, 6.4), T(0, 0.85, 0), P.WHITE, "SmoothPlastic", collide=True)
    for x in (-1.1, 1.1):
        for z in (-2.8, 2.8):
            b.box("Leg", (0.3, 0.8, 0.3), T(x, 0.4, z), P.WHITE, collide=False)
    b.box("Cushion", (2.3, 0.3, 4.2), T(0, 1.15, 0.9), color, "Fabric", collide=False)
    b.box("BackCushion", (2.3, 0.3, 2.4), T(0, 1.75, -2.2) * CF.angles(0.75, 0, 0), color, "Fabric", collide=False)
    return m


def towel(ctx, parent, cf, colors):
    m = ctx.fac.model(parent, "BeachTowel", pivot=cf)
    b = Builder(ctx, m, cf)
    for i, c in enumerate(colors[:3]):
        b.box("Towel", (3.2, 0.08, 1.9), T(0, 0.05, -1.9 + i * 1.9), c, "Fabric", collide=False, shadow=False)
    return m


def surfboard(ctx, parent, cf, color, stripe):
    m = ctx.fac.model(parent, "Surfboard", pivot=cf)
    b = Builder(ctx, m, cf)
    b.box("Board", (2.0, 7.0, 0.35), T(0, 3.2, 0), color, "SmoothPlastic", collide=False)
    b.ball("BoardTip", 2.0, T(0, 6.7, 0), color, collide=False, shadow=False)
    b.box("Stripe", (0.4, 6.6, 0.4), T(0, 3.2, 0), stripe, collide=False, shadow=False)
    return m


def tiki_torch(ctx, parent, base, light=True):
    m = ctx.fac.model(parent, "TikiTorch", pivot=CF(base), attrs={"NightLight": True})
    b = Builder(ctx, m, CF(base))
    b.vcyl("Bamboo", 6.5, 0.45, T(0, 3.25, 0), (186, 150, 92), "Wood", collide=True)
    for y in (1.6, 3.3, 5.0):
        b.vcyl("BambooRing", 0.18, 0.55, T(0, y, 0), (150, 116, 70), "Wood", collide=False)
    b.vcyl("Bowl", 0.9, 1.2, T(0, 6.8, 0), (90, 66, 44), "Wood", collide=False)
    flame = b.box("Flame", (0.7, 1.1, 0.7), T(0, 7.6, 0) * CF.angles(0, 0.78, 0), P.NEON_ORANGE, "Neon",
                  collide=False, shadow=False, attrs={"Flicker": True})
    ctx.fac.particles(flame, "Fire", texture="rbxasset://textures/particles/fire_main.dds",
                      color=[(0, (255, 210, 120)), (1, (255, 90, 30))], size=[(0, 1.1), (1, 0.2)],
                      transparency=[(0, 0.35), (1, 1)], rate=14, lifetime=(0.5, 0.9), speed=(2, 3.5),
                      spread=(10, 10), light_emission=1, zoffset=0.3)
    if light:
        ctx.fac.point_light(flame, (255, 160, 80), brightness=1.4, rng=16, attrs={"NightOnly": True})
    return m


def lifeguard_tower(ctx, parent, cf):
    m = ctx.fac.model(parent, "LifeguardTower", pivot=cf)
    b = Builder(ctx, m, cf)
    for x in (-2.6, 2.6):
        for z in (-2.6, 2.6):
            b.box("Leg", (0.6, 9, 0.6), T(x, 4.5, z), P.WHITE, "WoodPlanks")
    b.box("Deck", (7, 0.6, 7), T(0, 9.3, 0), P.WOOD_PALE, "WoodPlanks")
    b.box("Cabin", (5.6, 4.2, 5.6), T(0, 11.7, -0.4), (232, 70, 70), "WoodPlanks")
    b.box("Window", (4.2, 1.6, 0.2), T(0, 12.4, 2.45), (180, 230, 255), "Glass", transparency=0.3, collide=False)
    b.wedge("RoofL", (6.6, 1.8, 3.6), T(0, 14.7, -1.8) * yaw(math.pi), P.WHITE, "WoodPlanks")
    b.wedge("RoofR", (6.6, 1.8, 3.6), T(0, 14.7, 1.8), P.WHITE, "WoodPlanks")
    for i in range(6):
        b.box("Rung", (2.4, 0.25, 0.35), T(0, 1.2 + i * 1.45, 4.2 + i * 0.25), P.WOOD_PALE, "Wood")
    b.box("RailFront", (7, 1.2, 0.25), T(0, 10.2, 3.4), P.WHITE, "WoodPlanks", collide=False)
    b.box("FlagPole", (0.2, 5, 0.2), T(2.8, 16, -2.8), P.WHITE, "Metal", collide=False)
    b.box("Flag", (0.1, 1.4, 2.2), T(2.8, 17.6, -1.65), (240, 50, 60), "Fabric", collide=False, shadow=False)
    b.box("Lifebuoy", (2.0, 2.0, 0.4), T(0, 7.0, 2.85), (250, 120, 60), "SmoothPlastic", collide=False)
    return m


def volleyball(ctx, parent, cf):
    m = ctx.fac.model(parent, "VolleyballCourt", pivot=cf)
    b = Builder(ctx, m, cf)
    for x in (-11, 11):
        b.vcyl("NetPole", 8.5, 0.5, T(x, 4.25, 0), P.WHITE, "Metal")
    b.box("Net", (21.5, 3.2, 0.12), T(0, 6.3, 0), (255, 255, 255), "Fabric", transparency=0.45, collide=True)
    b.box("NetTape", (21.5, 0.4, 0.16), T(0, 8.0, 0), (30, 60, 140), "Fabric", collide=False)
    for side in (-1, 1):
        b.box("Line", (24, 0.06, 0.4), T(0, 0.04, side * 12), (40, 120, 220), "SmoothPlastic", collide=False, shadow=False)
        b.box("Line", (0.4, 0.06, 24), T(side * 12, 0.04, 0), (40, 120, 220), "SmoothPlastic", collide=False, shadow=False)
    b.ball("Volleyball", 1.6, T(4, 0.8, 5), (255, 236, 120), collide=False)
    return m


def sandcastle(ctx, parent, cf):
    m = ctx.fac.model(parent, "Sandcastle", pivot=cf)
    b = Builder(ctx, m, cf)
    sand = (226, 196, 140)
    b.box("Keep", (5, 3, 5), T(0, 1.5, 0), sand, "Sand", collide=False)
    for x in (-2.6, 2.6):
        for z in (-2.6, 2.6):
            b.vcyl("Tower", 4.4, 1.9, T(x, 2.2, z), sand, "Sand", collide=False)
            b.vcyl("TowerTop", 0.6, 2.3, T(x, 4.5, z), (214, 182, 124), "Sand", collide=False)
    b.vcyl("Spire", 3, 1.4, T(0, 4.5, 0), sand, "Sand", collide=False)
    b.box("Flag", (0.1, 0.8, 1.2), T(0, 6.6, 0.6), P.NEON_PINK, collide=False, shadow=False)
    b.box("FlagPole", (0.12, 2, 0.12), T(0, 6.2, 0), P.WOOD_DARK, collide=False)
    b.box("Bucket", (1.2, 1.2, 1.2), T(4.2, 0.6, 1.5), (255, 90, 90), collide=False)
    return m


def starfish(ctx, parent, base, color):
    m = ctx.fac.model(parent, "Starfish", pivot=CF(base))
    for i in range(5):
        a = i * 2 * math.pi / 5
        cf = CF(base) * yaw(a) * T(0, 0.15, -0.5)
        ctx.fac.part(m, "Arm", (0.45, 0.25, 1.1), cf, color, collide=False, shadow=False)
    return m


def flower_patch(ctx, parent, base, radius=2.5, n=8):
    rng = ctx.rng
    m = ctx.fac.model(parent, "FlowerPatch", pivot=CF(base))
    for i in range(n):
        a = rng.random() * 6.28
        r = radius * math.sqrt(rng.random())
        x, z = base[0] + math.cos(a) * r, base[2] + math.sin(a) * r
        ctx.fac.part(m, "Stem", (0.15, 0.9, 0.15), CF((x, base[1] + 0.45, z)), (60, 140, 60), collide=False, shadow=False)
        ctx.fac.part(m, "Bloom", (0.7, 0.7, 0.7), CF((x, base[1] + 1.0, z)), rng.choice(P.FLOWERS), shape="Ball",
                     collide=False, shadow=False)
    return m


def lamp_post(ctx, parent, base, glow=(255, 214, 150), height=9.0, style="paradise", light=True):
    """White curved beach lamp with a warm lantern."""
    m = ctx.fac.model(parent, "ParadiseLamp", pivot=CF(base), attrs={"NightLight": True})
    b = Builder(ctx, m, CF(base))
    b.vcyl("Base", 0.6, 1.6, T(0, 0.3, 0), P.WHITE, "SmoothPlastic")
    b.vcyl("Post", height, 0.45, T(0, height / 2, 0), P.WHITE, "SmoothPlastic")
    b.box("Arm", (0.3, 0.3, 2.2), T(0, height - 0.2, 0.9), P.WHITE, "SmoothPlastic", collide=False)
    lens = b.box("Lantern", (1.0, 1.3, 1.0), T(0, height - 1.0, 1.8), glow, "Neon", collide=False, shadow=False)
    b.box("Cap", (1.4, 0.3, 1.4), T(0, height - 0.25, 1.8), P.GOLD, "Metal", collide=False)
    if light:
        ctx.fac.point_light(lens, glow, brightness=1.2, rng=18, attrs={"NightOnly": True})
    return m


def string_lights(ctx, parent, a, b, colors, sag=1.6, n=10):
    """Bulbs hanging on a sagging wire between world points a and b."""
    m = ctx.fac.model(parent, "StringLights", pivot=CF(a), attrs={"NightGlow": True})
    pts = []
    for i in range(n + 1):
        t = i / n
        y = a[1] + (b[1] - a[1]) * t - sag * 4 * t * (1 - t)
        pts.append((a[0] + (b[0] - a[0]) * t, y, a[2] + (b[2] - a[2]) * t))
    bb = Builder(ctx, m)
    for i in range(n):
        bb.rod("Wire", pts[i], pts[i + 1], 0.08, (40, 40, 40), collide=False, shadow=False)
    for i in range(1, n):
        ctx.fac.part(m, "Bulb", (0.55, 0.55, 0.55), CF((pts[i][0], pts[i][1] - 0.35, pts[i][2])), colors[i % len(colors)],
                     "Neon", shape="Ball", collide=False, shadow=False)
    return m
