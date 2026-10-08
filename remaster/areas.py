"""District dressing: palm avenue, welcome arches, plaza fountains, casino boardwalk."""
import math

from factory import CF, beam_cf
from . import geom
from . import palette as P
from .geom import Builder, T, yaw


def palm_row(ctx, parent, x, z0, z1, step, height=(17, 23), lean_x=0.0, label="palm row"):
    rng = ctx.rng
    n = 0
    z = z0
    while z <= z1:
        if ctx.is_free(x, z, 2.2, ymax=0.9):
            geom.palm(ctx, parent, (x, 0.2, z), height=rng.uniform(*height), lean=(lean_x * rng.uniform(0.6, 1.2), rng.uniform(-0.05, 0.05)),
                      seed=n)
            ctx.block(x - 2, z - 2, x + 2, z + 2, 30, label)
            n += 1
        z += step
    return n


def welcome_arch(ctx, parent, z, text, width=46.0, facing=0.0, colors=(P.NEON_PINK, P.NEON_CYAN)):
    """Big arch over the boulevard: two white pylons, a curved neon-lit beam and a sign."""
    m = ctx.fac.model(parent, "ParadiseArch", pivot=CF((0, 0, z)))
    b = Builder(ctx, m, CF((0, 0, z)) * yaw(facing))
    h = 22.0
    for x in (-width / 2, width / 2):
        b.box("ArchPylon", (3.6, h, 3.6), T(x, h / 2, 0), P.WHITE, "Plaster")
        b.box("ArchPylonBase", (5.0, 1.4, 5.0), T(x, 0.7, 0), P.TRAVERTINE, "Limestone")
        b.box("ArchPylonCap", (4.6, 1.0, 4.6), T(x, h + 0.5, 0), P.GOLD, "Metal")
        for side in (-1, 1):
            b.box("ArchNeon", (0.35, h - 3, 0.35), T(x + side * 1.4, h / 2 + 0.5, -1.95), colors[0], "Neon", collide=False, shadow=False)
        geom.palm(ctx, m, (x + (5 if x > 0 else -5), 0.2, 4), height=19, lean=((0.2 if x > 0 else -0.2), 0.05))
    # curved beam: segments on an arc
    seg = 12
    rise = 6.0
    pts = []
    for i in range(seg + 1):
        t = i / seg
        x = -width / 2 + width * t
        y = h + 1.0 + rise * math.sin(math.pi * t)
        pts.append(b.at(T(x, y, 0)).p)
    for i in range(seg):
        cf, ln = beam_cf(pts[i], pts[i + 1])
        ctx.fac.part(m, "ArchBeam", (2.2, 2.2, ln + 0.4), cf, (26, 128, 146), "SmoothPlastic", collide=False)
        ctx.fac.part(m, "ArchBulbs", (0.5, 0.5, ln), cf * T(0, 1.3, -0.9), colors[i % 2], "Neon", collide=False, shadow=False)
    sign = b.box("ArchSign", (width * 0.62, 5.2, 0.7), T(0, h + rise - 1.4, 0), (255, 250, 240), "SmoothPlastic", collide=False)
    for face, nm in (("Front", "Lettering"), ("Back", "LetteringBack")):
        ctx.fac.sign(sign, text, face, color=(255, 88, 150), font="LuckiestGuy", stroke=(255, 255, 255), name=nm)
    b.box("ArchSignFrame", (width * 0.62 + 1.0, 0.45, 1.0), T(0, h + rise + 1.4, 0), colors[1], "Neon", collide=False)
    b.box("ArchSignFrame", (width * 0.62 + 1.0, 0.45, 1.0), T(0, h + rise - 4.2, 0), colors[1], "Neon", collide=False)
    ctx.block(-width / 2 - 4, z - 4, -width / 2 + 4, z + 4, 30, "arch")
    ctx.block(width / 2 - 4, z - 4, width / 2 + 4, z + 4, 30, "arch")
    return m


