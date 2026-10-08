"""Gameplay props: the Golden Bone hunt, trampolines and jump pads, boats, the client/server
remote. Positions use the geometry built by the other steps (ctx.spots)."""
import math

from factory import CF
from . import coast, geom
from . import palette as P
from .geom import Builder, T, yaw

GOLD = (255, 206, 72)


def remote(ctx):
    rs = ctx.doc.find_path("ReplicatedStorage")
    if ctx.doc.child(rs, "ParadiseSignal") is None:
        ctx.fac.new("RemoteEvent", rs, "ParadiseSignal")


def golden_bone(ctx, parent, bone_id, pos, phase=0.0):
    m = ctx.fac.model(parent, "GoldenBone", pivot=CF(pos),
                      attrs={"GoldenBone": bone_id, "Motion": "Spin", "AngularSpeed": 1.6, "Phase": phase})
    b = Builder(ctx, m, CF(pos))
    b.cyl("BoneShaft", 3.2, 0.9, T(0, 0, 0), GOLD, "Neon", collide=False, shadow=False)
    for x in (-1.6, 1.6):
        for z in (-0.42, 0.42):
            b.ball("BoneKnob", 1.25, T(x, 0, z), GOLD, "Neon", collide=False, shadow=False)
    hit = b.box("BoneHitbox", (5.5, 5.5, 5.5), T(0, 0, 0), GOLD, "SmoothPlastic", transparency=1, collide=False, touch=True,
                query=False, shadow=False)
    ctx.fac.point_light(hit, (255, 214, 90), brightness=1.4, rng=12, name="BoneGlow")
    ctx.fac.particles(hit, "BoneSparkle", rate=5, color=(255, 230, 120), size=[(0, 0.7), (1, 0)], lifetime=(0.8, 1.6),
                      speed=(1, 2.5), spread=(180, 180), light_emission=1)
    return m


def find_free(ctx, x, z, r=2.0, tries=24, ymax=None):
    if ctx.is_free(x, z, r, ymax=ymax):
        return x, z
    for i in range(1, tries + 1):
        a = i * 2.4
        d = 2.0 + i * 0.9
        nx, nz = x + math.cos(a) * d, z + math.sin(a) * d
        if ctx.is_free(nx, nz, r, ymax=ymax):
            return nx, nz
    return x, z


def ground_y(x, z):
    h = coast.height(x, z)
    return 0.5 if h is None else h


def trampoline(ctx, parent, x, y, z, power=135.0, d=12.0, color=(255, 90, 150)):
    m = ctx.fac.model(parent, "Trampoline", pivot=CF((x, y, z)))
    b = Builder(ctx, m, CF((x, y, z)))
    seg = 14
    r = d / 2
    for i in range(seg):
        a0, a1 = 2 * math.pi * i / seg, 2 * math.pi * (i + 1) / seg
        p0 = (x + math.cos(a0) * r, y + 2.4, z + math.sin(a0) * r)
        p1 = (x + math.cos(a1) * r, y + 2.4, z + math.sin(a1) * r)
        b.rod("TrampolineFrame", p0, p1, 0.9, color if i % 2 else P.WHITE, "SmoothPlastic", shape="Cylinder")
    for i in range(6):
        a = 2 * math.pi * i / 6
        b.box("TrampolineLeg", (0.6, 2.4, 0.6), T(math.cos(a) * (r - 0.3), 1.2, math.sin(a) * (r - 0.3)), (60, 60, 70), "Metal")
    b.vcyl("TrampolineMat", 0.4, d - 1.4, T(0, 2.3, 0), (30, 30, 40), "Fabric")
    b.box("PadZone", ((d - 2.4) * 0.72, 0.4, (d - 2.4) * 0.72), T(0, 2.3, 0), color, "SmoothPlastic", transparency=1, collide=False,
          query=False, shadow=False, attrs={"JumpPad": power})
    ctx.block(x - r - 1, z - r - 1, x + r + 1, z + r + 1, y + 3, "trampoline")
    return m


def launch_pad(ctx, parent, x, y, z, facing, up=95.0, forward=45.0):
    m = ctx.fac.model(parent, "LaunchPad", pivot=CF((x, y, z)))
    b = Builder(ctx, m, CF((x, y, z)) * yaw(facing))
    b.box("LaunchBase", (6, 0.6, 6), T(0, 0.3, 0), P.WHITE, "SmoothPlastic")
    b.box("LaunchArrow", (1.2, 0.1, 3.6), T(0, 0.65, -0.4), P.NEON_CYAN, "Neon", collide=False, shadow=False)
    b.wedge("LaunchArrowHead", (3.2, 0.1, 1.6), T(0, 0.65, -2.8) * yaw(math.pi), P.NEON_CYAN, "Neon", collide=False, shadow=False)
    b.box("PadZone", (5.2, 0.4, 5.2), T(0, 0.5, 0), P.NEON_CYAN, "SmoothPlastic", transparency=1, collide=False, query=False,
          shadow=False, attrs={"JumpPad": up, "PadForward": forward})
    ctx.block(x - 3.5, z - 3.5, x + 3.5, z + 3.5, y + 1, "launch pad")
    return m


