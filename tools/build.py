#!/usr/bin/env python3
"""Build the DOGROTS place.

    python3 tools/build.py [--base place/DOGROTS_V33.rbxl] [--out build/DOGROTS_V34.rbxl] [--no-map]

1. loads the base place (tools/rbxl.py keeps every untouched chunk byte-for-byte);
2. runs the map remaster (remaster/pipeline.py) unless --no-map;
3. applies src/ (changed script sources, new scripts);
4. writes the result.
"""
import argparse
import os
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, ROOT)

import factory  # noqa: E402
import rbxl  # noqa: E402
import scripts_sync  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=os.path.join(ROOT, "place", "DOGROTS_V33.rbxl"))
    ap.add_argument("--src", default=os.path.join(ROOT, "src"))
    ap.add_argument("--out", default=os.path.join(ROOT, "build", "DOGROTS_V34.rbxl"))
    ap.add_argument("--no-map", action="store_true")
    args = ap.parse_args()
    t0 = time.time()
    doc = rbxl.Doc.load(args.base)
    fac = factory.Factory(doc)
    if not args.no_map:
        from remaster import pipeline
        pipeline.run(doc, fac)
    changed, created = scripts_sync.apply(doc, fac, args.src)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    doc.save(args.out)
    for rel in changed:
        print("changed", rel)
    for rel in created:
        print("created", rel)
    n = sum(len(i.refs) for i in doc.classes.values())
    print("%d scripts changed, %d created, %d instances created in total, %d instances -> %s (%.1fs)"
          % (len(changed), len(created), fac.created, n, args.out, time.time() - t0))


if __name__ == "__main__":
    main()