def fountain(ctx, parent, x, z, r=9.0, jets=True, tier=True, accent=P.NEON_CYAN):
    """Round fountain: travertine rim, glassy water, central tiered bowl, water-jet particles."""
    m = ctx.fac.model(parent, "ParadiseFountain", pivot=CF((x, 0, z)))
    b = Builder(ctx, m, CF((x, 0, z)))
    seg = 16
    for i in range(seg):
        a0, a1 = 2 * math.pi * i / seg, 2 * math.pi * (i + 1) / seg
        p0 = (x + math.cos(a0) * r, 1.0, z + math.sin(a0) * r)
        p1 = (x + math.cos(a1) * r, 1.0, z + math.sin(a1) * r)
        cf, ln = beam_cf(p0, p1)
        ctx.fac.part(m, "FountainRim", (1.6, 1.6, ln + 0.6), cf, P.TRAVERTINE, "Marble")
    b.vcyl("FountainBasin", 0.6, r * 2 - 0.4, T(0, 0.35, 0), (40, 120, 150), "SmoothPlastic", collide=False)
    water = b.vcyl("FountainWater", 0.3, r * 2 - 0.6, T(0, 1.1, 0), (120, 220, 235), "Glass", transparency=0.35,
                   collide=False, shadow=False)
    b.vcyl("FountainGlow", 0.2, r * 2 - 1.2, T(0, 0.75, 0), accent, "Neon", transparency=0.5, collide=False, shadow=False,
           attrs={"NightNeon": True})
    if tier:
        b.vcyl("FountainColumn", 5.0, 1.8, T(0, 3.0, 0), P.TRAVERTINE, "Marble")
        b.vcyl("FountainBowl", 0.8, 7.0, T(0, 5.6, 0), P.TRAVERTINE, "Marble", collide=False)
        b.vcyl("FountainBowlWater", 0.2, 6.2, T(0, 6.05, 0), (150, 230, 240), "Glass", transparency=0.3, collide=False, shadow=False)
        b.vcyl("FountainTop", 2.0, 1.0, T(0, 7.0, 0), P.TRAVERTINE, "Marble", collide=False)
        spout = b.ball("FountainSpout", 1.2, T(0, 8.2, 0), P.GOLD, "Metal", collide=False)
        if jets:
            ctx.fac.particles(spout, "Jet", texture="rbxasset://textures/particles/smoke_main.dds", color=(225, 245, 255),
                              size=[(0, 0.8), (1, 1.6)], transparency=[(0, 0.35), (1, 1)], rate=28, lifetime=(1.0, 1.4),
                              speed=(12, 15), spread=(14, 14), accel=(0, -26, 0))
    if jets:
        for i in range(6):
            a = 2 * math.pi * i / 6
            nz = b.box("JetNozzle", (0.6, 0.4, 0.6), T(math.cos(a) * (r - 2.2), 1.2, math.sin(a) * (r - 2.2)), P.GOLD, "Metal",
                       collide=False)
            ctx.fac.particles(nz, "Jet", texture="rbxasset://textures/particles/smoke_main.dds", color=(225, 245, 255),
                              size=[(0, 0.5), (1, 1.1)], transparency=[(0, 0.4), (1, 1)], rate=16, lifetime=(0.8, 1.0),
                              speed=(10, 12), spread=(6, 6), accel=(0, -30, 0))
    ctx.block(x - r - 1, z - r - 1, x + r + 1, z + r + 1, 9, "fountain")
    return m


def planter_palm(ctx, parent, x, z, size=6.0, flowers=True):
    m = ctx.fac.model(parent, "PalmPlanter", pivot=CF((x, 0, z)))
    b = Builder(ctx, m, CF((x, 0, z)))
    b.box("PlanterBox", (size, 1.6, size), T(0, 0.8, 0), P.TRAVERTINE, "Limestone")
    b.box("PlanterSoil", (size - 0.8, 0.3, size - 0.8), T(0, 1.55, 0), P.SOIL, "Ground", collide=False)
    geom.palm(ctx, m, (x, 1.3, z), height=ctx.rng.uniform(15, 20), lean=(ctx.rng.uniform(-0.1, 0.1), ctx.rng.uniform(-0.1, 0.1)))
    if flowers:
        geom.flower_patch(ctx, m, (x, 1.6, z), radius=size * 0.38, n=6)
    ctx.block(x - size / 2, z - size / 2, x + size / 2, z + size / 2, 20, "planter")
    return m


def boulevard(ctx):
    m = ctx.group("Districts/PalmAvenue")
    n = 0
    for x in (-21.0, 21.0):
        n += palm_row(ctx, m, x, 170, 745, 26, lean_x=(0.12 if x > 0 else -0.12), label="avenue palm")
    welcome_arch(ctx, m, 712.0, "WELCOME TO PARADISE")
    welcome_arch(ctx, m, 168.0, "DOGROTS ISLAND", colors=(P.NEON_ORANGE, P.NEON_PINK))
    # median planters on the southern boulevard
    for z in (440.0, 520.0, 600.0, 660.0):
        if ctx.is_free(0, z, 4, ymax=0.9):
            planter_palm(ctx, m, 0.0, z, size=6.5)
    ctx.note("palm avenue: %d palms" % n)


