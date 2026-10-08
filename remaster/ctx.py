"""Shared context for remaster steps: the document, the factory, lookups and placement checks."""
import math
import random

import rbxl
import scene
from factory import CF, MAT, cf_at

DISTRICT = "Workspace/DOGROTS_District"


class Ctx:
    def __init__(self, doc, fac):
        self.doc = doc
        self.fac = fac
        self.district = doc.find_path(DISTRICT)
        self.rng = random.Random(1337)
        self._parts = None
        self.root = None          # 40_Paradise model
        self.groups = {}
        self.log = []
        self.blockers = []        # (x0, z0, x1, z1, ytop, label) footprints new props must avoid
        self.spots = {}           # named positions recorded by the builders (golden bones etc.)

    # ---------------------------------------------------------------- lookups
    def area(self, name):
        return self.doc.child(self.district, name)

    def find(self, path):
        return self.doc.find_path(DISTRICT + "/" + path)

    def parts(self, refresh=False):
        if self._parts is None or refresh:
            self._parts = scene.parts(self.doc)
        return self._parts

    def parts_under(self, ref):
        anc_ok = set(self.doc.descendants(ref))
        return [p for p in self.parts() if p.ref in anc_ok]

    # ---------------------------------------------------------------- output tree
    def group(self, path):
        """Model under 40_Paradise (created on demand), e.g. group('Coast/Palms')."""
        if self.root is None:
            self.root = self.fac.model(self.district, "40_Paradise", pivot=CF((0, 0, 300)),
                                       attrs={"ParadiseRemaster": True})
        cur, key = self.root, ""
        for seg in path.split("/"):
            key = key + "/" + seg
            if key not in self.groups:
                self.groups[key] = self.fac.model(cur, seg)
            cur = self.groups[key]
        return cur

    def note(self, msg):
        self.log.append(msg)

    # ---------------------------------------------------------------- placement
    CELL = 16.0

    def block(self, x0, z0, x1, z1, ytop=1e9, label="", ybottom=-1e9):
        b = (min(x0, x1), min(z0, z1), max(x0, x1), max(z0, z1), ytop, label, ybottom)
        self.blockers.append(b)
        grid = self.__dict__.setdefault("_grid", {})
        c = self.CELL
        for gx in range(int(b[0] // c), int(b[2] // c) + 1):
            for gz in range(int(b[1] // c), int(b[3] // c) + 1):
                grid.setdefault((gx, gz), []).append(b)

    def is_free(self, x, z, r, ymax=None, ymin=None):
        """True when the disc (x, z, r) touches no blocker. With ymax, blockers whose top is below
        ymax are ignored (low things like paving); with ymin, blockers whose bottom is above ymin
        are ignored (things overhead)."""
        grid = self.__dict__.get("_grid", {})
        c = self.CELL
        seen = set()
        for gx in range(int((x - r) // c), int((x + r) // c) + 1):
            for gz in range(int((z - r) // c), int((z + r) // c) + 1):
                for b in grid.get((gx, gz), ()):
                    if id(b) in seen:
                        continue
                    seen.add(id(b))
                    x0, z0, x1, z1, ytop, label, ybottom = b
                    if x + r > x0 and x - r < x1 and z + r > z0 and z - r < z1:
                        if ymax is not None and ytop <= ymax:
                            continue
                        if ymin is not None and ybottom >= ymin:
                            continue
                        return False
        return True

    def footprint_blockers_from_parts(self, min_height=0.6, ignore=None):
        """Register every visible or colliding part that rises above the ground as a blocker."""
        for p in self.parts():
            if ignore and ignore(p):
                continue
            hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
            r = p.cf.r
            ex = abs(r[0]) * hx + abs(r[1]) * hy + abs(r[2]) * hz
            ey = abs(r[3]) * hx + abs(r[4]) * hy + abs(r[5]) * hz
            ez = abs(r[6]) * hx + abs(r[7]) * hy + abs(r[8]) * hz
            top = p.cf.p[1] + ey
            if top < min_height:
                continue
            if p.transp >= 0.95 and not p.collide:
                continue
            self.block(p.cf.p[0] - ex, p.cf.p[2] - ez, p.cf.p[0] + ex, p.cf.p[2] + ez, top, p.name, p.cf.p[1] - ey)
