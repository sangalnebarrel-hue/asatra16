"""Paradise Lagoon: replaces the black COMING SOON cube over the old quarry hole.

Sandy lagoon (terrain, see ParadiseTerrain.LagoonHeight) with a boardwalk ring, the SKY TOWER
obby on a rock island (reward chest on top + zipline to the pier), a waterfall mountain with a
water slide, floating inflatables, a snack bar and an entrance gate from the boulevard.
"""
import math

from factory import CF, beam_cf
from . import coast, geom
from . import palette as P
from .geom import Builder, T, yaw

DECK_TOP = 0.5
ISLAND = (116.0, 633.0, 15.0)      # x, z, radius of the tower island
TOWER_BASE = 3.0                   # island top
TOWER_TOP = 118.0
MOUNTAIN = (158.0, 584.0)          # waterfall mountain centre
MOUNTAIN_TOP = 44.0
GATE = (44.0, 600.0)


def lagoon_ground(x, z):
    h = coast.lagoon_height(x, z)
    return -0.35 if h is None else h


def path_string(points):
    return ";".join("%.2f,%.2f,%.2f" % p for p in points)


def remove_black_cube(ctx):
    cube = ctx.find("37_AttractionRefresh/GlobalEventComingSoon/OpaqueBlackCuboid")
    if cube is not None:
        ctx.doc.remove(cube)
        ctx.note("lagoon: removed the black COMING SOON cube")


def boardwalk(ctx, m):
    """Deck ring around the basin (outside its edge) plus the entrance path."""
    b = Builder(ctx, m)
    x0, z0, x1, z1, r = coast.LAGOON_BASIN
    w = 9.0
    # straight sides
    b.box("Boardwalk", (x1 - x0 - 2 * r + 2, 0.6, w), T((x0 + x1) / 2, DECK_TOP - 0.3, z0 - w / 2 + 0.5), P.WOOD_DECK, "WoodPlanks")
    b.box("Boardwalk", (x1 - x0 - 2 * r + 2, 0.6, w), T((x0 + x1) / 2, DECK_TOP - 0.3, z1 + w / 2 - 0.5), P.WOOD_DECK, "WoodPlanks")
    b.box("Boardwalk", (w, 0.6, z1 - z0 - 2 * r + 2), T(x0 - w / 2 + 0.5, DECK_TOP - 0.3, (z0 + z1) / 2), P.WOOD_DECK, "WoodPlanks")
    b.box("Boardwalk", (w, 0.6, z1 - z0 - 2 * r + 2), T(x1 + w / 2 - 0.5, DECK_TOP - 0.3, (z0 + z1) / 2), P.WOOD_DECK, "WoodPlanks")
    # rounded corners: segments on the arc
    corners = [(x0 + r, z0 + r, math.pi, 1.5 * math.pi), (x1 - r, z0 + r, 1.5 * math.pi, 2 * math.pi),
               (x1 - r, z1 - r, 0.0, 0.5 * math.pi), (x0 + r, z1 - r, 0.5 * math.pi, math.pi)]
    for cx, cz, a0, a1 in corners:
        n = 6
        for i in range(n):
            t0 = a0 + (a1 - a0) * i / n
            t1 = a0 + (a1 - a0) * (i + 1) / n
            rr = r + w / 2 - 0.5
            p0 = (cx + math.cos(t0) * rr, DECK_TOP - 0.3, cz + math.sin(t0) * rr)
            p1 = (cx + math.cos(t1) * rr, DECK_TOP - 0.3, cz + math.sin(t1) * rr)
            cf, ln = beam_cf(p0, p1)
            ctx.fac.part(m, "Boardwalk", (w, 0.6, ln + 1.6), cf, P.WOOD_DECK, "WoodPlanks")
    # white edge railing on the water side (low, with gaps for the slide and bridge)
    for i in range(12):
        t = i / 11
        x = x0 + r + (x1 - x0 - 2 * r) * t
        for z in (z0 + 0.3, z1 - 0.3):
            b.box("DeckBollard", (0.7, 1.4, 0.7), T(x, DECK_TOP + 0.7, z), P.WHITE, "WoodPlanks", collide=False)
    # entrance path from the boulevard
    gx, gz = GATE
    b.box("LagoonPath", (gx - 26 + 4, 0.3, 12), T((26 + gx) / 2 + 2, DECK_TOP - 0.12, gz), P.PAVE_ROSE, "Pavement")
    b.box("LagoonPath", (x0 - w - gx + 1, 0.6, 10), T((gx + x0 - w) / 2, DECK_TOP - 0.3, gz), P.WOOD_DECK, "WoodPlanks")