def reward_plaza(ctx):
    """DOG-O-MATIC plaza becomes the casino boardwalk: fountains, neon arches, palms, giant dice."""
    m = ctx.group("Districts/CasinoBoardwalk")
    # plaza: x -180..-34, z 546..714 (machine on its west side, carpet along z = 630)
    fountain(ctx, m, -96.0, 586.0, r=10.0, accent=P.NEON_PURPLE)
    fountain(ctx, m, -96.0, 676.0, r=10.0, accent=P.NEON_PINK)
    # neon bulb arches over the purple carpet
    for i, x in enumerate((-110.0, -84.0, -58.0)):
        bulb_arch(ctx, m, x, 630.0, span=16.0, height=13.0, colors=[P.NEON_YELLOW, P.NEON_PINK, P.NEON_CYAN][i % 3])
    # palms in planters around the plaza edge
    for z in range(556, 712, 26):
        for x in (-46.0, -172.0):
            if ctx.is_free(x, z, 4, ymax=0.9):
                planter_palm(ctx, m, x, z, size=5.5)
    for x in range(-160, -40, 30):
        for z in (552.0, 708.0):
            if ctx.is_free(x, z, 4, ymax=0.9):
                planter_palm(ctx, m, x, z, size=5.5)
    giant_dice(ctx, m, -70.0, 566.0, 0.4)
    giant_dice(ctx, m, -64.0, 700.0, 1.1)
    chip_stack(ctx, m, -124.0, 702.0)
    chip_stack(ctx, m, -128.0, 560.0)


def bulb_arch(ctx, parent, x, z, span=16.0, height=13.0, colors=P.NEON_YELLOW):
    m = ctx.fac.model(parent, "BulbArch", pivot=CF((x, 0, z)), attrs={"NightGlow": True})
    b = Builder(ctx, m)
    seg = 14
    pts = []
    for i in range(seg + 1):
        a = math.pi * i / seg
        pts.append((x, height * math.sin(a) + 0.3, z - math.cos(a) * span / 2))
    for i in range(seg):
        cf, ln = beam_cf(pts[i], pts[i + 1])
        ctx.fac.part(m, "ArchTube", (1.1, 1.1, ln + 0.3), cf, (40, 30, 60), "Metal", collide=(i in (0, seg - 1)))
        ctx.fac.part(m, "ArchBulb", (0.75, 0.75, 0.75), CF(pts[i]) * T(0, 0, 0), colors, "Neon", shape="Ball", collide=False, shadow=False)
    ctx.block(x - 1.5, z - span / 2 - 1.5, x + 1.5, z - span / 2 + 1.5, 14, "bulb arch")
    ctx.block(x - 1.5, z + span / 2 - 1.5, x + 1.5, z + span / 2 + 1.5, 14, "bulb arch")
    return m


def giant_dice(ctx, parent, x, z, rot):
    m = ctx.fac.model(parent, "GiantDice", pivot=CF((x, 0, z)))
    s = 6.0
    cf = CF((x, s / 2, z)) * yaw(rot)
    ctx.fac.part(m, "Dice", (s, s, s), cf, (255, 255, 255), "SmoothPlastic")
    # pips: show 5 on top, 3 on front, 1 on the side
    pip = (0.9, 0.2, 0.9)
    for dx, dz in ((0, 0), (-1.6, -1.6), (1.6, 1.6), (-1.6, 1.6), (1.6, -1.6)):
        ctx.fac.part(m, "Pip", pip, cf * T(dx, s / 2 + 0.05, dz), (220, 40, 60), "SmoothPlastic", collide=False, shadow=False)
    for d in (-1.6, 0, 1.6):
        ctx.fac.part(m, "Pip", (0.9, 0.9, 0.2), cf * T(d, d, -s / 2 - 0.05), (20, 20, 30), "SmoothPlastic", collide=False, shadow=False)
    ctx.fac.part(m, "Pip", (0.2, 0.9, 0.9), cf * T(s / 2 + 0.05, 0, 0), (220, 40, 60), "SmoothPlastic", collide=False, shadow=False)
    ctx.block(x - 4.5, z - 4.5, x + 4.5, z + 4.5, s, "dice")
    return m


def chip_stack(ctx, parent, x, z):
    m = ctx.fac.model(parent, "ChipStack", pivot=CF((x, 0, z)))
    b = Builder(ctx, m, CF((x, 0, z)))
    cols = [(220, 40, 60), (30, 90, 200), (30, 160, 80), (240, 200, 60), (20, 20, 24)]
    for i in range(7):
        c = cols[i % len(cols)]
        b.vcyl("Chip", 0.9, 5.0, T(ctx.rng.uniform(-0.3, 0.3), 0.45 + i * 0.9, ctx.rng.uniform(-0.3, 0.3)), c, "SmoothPlastic")
    ctx.block(x - 3, z - 3, x + 3, z + 3, 7, "chips")
    return m


def run(ctx):
    boulevard(ctx)
    reward_plaza(ctx)
