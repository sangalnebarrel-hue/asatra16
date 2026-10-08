#!/usr/bin/env python3
"""Dump every script of a place into DIR (same layout as tools/extract.luau, no Lune needed).
Usage: extract.py PLACE.rbxl DIR"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxl  # noqa: E402

EXT = {"Script": ".server.luau", "LocalScript": ".client.luau", "ModuleScript": ".luau"}


def sanitize(n):
    return re.sub(r"[^A-Za-z0-9._\- ]", "_", n)


def seg(doc, ref):
    parent = doc.parent.get(ref, -1)
    name = doc.name(ref)
    same = [k for k in doc.kids(parent) if doc.name(k) == name]
    s = sanitize(name)
    if len(same) > 1:
        s += "~%d" % (same.index(ref) + 1)
    return s


def key(doc, ref):
    parts = []
    while ref != -1:
        parts.append(seg(doc, ref))
        ref = doc.parent.get(ref, -1)
    return "/".join(reversed(parts))


def main():
    place, out = sys.argv[1:3]
    doc = rbxl.Doc.load(place)
    manifest = []
    for cls, ext in EXT.items():
        cid = doc.by_name.get(cls)
        if cid is None:
            continue
        for ref in doc.classes[cid].refs:
            k = key(doc, ref)
            if k.startswith("ReplicatedStorage/DogAnimationClips"):
                continue
            path = os.path.join(out, k + ext)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                f.write(doc.get(ref, "Source"))
            manifest.append("%s\t%s%s" % (cls, k, ext))
    manifest.sort()
    with open(os.path.join(out, "MANIFEST.tsv"), "w") as f:
        f.write("\n".join(manifest) + "\n")
    print("extracted", len(manifest))


if __name__ == "__main__":
    main()