def sailboat(ctx, parent, cf, hull, sail, attrs, name="Sailboat", stream_mode=None):
    m = ctx.fac.model(parent, name, pivot=cf, attrs=attrs, stream_mode=stream_mode)
    b = Builder(ctx, m, cf)
    b.box("Hull", (6, 2.4, 16), T(0, 0.2, 0), hull, "WoodPlanks")
    b.wedge("Bow", (6, 2.4, 6), T(0, 0.2, -11), hull, "WoodPlanks")
    b.box("Deck", (5.2, 0.3, 15), T(0, 1.5, 1), P.WOOD_PALE, "WoodPlanks", collide=False)
    b.box("Stripe", (6.1, 0.5, 16.1), T(0, 0.9, 0), P.WHITE, "SmoothPlastic", collide=False)
    b.vcyl("Mast", 20, 0.6, T(0, 11.4, -2), P.WHITE, "Wood", collide=False)
    b.wedge("Sail", (0.25, 17, 9), T(0, 11.6, 2.6) * yaw(math.pi), sail, "Fabric", collide=False)
    b.wedge("Jib", (0.25, 13, 6), T(0, 9.6, -6.5), P.WHITE, "Fabric", collide=False)
    b.box("Pennant", (0.1, 1.0, 2.2), T(0, 21.8, -1), P.NEON_PINK, "Fabric", collide=False, shadow=False)
    return m


def boats(ctx):
    root = ctx.group("Boats")
    rng = ctx.rng
    # moored at the pier, rocking gently
    for i, (x, z) in enumerate(((-26.0, 830.0), (26.0, 872.0), (-26.0, 914.0))):
        cf = CF((x, coast.SEA + 0.6, z)) * yaw(0.0 if i % 2 else math.pi)
        sailboat(ctx, root, cf, [(240, 90, 90), (60, 150, 220), (250, 200, 60)][i], P.WHITE,
                 {"Motion": "Bob", "Phase": i * 1.7}, name="MooredBoat")
    # sailing around the island
    for i in range(5):
        radius = rng.uniform(560, 880)
        a = rng.uniform(0, 2 * math.pi)
        cx, cz = 0.0, 300.0
        pos = (cx + math.cos(a) * radius, coast.SEA + 0.6, cz + math.sin(a) * radius)
        sailboat(ctx, root, CF(pos), [(255, 255, 255), (230, 70, 90), (40, 120, 200)][i % 3], P.NEONS[i % len(P.NEONS)],
                 {"Motion": "Cruise", "Center": ("Vector3", (cx, 0, cz)), "Radius": radius, "Speed": rng.uniform(9, 14),
                  "Phase": a}, name="CruisingBoat", stream_mode=2)


def beach_sports(ctx):
    """Volleyball courts and lifeguard towers on the widest beaches (placed before the scatter)."""
    m = ctx.group("Coast/BeachSports")
    spots = []
    for x, z, rot in ((-214.0, 300.0, 0.0), (-238.0, 640.0, 0.0)):
        h = ground_y(x, z)
        geom.volleyball(ctx, m, CF((x, h, z)) * yaw(rot + math.pi / 2))
        ctx.block(x - 14, z - 14, x + 14, z + 14, 9, "volleyball")
        spots.append((x, h, z))
    towers = []
    for x, z in ((-212.0, 420.0), (212.0, 300.0), (-120.0, 786.0), (232.0, -60.0)):
        h = ground_y(x, z)
        out = (x / abs(x)) if abs(x) > 150 else 0
        face = math.atan2(out, 0 if out else 1)
        geom.lifeguard_tower(ctx, m, CF((x, h - 0.3, z)) * yaw(face))
        ctx.block(x - 5, z - 5, x + 5, z + 5, 18, "lifeguard")
        towers.append((x, h - 0.3, z))
    ctx.spots["Volleyball"] = (spots[0][0] + 6, spots[0][1] + 2.2, spots[0][2] + 5)
    ctx.spots["LifeguardDeck"] = (towers[0][0], towers[0][1] + 11.2, towers[0][2])
    ctx.spots["SouthTower"] = (towers[2][0], towers[2][1] + 11.2, towers[2][2])


