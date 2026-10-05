#!/usr/bin/env python3
"""Surgical builder for a Roblox binary place (.rbxl).

Copies the base place byte-for-byte and only touches what src/ changes:
  * Source of every existing script whose file in src/ differs from the place;
  * new scripts for files in src/ that are not in the place yet (each new instance
    copies every property of an existing instance of the same class, then gets its
    own Name, Source, UniqueId, HistoryId and ScriptGuid).

A full deserialize/serialize round trip (Lune / rbx-dom) rewrites property formats
(MeshId -> MeshContent, Tags as String) and drops properties it does not know, so
this tool never re-encodes a chunk it does not have to.

Usage: build_place.py BASE.rbxl SRC_DIR OUT.rbxl
"""
import os
import struct
import sys
import uuid

import lz4.block
import zstandard

MAGIC = b"<roblox!"
SCRIPT_EXT = {".server.luau": "Script", ".client.luau": "LocalScript", ".luau": "ModuleScript"}
# Property types this tool can copy: String is length-prefixed; the rest are fixed-width columns.
VARIABLE_TYPES = {0x01}
FIXED_TYPES = {0x02, 0x12, 0x1B, 0x1C, 0x1F, 0x21}  # Bool, Enum, Int64, SharedString, UniqueId, SecurityCapabilities
UNIQUE_ID = 0x1F


def sanitize(name):
    return "".join(c if (c.isalnum() and c.isascii()) or c in "._- " else "_" for c in name)


class Chunk:
    def __init__(self, name, raw, body):
        self.name, self.raw, self.body, self.dirty = name, raw, body, False

    def encode(self):
        if not self.dirty:
            return self.raw
        packed = zstandard.ZstdCompressor(level=19).compress(bytes(self.body))
        return self.name + struct.pack("<III", len(packed), len(self.body), 0) + packed


def read_chunks(data):
    assert data[:8] == MAGIC, "not a binary Roblox place"
    pos, out = 32, []
    while pos < len(data):
        name = data[pos:pos + 4]
        comp, uncomp, _ = struct.unpack("<III", data[pos + 4:pos + 16])
        start = pos
        pos += 16
        if comp == 0:
            body = data[pos:pos + uncomp]
            pos += uncomp
        else:
            packed = data[pos:pos + comp]
            pos += comp
            if packed[:4] == b"\x28\xb5\x2f\xfd":
                body = zstandard.ZstdDecompressor().decompress(packed, max_output_size=uncomp)
            else:
                body = lz4.block.decompress(packed, uncompressed_size=uncomp)
        assert len(body) == uncomp, name
        out.append(Chunk(name, data[start:pos], bytearray(body)))
        if name == b"END\x00":
            out[-1].raw = data[start:]  # keep the trailing </roblox> marker verbatim
            break
    return out


def deinterleave(buf, count, width):
    return [bytes(buf[j * count + i] for j in range(width)) for i in range(count)]


def interleave(values, width):
    count = len(values)
    out = bytearray(count * width)
    for i, v in enumerate(values):
        assert len(v) == width
        for j in range(width):
            out[j * count + i] = v[j]
    return out


def decode_refs(buf, count):
    refs, acc = [], 0
    for raw in deinterleave(buf, count, 4):
        n = struct.unpack(">I", raw)[0]
        acc += (n >> 1) ^ -(n & 1)
        refs.append(acc)
    return refs


def encode_refs(refs):
    out, prev = [], 0
    for r in refs:
        d = r - prev
        prev = r
        out.append(struct.pack(">I", ((d << 1) ^ (d >> 31)) & 0xFFFFFFFF))
    return interleave(out, 4)


def read_string(buf, pos):
    n = struct.unpack("<I", buf[pos:pos + 4])[0]
    return bytes(buf[pos + 4:pos + 4 + n]), pos + 4 + n