def gate(ctx, m):
    gx, gz = GATE
    b = Builder(ctx, m)
    for dz in (-8.5, 8.5):
        b.box("GateTotem", (3.4, 17, 3.4), T(gx, DECK_TOP + 8.5, gz + dz), (120, 78, 48), "Wood")
        for k in range(4):
            b.box("TotemBand", (3.8, 0.7, 3.8), T(gx, DECK_TOP + 2 + k * 4, gz + dz), P.NEONS[k % 4], "SmoothPlastic", collide=False)
        b.box("TotemTop", (4.6, 1.2, 4.6), T(gx, DECK_TOP + 17.6, gz + dz), (232, 184, 82), "Metal")
        geom.tiki_torch(ctx, m, (gx + 3.5, DECK_TOP, gz + dz * 1.45))
    b.wedge("GateRoofL", (6, 3, 12), T(gx, DECK_TOP + 19.7, gz - 6) * yaw(math.pi), (196, 160, 96), "Fabric")
    b.wedge("GateRoofR", (6, 3, 12), T(gx, DECK_TOP + 19.7, gz + 6), (196, 160, 96), "Fabric")
    sign = b.box("GateSign", (1.0, 5.0, 19), T(gx - 0.5, DECK_TOP + 15.2, gz), (255, 250, 238), "SmoothPlastic")
    ctx.fac.sign(sign, "PARADISE LAGOON", "Left", color=(40, 170, 200), font="LuckiestGuy", stroke=(255, 255, 255))
    ctx.fac.sign(sign, "PARADISE LAGOON", "Right", color=(40, 170, 200), font="LuckiestGuy", stroke=(255, 255, 255), name="LetteringBack")
    b.box("SignNeon", (1.2, 0.45, 19.6), T(gx - 0.5, DECK_TOP + 17.9, gz), P.NEON_CYAN, "Neon", collide=False)
    b.box("SignNeon", (1.2, 0.45, 19.6), T(gx - 0.5, DECK_TOP + 12.5, gz), P.NEON_PINK, "Neon", collide=False)
    for dz in (-12, 12):
        geom.palm(ctx, m, (gx - 5, DECK_TOP - 0.3, gz + dz), height=22, lean=(-0.15, dz / 60))


