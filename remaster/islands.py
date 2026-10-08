"""Horizon islands: lifted out of the new ocean to float over the bay, each with a waterfall
pouring into the sea, palms on the meadow and a glowing crystal. The island under the south
end (SkyIsland_04) stays where it is (hidden below the island)."""
import math

from factory import CF
from . import coast, geom
from . import palette as P
from .geom import Builder, T, yaw

SKIP = {"SkyIsland_04"}


def shift_model(ctx, model, dy):
    doc = ctx.doc
    for ref in [model] + doc.descendants(model):
        cls = doc.cls(ref)
        if cls in ("Part", "WedgePart", "MeshPart", "Seat", "SpawnLocation", "CornerWedgePart", "TrussPart"):
            cf = doc.get(ref, "CFrame")
            doc.set(ref, "CFrame", CF((cf.p[0], cf.p[1] + dy, cf.p[2]), cf.r, cf.rid))
        elif cls == "Model":
            piv = doc.get(ref, "WorldPivotData")
            if piv is not None:
                doc.set(ref, "WorldPivotData", CF((piv.p[0], piv.p[1] + dy, piv.p[2]), piv.r, piv.rid))


def island_bounds(ctx, model):
    xs, ys, zs = [], [], []
    meadow = None
    for p in ctx.parts_under(model):
        hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
        r = p.cf.r
        ex = abs(r[0]) * hx + abs(r[1]) * hy + abs(r[2]) * hz
        ey = abs(r[3]) * hx + abs(r[4]) * hy + abs(r[5]) * hz
        ez = abs(r[6]) * hx + abs(r[7]) * hy + abs(r[8]) * hz
        xs += [p.cf.p[0] - ex, p.cf.p[0] + ex]
        ys += [p.cf.p[1] - ey, p.cf.p[1] + ey]
        zs += [p.cf.p[2] - ez, p.cf.p[2] + ez]
        if p.name == "UpperMeadow":
            meadow = (p.cf.p, p.size, p.cf.p[1] + ey)
    return (min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)), meadow


def waterfall(ctx, parent, top, bottom_y, width=8.0, facing=0.0):
    """Falling sheet from `top` (x, y, z) down to bottom_y, with mist and foam where it lands."""
    x, y, z = top
    h = y - bottom_y
    m = ctx.fac.model(parent, "IslandWaterfall", pivot=CF((x, (y + bottom_y) / 2, z)), attrs={"Waterfall": True})
    b = Builder(ctx, m, CF((x, (y + bottom_y) / 2, z)) * yaw(facing))
    b.box("FallSheet", (width, h, 1.2), T(0, 0, 0), (200, 240, 250), "Neon", transparency=0.45, collide=False, shadow=False, query=False)
    b.box("FallSheet", (width * 1.25, h, 0.8), T(0, 0, 1.0), (170, 225, 245), "Glass", transparency=0.55, collide=False, shadow=False,
          query=False)
    foam = b.box("Foam", (width * 2.2, 0.6, width * 2.2), T(0, -h / 2 + 0.2, 0), (240, 250, 255), "SmoothPlastic", transparency=0.25,
                 collide=False, shadow=False, query=False)
    ctx.fac.particles(foam, "Mist", texture="rbxasset://textures/particles/smoke_main.dds", color=(235, 248, 255),
                      size=[(0, 6), (1, 14)], transparency=[(0, 0.5), (1, 1)], rate=8, lifetime=(2, 3.5), speed=(3, 7),
                      spread=(80, 80), accel=(0, 2, 0))
    lip = b.box("Lip", (width, 0.8, 2.0), T(0, h / 2 - 0.4, -0.4), (220, 245, 255), "SmoothPlastic", transparency=0.3, collide=False,
                shadow=False)
    ctx.fac.particles(lip, "Spray", color=(220, 245, 255), size=[(0, 0.8), (1, 0.1)], rate=12, lifetime=(1.2, 2.0),
                      speed=(3, 6), spread=(20, 20), accel=(0, -30, 0), emission_dir="Front")
    return m


def run(ctx):
    root = ctx.area("23_DistrictPolish")
    holder = ctx.doc.child(root, "Horizon_Islands") if root is not None else None
    if holder is None:
        return
    deco = ctx.group("Islands")
    rng = ctx.rng
    n = 0
    for model in ctx.doc.kids(holder):
        name = ctx.doc.name(model)
        if name in SKIP or ctx.doc.cls(model) != "Model":
            continue
        (x0, y0, z0, x1, y1, z1), meadow = island_bounds(ctx, model)
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
        dist = math.hypot(cx - coast.CENTER[0], cz - coast.CENTER[1])
        # lift: bottom well above the sea, higher islands further out
        target_bottom = 18.0 + rng.uniform(0, 30) + min(40.0, dist / 40.0)
        dy = max(0.0, target_bottom - y0)
        shift_model(ctx, model, dy)
        top = (meadow[2] if meadow else y1) + dy
        mc = meadow[0] if meadow else (cx, y1, cz)
        msize = meadow[1] if meadow else (x1 - x0, 1, z1 - z0)
        # waterfall from the meadow edge facing the main island
        to_center = math.atan2(coast.CENTER[0] - cx, coast.CENTER[1] - cz)
        sx, sz = math.sin(to_center), math.cos(to_center)
        reach = abs((x1 - x0) / 2 * sx) + abs((z1 - z0) / 2 * sz) + 1.5
        inner = abs(msize[0] / 2 * sx) + abs(msize[2] / 2 * sz) - 3.0
        ex, ez = cx + sx * reach, cz + sz * reach
        width = rng.uniform(12, 18)
        waterfall(ctx, deco, (ex, top - 0.5, ez), coast.SEA, width=width, facing=to_center)
        # a stream across the meadow edge feeds the fall
        a = (cx + sx * inner, top - 0.2, cz + sz * inner)
        b = (ex, top - 0.2, ez)
        from factory import beam_cf
        cf, ln = beam_cf(a, b)
        ctx.fac.part(deco, "IslandStream", (width * 0.8, 0.5, ln + 1.0), cf, (150, 220, 240), "Glass", transparency=0.3,
                     collide=False, shadow=False)
        # palms and a crystal on the meadow
        for k in range(3):
            a = rng.uniform(0, 2 * math.pi)
            r = rng.uniform(0.15, 0.32) * min(msize[0], msize[2])
            px, pz = mc[0] + math.cos(a) * r, mc[2] + math.sin(a) * r
            geom.palm(ctx, deco, (px, top - 0.2, pz), height=rng.uniform(14, 22), lean=(rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2)),
                      scale=1.1)
        cr = ctx.fac.model(deco, "IslandCrystal", pivot=CF((mc[0], top, mc[2])),
                           attrs={"Motion": "Float", "Travel": ("Vector3", (0, 1.2, 0)), "Phase": n * 0.9})
        cb = Builder(ctx, cr, CF((mc[0], top + 9, mc[2])))
        col = P.NEONS[n % len(P.NEONS)]
        cb.box("Crystal", (2.6, 7, 2.6), T(0, 0, 0) * CF.angles(0.2, 0.7, 0.15), col, "Neon", collide=False, shadow=False)
        cb.box("Crystal", (1.6, 4.4, 1.6), T(1.8, -1.4, 0.6) * CF.angles(-0.3, 0.3, 0.4), col, "Neon", collide=False, shadow=False)
        n += 1
    ctx.note("islands: %d lifted with waterfalls" % n)