class Place:
    def __init__(self, path):
        data = open(path, "rb").read()
        self.header = bytearray(data[:32])
        self.chunks = read_chunks(data)
        self.classes = {}  # class id -> {name, chunk, refs, props: {name: chunk}}
        self.class_by_name = {}
        self.ref_class = {}  # referent -> (class id, index)
        for ch in self.chunks:
            if ch.name == b"INST":
                cid, = struct.unpack("<I", ch.body[:4])
                cname, pos = read_string(ch.body, 4)
                service = ch.body[pos]
                count, = struct.unpack("<I", ch.body[pos + 1:pos + 5])
                refs = decode_refs(ch.body[pos + 5:pos + 5 + 4 * count], count)
                info = {"name": cname.decode(), "chunk": ch, "refs": refs, "service": service,
                        "props": {}, "head": pos}
                self.classes[cid] = info
                self.class_by_name[info["name"]] = cid
                for i, r in enumerate(refs):
                    self.ref_class[r] = (cid, i)
            elif ch.name == b"PROP":
                cid, = struct.unpack("<I", ch.body[:4])
                pname, pos = read_string(ch.body, 4)
                self.classes[cid]["props"][pname.decode()] = ch
            elif ch.name == b"PRNT":
                self.prnt = ch
                count, = struct.unpack("<I", ch.body[1:5])
                self.children = decode_refs(ch.body[5:5 + 4 * count], count)
                self.parents = decode_refs(ch.body[5 + 4 * count:5 + 8 * count], count)
        self.parent_of = dict(zip(self.children, self.parents))
        self.kids = {}
        for c, p in zip(self.children, self.parents):
            self.kids.setdefault(p, []).append(c)
        self.columns = {}

    # ---- property columns -------------------------------------------------
    def column(self, cid, pname):
        key = (cid, pname)
        if key not in self.columns:
            ch = self.classes[cid]["props"][pname]
            _, pos = read_string(ch.body, 4)
            ptype = ch.body[pos]
            values_at = pos + 1
            count = len(self.classes[cid]["refs"])
            buf = ch.body[values_at:]
            if ptype in VARIABLE_TYPES:
                values, p = [], 0
                for _ in range(count):
                    v, p = read_string(buf, p)
                    values.append(v)
                assert p == len(buf), (self.classes[cid]["name"], pname)
                width = None
            elif ptype in FIXED_TYPES:
                assert len(buf) % count == 0, (self.classes[cid]["name"], pname)
                width = len(buf) // count
                values = deinterleave(buf, count, width)
            else:
                raise ValueError("unsupported property type %d for %s.%s" % (ptype, self.classes[cid]["name"], pname))
            self.columns[key] = {"chunk": ch, "type": ptype, "width": width, "values": values, "head": values_at}
        return self.columns[key]

    def flush_columns(self):
        for (cid, pname), col in self.columns.items():
            ch = col["chunk"]
            if col["width"] is None:
                buf = b"".join(struct.pack("<I", len(v)) + v for v in col["values"])
            else:
                buf = interleave(col["values"], col["width"])
            new = ch.body[:col["head"]] + buf
            if new != ch.body:
                ch.body, ch.dirty = bytearray(new), True

    # ---- tree ---------------------------------------------------------------
    def name_of(self, ref):
        cid, i = self.ref_class[ref]
        return self.column(cid, "Name")["values"][i].decode("utf-8", "replace")

    def class_of(self, ref):
        return self.classes[self.ref_class[ref][0]]["name"]

    def find_child(self, parent, seg):
        hits = [c for c in self.kids.get(parent, []) if sanitize(self.name_of(c)) == seg]
        if len(hits) > 1:
            raise ValueError("ambiguous path segment %r" % seg)
        return hits[0] if hits else None

    def resolve(self, key):
        cur = -1  # the DataModel
        for seg in key.split("/"):
            cur = self.find_child(cur, seg)
            if cur is None:
                return None
        return cur

    # ---- edits --------------------------------------------------------------
    def set_string(self, ref, pname, text):
        cid, i = self.ref_class[ref]
        col = self.column(cid, pname)
        assert col["width"] is None
        value = text.encode("utf-8")
        if col["values"][i] != value:
            col["values"][i] = value
            return True
        return False

    def get_string(self, ref, pname):
        cid, i = self.ref_class[ref]
        return self.column(cid, pname)["values"][i].decode("utf-8")

    def add_instance(self, class_name, parent, name, source=None):
        cid = self.class_by_name[class_name]
        info = self.classes[cid]
        assert not info["service"], class_name
        # Template: an instance of the class without attributes or tags.
        template = None
        for i in range(len(info["refs"])):
            attrs = self.column(cid, "AttributesSerialize")["values"][i] if "AttributesSerialize" in info["props"] else b""
            if attrs == b"" and (class_name == "Folder" or "Source" in info["props"]):
                template = i
                break
        assert template is not None, "no template instance for " + class_name
        ref = max(self.ref_class) + 1
        for pname in info["props"]:
            col = self.column(cid, pname)
            value = col["values"][template]
            if pname == "Name":
                value = name.encode("utf-8")
            elif pname == "Source":
                value = source.encode("utf-8")
            elif pname == "ScriptGuid":
                value = ("{%s}" % str(uuid.uuid4()).upper()).encode()
            elif pname in ("LinkedSource", "AttributesSerialize"):
                value = b""
            elif col["type"] == UNIQUE_ID:
                # Bytes 0..7 hold the (rotated) random component of the id.
                value = os.urandom(8) + value[8:]
            elif pname == "Disabled":
                value = b"\x00"
            col["values"].append(value)
        info["refs"].append(ref)
        self.ref_class[ref] = (cid, len(info["refs"]) - 1)
        self.children.append(ref)
        self.parents.append(parent)
        self.parent_of[ref] = parent
        self.kids.setdefault(parent, []).append(ref)
        self.added = getattr(self, "added", 0) + 1
        info["grew"] = True
        return ref

    def write(self, path):
        self.flush_columns()
        for cid, info in self.classes.items():
            if info.get("grew"):
                ch, head = info["chunk"], info["head"]
                tail = bytearray()
                if info["service"]:
                    raise ValueError("service classes are not supported")
                ch.body = ch.body[:head] + bytes([info["service"]]) + struct.pack("<I", len(info["refs"])) + encode_refs(info["refs"]) + tail
                ch.dirty = True
        if getattr(self, "added", 0):
            count = len(self.children)
            self.prnt.body = bytearray(b"\x00" + struct.pack("<I", count) + encode_refs(self.children) + encode_refs(self.parents))
            self.prnt.dirty = True
            classes, instances = struct.unpack("<ii", self.header[16:24])
            self.header[16:24] = struct.pack("<ii", classes, instances + self.added)
        with open(path, "wb") as f:
            f.write(self.header)
            for ch in self.chunks:
                f.write(ch.encode())


