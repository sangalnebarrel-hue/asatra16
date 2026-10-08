"""Global material/colour pass: the tropical palette over the authored geometry.

Rules are matched in order on (area, name, material, colour); the first match wins.
Invisible parts, neon, signs and protected subtrees (giant dog, dogs, the Void,
the DOG-O-MATIC rig, museum exhibits) are left untouched.
"""
import re

from factory import MAT
from . import palette as P

PROTECTED_SUBTREES = ("THE_DOG", "TheDog_ClimbingBody", "Exhibits", "DOGROTS_Merchant", "DOGROTS_Builder",
                      "StorageRoofMascot", "RewardMachine", "RewardMachineRig", "KennelDogs", "ActiveDogs",
                      "Subject008Chamber", "Stations", "CentralChamber", "Core", "PortalArrivalCourt")
SKIP_AREAS = ("13_TheVoid", "NavigationAnchors")


def _hsv_shift_green(c, lo=(36, 118, 70), hi=(96, 176, 72)):
    """Keep relative light/dark variation of foliage while moving it into tropical greens."""
    t = max(0.0, min(1.0, (P.lum(c) - 40) / 110.0))
    return P.lerp(lo, hi, t)


def _rock(c):
    t = max(0.0, min(1.0, (P.lum(c) - 50) / 90.0))
    return P.lerp(P.ROCK_DARK, P.ROCK, t)


def _same(c):
    return c


AREA_WALLS = {
    "32_WelcomeHub": P.PLASTER["coral"],
    "11_Shops": P.PLASTER["cream"],
    "31_BackDistrictExpansion": P.PLASTER["peach"],
    "09_DogPark": P.PLASTER["cream"],
    "36_DistrictRefresh": P.PLASTER["mint"],
    "37_AttractionRefresh": P.PLASTER["cream"],
}
AREA_ROOFS = {
    "32_WelcomeHub": (P.TERRACOTTA, "ClayRoofTiles"),
    "11_Shops": (P.TERRACOTTA, "ClayRoofTiles"),
    "09_DogPark": (P.TEAL_ROOF, "Metal"),
    "31_BackDistrictExpansion": (P.TEAL_ROOF, "Metal"),
    "36_DistrictRefresh": (P.TERRACOTTA, "ClayRoofTiles"),
}

OUTDOOR = ("01_IslandAndStreets", "32_WelcomeHub", "33_DogExpress", "09_DogPark", "31_BackDistrictExpansion", "34_GardenPolish",
           "11_Shops", "27_RewardMachinePlaza", "03_DogLine")

# (areas or None, name regex, materials or None, colour fn or rgb, material or None[, predicate(p, rgb)])
RULES = [
    # ---- welcome arch and dark street furniture -> white posts, gold caps, teal beams ---------
    (("32_WelcomeHub",), r"^Pylon$", ("Metal",), P.WHITE, "Plaster"),
    (("32_WelcomeHub",), r"^(Lintel|Roof|DOGROTS)$", ("Metal",), P.TEAL_DARK, "SmoothPlastic", lambda p, c: max(p.size) > 20 or p.name == "DOGROTS"),
    (OUTDOOR, r"^(Column|LanternFrame|LanternBase|LanternHousing|ArmPost|Post|Pole|Support|MetalLeg|Leg|BenchLeg|StoolLeg|Foot)$",
     ("Metal", "Plastic", "SmoothPlastic"), P.WHITE, "SmoothPlastic", lambda p, c: P.lum(c) < 80 and max(p.size) < 14),
    (OUTDOOR, r"^(Roof|LanternCap|Cap|CopperCollar)$", ("Metal",), P.GOLD, "Metal", lambda p, c: P.lum(c) < 80 and max(p.size) < 5),
    (OUTDOOR, r"^(Toe|Pad|DarkPlinth|Honor|Discovery|Legacy)$", ("Metal", "SmoothPlastic", "Concrete"), P.TEAL_DARK, None, lambda p, c: P.lum(c) < 80),
    # ---- museum: cream & navy -> white marble & deep teal; lab: white with aqua glass ----
    (("06_DogDexMuseum",), r".*", ("Concrete", "Marble", "Plastic", "SmoothPlastic"), "museum", None),
    (("05_MutationLab",), r".*", ("Marble", "Metal", "Concrete", "Glass"), "lab", None),
    # ---- ground ---------------------------------------------------------------
    (None, r"^(LivingGround|UpperMeadow|GrassLip|Lawn|Turf|Meadow|CentralEventGarden)", None, P.LAWN, "LeafyGrass"),
    (("04_PlayerYards",), r"^(YardFoundation|WorkArea|CosmeticGarden)$", None, P.LAWN_YARD, "LeafyGrass"),
    (None, r"(Hedge|Leaves|LeafCluster|LowBush|Planting|Shrub|Bush|Foliage|Canopy|VoxelCanopy)", ("Grass", "LeafyGrass", "Plastic", "SmoothPlastic"),
     _hsv_shift_green, "LeafyGrass"),
    (None, r"^(Trunk|DistantTrunk)$", None, P.WOOD_DARK, "Wood"),
    (None, r"^Soil$", None, P.SOIL, "Ground"),
    # ---- island rock ------------------------------------------------------------
    (("01_IslandAndStreets", "34_GardenPolish"),
     r"^(IslandMass|WeatheredBasalt|EndStrata|RockShelf|BrokenBasalt|Outcrop)", None, _rock, "Rock"),
    # floating islands: pale limestone karst with darker roots
    (("23_DistrictPolish",), r"^RockShelf$", None, (184, 170, 150), "Limestone"),
    (("23_DistrictPolish",), r"^BrokenBasalt$", None, (138, 126, 114), "Rock"),
    # ---- streets ------------------------------------------------------------------
    (("01_IslandAndStreets",), r"^(MainBoulevard|InnerYardPromenade|OuterYardPromenade)$", None, P.PAVE, "Pavement"),
    (("01_IslandAndStreets",), r"^YardCrossing$", None, P.PAVE_ROSE, "Pavement"),
    (("01_IslandAndStreets", "33_DogExpress", "31_BackDistrictExpansion"), r"^(Column|Roof)$", ("Metal",), P.WHITE, "SmoothPlastic"),
    (("01_IslandAndStreets", "33_DogExpress", "31_BackDistrictExpansion"), r"^CopperCollar$", None, P.GOLD, "Metal"),
    (("33_DogExpress",), r"^(Outbound|Return)$", None, (52, 120, 134), "Pavement"),
    (None, r"(Promenade|Boulevard|Forecourt|Apron|Approach|WalkingLoop|GardenLoop|CrossPath|SouthReturn|ServiceWalk|EntranceWalk|EndConnection|PlazaFoundation|PawCourt|LimestoneCourt|Destination|RearServiceWalk)",
     ("Concrete", "Marble", "Plastic", "SmoothPlastic", "Slate"), P.PAVE_WARM, "Pavement"),
    (None, r"(Curb|StoneCap|StoneFoot|Edging|PerimeterStone|LimestoneCap|LimestoneBorder|StoneEdging|GardenCurb|PromenadeEdge|EntryPlanter|Plinth|LowerStep|UpperStep|^Cap$|^Foot$)",
     ("Concrete", "Slate", "Plastic"), P.TRAVERTINE, "Limestone"),
    # ---- roofs, trims and walls by district ------------------------------------------
    (tuple(AREA_ROOFS), r"(SteppedTileRoof|PitchedRoof|^Roof$|SideRoof|IntegratedAwning|^Ridge$)", None, "area_roof", None),
    (tuple(AREA_WALLS), r"(Cornice|Sill|FacadePier|WallPier|SideHeader|FacadeHeader|TimberCap)", ("Concrete", "Plastic", "SmoothPlastic", "Wood"), P.WHITE, "Plaster"),
    (tuple(AREA_WALLS), r"(Wall|Gable|Header|Masonry|Return)", ("Concrete", "Plastic", "SmoothPlastic"), "area_wall", "Plaster"),
]

