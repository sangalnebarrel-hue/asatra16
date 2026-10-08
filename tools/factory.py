"""Instance factory on top of rbxl.Doc: new instances get every stored column of their
class (copied from a plain template instance of the same class in the place), then
the values passed in. Geometry helpers take world CFrames (rbxl.CF).
"""
import math
import struct
import uuid

import rbxl

CF = rbxl.CF

MAT = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Wood": 512, "WoodPlanks": 528, "Marble": 784,
       "Basalt": 788, "Slate": 800, "CrackedLava": 804, "Concrete": 816, "Limestone": 820, "Granite": 832,
       "Pavement": 836, "Brick": 848, "Pebble": 864, "Cobblestone": 880, "Rock": 896, "Sandstone": 912,
       "CorrodedMetal": 1040, "DiamondPlate": 1056, "Foil": 1072, "Metal": 1088, "Grass": 1280,
       "LeafyGrass": 1284, "Sand": 1296, "Fabric": 1312, "Snow": 1328, "Mud": 1344, "Ground": 1360,
       "Asphalt": 1376, "Salt": 1392, "Ice": 1536, "Glacier": 1552, "Glass": 1568, "ForceField": 1584,
       "Cardboard": 2304, "Carpet": 2305, "CeramicTiles": 2306, "ClayRoofTiles": 2307, "RoofShingles": 2308,
       "Leather": 2309, "Plaster": 2310, "Rubber": 2311}
SHAPE = {"Ball": 0, "Block": 1, "Cylinder": 2}
FACE = {"Right": 0, "Top": 1, "Back": 2, "Left": 3, "Bottom": 4, "Front": 5}


def rgb(r, g, b):
    return (int(r), int(g), int(b))


def c3(color):
    """(r,g,b) 0..255 -> Color3 floats."""
    return (color[0] / 255.0, color[1] / 255.0, color[2] / 255.0)


