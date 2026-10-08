"""Landmarks around the island: the Paw Pier with its Ferris wheel, the lighthouse."""
import math

from factory import CF
from . import coast, geom
from . import palette as P
from .geom import Builder, T, yaw

DECK_Y = 0.5          # top of the boulevard
PIER_X = 16.0         # half width of the walkway
PIER_Z0, PIER_Z1 = 752.0, 968.0
PLAT = (-74.0, 968.0, 74.0, 1092.0)  # end platform x0, z0, x1, z1
WHEEL_C = (0.0, 52.0, 1046.0)
WHEEL_R = 40.0


def seabed(x, z):
    h = coast.height(x, z)
    return -6.0 if h is None else h


def deck(b, name, x0, z0, x1, z1, color=P.WOOD_DECK):
    """Deck slab whose top is DECK_Y."""
    return b.box(name, (x1 - x0, 1.0, z1 - z0), T((x0 + x1) / 2, DECK_Y - 0.5, (z0 + z1) / 2), color, "WoodPlanks")


def piling(b, x, z, d=1.7):
    bed = seabed(x, z) - 2
    top = DECK_Y - 1.0
    h = top - bed
    b.vcyl("Piling", h, d, T(x, bed + h / 2, z), (110, 84, 62), "Wood")
    b.vcyl("PilingCap", 0.5, d + 0.4, T(x, top - 0.3, z), (90, 68, 50), "Wood", collide=False)


