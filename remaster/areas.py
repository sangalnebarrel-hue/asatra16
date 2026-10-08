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
    small = ctx.fac.model(m, "StepDice", pivot=CF((-63.0, 1.6, 570.0)))
    ctx.fac.part(small, "Dice", (3.2, 3.2, 3.2), CF((-63.0, 1.6, 570.5)) * yaw(0.9), (255, 90, 120), "SmoothPlastic")
    ctx.spots["CasinoDice"] = (-70.0, 8.2, 566.0)
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
    coast_rocks(ctx)
    boulevard(ctx)
    reward_plaza(ctx)
    shops(ctx)
    museum(ctx)
    blossoms(ctx)


# ---------------------------------------------------------------------------- blossoms & shops
BLOSSOMS = [(255, 70, 150), (240, 60, 200), (255, 130, 60), (255, 210, 80), (255, 255, 255)]


def blossoms(ctx):
    """Bougainvillea-style flowers on the old voxel trees and planters."""
    doc = ctx.doc
    rng = ctx.rng
    trees = {}
    for p in ctx.parts():
        if p.name in ("Leaves", "LeafCluster", "Canopy", "VoxelCanopy") and p.area in (
                "32_WelcomeHub", "34_GardenPolish", "27_RewardMachinePlaza", "31_BackDistrictExpansion", "09_DogPark",
                "02_DogFactory", "03_DogLine", "11_Shops", "06_DogDexMuseum"):
            trees.setdefault(doc.parent[p.ref], []).append(p)
    m = ctx.group("Districts/Blossoms")
    n = 0
    for model, leaves in trees.items():
        if doc.name(model) not in ("Broadleaf", "Cypress", "VoxelTree", "Planter", "GardenBed", "RaisedBed"):
            continue
        palette = rng.sample(BLOSSOMS, 2)
        count = 0
        for p in leaves:
            hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
            for k in range(2):
                lx, lz = rng.uniform(-hx, hx) * 0.85, rng.uniform(-hz, hz) * 0.85
                side = rng.random()
                if side < 0.6:
                    local = (lx, hy + 0.15, lz)
                else:
                    sx = hx if rng.random() < 0.5 else -hx
                    local = (sx * 1.02, rng.uniform(-hy, hy) * 0.7, lz)
                pos = p.cf * local
                d = rng.uniform(0.7, 1.4)
                ctx.fac.part(m, "Blossom", (d, d, d), CF(pos), rng.choice(palette), "SmoothPlastic", shape="Ball",
                             collide=False, shadow=False)
                count += 1
            if count > 14:
                break
        n += count
    ctx.note("blossoms: %d flowers on %d trees" % (n, len(trees)))


SHOP_COLORS = {"UPGRADES": ((172, 230, 206), (32, 168, 170)), "COSMETICS": ((250, 192, 208), (255, 90, 150)),
               "SUPPLIES": ((255, 230, 160), (255, 140, 50))}


def shops(ctx):
    """Pastel shop fronts with striped awnings and neon sign frames."""
    from .restyle import set_look
    doc = ctx.doc
    area = ctx.area("11_Shops")
    m = ctx.group("Districts/ShopFronts")
    for shop_name, (wall, accent) in SHOP_COLORS.items():
        shop = doc.child(area, shop_name)
        if shop is None:
            continue
        floor = None
        for p in ctx.parts_under(shop):
            if p.name == "ShopFloor":
                floor = p
            if p.mat in ("Concrete", "Plastic", "SmoothPlastic", "Plaster") and any(
                    k in p.name for k in ("Wall", "Gable", "Header", "Masonry", "SideSill", "WindowSillWall")):
                if p.name != "FacadeHeader":
                    set_look(doc, p, wall, "Plaster")
        if floor is None:
            continue
        zc = floor.cf.p[2]
        x_wall, x_out = 118.2, 111.2
        y_top, y_low = 15.0, 12.4
        stripes = 10
        width = 34.0
        for i in range(stripes):
            z = zc - width / 2 + (i + 0.5) * width / stripes
            a = (x_wall, y_top, z)
            b = (x_out, y_low, z)
            from factory import beam_cf
            cf, ln = beam_cf(a, b)
            ctx.fac.part(m, "AwningStripe", (width / stripes + 0.02, 0.3, ln), cf, accent if i % 2 == 0 else P.WHITE, "Fabric",
                         collide=False)
            ctx.fac.part(m, "AwningScallop", (width / stripes * 0.8, 0.9, 0.3), CF((x_out - 0.1, y_low - 0.45, z)),
                         accent if i % 2 == 0 else P.WHITE, "Fabric", collide=False, shadow=False)
        # neon frame around the shop name
        for dy in (-2.15, 2.15):
            ctx.fac.part(m, "SignNeon", (0.35, 0.35, 33.0), CF((117.4, 17.2 + dy, zc)), accent, "Neon", collide=False, shadow=False)
        for dz in (-16.5, 16.5):
            ctx.fac.part(m, "SignNeon", (0.35, 4.6, 0.35), CF((117.4, 17.2, zc + dz)), accent, "Neon", collide=False, shadow=False)
        # palm planters at the doors
        for dz in (-21.0, 21.0):
            x, z = 108.0, zc + dz
            if ctx.is_free(x, z, 3.2, ymax=0.9):
                planter_palm(ctx, m, x, z, size=5.0)
    ctx.note("shops: pastel fronts with awnings")


def museum(ctx):
    m = ctx.group("Districts/MuseumGardens")
    placed = 0
    for x, z in ((-12.0, 430.0), (-12.0, 532.0), (-24.0, 430.0), (-24.0, 532.0), (-30.0, 446.0), (-30.0, 516.0)):
        if ctx.is_free(x, z, 3.2, ymax=0.9):
            planter_palm(ctx, m, x, z, size=5.5)
            placed += 1
    ctx.note("museum: %d palm planters" % placed)


def coast_rocks(ctx):
    """Island cliff faces next to sandy beaches turn to warm sandstone; rocky shores stay dark."""
    from .restyle import set_look
    from . import coast
    n = 0
    for p in ctx.parts():
        if p.area != "01_IslandAndStreets" or not p.name.startswith(("WeatheredBasalt", "EndStrata", "IslandMass")):
            continue
        d, px, pz = coast.nearest(p.cf.p[0], p.cf.p[2])
        if coast.beach_weight(px, pz) > 0.6:
            c = tuple(round(v * 255) for v in p.color)
            t = max(0.0, min(1.0, (P.lum(c) - 60) / 60.0))
            set_look(ctx.doc, p, P.lerp((196, 164, 120), (226, 196, 150), t), "Sandstone")
            n += 1
    ctx.note("coast rocks: %d cliff parts to sandstone" % n)
