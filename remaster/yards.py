"""Player yards: a private beach garden behind every villa (palms, hammock, fire pit, loungers)
and palms along the inner promenade. The yards themselves are styled at runtime by
PlotAppearance (Paradise villa skin); nothing inside the yard models is touched here."""
import math

from factory import CF, beam_cf
from . import coast, geom
from . import palette as P
from .geom import Builder, T, yaw


def yard_frames(ctx):
    """(name, center (x, z), back direction sign) for each yard, from YardFoundation and StorageAnchor."""
    out = []
    yards = ctx.area("04_PlayerYards")
    for y in ctx.doc.kids(yards):
        name = ctx.doc.name(y)
        if not name.startswith("Yard_"):
            continue
        land = ctx.doc.child(y, "YardLandscape")
        found = ctx.doc.child(land, "YardFoundation") if land is not None else None
        anchor = ctx.doc.child(y, "StorageAnchor")
        if found is None or anchor is None:
            continue
        c = ctx.doc.get(found, "CFrame").p
        a = ctx.doc.get(anchor, "CFrame").p
        out.append((name, (c[0], c[2]), 1 if a[0] > c[0] else -1, ctx.doc.get(found, "size")))
    return out


def hammock(ctx, parent, a, b, color):
    """Two posts and a sagging fabric hammock between world points a and b (ground level)."""
    m = ctx.fac.model(parent, "Hammock", pivot=CF(a))
    bb = Builder(ctx, m)
    for p in (a, b):
        bb.vcyl("HammockPost", 6.5, 0.7, T(p[0], p[1] + 3.25, p[2]), P.WOOD_DARK, "Wood")
    n = 6
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((a[0] + (b[0] - a[0]) * t, a[1] + 4.6 - 2.2 * 4 * t * (1 - t), a[2] + (b[2] - a[2]) * t))
    for i in range(n):
        cf, ln = beam_cf(pts[i], pts[i + 1])
        ctx.fac.part(m, "HammockCloth", (2.6, 0.2, ln + 0.3), cf, color if i % 2 else P.WHITE, "Fabric", collide=False)
    return m


def fire_pit(ctx, parent, x, y, z):
    m = ctx.fac.model(parent, "FirePit", pivot=CF((x, y, z)), attrs={"NightLight": True})
    b = Builder(ctx, m, CF((x, y, z)))
    for i in range(8):
        a = i * math.pi / 4
        b.box("PitStone", (1.6, 1.0, 1.4), T(math.cos(a) * 2.4, 0.5, math.sin(a) * 2.4) * yaw(-a), P.ROCK, "Rock")
    for i in range(3):
        b.cyl("Log", 3.6, 0.7, T(0, 0.5, 0) * yaw(i * 1.05), P.WOOD_DARK, "Wood", collide=False)
    flame = b.box("Flame", (1.2, 1.2, 1.2), T(0, 1.2, 0) * yaw(0.7), P.NEON_ORANGE, "Neon", collide=False, shadow=False)
    ctx.fac.particles(flame, "Fire", texture="rbxasset://textures/particles/fire_main.dds",
                      color=[(0, (255, 210, 120)), (1, (255, 80, 30))], size=[(0, 2.2), (1, 0.4)],
                      transparency=[(0, 0.3), (1, 1)], rate=18, lifetime=(0.6, 1.0), speed=(2.5, 4), spread=(12, 12),
                      light_emission=1)
    ctx.fac.point_light(flame, (255, 150, 70), brightness=1.6, rng=20, attrs={"NightOnly": True})
    for i in range(3):
        a = i * 2 * math.pi / 3 + 0.5
        b.cyl("LogSeat", 4.0, 1.4, T(math.cos(a) * 5.2, 0.7, math.sin(a) * 5.2) * yaw(-a + math.pi / 2), (140, 100, 64), "Wood")
    return m


def ground(x, z):
    h = coast.height(x, z)
    return 0.1 if h is None else h


def beach_garden(ctx, root, name, cz, sign, half_w):
    """Behind the villa: its own stretch of beach between the yard edge and the sea."""
    rng = ctx.rng
    m = ctx.fac.model(root, name.replace("Yard_", "BeachGarden_"), pivot=CF((sign * 196.0, 0, cz)))
    edge = 180.0
    z0, z1 = cz - half_w + 6, cz + half_w - 6
    # palms near the water
    k = 0
    for z in (z0 + 4, (z0 + z1) / 2 - 9, (z0 + z1) / 2 + 9, z1 - 4):
        x = sign * (edge + rng.uniform(22, 28))
        if ctx.is_free(x, z, 2.2, ymax=0.9):
            geom.palm(ctx, m, (x, ground(x, z) - 0.3, z), height=rng.uniform(17, 23),
                      lean=(sign * rng.uniform(0.15, 0.3), rng.uniform(-0.1, 0.1)), seed=k)
            ctx.block(x - 2, z - 2, x + 2, z + 2, 30, "garden palm")
            k += 1
    # hammock between two posts
    x = sign * (edge + 15)
    za, zb = cz - 14, cz - 4
    if ctx.is_free(x, (za + zb) / 2, 6):
        y = min(ground(x, za), ground(x, zb))
        hammock(ctx, m, (x, y, za), (x, y, zb), P.PLASTER["coral"])
        ctx.block(x - 2, za - 1, x + 2, zb + 1, 7, "hammock")
    # fire pit with log seats
    fx, fz = sign * (edge + 9), cz + 10
    if ctx.is_free(fx, fz, 7.5):
        fire_pit(ctx, m, fx, ground(fx, fz) + 0.05, fz)
        ctx.block(fx - 7, fz - 7, fx + 7, fz + 7, 3, "fire pit")
    # two loungers facing the sea
    for dz in (-4.0, 4.0):
        lz = cz + 22 + dz
        lx = sign * (edge + 17)
        if lz < z1 and ctx.is_free(lx, lz, 3.5):
            geom.lounger(ctx, m, CF((lx, ground(lx, lz) - 0.1, lz)) * yaw(math.pi / 2 * sign), P.PLASTER["sky"])
            ctx.block(lx - 3.5, lz - 2, lx + 3.5, lz + 2, 3, "lounger")
    # tiki torches at the corners of the garden
    for z in (z0, z1):
        tx = sign * (edge + 4)
        if ctx.is_free(tx, z, 1.5):
            geom.tiki_torch(ctx, m, (tx, ground(tx, z) - 0.2, z), light=False)
            ctx.block(tx - 1, z - 1, tx + 1, z + 1, 9, "garden torch")
    return m


def run(ctx):
    root = ctx.group("Districts/VillaGardens")
    frames = yard_frames(ctx)
    for name, (cx, cz), back, size in frames:
        half_w = min(size[0], size[2]) / 2
        beach_garden(ctx, root, name, cz, back, half_w)
    # palms on the inner promenade, between the yard entrances and the tongue
    n = 0
    for x in (-36.0, 36.0):
        n += palm_column(ctx, root, x, -150.0, 150.0, 18.0)
    ctx.note("villa gardens: %d yards, %d promenade palms" % (len(frames), n))


def palm_column(ctx, parent, x, z0, z1, step):
    rng = ctx.rng
    n = 0
    z = z0
    while z <= z1:
        if ctx.is_free(x, z, 1.8, ymax=0.9):
            geom.palm(ctx, parent, (x, 0.2, z), height=rng.uniform(15, 20), lean=(0.1 if x > 0 else -0.1, rng.uniform(-0.05, 0.05)), seed=n)
            ctx.block(x - 1.8, z - 1.8, x + 1.8, z + 1.8, 25, "promenade palm")
            n += 1
        z += step
    return n
