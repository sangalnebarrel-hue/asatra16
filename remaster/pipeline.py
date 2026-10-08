"""Order of the remaster steps (called by tools/build.py)."""
from . import areas, beach, coast, factory_dog, islands, lagoon, landmarks, restyle, yards
from .ctx import Ctx


def outside_blockers(ctx):
    """Existing parts that stick out of the island footprint block coastal props."""
    n = 0
    for p in ctx.parts():
        hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
        r = p.cf.r
        ex = abs(r[0]) * hx + abs(r[1]) * hy + abs(r[2]) * hz
        ey = abs(r[3]) * hx + abs(r[4]) * hy + abs(r[5]) * hz
        ez = abs(r[6]) * hx + abs(r[7]) * hy + abs(r[8]) * hz
        x, y, z = p.cf.p
        if p.cf.p[1] + ey < -12 or p.area in (None, "23_DistrictPolish", "13_TheVoid", "NavigationAnchors"):
            continue
        corners_out = any(coast.nearest(cx, cz)[0] > 0.5 for cx in (x - ex, x + ex) for cz in (z - ez, z + ez))
        if corners_out:
            ctx.block(x - ex, z - ez, x + ex, z + ez, y + ey, p.name)
            n += 1
    ctx.note("blockers from existing parts outside the footprint: %d" % n)


def run(doc, fac):
    ctx = Ctx(doc, fac)
    restyle.run(ctx)
    ctx.footprint_blockers_from_parts(min_height=0.6, ignore=lambda p: p.area in (None, "13_TheVoid", "NavigationAnchors"))
    ctx.note("blockers: %d" % len(ctx.blockers))
    landmarks.run(ctx)
    lagoon.run(ctx)
    areas.run(ctx)
    factory_dog.run(ctx)
    yards.run(ctx)
    islands.run(ctx)
    beach.run(ctx)
    for line in ctx.log:
        print("[remaster]", line)
    return ctx
