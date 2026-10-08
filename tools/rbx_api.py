"""Roblox API model parsed from @rbxts/types (npm) generated declarations.

    api = RbxApi.load(path_to_rbxts_types_package)
    api.has_member("Part", "Shape") -> True
    api.enum_value("Material", "Neon") -> 288

Fetch the package with `npm pack @rbxts/types` (tools/fetch_api.sh).
"""
import json
import os
import re

IFACE_RE = re.compile(r"^interface (\w+)(?:<.*?>)?(?: extends ([\w, ]+?)(?:<.*?>)?)? \{")
MEMBER_RE = re.compile(r"^    (readonly )?(\w+)(\??)(\(|<|: )")
ENUM_NS_RE = re.compile(r"^    export namespace (\w+) \{")
ENUM_ITEM_RE = re.compile(r"^        export interface (\w+) extends globalThis\.EnumItem \{")
ENUM_VALUE_RE = re.compile(r"^            Value: (-?\d+);")


class RbxApi:
    def __init__(self):
        self.classes = {}     # name -> {"extends": [...], "members": {name: kind}}
        self.creatable = set()
        self.services = set()
        self.enums = {}       # enum -> {item: value}

    @classmethod
    def load(cls, package_dir):
        api = cls()
        gen = os.path.join(package_dir, "include", "generated")
        for fn in ("None.d.ts", "PluginSecurity.d.ts"):
            api._parse_classes(os.path.join(gen, fn))
        api._parse_enums(os.path.join(gen, "enums.d.ts"))
        return api

    def _parse_classes(self, path):
        cur = None
        block = None
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                m = IFACE_RE.match(line)
                if m:
                    name = m.group(1)
                    if name in ("Services", "CreatableInstances"):
                        block, cur = name, None
                        continue
                    block = None
                    cur = self.classes.setdefault(name, {"extends": [], "members": {}})
                    if m.group(2):
                        cur["extends"] = [s.strip() for s in m.group(2).split(",")]
                    continue
                if line.startswith("}"):
                    cur, block = None, None
                    continue
                if block:
                    m = re.match(r"^    (\w+): ", line)
                    if m:
                        (self.services if block == "Services" else self.creatable).add(m.group(1))
                    continue
                if cur is None:
                    continue
                m = MEMBER_RE.match(line)
                if m:
                    mname = m.group(2)
                    if mname.startswith("_nominal_"):
                        continue
                    kind = "method" if m.group(4) in ("(", "<") else "property"
                    if kind == "property" and "RBXScriptSignal" in line:
                        kind = "event"
                    cur["members"][mname] = kind

    def _parse_enums(self, path):
        cur, item = None, None
        with open(path, encoding="utf-8") as f:
            for line in f:
                m = ENUM_NS_RE.match(line)
                if m:
                    cur = self.enums.setdefault(m.group(1), {})
                    continue
                m = ENUM_ITEM_RE.match(line)
                if m and cur is not None:
                    item = m.group(1)
                    continue
                m = ENUM_VALUE_RE.match(line)
                if m and cur is not None and item:
                    cur[item] = int(m.group(1))
                    item = None

    def ancestry(self, cls):
        out, stack, seen = [], [cls], set()
        while stack:
            c = stack.pop(0)
            if c in seen or c not in self.classes:
                continue
            seen.add(c)
            out.append(c)
            stack.extend(self.classes[c]["extends"])
        return out

    def member(self, cls, name):
        for c in self.ancestry(cls):
            k = self.classes[c]["members"].get(name)
            if k:
                return k
        return None

    def has_member(self, cls, name):
        return self.member(cls, name) is not None

    def is_a(self, cls, base):
        return base in self.ancestry(cls)

    def enum_value(self, enum, item):
        return self.enums[enum][item]


def default_package_dir():
    return os.environ.get("RBXTS_TYPES", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".cache", "rbxts-types", "package"))


if __name__ == "__main__":
    import sys
    api = RbxApi.load(sys.argv[1] if len(sys.argv) > 1 else default_package_dir())
    print(len(api.classes), "classes,", len(api.creatable), "creatable,", len(api.services), "services,", len(api.enums), "enums")
    print(json.dumps({k: api.enums[k] for k in ("Material", "SurfaceGuiSizingMode", "NormalId", "PartType", "ModelStreamingMode")}, indent=0)[:1500])