class Factory:
    def __init__(self, doc):
        self.doc = doc
        self.templates = {}
        self._unique_top = None
        self._unique_tail = None
        self.created = 0
        self._sstr_index = {}

    # ------------------------------------------------------------------ ids
    def _next_unique(self):
        if self._unique_top is None:
            top, tail = 0, None
            for cid, info in self.doc.classes.items():
                col = self.doc.column(cid, "UniqueId") if "UniqueId" in info.order else None
                if col is None:
                    continue
                for v in col.values:
                    idx = struct.unpack(">I", v[:4])[0]
                    if idx < 0x10000000 and idx > top:
                        top = idx
                    if tail is None and v[4:] != bytes(12):
                        tail = v[4:]
            self._unique_top = max(top, 0x00200000)
            self._unique_tail = tail or bytes(12)
        self._unique_top += 1
        return struct.pack(">I", self._unique_top) + self._unique_tail

    def shared_string(self, value):
        """Index of `value` in the SSTR table (appended if new)."""
        if isinstance(value, str):
            value = value.encode("utf-8")
        if value in self._sstr_index:
            return self._sstr_index[value]
        vals = self.doc.shared_strings()
        for i, (h, v) in enumerate(vals):
            if v == value:
                self._sstr_index[value] = i
                return i
        vals.append((bytes(16), value))
        self.doc._sstr_dirty = True
        self._sstr_index[value] = len(vals) - 1
        return len(vals) - 1

    # ------------------------------------------------------------------ templates
    def template(self, cls):
        if cls in self.templates:
            return self.templates[cls]
        doc = self.doc
        cid = doc.by_name.get(cls)
        if cid is None:
            raise KeyError("class %s has no instance in the place to copy columns from" % cls)
        info = doc.classes[cid]
        for p in info.order:
            doc.column(cid, p)
        best = None
        for i, ref in enumerate(info.refs):
            attrs = info.props["AttributesSerialize"].values[i] if "AttributesSerialize" in info.props else b""
            tags = info.props["Tags"].values[i] if "Tags" in info.props else 0
            if attrs or tags:
                continue
            if cls in ("Part", "WedgePart", "Seat", "SpawnLocation") and not info.props["Anchored"].values[i]:
                continue
            best = i
            break
        if best is None:
            best = 0
        vals = {p: info.props[p].values[best] for p in info.order}
        # neutral values for things that must not leak from the template
        for p, col in info.props.items():
            if p == "AttributesSerialize":
                vals[p] = b""
            elif p == "Tags":
                vals[p] = 0
            elif p == "HistoryId":
                vals[p] = bytes(16)
            elif p == "SourceAssetId":
                vals[p] = -1
        if cls in ("Part", "WedgePart", "CornerWedgePart", "MeshPart", "Seat", "SpawnLocation", "TrussPart"):
            vals.update({"Anchored": True, "CanCollide": True, "CanQuery": True, "CanTouch": True, "CastShadow": True,
                         "Locked": False, "Massless": False, "Reflectance": 0.0, "Transparency": 0.0,
                         "Velocity": (0.0, 0.0, 0.0), "RotVelocity": (0.0, 0.0, 0.0), "PivotOffset": CF(),
                         "CollisionGroup": b"Default", "CollisionGroupId": 0, "CustomPhysicalProperties": (2,),
                         "MaterialVariantSerialized": b"", "RootPriority": 0})
            for face in ("Back", "Bottom", "Front", "Left", "Right", "Top"):
                vals[face + "Surface"] = 0
                vals[face + "SurfaceInput"] = 0
                vals[face + "ParamA"] = -0.5
                vals[face + "ParamB"] = 0.5
            if "shape" in vals:
                vals["shape"] = 1
            if "formFactorRaw" in vals:
                vals["formFactorRaw"] = 1
        if cls == "Model":
            vals.update({"PrimaryPart": -1, "LevelOfDetail": 0, "ModelStreamingMode": 0, "NeedsPivotMigration": False,
                         "ScaleFactor": 1.0, "WorldPivotData": None})
        self.templates[cls] = vals
        return vals

    # ------------------------------------------------------------------ create
    def new(self, cls, parent, name, props=None, attrs=None, tags=None):
        doc = self.doc
        vals = dict(self.template(cls))
        vals["Name"] = name.encode("utf-8") if isinstance(name, str) else name
        if "UniqueId" in vals:
            vals["UniqueId"] = self._next_unique()
        if "ScriptGuid" in vals:
            vals["ScriptGuid"] = ("{%s}" % str(uuid.uuid4()).upper()).encode()
        for k, v in (props or {}).items():
            vals[k] = v
        if attrs:
            vals["AttributesSerialize"] = rbxl.Doc.build_attributes(attrs)
        if tags:
            vals["Tags"] = self.shared_string(b"\x00".join(t.encode() for t in tags))
        cid = doc.by_name[cls]
        info = doc.classes[cid]
        unknown = [k for k in vals if k not in info.order]
        if unknown:
            raise KeyError("%s: no stored column for %s" % (cls, unknown))
        self.created += 1
        return doc.add(cls, parent, vals, {})

    # ------------------------------------------------------------------ helpers
    def folder(self, parent, name, attrs=None):
        return self.new("Folder", parent, name, attrs=attrs)

    def model(self, parent, name, pivot=None, attrs=None, stream_mode=None):
        props = {}
        if pivot is not None:
            props["WorldPivotData"] = pivot
        if stream_mode is not None:
            props["ModelStreamingMode"] = stream_mode
        return self.new("Model", parent, name, props, attrs=attrs)

    def part(self, parent, name, size, cf, color, material="SmoothPlastic", shape="Block", transparency=0.0,
             collide=True, shadow=True, touch=False, query=None, reflectance=0.0, attrs=None, cls="Part", tags=None):
        props = {
            "size": tuple(float(max(0.001, v)) for v in size),
            "CFrame": cf if isinstance(cf, CF) else CF(cf),
            "Color3uint8": tuple(int(max(0, min(255, round(v)))) for v in color),
            "Material": MAT[material] if isinstance(material, str) else material,
            "Transparency": float(transparency),
            "CanCollide": bool(collide),
            "CanTouch": bool(touch),
            "CanQuery": bool(collide if query is None else query),
            "CastShadow": bool(shadow),
            "Reflectance": float(reflectance),
        }
        if cls == "Part":
            props["shape"] = SHAPE[shape]
        return self.new(cls, parent, name, props, attrs=attrs, tags=tags)

    def wedge(self, parent, name, size, cf, color, material="SmoothPlastic", **kw):
        return self.part(parent, name, size, cf, color, material, cls="WedgePart", **kw)

    def point_light(self, parent, color, brightness=1.0, rng=12.0, shadows=False, name="PointLight", enabled=True, attrs=None):
        return self.new("PointLight", parent, name, {"Color": c3(color), "Brightness": float(brightness),
                                                      "Range": float(rng), "Shadows": shadows, "Enabled": enabled},
                        attrs=attrs)

    def surface_light(self, parent, color, face="Bottom", brightness=1.0, rng=12.0, angle=90.0, name="SurfaceLight", attrs=None):
        return self.new("SurfaceLight", parent, name, {"Color": c3(color), "Brightness": float(brightness), "Range": float(rng),
                                                        "Angle": float(angle), "Face": FACE[face], "Shadows": False,
                                                        "Enabled": True}, attrs=attrs)

    def attachment(self, parent, name, local_cf=None):
        return self.new("Attachment", parent, name, {"CFrame": local_cf or CF(), "Visible": False})

    def particles(self, parent, name, **p):
        """ParticleEmitter. Keys: texture, color (rgb or [(t,rgb)]), size [(t,v)], transparency [(t,v)],
        rate, lifetime (a,b), speed (a,b), spread (x,y), accel (x,y,z), emission_dir (face), light_emission,
        rot (a,b), rotspeed (a,b), drag, locked, zoffset, shape..."""
        def seq(v):
            if isinstance(v, (int, float)):
                return ((0.0, float(v), 0.0), (1.0, float(v), 0.0))
            return tuple((float(t), float(x), 0.0) for t, x in v)

        def cseq(v):
            if isinstance(v[0], (int, float)):
                c = c3(v)
                return ((0.0,) + c + (0.0,), (1.0,) + c + (0.0,))
            return tuple((float(t),) + c3(c) + (0.0,) for t, c in v)
        props = {
            "Texture": p.get("texture", "rbxasset://textures/particles/sparkles_main.dds").encode(),
            "Color": cseq(p.get("color", (255, 255, 255))),
            "Size": seq(p.get("size", 1.0)),
            "Transparency": seq(p.get("transparency", 0.0)),
            "Rate": float(p.get("rate", 10)),
            "Lifetime": tuple(float(v) for v in p.get("lifetime", (1, 2))),
            "Speed": tuple(float(v) for v in p.get("speed", (2, 4))),
            "SpreadAngle": tuple(float(v) for v in p.get("spread", (0, 0))),
            "Acceleration": tuple(float(v) for v in p.get("accel", (0, 0, 0))),
            "EmissionDirection": FACE[p.get("emission_dir", "Top")],
            "LightEmission": float(p.get("light_emission", 0)),
            "LightInfluence": float(p.get("light_influence", 1 if p.get("light_emission", 0) == 0 else 0)),
            "Rotation": tuple(float(v) for v in p.get("rot", (0, 0))),
            "RotSpeed": tuple(float(v) for v in p.get("rotspeed", (0, 0))),
            "Drag": float(p.get("drag", 0)),
            "LockedToPart": bool(p.get("locked", False)),
            "ZOffset": float(p.get("zoffset", 0)),
            "Enabled": bool(p.get("enabled", True)),
            "Squash": ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0)),
            "Brightness": float(p.get("brightness", 1)),
            "Orientation": int(p.get("orientation", 0)),
            "VelocityInheritance": 0.0,
            "TimeScale": 1.0,
            "Shape": int(p.get("shape", 0)),
            "ShapeStyle": int(p.get("shape_style", 0)),
            "ShapeInOut": int(p.get("shape_inout", 0)),
            "ShapePartial": 1.0,
            "FlipbookLayout": 0, "FlipbookMode": 0,
        }
        return self.new("ParticleEmitter", parent, name, props, attrs=p.get("attrs"))

    def sign(self, part, text, face="Front", color=(255, 255, 255), bg=None, font="FredokaOne", stroke=None,
             pixels_per_stud=40, light_influence=0.0, name="Lettering", scaled=True, rich=False):
        """SurfaceGui + TextLabel filling the face of `part`."""
        gui = self.new("SurfaceGui", part, name, {
            "Face": FACE[face], "SizingMode": 1, "PixelsPerStud": float(pixels_per_stud),
            "LightInfluence": float(light_influence), "AlwaysOnTop": False, "Enabled": True, "Adornee": -1,
            "Brightness": 1.0, "MaxDistance": 0.0, "ZOffset": 0.0, "ClipsDescendants": True,
            "Active": False, "CanvasSize": (800.0, 600.0)})
        fam = {"FredokaOne": b"rbxasset://fonts/families/FredokaOne.json",
               "LuckiestGuy": b"rbxasset://fonts/families/LuckiestGuy.json",
               "GothamBold": b"rbxasset://fonts/families/GothamSSm.json",
               "Bangers": b"rbxasset://fonts/families/Bangers.json",
               "Arcade": b"rbxasset://fonts/families/PressStart2P.json"}[font]
        weight = 700 if font == "GothamBold" else 400
        props = {"Text": text.encode("utf-8"), "TextColor3": c3(color), "TextScaled": scaled, "TextWrapped": True,
                 "BackgroundTransparency": 1.0 if bg is None else 0.0,
                 "BackgroundColor3": c3(bg or (0, 0, 0)), "Size": (1.0, 0, 1.0, 0), "Position": (0.0, 0, 0.0, 0),
                 "FontFace": (fam, weight, 0, b""), "TextStrokeTransparency": 1.0 if stroke is None else 0.0,
                 "TextStrokeColor3": c3(stroke or (0, 0, 0)), "BorderSizePixel": 0, "RichText": rich,
                 "TextXAlignment": 2, "TextYAlignment": 1, "Visible": True, "TextTransparency": 0.0,
                 "AnchorPoint": (0.0, 0.0), "Rotation": 0.0, "ZIndex": 1, "TextSize": 48.0}
        label = self.new("TextLabel", gui, "Text", props)
        return gui, label


# ---------------------------------------------------------------------------- math helpers
def v_add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def v_sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def v_scale(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def v_len(a):
    return math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


def v_norm(a):
    n = v_len(a) or 1.0
    return (a[0] / n, a[1] / n, a[2] / n)


def cf_at(x, y, z, ry=0.0, rx=0.0, rz=0.0):
    """CFrame.new(x,y,z) * CFrame.Angles(rx, ry, rz) — but yaw applied first (Y then X then Z) via composition."""
    base = CF((x, y, z))
    if ry:
        base = base * CF.angles(0, ry, 0)
    if rx:
        base = base * CF.angles(rx, 0, 0)
    if rz:
        base = base * CF.angles(0, 0, rz)
    return base


def beam_cf(a, b):
    """CFrame centred between a and b, with its Z axis along a->b (size Z = length)."""
    mid = v_scale(v_add(a, b), 0.5)
    d = v_sub(b, a)
    if abs(d[0]) < 1e-6 and abs(d[2]) < 1e-6:
        cf = CF.look_at(mid, b, up=(1.0, 0.0, 0.0))
    else:
        cf = CF.look_at(mid, b)
    return cf, v_len(d)
