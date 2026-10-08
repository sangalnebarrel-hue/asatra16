"""World-space part list from a Doc, for analysis and preview renders."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxl  # noqa: E402

PART_CLASSES = ("Part", "WedgePart", "MeshPart", "Seat", "SpawnLocation", "TrussPart", "CornerWedgePart", "VehicleSeat")
MATERIALS = {256: "Plastic", 272: "SmoothPlastic", 288: "Neon", 512: "Wood", 528: "WoodPlanks", 784: "Marble",
             788: "Basalt", 800: "Slate", 804: "CrackedLava", 816: "Concrete", 820: "Limestone", 832: "Granite",
             836: "Pavement", 848: "Brick", 864: "Pebble", 880: "Cobblestone", 896: "Rock", 912: "Sandstone",
             1040: "CorrodedMetal", 1056: "DiamondPlate", 1072: "Foil", 1088: "Metal", 1280: "Grass",
             1284: "LeafyGrass", 1296: "Sand", 1312: "Fabric", 1328: "Snow", 1344: "Mud", 1360: "Ground",
             1376: "Asphalt", 1392: "Salt", 1536: "Ice", 1552: "Glacier", 1568: "Glass", 1584: "ForceField",
             1792: "Air", 2048: "Water", 2304: "Cardboard", 2305: "Carpet",
             2306: "CeramicTiles", 2307: "ClayRoofTiles", 2308: "RoofShingles", 2309: "Leather", 2310: "Plaster",
             2311: "Rubber"}
MAT_ID = {v: k for k, v in MATERIALS.items()}
SHAPES = {0: "Ball", 1: "Block", 2: "Cylinder", 3: "Wedge", 4: "CornerWedge"}


class P:
    __slots__ = ("ref", "cls", "name", "cf", "size", "color", "mat", "transp", "shape", "area", "path", "collide")


def parts(doc, root_path="Workspace", with_path=False):
    root = doc.find_path(root_path) if root_path else -1
    out = []
    district = doc.find_path("Workspace/DOGROTS_District")
    for ref in doc.descendants(root):
        cls = doc.cls(ref)
        if cls not in PART_CLASSES:
            continue
        p = P()
        p.ref, p.cls = ref, cls
        p.name = doc.name(ref)
        p.cf = doc.get(ref, "CFrame")
        p.size = doc.get(ref, "size")
        c = doc.get(ref, "Color3uint8")
        p.color = (c[0] / 255, c[1] / 255, c[2] / 255)
        p.mat = MATERIALS.get(doc.get(ref, "Material"), str(doc.get(ref, "Material")))
        p.transp = doc.get(ref, "Transparency")
        if cls == "WedgePart":
            p.shape = "Wedge"
        elif cls == "CornerWedgePart":
            p.shape = "CornerWedge"
        elif cls == "MeshPart":
            p.shape = "Mesh"
        else:
            p.shape = SHAPES.get(doc.get(ref, "shape", 1), "Block")
        p.collide = doc.get(ref, "CanCollide")
        anc = doc.ancestors(ref)
        p.area = None
        if district is not None and district in anc:
            i = anc.index(district)
            p.area = doc.name(anc[i - 1]) if i > 0 else p.name
        if with_path:
            p.path = doc.path(ref)
        out.append(p)
    return out