def railing(b, a, c, posts_every=8.0, color=P.WHITE):
    ax, az = a
    cx, cz = c
    length = math.hypot(cx - ax, cz - az)
    n = max(1, int(length // posts_every))
    for i in range(n + 1):
        t = i / n
        x, z = ax + (cx - ax) * t, az + (cz - az) * t
        b.box("RailPost", (0.6, 3.6, 0.6), T(x, DECK_Y + 1.8, z), color, "WoodPlanks")
    b.rod("HandRail", (ax, DECK_Y + 3.5, az), (cx, DECK_Y + 3.5, cz), 0.45, color, "WoodPlanks")
    b.rod("MidRail", (ax, DECK_Y + 1.9, az), (cx, DECK_Y + 1.9, cz), 0.3, color, "WoodPlanks", collide=False)


def build_pier(ctx):
    m = ctx.group("Landmarks/PawPier")
    b = Builder(ctx, m)
    # walkway (overlaps the island edge so there is no seam)
    for z in range(int(PIER_Z0), int(PIER_Z1), 24):
        z1 = min(z + 24, PIER_Z1)
        deck(b, "PierDeck", -PIER_X, z, PIER_X, z1)
        for x in (-PIER_X + 1.2, PIER_X - 1.2):
            if z > 770:
                piling(b, x, z)
        b.box("DeckStripe", (0.3, 0.05, z1 - z), T(-PIER_X + 3.5, DECK_Y + 0.02, (z + z1) / 2), P.WHITE, collide=False, shadow=False)
        b.box("DeckStripe", (0.3, 0.05, z1 - z), T(PIER_X - 3.5, DECK_Y + 0.02, (z + z1) / 2), P.WHITE, collide=False, shadow=False)
    railing(b, (-PIER_X + 0.4, 770.0), (-PIER_X + 0.4, PIER_Z1))
    railing(b, (PIER_X - 0.4, 770.0), (PIER_X - 0.4, PIER_Z1))
    # lamps and string lights
    lamps = []
    for z in range(784, int(PIER_Z1), 30):
        for x in (-PIER_X + 1.5, PIER_X - 1.5):
            geom.lamp_post(ctx, m, (x, DECK_Y, z), glow=(255, 206, 140), height=10)
            lamps.append((x, z))
    for z in range(784, int(PIER_Z1) - 30, 30):
        geom.string_lights(ctx, m, (-PIER_X + 1.5, DECK_Y + 9.6, z), (PIER_X - 1.5, DECK_Y + 9.6, z + 30),
                           [P.NEON_PINK, P.NEON_YELLOW, P.NEON_CYAN, P.NEON_ORANGE], sag=1.4, n=10)
    # benches facing the sea
    for z in range(800, int(PIER_Z1), 40):
        for side in (-1, 1):
            bench(ctx, m, CF((side * (PIER_X - 3.2), DECK_Y, z + 15)) * yaw(-side * math.pi / 2))
    # end platform
    x0, z0, x1, z1 = PLAT
    for x in range(int(x0), int(x1), 37):
        for z in range(int(z0), int(z1), 31):
            deck(b, "PlatformDeck", x, z, min(x + 37, x1), min(z + 31, z1))
    for x in range(int(x0) + 2, int(x1), 14):
        for z in (z0 + 1.5, z1 - 1.5):
            piling(b, x, z, 2.0)
    for z in range(int(z0) + 14, int(z1), 14):
        for x in (x0 + 1.5, x1 - 1.5):
            piling(b, x, z, 2.0)
    railing(b, (x0 + 0.4, z0), (x0 + 0.4, z1 - 0.4))
    railing(b, (x1 - 0.4, z0), (x1 - 0.4, z1 - 0.4))
    railing(b, (x0 + 0.4, z1 - 0.4), (x1 - 0.4, z1 - 0.4))
    railing(b, (x0 + 0.4, z0), (-PIER_X, z0))
    railing(b, (PIER_X, z0), (x1 - 0.4, z0))
    for x, z in ((x0 + 6, z0 + 6), (x1 - 6, z0 + 6), (x0 + 6, z1 - 6), (x1 - 6, z1 - 6)):
        geom.lamp_post(ctx, m, (x, DECK_Y, z), glow=(255, 206, 140), height=11)
    pier_arch(ctx, m)
    ctx.block(-PIER_X - 4, PIER_Z0 - 6, PIER_X + 4, PIER_Z1 + 2, label="pier")
    ctx.block(x0 - 4, z0 - 4, x1 + 4, z1 + 4, label="pier platform")
    return m


def bench(ctx, parent, cf):
    m = ctx.fac.model(parent, "PierBench", pivot=cf)
    b = Builder(ctx, m, cf)
    b.box("Seat", (5.5, 0.35, 1.8), T(0, 1.6, 0), P.WOOD_DECK, "WoodPlanks")
    b.box("Back", (5.5, 1.6, 0.3), T(0, 2.6, 0.85) * CF.angles(-0.18, 0, 0), P.WOOD_DECK, "WoodPlanks", collide=False)
    for x in (-2.3, 2.3):
        b.box("Leg", (0.35, 1.6, 1.6), T(x, 0.8, 0.1), P.WHITE, "Metal", collide=False)
    return m


def pier_arch(ctx, parent):
    """Gateway arch at the start of the pier with the PAW PIER sign."""
    z = 772.0
    m = ctx.fac.model(parent, "PierGate", pivot=CF((0, DECK_Y, z)))
    b = Builder(ctx, m)
    for x in (-PIER_X - 1, PIER_X + 1):
        b.box("GatePillar", (3.2, 18, 3.2), T(x, DECK_Y + 9, z), P.WHITE, "Plaster")
        b.box("GatePillarCap", (4, 0.8, 4), T(x, DECK_Y + 18.4, z), P.GOLD, "Metal")
        b.box("GatePillarFoot", (4, 1.2, 4), T(x, DECK_Y + 0.6, z), P.TRAVERTINE, "Limestone")
        b.box("NeonStrip", (0.35, 15, 0.35), T(x, DECK_Y + 9, z - 1.7), P.NEON_CYAN, "Neon", collide=False, shadow=False)
    beam = b.box("GateBeam", (2 * PIER_X + 6, 3.4, 2.4), T(0, DECK_Y + 16.6, z), (24, 120, 140), "SmoothPlastic")
    sign = b.box("GateSign", (2 * PIER_X - 2, 5.2, 0.6), T(0, DECK_Y + 21.3, z), (255, 250, 240), "SmoothPlastic")
    for face in ("Front", "Back"):
        ctx.fac.sign(sign, "PAW PIER", face, color=(255, 90, 150), font="LuckiestGuy", stroke=(255, 255, 255),
                     name="Lettering" + face)
    b.box("SignFrame", (2 * PIER_X - 1, 0.5, 1.0), T(0, DECK_Y + 24.1, z), P.NEON_PINK, "Neon", collide=False)
    b.box("SignFrame", (2 * PIER_X - 1, 0.5, 1.0), T(0, DECK_Y + 18.5, z), P.NEON_PINK, "Neon", collide=False)
    geom.palm(ctx, m, (-PIER_X - 6, DECK_Y - 0.2, z - 6), height=20, lean=(-0.2, 0.05))
    geom.palm(ctx, m, (PIER_X + 6, DECK_Y - 0.2, z - 6), height=21, lean=(0.2, 0.05))
    return m


def build_ferris_wheel(ctx):
    """Wheel geometry in model 'Wheel' (rotated by the client around the hub, Motion=FerrisWheel),
    gondolas in 'Gondolas' (each a model kept level by the client)."""
    root = ctx.group("Landmarks/FerrisWheel")
    cx, cy, cz = WHEEL_C
    hub = CF((cx, cy, cz))
    base = Builder(ctx, root)
    # A-frame legs on both sides of the wheel (wheel plane = XY, axle along Z)
    for zside in (-1, 1):
        zz = cz + zside * 7.0
        for xside in (-1, 1):
            a = (cx + xside * 22.0, DECK_Y, zz + zside * 3.0)
            base.rod("SupportLeg", a, (cx, cy, zz), 2.2, P.WHITE, "Metal")
            base.box("LegFoot", (5, 1.2, 5), T(a[0], DECK_Y + 0.6, a[2]), P.TRAVERTINE, "Limestone")
        base.rod("SupportBrace", (cx - 11, cy * 0.5, zz + zside * 1.5), (cx + 11, cy * 0.5, zz + zside * 1.5), 1.2, P.WHITE, "Metal")
    base.cyl("Axle", 16, 3.2, CF((cx, cy, cz)) * CF.angles(0, math.pi / 2, 0), P.GOLD, "Metal")
    wheel = ctx.fac.model(root, "Wheel", pivot=hub, attrs={"Motion": "FerrisWheel", "AngularSpeed": 0.07})
    wb = Builder(ctx, wheel)
    seg = 32
    for zoff in (-5.0, 5.0):
        for i in range(seg):
            a0, a1 = 2 * math.pi * i / seg, 2 * math.pi * (i + 1) / seg
            p0 = (cx + math.cos(a0) * WHEEL_R, cy + math.sin(a0) * WHEEL_R, cz + zoff)
            p1 = (cx + math.cos(a1) * WHEEL_R, cy + math.sin(a1) * WHEEL_R, cz + zoff)
            wb.rod("Rim", p0, p1, 1.3, P.WHITE, "Metal", collide=False)
        # inner ring
        for i in range(seg):
            a0, a1 = 2 * math.pi * i / seg, 2 * math.pi * (i + 1) / seg
            r = WHEEL_R * 0.62
            wb.rod("InnerRim", (cx + math.cos(a0) * r, cy + math.sin(a0) * r, cz + zoff),
                   (cx + math.cos(a1) * r, cy + math.sin(a1) * r, cz + zoff), 0.8, (255, 120, 170), "Metal", collide=False)
    spokes = 16
    for i in range(spokes):
        a = 2 * math.pi * i / spokes
        for zoff in (-5.0, 5.0):
            wb.rod("Spoke", (cx, cy, cz + zoff * 0.3), (cx + math.cos(a) * WHEEL_R, cy + math.sin(a) * WHEEL_R, cz + zoff), 0.55,
                   P.WHITE, "Metal", collide=False)
        # neon bulbs along the spoke (colour-cycled at night)
        for k in (0.35, 0.55, 0.75, 0.95):
            r = WHEEL_R * k
            ctx.fac.part(wheel, "WheelBulb", (0.9, 0.9, 0.9), CF((cx + math.cos(a) * r, cy + math.sin(a) * r, cz - 5.6)),
                         P.NEONS[i % len(P.NEONS)], "Neon", shape="Ball", collide=False, shadow=False,
                         attrs={"Spoke": i})
    wb.cyl("Hub", 12, 6, CF((cx, cy, cz)) * CF.angles(0, math.pi / 2, 0), (255, 90, 150), "SmoothPlastic", collide=False)
    hubsign = wb.box("HubSign", (9, 9, 0.6), T(cx, cy, cz - 6.5), (255, 250, 240), collide=False)
    ctx.fac.sign(hubsign, "DOG\nROTS", "Front", color=(255, 80, 150), font="LuckiestGuy")
    ctx.fac.sign(hubsign, "DOG\nROTS", "Back", color=(255, 80, 150), font="LuckiestGuy", name="LetteringBack")
    gond = ctx.fac.model(root, "Gondolas", pivot=hub)
    n = 16
    colors = [P.PLASTER["coral"], P.PLASTER["mint"], P.PLASTER["lemon"], P.PLASTER["sky"], P.PLASTER["lavender"], P.PLASTER["peach"]]
    for i in range(n):
        a = 2 * math.pi * i / n
        px, py = cx + math.cos(a) * WHEEL_R, cy + math.sin(a) * WHEEL_R
        g = ctx.fac.model(gond, "Gondola", pivot=CF((px, py, cz)), attrs={"Angle": a})
        gb = Builder(ctx, g, CF((px, py, cz)))
        col = colors[i % len(colors)]
        gb.box("Hanger", (0.4, 3.0, 0.4), T(0, -1.5, 0), P.WHITE, "Metal", collide=False)
        gb.box("CabinFloor", (5.2, 0.4, 7.2), T(0, -6.4, 0), P.WHITE, collide=False)
        gb.box("CabinBody", (5.2, 2.2, 7.2), T(0, -5.1, 0), col, collide=False)
        gb.box("CabinGlass", (4.8, 2.0, 6.8), T(0, -3.0, 0), (200, 240, 255), "Glass", transparency=0.55, collide=False, shadow=False)
        gb.box("CabinRoof", (5.8, 0.5, 7.8), T(0, -1.75, 0), col, collide=False)
        gb.ball("RoofBall", 1.0, T(0, -1.2, 0), P.GOLD, "Metal", collide=False)
    ctx.block(PLAT[0], cz - 14, PLAT[2], cz + 14, label="ferris wheel")
    ctx.note("ferris wheel: %d gondolas" % n)
    return root


LIGHTHOUSE = (292.0, 612.0)


def build_lighthouse(ctx):
    """Lighthouse on a rock islet off the east cliffs, with a boardwalk bridge from the island."""
    root = ctx.group("Landmarks/Lighthouse")
    x, z = LIGHTHOUSE
    b = Builder(ctx, root)
    rng = ctx.rng
    # rock islet rising from the sea (top at y = 3)
    top = 3.0
    bed = seabed(x, z)
    b.vcyl("IsletCore", top - bed, 34, T(x, (top + bed) / 2, z), P.ROCK_DARK, "Rock")
    b.vcyl("IsletTop", 1.0, 30, T(x, top - 0.5, z), (196, 170, 128), "Sandstone")
    for i in range(10):
        a = i * 2 * math.pi / 10 + rng.uniform(-0.2, 0.2)
        r = rng.uniform(15, 19)
        geom.boulder(ctx, root, (x + math.cos(a) * r, rng.uniform(-6, 0), z + math.sin(a) * r), size=rng.uniform(8, 13),
                     color=P.ROCK if i % 2 else P.ROCK_DARK)
    # tower: stacked tapering drums, red/white bands
    y = top
    h_total = 64.0
    bands = 8
    for i in range(bands):
        h = h_total / bands
        d = 13.0 - i * 0.7
        b.vcyl("TowerBand", h, d, T(x, y + h / 2, z), (230, 60, 60) if i % 2 else P.WHITE, "Plaster")
        y += h
    b.vcyl("Gallery", 1.0, 13.5, T(x, y + 0.5, z), (60, 60, 64), "Metal")
    for i in range(16):
        a = i * 2 * math.pi / 16
        b.box("GalleryPost", (0.3, 3.0, 0.3), T(x + math.cos(a) * 6.4, y + 2.5, z + math.sin(a) * 6.4), (60, 60, 64), "Metal", collide=False)
    lantern = b.vcyl("LanternGlass", 7.0, 7.4, T(x, y + 4.5, z), (255, 244, 200), "Glass", transparency=0.35, collide=False)
    lamp = b.ball("Lamp", 3.6, T(x, y + 4.5, z), (255, 236, 170), "Neon", collide=False, attrs={"NightGlow": True})
    ctx.fac.point_light(lamp, (255, 230, 170), brightness=3, rng=40, name="LighthouseGlow")
    b.vcyl("LanternRoof", 1.2, 8.6, T(x, y + 8.6, z), (230, 60, 60), "Metal")
    b.ball("Dome", 6.6, T(x, y + 9.4, z), (230, 60, 60), "Metal")
    b.box("Vane", (0.3, 3.0, 0.3), T(x, y + 13.6, z), P.GOLD, "Metal", collide=False)
    beam = ctx.fac.model(root, "Beam", pivot=CF((x, y + 4.5, z)), attrs={"Motion": "LighthouseBeam", "AngularSpeed": 0.9})
    bb = Builder(ctx, beam)
    for side in (-1, 1):
        bb.box("BeamCone", (3.0, 3.0, 90), T(x + side * 46.0, y + 4.5, z) * yaw(math.pi / 2), (255, 244, 190), "Neon",
               transparency=0.82, collide=False, shadow=False, query=False)
    # door and windows
    b.box("Door", (3.2, 5.2, 0.6), T(x - 6.3, top + 2.6, z) * yaw(math.pi / 2), P.WOOD_DARK, "WoodPlanks", collide=False)
    for i in (2, 4, 6):
        b.box("Window", (1.6, 2.2, 0.5), T(x - (6.1 - i * 0.35), top + i * 8 + 3, z) * yaw(math.pi / 2), (40, 70, 100), "Glass", collide=False)
    # boardwalk bridge from the island edge (x = 216) to the islet
    bz = z
    bx0, bx1 = 212.0, x - 15.0
    seg = 0
    xx = bx0
    while xx < bx1:
        x2 = min(xx + 14.0, bx1)
        b.box("BridgeDeck", (x2 - xx, 0.8, 9.0), T((xx + x2) / 2, top - 0.4 - (0 if seg else 0), bz), P.WOOD_DECK, "WoodPlanks")
        if xx > 220:
            for side in (-1, 1):
                bed2 = seabed(xx, bz + side * 4)
                hh = top - 0.8 - bed2
                b.vcyl("BridgePiling", hh, 1.4, T(xx, bed2 + hh / 2, bz + side * 4), (110, 84, 62), "Wood")
        xx = x2
        seg += 1
    # the bridge starts 2.5 studs above the island top: a short ramp
    b.wedge("BridgeRamp", (9.0, top - 0.3, 8.0), T(208.0, (top + 0.3) / 2, bz) * yaw(math.pi / 2), P.WOOD_DECK, "WoodPlanks")
    for side in (-1, 1):
        b.rod("BridgeRope", (212.0, top + 3.0, bz + side * 4.4), (bx1, top + 3.0, bz + side * 4.4), 0.35, (230, 210, 170), "Fabric")
        for k in range(0, int(bx1 - 212) + 1, 10):
            b.box("RopePost", (0.5, 3.4, 0.5), T(212.0 + k, top + 1.7, bz + side * 4.4), P.WOOD_DARK, "Wood")
    ctx.block(x - 22, z - 22, x + 22, z + 22, label="lighthouse")
    ctx.block(200, bz - 6, x, bz + 6, label="lighthouse bridge")
    return root


def run(ctx):
    build_pier(ctx)
    build_ferris_wheel(ctx)
    build_lighthouse(ctx)
