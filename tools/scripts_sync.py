"""Apply src/ scripts to a Doc: changed sources are replaced, new files become new
script instances (Script / LocalScript / ModuleScript by extension)."""
import os
import re

SCRIPT_EXT = [(".server.luau", "Script"), (".client.luau", "LocalScript"), (".luau", "ModuleScript")]


def sanitize(n):
    return re.sub(r"[^A-Za-z0-9._\- ]", "_", n)


def find_segment(doc, parent, seg):
    m = re.match(r"^(.*)~(\d+)$", seg)
    want, nth = (m.group(1), int(m.group(2))) if m else (seg, None)
    hits = [k for k in doc.kids(parent) if sanitize(doc.name(k)) == want]
    if nth is not None:
        return hits[nth - 1] if len(hits) >= nth else None
    if len(hits) > 1:
        raise ValueError("ambiguous path segment %r under %s" % (seg, doc.path(parent) if parent != -1 else "game"))
    return hits[0] if hits else None


def resolve(doc, key):
    cur = -1
    for seg in key.split("/"):
        cur = find_segment(doc, cur, seg)
        if cur is None:
            return None
    return cur


def script_files(src):
    for root, _, files in os.walk(src):
        for fn in sorted(files):
            if not fn.endswith(".luau"):
                continue
            rel = os.path.relpath(os.path.join(root, fn), src).replace(os.sep, "/")
            for ext, cls in SCRIPT_EXT:
                if rel.endswith(ext):
                    yield rel, rel[: -len(ext)], cls
                    break


def apply(doc, fac, src):
    changed, created = [], []
    pending = sorted(script_files(src), key=lambda t: t[1].count("/"))  # parents before children
    for rel, key, cls in pending:
        with open(os.path.join(src, rel), "rb") as f:
            text = f.read()
        ref = resolve(doc, key)
        if ref is not None:
            if doc.cls(ref) != cls:
                raise SystemExit("%s: place has %s, file says %s" % (rel, doc.cls(ref), cls))
            if doc.get(ref, "Source") != text:
                doc.set(ref, "Source", text)
                changed.append(rel)
            continue
        parent_key, _, name = key.rpartition("/")
        parent = resolve(doc, parent_key) if parent_key else -1
        if parent is None:
            raise SystemExit("%s: parent %s does not exist in the place" % (rel, parent_key))
        if "~" in name:
            raise SystemExit("%s: new scripts cannot use ~N names" % rel)
        props = {"Source": text, "LinkedSource": b""}
        if cls != "ModuleScript":
            props["Disabled"] = False
        fac.new(cls, parent, name, props)
        created.append(rel)
    return changed, created