def bones(ctx):
    root = ctx.group("GoldenBones")
    S = ctx.spots
    spots = []

    def add(name, pos):
        spots.append((name, pos))
    for key in ("SkyTowerHalfway", "MountainSummit", "BehindWaterfall", "LagoonDeep", "PierEnd", "UnderPier", "LighthouseDoor",
                "FerrisBase", "CocoBar", "Volleyball", "LifeguardDeck", "SouthTower", "CasinoDice", "IslandFalls", "NorthRock",
                "ZiplineEnd", "SnorkelReef"):
        if key in S:
            add(key, S[key])
    # land spots: nudged to a free place near the target
    for key, (x, z) in (("PalmAvenue", (0.0, 604.0)), ("ShopsBackyard", (160.0, 305.0)), ("DogPark", (-100.0, 206.0)),
                        ("LabGarden", (52.0, 488.0)), ("MuseumSteps", (-40.0, 452.0)), ("TongueEnd", (0.0, 150.0)),
                        ("FactoryGarden", (-60.0, -150.0)), ("VillaBeach", (-200.0, 20.0))):
        nx, nz = find_free(ctx, x, z, 2.5)
        add(key, (nx, ground_y(nx, nz) + 2.2, nz))
    for i, (name, pos) in enumerate(spots):
        golden_bone(ctx, root, "%02d_%s" % (i + 1, name), pos, phase=i * 0.7)
    ctx.note("golden bones: %d" % len(spots))


def extra_spots(ctx):
    """Dedicated perches for bones: a sea stack on the north shore, a reef under the south beach."""
    m = ctx.group("GoldenBones/Perches")
    rng = ctx.rng
    # a basalt sea stack off the north shore
    x, z = -40.0, -266.0
    bed = ground_y(x, z)
    b = Builder(ctx, m)
    b.vcyl("SeaStack", 3.0 - bed, 9, T(x, (3.0 + bed) / 2, z), P.ROCK_DARK, "Basalt")
    b.vcyl("SeaStackTop", 1.0, 10, T(x, 3.0, z), P.ROCK_MOSS, "LeafyGrass")
    ctx.spots["NorthRock"] = (x, 6.0, z)
    ctx.block(x - 6, z - 6, x + 6, z + 6, 4, "sea stack")
    # a little coral reef in the south shallows (snorkel spot)
    rx, rz = 120.0, 800.0
    for i in range(14):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0, 12)
        cx, cz = rx + math.cos(a) * r, rz + math.sin(a) * r
        h = ground_y(cx, cz)
        col = rng.choice([(255, 110, 140), (255, 170, 80), (180, 120, 255), (90, 210, 200), (255, 230, 120)])
        b.ball("Coral", rng.uniform(2, 4.5), T(cx, h + 0.6, cz), col, "SmoothPlastic", collide=False)
        b.box("CoralBranch", (0.6, rng.uniform(2, 4), 0.6), T(cx + 1, h + 1.5, cz) * CF.angles(rng.uniform(-0.4, 0.4), 0, rng.uniform(-0.4, 0.4)),
              col, "SmoothPlastic", collide=False)
    ctx.spots["SnorkelReef"] = (rx, ground_y(rx, rz) + 2.0, rz)


def navigation(ctx):
    """District map entry for the Paw Pier (MapRouting key PawPier)."""
    nav = ctx.find("NavigationAnchors")
    target = ctx.spots.get("PierAnchor")
    if nav is None or target is None or ctx.doc.child(nav, "PawPier") is not None:
        return
    mirror = ctx.fac.part(nav, "PawPier", (1, 1, 1), ctx.doc.get(target, "CFrame"), (120, 130, 120), transparency=1,
                          collide=False, query=False, shadow=False)
    ctx.fac.new("ObjectValue", mirror, "Target", {"Value": target})


def run(ctx):
    remote(ctx)
    navigation(ctx)
    beach_sports(ctx)
    pads = ctx.group("Bounce")
    # trampolines on the west beach and the lagoon lawn
    for x, z in ((-222.0, 360.0), (-222.0, 384.0), (-242.0, 560.0)):
        trampoline(ctx, pads, x, ground_y(x, z) - 0.2, z, power=140, color=P.NEONS[int(z) % len(P.NEONS)])
    trampoline(ctx, pads, 196.0, 0.4, 560.0, power=150, d=14, color=P.NEON_CYAN)
    # launch pad on the lagoon's west boardwalk: into the water
    launch_pad(ctx, pads, 56.0, 0.5, 662.0, facing=-math.pi / 2, up=85, forward=55)
    boats(ctx)
    extra_spots(ctx)
    bones(ctx)