def tower(ctx, root):
    """SKY TOWER: spiral obby around a pillar on the lagoon island; reward chest and zipline on top."""
    m = ctx.fac.model(root, "SkyTower", pivot=CF((ISLAND[0], TOWER_BASE, ISLAND[1])), attrs={"ParadiseObby": "SkyTower"},
                      stream_mode=2)
    b = Builder(ctx, m)
    ix, iz, ir = ISLAND
    bed = lagoon_ground(ix, iz)
    # rock island
    b.vcyl("IslandRock", TOWER_BASE - bed + 1, ir * 2, T(ix, (TOWER_BASE + bed) / 2 - 0.5, iz), P.ROCK, "Rock")
    b.vcyl("IslandSand", 1.0, ir * 2 - 3, T(ix, TOWER_BASE - 0.4, iz), (240, 220, 176), "Sand")
    rng = ctx.rng
    for i in range(8):
        a = i * math.pi / 4 + 0.3
        geom.boulder(ctx, m, (ix + math.cos(a) * (ir + 1), -3.5, iz + math.sin(a) * (ir + 1)), size=rng.uniform(6, 9))
    # pillar
    pillar_h = TOWER_TOP - TOWER_BASE
    b.vcyl("TowerPillar", pillar_h, 9, T(ix, TOWER_BASE + pillar_h / 2, iz), P.WHITE, "Plaster")
    for k in range(1, int(pillar_h // 12) + 1):
        b.vcyl("PillarRing", 0.8, 9.6, T(ix, TOWER_BASE + k * 12, iz), P.NEONS[k % len(P.NEONS)], "Neon", collide=False)
    # spiral platforms
    y = TOWER_BASE + 3.2
    a = 0.0
    step_y, step_a = 3.4, math.radians(31)
    colors = [(255, 96, 140), (255, 166, 64), (255, 226, 80), (110, 220, 110), (60, 200, 230), (150, 120, 255)]
    n = 0
    checkpoints = []
    last_a = None
    while y < TOWER_TOP - 2:
        rad = 11.0 if (n // 6) % 2 == 0 else 13.5
        if y > TOWER_TOP - 12:
            rad = 16.0  # clear of the crown deck overhead
            last_a = a
        px, pz = ix + math.cos(a) * rad, iz + math.sin(a) * rad
        col = colors[n % len(colors)]
        size = (4.6, 1.0, 4.6) if n % 9 else (6.5, 1.0, 6.5)
        b.box("ObbyStep", size, T(px, y, pz) * yaw(-a), col, "SmoothPlastic", attrs={"ObbyStep": n + 1})
        # thin arm to the pillar (visual)
        b.rod("StepArm", (ix + math.cos(a) * 4.4, y - 0.8, iz + math.sin(a) * 4.4), (px, y - 0.6, pz), 0.5, P.WHITE, "Metal",
              collide=False)
        if n % 9 == 8:
            checkpoints.append((px, y, pz))
        y += step_y
        a += step_a
        n += 1
    # crown: wide deck on top
    top = TOWER_TOP
    b.vcyl("CrownDeck", 1.2, 26, T(ix, top, iz), (255, 250, 240), "SmoothPlastic")
    b.vcyl("CrownRim", 1.0, 27, T(ix, top - 0.9, iz), P.NEON_PINK, "Neon", collide=False)
    def near_arrival(t):
        if last_a is None:
            return False
        d = (t - last_a) % (2 * math.pi)
        return d < math.radians(28) or d > 2 * math.pi - math.radians(28)
    for i in range(20):
        t = i * 2 * math.pi / 20
        if near_arrival(t):
            continue
        b.box("CrownPost", (0.5, 3.0, 0.5), T(ix + math.cos(t) * 12.6, top + 2.0, iz + math.sin(t) * 12.6), P.WHITE, "Metal")
    for i in range(20):
        t0, t1 = i * 2 * math.pi / 20, (i + 1) * 2 * math.pi / 20
        if near_arrival(t0) or near_arrival(t1):
            continue
        b.rod("CrownRail", (ix + math.cos(t0) * 12.6, top + 3.4, iz + math.sin(t0) * 12.6),
              (ix + math.cos(t1) * 12.6, top + 3.4, iz + math.sin(t1) * 12.6), 0.4, P.WHITE, "Metal")
    # the last step lands on the crown: an opening in the railing is where the spiral arrives
    flag_pole = b.box("FlagPole", (0.5, 16, 0.5), T(ix, top + 8.6, iz), P.WHITE, "Metal")
    b.box("Flag", (0.2, 4.0, 6.5), T(ix, top + 14.5, iz + 3.4), (255, 90, 150), "Fabric", collide=False)
    sign = b.box("TowerSign", (12, 3.2, 0.6), T(ix, top + 5.0, iz - 2.4), (255, 250, 240), "SmoothPlastic", collide=False)
    ctx.fac.sign(sign, "SKY TOWER", "Front", color=(255, 80, 150), font="LuckiestGuy", stroke=(255, 255, 255))
    ctx.fac.sign(sign, "SKY TOWER", "Back", color=(255, 80, 150), font="LuckiestGuy", stroke=(255, 255, 255), name="LetteringBack")
    # reward chest
    chest = ctx.fac.model(m, "TowerChest", pivot=CF((ix + 6, top + 0.6, iz + 6)), attrs={"ParadiseChest": "SkyTower"})
    cb = Builder(ctx, chest, CF((ix + 6, top + 0.6, iz + 6)) * yaw(math.radians(-45)))
    body = cb.box("ChestBody", (5, 3, 3.6), T(0, 1.5, 0), (150, 96, 52), "WoodPlanks")
    cb.box("ChestLid", (5.2, 1.4, 3.8), T(0, 3.6, 0), (170, 110, 60), "WoodPlanks")
    for x in (-1.9, 1.9):
        cb.box("ChestBand", (0.5, 4.4, 3.9), T(x, 2.2, 0), P.GOLD, "Metal", collide=False)
    lock = cb.box("ChestLock", (0.9, 1.1, 0.4), T(0, 2.9, -1.95), P.GOLD, "Metal", collide=False)
    glow = cb.box("ChestGlow", (4.4, 0.3, 3.0), T(0, 3.1, 0), P.NEON_YELLOW, "Neon", collide=False)
    ctx.fac.particles(glow, "Sparkles", rate=6, color=(255, 230, 120), size=[(0, 0.5), (1, 0)], lifetime=(1, 2), speed=(1, 3),
                      spread=(30, 30), light_emission=1)
    ctx.fac.new("ProximityPrompt", body, "ChestPrompt", {
        "ActionText": b"Open chest", "ObjectText": b"SKY TOWER REWARD", "HoldDuration": 0.8,
        "MaxActivationDistance": 12.0, "RequiresLineOfSight": False, "Enabled": True}, attrs={"ParadiseChest": "SkyTower"})
    # checkpoint height signs
    for i, (px, py, pz) in enumerate(checkpoints):
        s = b.box("HeightSign", (3.4, 1.4, 0.3), T(px, py + 2.2, pz) * yaw(-math.atan2(pz - iz, px - ix) - math.pi / 2),
                  P.WHITE, collide=False)
        ctx.fac.sign(s, "%d m" % int(py), "Front", color=(40, 40, 60), font="FredokaOne")
    ctx.block(ix - 20, iz - 20, ix + 20, iz + 20, label="sky tower")
    ctx.note("lagoon: sky tower with %d steps" % n)
    return m


def zipline(ctx, root, start, end, name="ZiplineToPier"):
    """Cable from start to end; the client rides it (RideTrack, Kind=Zipline)."""
    m = ctx.fac.model(root, name, pivot=CF(start), attrs={"RideTrack": "Zipline", "Speed": 62.0,
                                                          "Path": path_string([start, end])})
    b = Builder(ctx, m)
    n = 14
    pts = []
    for i in range(n + 1):
        t = i / n
        sag = 4.0 * t * (1 - t) * 6.0
        pts.append((start[0] + (end[0] - start[0]) * t, start[1] + (end[1] - start[1]) * t - sag, start[2] + (end[2] - start[2]) * t))
    m_attrs_path = path_string(pts)
    ctx.doc.set(m, "AttributesSerialize", ctx.doc.build_attributes({"RideTrack": "Zipline", "Speed": 62.0, "Path": m_attrs_path}))
    for i in range(n):
        b.rod("Cable", pts[i], pts[i + 1], 0.25, (40, 40, 46), "Metal", collide=False, shadow=False, query=False)
    # stations
    for p, label in ((start, "Start"), (end, "End")):
        b.box("ZipStation" + label, (3.2, 2.2, 3.2), T(p[0], p[1] + 1.4, p[2]), P.GOLD, "Metal", collide=False)
        b.box("ZipBeacon" + label, (1.2, 1.2, 1.2), T(p[0], p[1] + 3.2, p[2]), P.NEON_CYAN, "Neon", collide=False)
    trigger = b.box("ZipStart", (5, 6, 5), T(start[0], start[1] - 2.0, start[2]), P.NEON_CYAN, "Neon", transparency=0.85,
                    collide=False, touch=False, query=True)
    ctx.fac.new("ProximityPrompt", trigger, "RidePrompt", {
        "ActionText": b"Ride the zipline", "ObjectText": b"ZIPLINE", "HoldDuration": 0.3,
        "MaxActivationDistance": 10.0, "RequiresLineOfSight": False, "Enabled": True})
    return m


def mountain(ctx, root):
    """Rock mountain in the north-east of the lagoon: waterfall, steps to the top, water slide."""
    m = ctx.fac.model(root, "WaterfallMountain", pivot=CF((MOUNTAIN[0], 0, MOUNTAIN[1])))
    b = Builder(ctx, m)
    rng = ctx.rng
    mx, mz = MOUNTAIN
    # stacked rock masses (tapering)
    layers = [(-6.0, 30.0, 26.0), (6.0, 26.0, 22.0), (16.0, 22.0, 18.0), (26.0, 18.0, 15.0), (35.0, 14.0, 12.0)]
    for i, (y, sx, sz) in enumerate(layers):
        h = 12.0
        for k in range(3):
            ox, oz = rng.uniform(-3, 3), rng.uniform(-3, 3)
            b.box("MountainRock", (sx * rng.uniform(0.8, 1.05), h, sz * rng.uniform(0.8, 1.05)),
                  T(mx + ox, y + h / 2, mz + oz) * yaw(rng.uniform(-0.35, 0.35)),
                  P.lerp(P.ROCK, P.ROCK_DARK, rng.random() * 0.6), "Rock")
        b.box("MountainMoss", (sx * 0.7, 1.0, sz * 0.7), T(mx + rng.uniform(-2, 2), y + h + 0.3, mz + rng.uniform(-2, 2)),
              (78, 150, 70), "LeafyGrass", collide=False)
    top = MOUNTAIN_TOP
    b.box("SummitDeck", (14, 1.0, 14), T(mx, top - 0.5, mz), P.WOOD_DECK, "WoodPlanks")
    geom.palm(ctx, m, (mx + 5, top - 0.6, mz + 5), height=14, lean=(0.2, 0.1))
    geom.palm(ctx, m, (mx + 6, top - 0.6, mz - 4), height=12, lean=(0.25, -0.1))
    # stairs up the east side: switchbacks hugging the rock (half-extent shrinks with height)
    steps = int((top - 1) / 1.6)
    for i in range(steps):
        y = 0.5 + i * 1.6
        half = 15 if y < 6 else 13 if y < 17 else 11 if y < 27 else 9 if y < 36 else 7
        flight = (i // 7) % 2
        t = (i % 7) / 6.0
        zz = mz - 9 + (t if flight == 0 else 1 - t) * 18
        b.box("MountainStep", (5.0, 1.2, 3.2), T(mx + half + 2.6, y, zz), (196, 170, 128), "Sandstone")
    b.box("SummitLanding", (6, 1.2, 8), T(mx + 9.5, top - 1.2, mz), (196, 170, 128), "Sandstone")
    # waterfall from an overhanging ledge on the lagoon (west) face into the water
    wf_x = mx - 18.0
    b.box("WaterfallLedge", (12, 2.2, 10), T(mx - 12.5, top - 7, mz), P.ROCK_DARK, "Rock")
    for k, (dx, w, alpha) in enumerate(((0.0, 7.0, 0.35), (0.6, 5.0, 0.5), (-0.4, 9.0, 0.7))):
        b.box("Waterfall", (1.0, top - 6 + 4, w), T(wf_x + dx - k * 0.5, (top - 6 - 4) / 2, mz),
              (170, 230, 245), "Neon" if k == 0 else "Glass", transparency=alpha, collide=False, shadow=False, query=False,
              attrs={"Waterfall": True})
    spray = b.box("WaterfallFoam", (8, 1, 12), T(wf_x - 3, -3.6, mz), (240, 250, 255), "SmoothPlastic", transparency=0.4,
                  collide=False, shadow=False, query=False)
    ctx.fac.particles(spray, "Mist", texture="rbxasset://textures/particles/smoke_main.dds", color=(235, 248, 255),
                      size=[(0, 4), (1, 9)], transparency=[(0, 0.55), (1, 1)], rate=10, lifetime=(1.5, 2.5), speed=(3, 6),
                      spread=(70, 70), accel=(0, 2, 0))
    lip = b.box("WaterfallLip", (3, 1, 8), T(wf_x + 1.0, top - 5.6, mz), (190, 236, 248), "SmoothPlastic", transparency=0.3,
                collide=False, shadow=False)
    ctx.fac.particles(lip, "Spray", texture="rbxasset://textures/particles/sparkles_main.dds", color=(220, 245, 255),
                      size=[(0, 0.6), (1, 0.1)], rate=16, lifetime=(1.0, 1.6), speed=(4, 7), spread=(25, 25),
                      accel=(0, -40, 0), emission_dir="Left")
    # cliff-jump ledge over deep water
    b.box("JumpLedge", (8, 1, 5), T(mx - 13, 26.5, mz + 9), P.WOOD_DECK, "WoodPlanks")
    s = b.box("JumpSign", (4, 1.6, 0.3), T(mx - 13, 29, mz + 11.3), (255, 250, 240), collide=False)
    ctx.fac.sign(s, "CLIFF JUMP!", "Front", color=(255, 80, 120), font="LuckiestGuy")
    ctx.block(mx - 22, mz - 22, mx + 22, mz + 22, label="mountain")
    return m


def water_slide(ctx, root):
    """Spiral slide from the summit into the lagoon (RideTrack, Kind=Slide)."""
    mx, mz = MOUNTAIN
    pts = [(mx + 2.0, MOUNTAIN_TOP + 1.5, mz + 4.0)]
    n = 40
    a0, a1 = math.radians(80), math.radians(290)
    for i in range(1, n + 1):
        t = i / n
        a = a0 + (a1 - a0) * t
        rad = 12.0 + 12.0 * t
        y = MOUNTAIN_TOP + 1.0 - t * (MOUNTAIN_TOP - 5.0)
        pts.append((mx + math.cos(a) * rad, y, mz + math.sin(a) * rad))
    # run-out into the lagoon, heading south-west into deep water
    last = pts[-1]
    exit_pt = (last[0] - 20.0, -2.4, last[2] + 22.0)
    pts.append(((last[0] + exit_pt[0]) / 2, 0.6, (last[2] + exit_pt[2]) / 2))
    pts.append(exit_pt)
    m = ctx.fac.model(root, "WaterSlide", pivot=CF(pts[0]),
                      attrs={"RideTrack": "Slide", "Speed": 46.0, "Path": path_string(pts)})
    b = Builder(ctx, m)
    colors = [(40, 200, 230), (255, 214, 60)]
    for i in range(len(pts) - 1):
        a, c = pts[i], pts[i + 1]
        cf, ln = beam_cf(a, c)
        col = colors[(i // 2) % 2]
        ctx.fac.part(m, "SlideBed", (4.2, 0.4, ln + 0.6), cf * T(0, -1.2, 0), col, "SmoothPlastic", collide=False)
        ctx.fac.part(m, "SlideWall", (0.4, 1.8, ln + 0.6), cf * T(-2.1, -0.4, 0), col, "SmoothPlastic", collide=False)
        ctx.fac.part(m, "SlideWall", (0.4, 1.8, ln + 0.6), cf * T(2.1, -0.4, 0), col, "SmoothPlastic", collide=False)
        ctx.fac.part(m, "SlideWater", (3.6, 0.1, ln + 0.6), cf * T(0, -0.95, 0), (190, 240, 255), "Glass",
                     transparency=0.4, collide=False, shadow=False, query=False)
        if i % 4 == 0 and a[1] > 4:
            b.vcyl("SlideSupport", a[1] - 1.5, 0.8, T(a[0], (a[1] - 1.5) / 2, a[2]), P.WHITE, "Metal", collide=False)
    entry = b.box("SlideStart", (5, 5, 5), T(pts[0][0], pts[0][1] + 1.0, pts[0][2]), P.NEON_CYAN, "Neon", transparency=0.85,
                  collide=False, query=True)
    ctx.fac.new("ProximityPrompt", entry, "RidePrompt", {
        "ActionText": b"Slide!", "ObjectText": b"WATER SLIDE", "HoldDuration": 0.0,
        "MaxActivationDistance": 9.0, "RequiresLineOfSight": False, "Enabled": True})
    s = b.box("SlideSign", (6, 2, 0.3), T(pts[0][0], pts[0][1] + 5.0, pts[0][2]), (255, 250, 240), collide=False)
    ctx.fac.sign(s, "WATER SLIDE", "Front", color=(30, 160, 210), font="LuckiestGuy")
    ctx.fac.sign(s, "WATER SLIDE", "Back", color=(30, 160, 210), font="LuckiestGuy", name="LetteringBack")
    return m


def bridge_to_island(ctx, root):
    """Floating wooden bridge from the west boardwalk to the tower island."""
    m = ctx.fac.model(root, "IslandBridge", pivot=CF((80, DECK_TOP, ISLAND[1])))
    b = Builder(ctx, m)
    x0 = coast.LAGOON_BASIN[0] - 1
    x1 = ISLAND[0] - ISLAND[2] + 2
    z = ISLAND[1]
    n = int((x1 - x0) / 3.2)
    for i in range(n):
        x = x0 + (i + 0.5) * (x1 - x0) / n
        t = i / max(1, n - 1)
        y = DECK_TOP + 2.5 * math.sin(t * math.pi) - 0.3 + (TOWER_BASE - DECK_TOP) * t
        b.box("BridgePlank", ((x1 - x0) / n - 0.25, 0.5, 7), T(x, y, z), P.WOOD_DECK, "WoodPlanks")
        if i % 3 == 0:
            for side in (-1, 1):
                b.box("BridgePost", (0.4, 3.2, 0.4), T(x, y + 1.6, z + side * 3.6), P.WOOD_DARK, "Wood", collide=False)
    for side in (-1, 1):
        b.rod("BridgeRope", (x0, DECK_TOP + 3, z + side * 3.6), (x1, TOWER_BASE + 3, z + side * 3.6), 0.3, (230, 210, 170), "Fabric",
              collide=False)
    return m


def inflatables(ctx, root):
    """Bobbing rings and a giant flamingo on the water (DistrictWorldMotion 'Float')."""
    m = ctx.fac.model(root, "Inflatables", pivot=CF((116, -4, 633)))
    rng = ctx.rng
    spots = [(86, 590), (96, 680), (140, 676), (150, 640), (84, 650), (128, 600), (100, 612)]
    for i, (x, z) in enumerate(spots):
        y = coast.SEA + 0.45
        ring = ctx.fac.model(m, "SwimRing", pivot=CF((x, y, z)),
                             attrs={"Motion": "Float", "Travel": ("Vector3", (0, 0.35, 0)), "Phase": i * 1.3})
        rb = Builder(ctx, ring, CF((x, y, z)))
        col = [(255, 90, 140), (255, 200, 60), (60, 200, 230), (130, 220, 100)][i % 4]
        for k in range(8):
            a0 = k * math.pi / 4
            rb.cyl("RingSeg", 2.4, 1.2, T(math.cos(a0) * 2.6, 0, math.sin(a0) * 2.6) * yaw(-(a0 + math.pi / 2)), col if k % 2 else P.WHITE,
                   "SmoothPlastic", collide=False)
    fx, fz = 132, 660
    fl = ctx.fac.model(m, "GiantFlamingo", pivot=CF((fx, coast.SEA + 0.6, fz)),
                       attrs={"Motion": "Float", "Travel": ("Vector3", (0, 0.4, 0)), "Phase": 2.0})
    fb = Builder(ctx, fl, CF((fx, coast.SEA + 0.6, fz)) * yaw(0.6))
    pink = (255, 120, 170)
    fb.box("FloatBody", (6, 2.4, 9), T(0, 0.4, 0), pink, collide=True)
    fb.ball("FloatBack", 5, T(0, 1.4, 2.6), pink, collide=False)
    fb.box("Neck", (1.4, 7, 1.4), T(0, 4.6, -3.6) * CF.angles(-0.25, 0, 0), pink, collide=False)
    fb.ball("Head", 2.6, T(0, 8.2, -4.6), pink, collide=False)
    fb.box("Beak", (0.9, 0.9, 2.2), T(0, 8.0, -6.2), (40, 40, 40), collide=False)
    for side in (-1, 1):
        fb.ball("Eye", 0.6, T(side * 1.0, 8.6, -5.4), (20, 20, 20), collide=False)
    return m


def snack_bar(ctx, root):
    """'COCO DOG' tiki snack bar on the south-west of the boardwalk."""
    x, z = 74.0, 724.0
    m = ctx.fac.model(root, "CocoDogBar", pivot=CF((x, DECK_TOP, z)))
    b = Builder(ctx, m, CF((x, DECK_TOP, z)))
    b.box("BarFloor", (18, 0.6, 12), T(0, -0.3, 0), P.WOOD_DECK, "WoodPlanks")
    for px in (-8, 8):
        for pz in (-5, 5):
            b.vcyl("BambooPost", 9, 0.8, T(px, 4.5, pz), (196, 160, 96), "Wood")
    b.wedge("ThatchL", (20, 3.5, 7.5), T(0, 10.6, -3.7) * yaw(math.pi), (210, 172, 104), "Fabric")
    b.wedge("ThatchR", (20, 3.5, 7.5), T(0, 10.6, 3.7), (210, 172, 104), "Fabric")
    b.box("ThatchFringe", (20.5, 0.8, 15.5), T(0, 8.6, 0), (196, 156, 90), "Fabric", collide=False)
    b.box("Counter", (14, 3.6, 2.4), T(0, 1.8, -3.2), (120, 78, 48), "WoodPlanks")
    b.box("CounterTop", (14.6, 0.4, 3.0), T(0, 3.8, -3.2), (232, 200, 150), "WoodPlanks")
    for i in range(5):
        b.vcyl("Stool", 2.4, 1.6, T(-5 + i * 2.5, 1.2, -6.0), (230, 70, 110) if i % 2 else (60, 190, 210), "SmoothPlastic")
    sign = b.box("BarSign", (12, 2.6, 0.4), T(0, 7.6, -6.4), (40, 170, 160), "SmoothPlastic", collide=False)
    ctx.fac.sign(sign, "COCO DOG BAR", "Front", color=(255, 246, 220), font="LuckiestGuy")
    b.box("BarNeon", (12.4, 0.35, 0.5), T(0, 9.0, -6.5), P.NEON_PINK, "Neon", collide=False)
    for i in range(6):
        b.ball("Coconut", 1.2, T(-4 + i * 1.6, 4.6, -3.2), (110, 78, 50), "Wood", collide=False)
        b.box("Straw", (0.15, 1.4, 0.15), T(-4 + i * 1.6, 5.4, -3.2) * CF.angles(0, 0, 0.3), P.NEONS[i % 5], collide=False)
    return m


def scenery(ctx, root):
    """Palms, umbrellas and loungers on the lagoon's sandy banks and lawns."""
    m = ctx.fac.model(root, "LagoonScenery", pivot=CF((116, 0, 633)))
    rng = ctx.rng
    placed = []
    x0, z0, x1, z1, r = coast.LAGOON_BASIN

    def free(x, z, rad):
        for px, pz, pr in placed:
            if (px - x) ** 2 + (pz - z) ** 2 < (pr + rad) ** 2:
                return False
        return ctx.is_free(x, z, rad)
    # palms ring outside the boardwalk
    for i in range(60):
        a = rng.random() * 2 * math.pi
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
        rx, rz = (x1 - x0) / 2 + rng.uniform(14, 24), (z1 - z0) / 2 + rng.uniform(14, 24)
        x, z = cx + math.cos(a) * rx, cz + math.sin(a) * rz
        if x < 40 or x > 210 or z < 534 or z > 752:
            continue
        if not free(x, z, 6):
            continue
        placed.append((x, z, 6))
        geom.palm(ctx, m, (x, -0.3, z), height=rng.uniform(16, 24), lean=(rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2)))
    # umbrellas + loungers on the inner sandy bank (between boardwalk and water)
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    for i in range(40):
        a = rng.random() * 2 * math.pi
        x, z = cx + math.cos(a) * ((x1 - x0) / 2 - 3), cz + math.sin(a) * ((z1 - z0) / 2 - 3)
        s = coast.lagoon_distance(x, z)
        if not (1.0 < s < 4.5):
            continue
        if not free(x, z, 5):
            continue
        placed.append((x, z, 5))
        h = coast.lagoon_height(x, z)
        cols = [((255, 90, 120), (255, 255, 255)), ((40, 190, 210), (255, 255, 255)), ((255, 196, 60), (255, 120, 60))][i % 3]
        geom.umbrella(ctx, m, (x, h - 0.2, z), cols, tilt=0.05)
    return m


def run(ctx):
    remove_black_cube(ctx)
    root = ctx.group("ParadiseLagoon")
    ctx.block(GATE[0] - 6, GATE[1] - 14, GATE[0] + 6, GATE[1] + 14, label="lagoon gate")
    boardwalk(ctx, root)
    gate(ctx, root)
    t = tower(ctx, root)
    mountain(ctx, root)
    water_slide(ctx, root)
    bridge_to_island(ctx, root)
    inflatables(ctx, root)
    snack_bar(ctx, root)
    zip_start = (ISLAND[0] - 2, TOWER_TOP + 6.0, ISLAND[1] + 10)
    from .landmarks import DECK_Y, PLAT
    zip_end = (PLAT[2] - 14, DECK_Y + 9.0, PLAT[1] + 14)
    zipline(ctx, root, zip_start, zip_end)
    scenery(ctx, root)
    return root