def script_files(src):
    for root, _, files in os.walk(src):
        for fn in sorted(files):
            if not fn.endswith(".luau"):
                continue
            rel = os.path.relpath(os.path.join(root, fn), src).replace(os.sep, "/")
            for ext, cls in SCRIPT_EXT.items():
                if rel.endswith(ext):
                    yield rel, rel[: -len(ext)], cls
                    break


def main():
    base, src, out = sys.argv[1:4]
    place = Place(base)
    changed, created = [], []
    pending = sorted(script_files(src), key=lambda t: t[1].count("/"))  # parents before children
    for rel, key, cls in pending:
        with open(os.path.join(src, rel), encoding="utf-8", newline="") as f:
            text = f.read()
        ref = place.resolve(key)
        if ref is not None:
            if place.class_of(ref) != cls:
                raise SystemExit("%s: place has %s, file says %s" % (rel, place.class_of(ref), cls))
            if place.set_string(ref, "Source", text):
                changed.append(rel)
            continue
        parent_key, _, name = key.rpartition("/")
        parent = place.resolve(parent_key) if parent_key else -1
        if parent is None:
            raise SystemExit("%s: parent %s does not exist in the place" % (rel, parent_key))
        place.add_instance(cls, parent, name, text)
        created.append(rel)
    place.write(out)
    for rel in changed:
        print("changed", rel)
    for rel in created:
        print("created", rel)
    print("%d changed, %d created -> %s" % (len(changed), len(created), out))


if __name__ == "__main__":
    main()