_compiled = [(r[0], re.compile(r[1]), r[2], r[3], r[4], r[5] if len(r) > 5 else None) for r in RULES]

NAVY = (19, 30, 49)


def _museum(p, c):
    """Navy -> deep teal; cream/beige -> white marble; dark brown niches -> warm sand shadow."""
    if max(abs(c[0] - NAVY[0]), abs(c[1] - NAVY[1]), abs(c[2] - NAVY[2])) < 18:
        return (16, 86, 96), None
    l = P.lum(c)
    if l > 180 and c[0] >= c[2]:
        return P.lerp(c, (250, 246, 238), 0.6), None
    if p.name == "NicheShadow":
        return (120, 92, 70), None
    return None


def _lab(p, c):
    if p.mat == "Glass":
        return P.lerp(c, (196, 246, 250), 0.45), None
    l = P.lum(c)
    if l > 120:
        return P.lerp(c, (244, 248, 250), 0.65), None
    if l < 70:
        return (30, 56, 68), None
    return None


def run(ctx):
    doc = ctx.doc
    protected = set()
    for name in PROTECTED_SUBTREES:
        for ref in _find_all(doc, ctx.district, name):
            protected.add(ref)
            protected.update(doc.descendants(ref))
    counts = {}
    for p in ctx.parts():
        if p.area is None or p.area in SKIP_AREAS or p.ref in protected:
            continue
        if p.transp >= 0.95 or p.mat == "Neon":
            continue
        c = tuple(round(v * 255) for v in p.color)
        for i, (areas, rx, mats, col, mat, pred) in enumerate(_compiled):
            if areas and p.area not in areas:
                continue
            if mats and p.mat not in mats:
                continue
            if not rx.search(p.name):
                continue
            if pred and not pred(p, c):
                continue
            new_mat = mat
            if col == "area_roof":
                new_col, new_mat = AREA_ROOFS[p.area]
            elif col == "area_wall":
                new_col = AREA_WALLS[p.area]
            elif col == "museum":
                r = _museum(p, c)
                if r is None:
                    break
                new_col, new_mat = r
            elif col == "lab":
                r = _lab(p, c)
                if r is None:
                    break
                new_col, new_mat = r
            elif callable(col):
                new_col = col(c)
            else:
                new_col = col
            set_look(doc, p, new_col, new_mat)
            counts[i] = counts.get(i, 0) + 1
            break
    for i, n in sorted(counts.items()):
        ctx.note("restyle rule %d (%s): %d parts" % (i, RULES[i][1][:40], n))
    ctx.parts(refresh=True)


def set_look(doc, p, color, material=None):
    doc.set(p.ref, "Color3uint8", tuple(int(max(0, min(255, round(v)))) for v in color))
    if material:
        doc.set(p.ref, "Material", MAT[material])


def _find_all(doc, root, name):
    return [r for r in doc.descendants(root) if doc.name(r) == name]
