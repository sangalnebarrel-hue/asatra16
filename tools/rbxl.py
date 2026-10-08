#!/usr/bin/env python3
"""Full codec for Roblox binary places/models (.rbxl/.rbxm).

Unlike a deserialize/serialize round trip through rbx-dom, this keeps every chunk
the edit does not touch byte-for-byte, keeps property formats exactly as Roblox
wrote them (MeshId vs MeshContent, Tags, PhysicalProperties flags, CFrame rotation
ids) and supports every property type that appears in the DOGROTS place, so a
column can be decoded, edited and re-encoded losslessly.

    doc = Doc.load("place.rbxl")
    part = doc.find_path("Workspace/Map")
    doc.set(part, "Color", (1.0, 0.5, 0.2))
    new = doc.add("Part", parent=part, Name="Wall", Size=(4, 10, 1), ...)
    doc.remove(old_ref)                     # with its whole subtree
    doc.save("out.rbxl")

Values: String/ProtectedString -> bytes, Bool -> bool, Int32/Int64/Enum/BrickColor ->
int, Float32/Float64 -> float, Vector2/Vector3/Color3 -> tuple, CFrame -> CF (pos +
9-float rotation, keeps the rotation id it was read with), Referent -> int (-1 = nil),
the rest -> small tuples or raw bytes (see the codec table at the bottom).
"""
import math
import os
import struct

import lz4.block
import zstandard

MAGIC = b"<roblox!"
ZSTD_LEVEL = int(os.environ.get("DOGROTS_ZSTD_LEVEL", "9"))


# ---------------------------------------------------------------------------- helpers
def _r_string(buf, pos):
    n = struct.unpack_from("<I", buf, pos)[0]
    return bytes(buf[pos + 4:pos + 4 + n]), pos + 4 + n


def _w_string(b):
    if isinstance(b, str):
        b = b.encode("utf-8")
    return struct.pack("<I", len(b)) + b


def _deinterleave(buf, pos, count, width):
    """Interleaved column of `count` big-endian `width`-byte words -> list of bytes."""
    end = pos + count * width
    block = buf[pos:end]
    out = [bytearray(width) for _ in range(count)]
    for j in range(width):
        row = block[j * count:(j + 1) * count]
        for i in range(count):
            out[i][j] = row[i]
    return [bytes(v) for v in out], end


def _interleave(words, width):
    count = len(words)
    out = bytearray(count * width)
    for i, w in enumerate(words):
        for j in range(width):
            out[j * count + i] = w[j]
    return bytes(out)


def _zig_dec32(n):
    return (n >> 1) ^ -(n & 1)


def _zig_enc32(x):
    return ((x << 1) ^ (x >> 31)) & 0xFFFFFFFF


def _zig_dec64(n):
    return (n >> 1) ^ -(n & 1)


def _zig_enc64(x):
    return ((x << 1) ^ (x >> 63)) & 0xFFFFFFFFFFFFFFFF


def _f_from_rbx(u):
    bits = ((u >> 1) | ((u & 1) << 31)) & 0xFFFFFFFF
    return struct.unpack("<f", struct.pack("<I", bits))[0]


def _f_to_rbx(f):
    bits = struct.unpack("<I", struct.pack("<f", f))[0]
    return ((bits << 1) | (bits >> 31)) & 0xFFFFFFFF


def _read_i32s(buf, pos, count):
    words, end = _deinterleave(buf, pos, count, 4)
    return [_zig_dec32(int.from_bytes(w, "big")) for w in words], end


def _write_i32s(vals):
    return _interleave([_zig_enc32(v).to_bytes(4, "big") for v in vals], 4)


def _read_u32s(buf, pos, count):
    words, end = _deinterleave(buf, pos, count, 4)
    return [int.from_bytes(w, "big") for w in words], end


def _write_u32s(vals):
    return _interleave([(v & 0xFFFFFFFF).to_bytes(4, "big") for v in vals], 4)


def _read_f32s(buf, pos, count):
    words, end = _deinterleave(buf, pos, count, 4)
    return [_f_from_rbx(int.from_bytes(w, "big")) for w in words], end


def _write_f32s(vals):
    return _interleave([_f_to_rbx(v).to_bytes(4, "big") for v in vals], 4)


def _read_refs(buf, pos, count):
    vals, end = _read_i32s(buf, pos, count)
    out, acc = [], 0
    for d in vals:
        acc += d
        out.append(acc)
    return out, end


def _write_refs(refs):
    deltas, prev = [], 0
    for r in refs:
        deltas.append(r - prev)
        prev = r
    return _write_i32s(deltas)


def f32(x):
    """Round a Python float to the nearest float32 (what Roblox will store)."""
    return struct.unpack("<f", struct.pack("<f", x))[0]


# ---------------------------------------------------------------------------- CFrame
_DIRS = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (-1, 0, 0), (0, -1, 0), (0, 0, -1)]


def _rot_from_id(rid):
    k = rid - 1
    right, up = _DIRS[k // 6], _DIRS[k % 6]
    # back = right x up  (look = -back)
    bx = right[1] * up[2] - right[2] * up[1]
    by = right[2] * up[0] - right[0] * up[2]
    bz = right[0] * up[1] - right[1] * up[0]
    # row-major R00 R01 R02 / R10 R11 R12 / R20 R21 R22 with columns right, up, back
    return (float(right[0]), float(up[0]), float(bx),
            float(right[1]), float(up[1]), float(by),
            float(right[2]), float(up[2]), float(bz))


_ROT_IDS = {}
for _rid in range(2, 0x24):
    _k = _rid - 1
    if _k // 6 % 3 == _k % 6 % 3:
        continue  # right and up on the same axis
    _ROT_IDS[_rot_from_id(_rid)] = _rid


class CF:
    """CFrame: p = (x, y, z), r = 9 floats row-major, rid = binary rotation id (0 = full)."""
    __slots__ = ("p", "r", "rid")

    def __init__(self, p=(0.0, 0.0, 0.0), r=(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0), rid=None):
        self.p = tuple(float(v) for v in p)
        self.r = tuple(float(v) for v in r)
        if rid is None:
            rid = _ROT_IDS.get(tuple(round(v) if abs(v - round(v)) < 1e-6 else v for v in self.r), 0)
            if rid:
                self.r = _rot_from_id(rid)
        self.rid = rid

    def __repr__(self):
        return "CF(%s, %s)" % (", ".join("%.3f" % v for v in self.p), ", ".join("%.3f" % v for v in self.r))

    def __eq__(self, o):
        return isinstance(o, CF) and self.p == o.p and self.r == o.r

    # --- math (pure python; the generator uses its own numpy-free helpers too)
    @property
    def right(self):
        return (self.r[0], self.r[3], self.r[6])

    @property
    def up(self):
        return (self.r[1], self.r[4], self.r[7])

    @property
    def back(self):
        return (self.r[2], self.r[5], self.r[8])

    def __mul__(self, o):
        a = self.r
        if isinstance(o, CF):
            b = o.r
            r = tuple(sum(a[i * 3 + k] * b[k * 3 + j] for k in range(3)) for i in range(3) for j in range(3))
            p = tuple(self.p[i] + sum(a[i * 3 + k] * o.p[k] for k in range(3)) for i in range(3))
            return CF(p, r)
        # point
        return tuple(self.p[i] + sum(a[i * 3 + k] * o[k] for k in range(3)) for i in range(3))

    def inverse(self):
        a = self.r
        rt = (a[0], a[3], a[6], a[1], a[4], a[7], a[2], a[5], a[8])
        p = tuple(-sum(rt[i * 3 + k] * self.p[k] for k in range(3)) for i in range(3))
        return CF(p, rt)

    def vector_to_world(self, v):
        a = self.r
        return tuple(sum(a[i * 3 + k] * v[k] for k in range(3)) for i in range(3))

    def vector_to_object(self, v):
        a = self.r
        return tuple(sum(a[k * 3 + i] * v[k] for k in range(3)) for i in range(3))

    def point_to_object(self, v):
        d = (v[0] - self.p[0], v[1] - self.p[1], v[2] - self.p[2])
        return self.vector_to_object(d)

    @staticmethod
    def angles(rx=0.0, ry=0.0, rz=0.0, p=(0.0, 0.0, 0.0)):
        """CFrame.new(p) * CFrame.Angles(rx, ry, rz)  (R = Rx * Ry * Rz)."""
        cx, sx = math.cos(rx), math.sin(rx)
        cy, sy = math.cos(ry), math.sin(ry)
        cz, sz = math.cos(rz), math.sin(rz)
        rxm = (1, 0, 0, 0, cx, -sx, 0, sx, cx)
        rym = (cy, 0, sy, 0, 1, 0, -sy, 0, cy)
        rzm = (cz, -sz, 0, sz, cz, 0, 0, 0, 1)

        def mm(a, b):
            return tuple(sum(a[i * 3 + k] * b[k * 3 + j] for k in range(3)) for i in range(3) for j in range(3))
        return CF(p, mm(mm(rxm, rym), rzm))

    @staticmethod
    def look_at(eye, target, up=(0.0, 1.0, 0.0)):
        fx, fy, fz = target[0] - eye[0], target[1] - eye[1], target[2] - eye[2]
        n = math.sqrt(fx * fx + fy * fy + fz * fz) or 1.0
        fx, fy, fz = fx / n, fy / n, fz / n
        # right = forward x up
        rx, ry, rz = fy * up[2] - fz * up[1], fz * up[0] - fx * up[2], fx * up[1] - fy * up[0]
        n = math.sqrt(rx * rx + ry * ry + rz * rz)
        if n < 1e-6:
            rx, ry, rz = 1.0, 0.0, 0.0
            n = 1.0
        rx, ry, rz = rx / n, ry / n, rz / n
        # up = right x forward
        ux, uy, uz = ry * fz - rz * fy, rz * fx - rx * fz, rx * fy - ry * fx
        bx, by, bz = -fx, -fy, -fz
        return CF(eye, (rx, ux, bx, ry, uy, by, rz, uz, bz))


# ---------------------------------------------------------------------------- codecs
# Each codec: dec(buf, pos, count, doc) -> (values, end) ; enc(values, doc) -> bytes

def _dec_string(buf, pos, count, doc):
    out = []
    for _ in range(count):
        v, pos = _r_string(buf, pos)
        out.append(v)
    return out, pos


def _enc_string(vals, doc):
    return b"".join(_w_string(v) for v in vals)


def _dec_bool(buf, pos, count, doc):
    return [b != 0 for b in buf[pos:pos + count]], pos + count


def _enc_bool(vals, doc):
    return bytes(1 if v else 0 for v in vals)


def _dec_i32(buf, pos, count, doc):
    return _read_i32s(buf, pos, count)


def _enc_i32(vals, doc):
    return _write_i32s(vals)


def _dec_f32(buf, pos, count, doc):
    return _read_f32s(buf, pos, count)


def _enc_f32(vals, doc):
    return _write_f32s(vals)


def _dec_f64(buf, pos, count, doc):
    return list(struct.unpack_from("<%dd" % count, buf, pos)), pos + 8 * count


def _enc_f64(vals, doc):
    return struct.pack("<%dd" % len(vals), *vals)


def _dec_udim(buf, pos, count, doc):
    s, pos = _read_f32s(buf, pos, count)
    o, pos = _read_i32s(buf, pos, count)
    return list(zip(s, o)), pos


def _enc_udim(vals, doc):
    return _write_f32s([v[0] for v in vals]) + _write_i32s([v[1] for v in vals])


def _dec_udim2(buf, pos, count, doc):
    sx, pos = _read_f32s(buf, pos, count)
    sy, pos = _read_f32s(buf, pos, count)
    ox, pos = _read_i32s(buf, pos, count)
    oy, pos = _read_i32s(buf, pos, count)
    return [(a, b, c, d) for a, b, c, d in zip(sx, ox, sy, oy)], pos  # (sx, ox, sy, oy) like UDim2.new


def _enc_udim2(vals, doc):
    return (_write_f32s([v[0] for v in vals]) + _write_f32s([v[2] for v in vals])
            + _write_i32s([v[1] for v in vals]) + _write_i32s([v[3] for v in vals]))


def _dec_ray(buf, pos, count, doc):
    out = []
    for _ in range(count):
        out.append(struct.unpack_from("<6f", buf, pos))
        pos += 24
    return out, pos


def _enc_ray(vals, doc):
    return b"".join(struct.pack("<6f", *v) for v in vals)


def _dec_u8(buf, pos, count, doc):
    return list(buf[pos:pos + count]), pos + count


def _enc_u8(vals, doc):
    return bytes(vals)


def _dec_u32(buf, pos, count, doc):
    return _read_u32s(buf, pos, count)


def _enc_u32(vals, doc):
    return _write_u32s(vals)


def _dec_color3(buf, pos, count, doc):
    r, pos = _read_f32s(buf, pos, count)
    g, pos = _read_f32s(buf, pos, count)
    b, pos = _read_f32s(buf, pos, count)
    return list(zip(r, g, b)), pos


def _enc_color3(vals, doc):
    return b"".join(_write_f32s([v[i] for v in vals]) for i in range(3))


def _dec_vec2(buf, pos, count, doc):
    x, pos = _read_f32s(buf, pos, count)
    y, pos = _read_f32s(buf, pos, count)
    return list(zip(x, y)), pos


def _enc_vec2(vals, doc):
    return b"".join(_write_f32s([v[i] for v in vals]) for i in range(2))


def _dec_vec3(buf, pos, count, doc):
    x, pos = _read_f32s(buf, pos, count)
    y, pos = _read_f32s(buf, pos, count)
    z, pos = _read_f32s(buf, pos, count)
    return list(zip(x, y, z)), pos


def _enc_vec3(vals, doc):
    return b"".join(_write_f32s([v[i] for v in vals]) for i in range(3))


def _dec_cframes(buf, pos, count):
    rots = []
    for _ in range(count):
        rid = buf[pos]
        pos += 1
        if rid == 0:
            rots.append((0, struct.unpack_from("<9f", buf, pos)))
            pos += 36
        else:
            rots.append((rid, _rot_from_id(rid)))
    ps, pos = _dec_vec3(buf, pos, count, None)
    return [CF(p, r, rid) for (rid, r), p in zip(rots, ps)], pos


def _enc_cframes(vals):
    out = bytearray()
    for v in vals:
        if v.rid:
            out.append(v.rid)
        else:
            out.append(0)
            out += struct.pack("<9f", *v.r)
    out += _enc_vec3([v.p for v in vals], None)
    return bytes(out)


def _dec_cframe(buf, pos, count, doc):
    return _dec_cframes(buf, pos, count)


def _enc_cframe(vals, doc):
    return _enc_cframes(vals)


def _dec_refs(buf, pos, count, doc):
    return _read_refs(buf, pos, count)


def _enc_refs(vals, doc):
    return _write_refs(vals)


def _dec_v3i16(buf, pos, count, doc):
    out = []
    for _ in range(count):
        out.append(struct.unpack_from("<3h", buf, pos))
        pos += 6
    return out, pos


def _enc_v3i16(vals, doc):
    return b"".join(struct.pack("<3h", *v) for v in vals)


def _dec_numseq(buf, pos, count, doc):
    out = []
    for _ in range(count):
        n = struct.unpack_from("<I", buf, pos)[0]
        pos += 4
        kps = []
        for _ in range(n):
            kps.append(struct.unpack_from("<3f", buf, pos))
            pos += 12
        out.append(tuple(kps))
    return out, pos


def _enc_numseq(vals, doc):
    out = bytearray()
    for kps in vals:
        out += struct.pack("<I", len(kps))
        for k in kps:
            out += struct.pack("<3f", *k)
    return bytes(out)


def _dec_colseq(buf, pos, count, doc):
    out = []
    for _ in range(count):
        n = struct.unpack_from("<I", buf, pos)[0]
        pos += 4
        kps = []
        for _ in range(n):
            kps.append(struct.unpack_from("<5f", buf, pos))
            pos += 20
        out.append(tuple(kps))
    return out, pos


def _enc_colseq(vals, doc):
    out = bytearray()
    for kps in vals:
        out += struct.pack("<I", len(kps))
        for k in kps:
            out += struct.pack("<5f", *k)
    return bytes(out)


def _dec_numrange(buf, pos, count, doc):
    out = []
    for _ in range(count):
        out.append(struct.unpack_from("<2f", buf, pos))
        pos += 8
    return out, pos


def _enc_numrange(vals, doc):
    return b"".join(struct.pack("<2f", *v) for v in vals)


def _dec_rect(buf, pos, count, doc):
    cols = []
    for _ in range(4):
        c, pos = _read_f32s(buf, pos, count)
        cols.append(c)
    return list(zip(*cols)), pos


def _enc_rect(vals, doc):
    return b"".join(_write_f32s([v[i] for v in vals]) for i in range(4))


def _dec_physprops(buf, pos, count, doc):
    out = []
    for _ in range(count):
        flag = buf[pos]
        pos += 1
        if not flag & 1:
            out.append((flag,))  # default physics (2 = written by the AcousticAbsorption-aware format)
        else:
            n = 6 if flag & 2 else 5  # bit 1: AcousticAbsorption follows the classic five
            out.append((flag,) + struct.unpack_from("<%df" % n, buf, pos))
            pos += 4 * n
    return out, pos


def _enc_physprops(vals, doc):
    out = bytearray()
    for v in vals:
        out.append(v[0])
        if v[0] & 1:
            out += struct.pack("<%df" % (len(v) - 1), *v[1:])
    return bytes(out)


def _dec_color3u8(buf, pos, count, doc):
    r = buf[pos:pos + count]
    g = buf[pos + count:pos + 2 * count]
    b = buf[pos + 2 * count:pos + 3 * count]
    return list(zip(r, g, b)), pos + 3 * count


def _enc_color3u8(vals, doc):
    return bytes(v[0] for v in vals) + bytes(v[1] for v in vals) + bytes(v[2] for v in vals)


def _dec_i64(buf, pos, count, doc):
    words, end = _deinterleave(buf, pos, count, 8)
    return [_zig_dec64(int.from_bytes(w, "big")) for w in words], end


def _enc_i64(vals, doc):
    return _interleave([_zig_enc64(v).to_bytes(8, "big") for v in vals], 8)


def _dec_sstr(buf, pos, count, doc):
    return _read_u32s(buf, pos, count)


def _enc_sstr(vals, doc):
    return _write_u32s(vals)


def _dec_optcf(buf, pos, count, doc):
    assert buf[pos] == 0x10
    cfs, pos = _dec_cframes(buf, pos + 1, count)
    assert buf[pos] == 0x02
    flags = buf[pos + 1:pos + 1 + count]
    pos += 1 + count
    return [cf if f else None for cf, f in zip(cfs, flags)], pos


def _enc_optcf(vals, doc):
    cfs = [v if v is not None else CF() for v in vals]
    return b"\x10" + _enc_cframes(cfs) + b"\x02" + bytes(1 if v is not None else 0 for v in vals)


def _dec_fixed(width):
    def dec(buf, pos, count, doc):
        return _deinterleave(buf, pos, count, width)
    return dec


def _enc_fixed(width):
    def enc(vals, doc):
        return _interleave(vals, width)
    return enc


def _dec_font(buf, pos, count, doc):
    out = []
    for _ in range(count):
        fam, pos = _r_string(buf, pos)
        weight, style = struct.unpack_from("<HB", buf, pos)
        pos += 3
        cached, pos = _r_string(buf, pos)
        out.append((fam, weight, style, cached))
    return out, pos


def _enc_font(vals, doc):
    out = bytearray()
    for fam, weight, style, cached in vals:
        out += _w_string(fam) + struct.pack("<HB", weight, style) + _w_string(cached)
    return bytes(out)


def _dec_content(buf, pos, count, doc):
    # source types (i32 interleaved): 0 none, 1 uri, 2 object
    kinds, pos = _read_i32s(buf, pos, count)
    nuri = struct.unpack_from("<I", buf, pos)[0]
    pos += 4
    uris = []
    for _ in range(nuri):
        u, pos = _r_string(buf, pos)
        uris.append(u)
    nobj = struct.unpack_from("<I", buf, pos)[0]
    pos += 4
    objs, pos = _read_refs(buf, pos, nobj)
    next_ = struct.unpack_from("<I", buf, pos)[0]
    pos += 4
    assert next_ == 0, "external content not supported"
    out, ui, oi = [], 0, 0
    for k in kinds:
        if k == 0:
            out.append(None)
        elif k == 1:
            out.append(("uri", uris[ui]))
            ui += 1
        elif k == 2:
            out.append(("obj", objs[oi]))
            oi += 1
        else:
            raise ValueError("content kind %d" % k)
    return out, pos


def _enc_content(vals, doc):
    kinds, uris, objs = [], [], []
    for v in vals:
        if v is None:
            kinds.append(0)
        elif v[0] == "uri":
            kinds.append(1)
            uris.append(v[1])
        else:
            kinds.append(2)
            objs.append(v[1])
    out = bytearray(_write_i32s(kinds))
    out += struct.pack("<I", len(uris))
    for u in uris:
        out += _w_string(u)
    out += struct.pack("<I", len(objs)) + _write_refs(objs)
    out += struct.pack("<I", 0)
    return bytes(out)


CODECS = {
    0x01: ("String", _dec_string, _enc_string),
    0x02: ("Bool", _dec_bool, _enc_bool),
    0x03: ("Int32", _dec_i32, _enc_i32),
    0x04: ("Float32", _dec_f32, _enc_f32),
    0x05: ("Float64", _dec_f64, _enc_f64),
    0x06: ("UDim", _dec_udim, _enc_udim),
    0x07: ("UDim2", _dec_udim2, _enc_udim2),
    0x08: ("Ray", _dec_ray, _enc_ray),
    0x09: ("Faces", _dec_u8, _enc_u8),
    0x0A: ("Axes", _dec_u8, _enc_u8),
    0x0B: ("BrickColor", _dec_u32, _enc_u32),
    0x0C: ("Color3", _dec_color3, _enc_color3),
    0x0D: ("Vector2", _dec_vec2, _enc_vec2),
    0x0E: ("Vector3", _dec_vec3, _enc_vec3),
    0x10: ("CFrame", _dec_cframe, _enc_cframe),
    0x12: ("Enum", _dec_u32, _enc_u32),
    0x13: ("Ref", _dec_refs, _enc_refs),
    0x14: ("Vector3int16", _dec_v3i16, _enc_v3i16),
    0x15: ("NumberSequence", _dec_numseq, _enc_numseq),
    0x16: ("ColorSequence", _dec_colseq, _enc_colseq),
    0x17: ("NumberRange", _dec_numrange, _enc_numrange),
    0x18: ("Rect", _dec_rect, _enc_rect),
    0x19: ("PhysicalProperties", _dec_physprops, _enc_physprops),
    0x1A: ("Color3uint8", _dec_color3u8, _enc_color3u8),
    0x1B: ("Int64", _dec_i64, _enc_i64),
    0x1C: ("SharedString", _dec_sstr, _enc_sstr),
    0x1E: ("OptionalCFrame", _dec_optcf, _enc_optcf),
    0x1F: ("UniqueId", _dec_fixed(16), _enc_fixed(16)),
    0x20: ("Font", _dec_font, _enc_font),
    0x21: ("SecurityCapabilities", _dec_fixed(8), _enc_fixed(8)),
    0x22: ("Content", _dec_content, _enc_content),
}
TYPE_ID = {v[0]: k for k, v in CODECS.items()}


# ---------------------------------------------------------------------------- chunks
class Chunk:
    __slots__ = ("name", "raw", "body", "dirty", "compression")

    def __init__(self, name, raw, body, compression):
        self.name, self.raw, self.body, self.dirty, self.compression = name, raw, body, False, compression

    def encode(self):
        if not self.dirty:
            return self.raw
        body = bytes(self.body)
        if self.compression == "none":
            return self.name + struct.pack("<III", 0, len(body), 0) + body
        if self.compression == "lz4":
            packed = lz4.block.compress(body, store_size=False)
        else:
            packed = zstandard.ZstdCompressor(level=ZSTD_LEVEL).compress(body)
        return self.name + struct.pack("<III", len(packed), len(body), 0) + packed


def read_chunks(data):
    assert data[:8] == MAGIC, "not a binary Roblox file"
    pos, out = 32, []
    while pos < len(data):
        name = data[pos:pos + 4]
        comp, uncomp, _ = struct.unpack_from("<III", data, pos + 4)
        start = pos
        pos += 16
        if comp == 0:
            body = data[pos:pos + uncomp]
            pos += uncomp
            kind = "none"
        else:
            packed = data[pos:pos + comp]
            pos += comp
            if packed[:4] == b"\x28\xb5\x2f\xfd":
                body = zstandard.ZstdDecompressor().decompress(packed, max_output_size=uncomp)
                kind = "zstd"
            else:
                body = lz4.block.decompress(packed, uncompressed_size=uncomp)
                kind = "lz4"
        assert len(body) == uncomp, name
        out.append(Chunk(name, data[start:pos], bytearray(body), kind))
        if name == b"END\x00":
            out[-1].raw = data[start:]
            break
    return out


# ---------------------------------------------------------------------------- document
class Opaque:
    __slots__ = ("raw",)

    def __init__(self, raw):
        self.raw = raw

    def __eq__(self, o):
        return isinstance(o, Opaque) and o.raw == self.raw


class Column:
    __slots__ = ("cid", "name", "type", "values", "chunk", "dirty")

    def __init__(self, cid, name, ptype, values, chunk):
        self.cid, self.name, self.type, self.values, self.chunk, self.dirty = cid, name, ptype, values, chunk, False


class ClassInfo:
    __slots__ = ("cid", "name", "service", "refs", "chunk", "props", "order", "index", "dirty")

    def __init__(self, cid, name, service, refs, chunk):
        self.cid, self.name, self.service, self.refs, self.chunk = cid, name, service, refs, chunk
        self.props = {}   # prop name -> Column (decoded lazily)
        self.order = []   # prop names in file order
        self.index = {r: i for i, r in enumerate(refs)}
        self.dirty = False


class Doc:
    def __init__(self, data):
        self.header = bytearray(data[:32])
        self.chunks = read_chunks(data)
        self.classes = {}
        self.by_name = {}
        self.ref_cid = {}
        self._raw_props = {}  # (cid, name) -> chunk, decoded on first use
        self.sstr = None
        for ch in self.chunks:
            if ch.name == b"INST":
                body = ch.body
                cid = struct.unpack_from("<I", body, 0)[0]
                cname, pos = _r_string(body, 4)
                service = body[pos]
                count = struct.unpack_from("<I", body, pos + 1)[0]
                refs, end = _read_refs(body, pos + 5, count)
                info = ClassInfo(cid, cname.decode(), service, refs, ch)
                self.classes[cid] = info
                self.by_name[info.name] = cid
                for r in refs:
                    self.ref_cid[r] = cid
            elif ch.name == b"PROP":
                cid = struct.unpack_from("<I", ch.body, 0)[0]
                pname, _ = _r_string(ch.body, 4)
                pname = pname.decode()
                self.classes[cid].order.append(pname)
                self._raw_props[(cid, pname)] = ch
            elif ch.name == b"PRNT":
                count = struct.unpack_from("<I", ch.body, 1)[0]
                kids, pos = _read_refs(ch.body, 5, count)
                pars, pos = _read_refs(ch.body, pos, count)
                self.prnt = ch
                self.parent = dict(zip(kids, pars))
                self.prnt_order = kids
            elif ch.name == b"SSTR":
                self.sstr = ch
        self.children = {}
        for k in self.prnt_order:
            self.children.setdefault(self.parent[k], []).append(k)
        self._sstr_vals = None
        self._dangling = set()
        self.next_ref = max(self.ref_cid) + 1 if self.ref_cid else 0
        self.tree_dirty = False

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f:
            return cls(f.read())

    # ------------------------------------------------------------------ columns
    def column(self, cid, pname):
        info = self.classes[cid]
        col = info.props.get(pname)
        if col is None:
            ch = self._raw_props.get((cid, pname))
            if ch is None:
                return None
            body = ch.body
            _, pos = _r_string(body, 4)
            ptype = body[pos]
            pos += 1
            if ptype not in CODECS:
                # A type this codec does not know: keep the column as one opaque blob. Fine for
                # single-instance classes (Terrain); such a class cannot gain or lose instances.
                col = Column(cid, pname, ptype, [Opaque(bytes(body[pos:]))] * len(info.refs), ch)
                info.props[pname] = col
                return col
            vals, end = CODECS[ptype][1](body, pos, len(info.refs), self)
            if end != len(body):
                raise ValueError("%s.%s: decoded %d of %d bytes" % (info.name, pname, end, len(body)))
            col = Column(cid, pname, ptype, vals, ch)
            info.props[pname] = col
        return col

    def prop_names(self, ref):
        return list(self.classes[self.ref_cid[ref]].order)

    def get(self, ref, pname, default=None):
        cid = self.ref_cid[ref]
        col = self.column(cid, pname)
        if col is None:
            return default
        return col.values[self.classes[cid].index[ref]]

    def set(self, ref, pname, value):
        cid = self.ref_cid[ref]
        info = self.classes[cid]
        col = self.column(cid, pname)
        if col is None:
            raise KeyError("%s has no stored property %s" % (info.name, pname))
        i = info.index[ref]
        if col.values[i] != value:
            col.values[i] = value
            col.dirty = True

    def has_prop(self, class_name, pname):
        cid = self.by_name.get(class_name)
        return cid is not None and (cid, pname) in self._raw_props

    def prop_type(self, class_name, pname):
        cid = self.by_name[class_name]
        ch = self._raw_props[(cid, pname)]
        _, pos = _r_string(ch.body, 4)
        return CODECS[ch.body[pos]][0]

    def name(self, ref):
        return self.get(ref, "Name", b"").decode("utf-8", "replace")

    def cls(self, ref):
        return self.classes[self.ref_cid[ref]].name

    # ------------------------------------------------------------------ tree
    def kids(self, ref):
        return list(self.children.get(ref, []))

    def descendants(self, ref):
        out, stack = [], list(reversed(self.children.get(ref, [])))
        while stack:
            r = stack.pop()
            out.append(r)
            stack.extend(reversed(self.children.get(r, [])))
        return out

    def child(self, ref, name):
        for k in self.children.get(ref, []):
            if self.name(k) == name:
                return k
        return None

    def find_path(self, path, root=-1):
        cur = root
        for seg in path.split("/"):
            cur = self.child(cur, seg)
            if cur is None:
                return None
        return cur

    def path(self, ref):
        parts = []
        while ref != -1 and ref is not None:
            parts.append(self.name(ref))
            ref = self.parent.get(ref, -1)
        return "/".join(reversed(parts))

    def ancestors(self, ref):
        out = []
        ref = self.parent.get(ref, -1)
        while ref != -1:
            out.append(ref)
            ref = self.parent.get(ref, -1)
        return out

    def set_parent(self, ref, parent):
        old = self.parent[ref]
        self.children[old].remove(ref)
        self.children.setdefault(parent, []).append(ref)
        self.parent[ref] = parent
        self.tree_dirty = True

    # ------------------------------------------------------------------ shared strings
    def shared_strings(self):
        if self._sstr_vals is None:
            vals = []
            if self.sstr is not None:
                body = self.sstr.body
                count = struct.unpack_from("<I", body, 4)[0]
                pos = 8
                for _ in range(count):
                    h = bytes(body[pos:pos + 16])
                    v, pos = _r_string(body, pos + 16)
                    vals.append((h, v))
            self._sstr_vals = vals
        return self._sstr_vals

    # ------------------------------------------------------------------ add / remove
    def ensure_class(self, class_name):
        cid = self.by_name.get(class_name)
        if cid is not None:
            return cid
        cid = max(self.classes) + 1 if self.classes else 0
        body = bytearray(struct.pack("<I", cid) + _w_string(class_name.encode()) + b"\x00" + struct.pack("<I", 0))
        ch = Chunk(b"INST", b"", body, "zstd")
        ch.dirty = True
        # INST chunks come before the first PROP chunk
        first_prop = next(i for i, c in enumerate(self.chunks) if c.name in (b"PROP", b"PRNT"))
        self.chunks.insert(first_prop, ch)
        info = ClassInfo(cid, class_name, 0, [], ch)
        info.dirty = True
        self.classes[cid] = info
        self.by_name[class_name] = cid
        return cid

    def ensure_prop(self, class_name, pname, ptype_name, default):
        """Make sure the class has a column for pname (filled with `default` for existing instances)."""
        cid = self.ensure_class(class_name)
        if (cid, pname) in self._raw_props:
            return self.column(cid, pname)
        info = self.classes[cid]
        ptype = TYPE_ID[ptype_name]
        head = struct.pack("<I", cid) + _w_string(pname.encode()) + bytes([ptype])
        ch = Chunk(b"PROP", b"", bytearray(head), "zstd")
        # place after this class's last PROP chunk (or before PRNT)
        idx = None
        for i, c in enumerate(self.chunks):
            if c.name == b"PROP" and struct.unpack_from("<I", c.body, 0)[0] == cid:
                idx = i + 1
        if idx is None:
            idx = next(i for i, c in enumerate(self.chunks) if c.name == b"PRNT")
        self.chunks.insert(idx, ch)
        self._raw_props[(cid, pname)] = ch
        info.order.append(pname)
        col = Column(cid, pname, ptype, [default] * len(info.refs), ch)
        col.dirty = True
        info.props[pname] = col
        return col

    def add(self, class_name, parent, props, defaults):
        """Append an instance. `props` overrides; every other stored column gets defaults[pname]
        (or raises if the class stores a property we have no default for)."""
        cid = self.ensure_class(class_name)
        info = self.classes[cid]
        ref = self.next_ref
        self.next_ref += 1
        # decode all columns of the class first so the append stays aligned
        for pname in info.order:
            self.column(cid, pname)
        for pname in info.order:
            col = info.props[pname]
            if pname in props:
                v = props[pname]
            elif pname in defaults:
                v = defaults[pname]
            else:
                raise KeyError("no value for %s.%s" % (class_name, pname))
            col.values.append(v)
            col.dirty = True
        for pname in props:
            if pname not in info.order:
                raise KeyError("%s has no column %s (call ensure_prop first)" % (class_name, pname))
        info.index[ref] = len(info.refs)
        info.refs.append(ref)
        info.dirty = True
        self.ref_cid[ref] = cid
        self.parent[ref] = parent
        self.children.setdefault(parent, []).append(ref)
        self.prnt_order.append(ref)
        self.tree_dirty = True
        return ref

    def remove(self, ref):
        """Remove an instance and its subtree. Ref properties pointing at removed instances become nil."""
        doomed = [ref] + self.descendants(ref)
        dset = set(doomed)
        self.children[self.parent[ref]].remove(ref)
        by_cid = {}
        for r in doomed:
            by_cid.setdefault(self.ref_cid[r], set()).add(r)
        for cid, rs in by_cid.items():
            info = self.classes[cid]
            for pname in info.order:
                self.column(cid, pname)
            keep = [i for i, r in enumerate(info.refs) if r not in rs]
            for pname in info.order:
                col = info.props[pname]
                col.values = [col.values[i] for i in keep]
                col.dirty = True
            info.refs = [info.refs[i] for i in keep]
            info.index = {r: i for i, r in enumerate(info.refs)}
            info.dirty = True
        for r in doomed:
            del self.ref_cid[r]
            self.parent.pop(r, None)
            self.children.pop(r, None)
        self.prnt_order = [k for k in self.prnt_order if k not in dset]
        self._dangling.update(dset)
        self.tree_dirty = True

    def _clear_dangling_refs(self):
        if not self._dangling:
            return
        dset = self._dangling
        for (cid, pname), ch in self._raw_props.items():
            _, pos = _r_string(ch.body, 4)
            if ch.body[pos] not in (0x13, 0x22):
                continue
            col = self.column(cid, pname)
            if col.type == 0x13:
                new = [-1 if v in dset else v for v in col.values]
            else:
                new = [None if (v is not None and v[0] == "obj" and v[1] in dset) else v for v in col.values]
            if new != col.values:
                col.values = new
                col.dirty = True
        self._dangling.clear()

    # ------------------------------------------------------------------ save
    def save(self, path):
        self._clear_dangling_refs()
        for cid, info in self.classes.items():
            if info.dirty:
                body = bytearray(struct.pack("<I", cid) + _w_string(info.name.encode()) + bytes([info.service])
                                 + struct.pack("<I", len(info.refs)) + _write_refs(info.refs))
                if info.service:
                    body += bytes([1]) * len(info.refs)
                info.chunk.body = body
                info.chunk.dirty = True
            for pname, col in info.props.items():
                if col.dirty:
                    ch = col.chunk
                    head = struct.pack("<I", cid) + _w_string(pname.encode()) + bytes([col.type])
                    if col.type not in CODECS:
                        raise ValueError("cannot re-encode opaque column %s.%s" % (info.name, pname))
                    ch.body = bytearray(head + CODECS[col.type][2](col.values, self))
                    ch.dirty = True
        # drop classes that ended up with no instances
        empty = {cid for cid, info in self.classes.items() if not info.refs}
        chunks = []
        for ch in self.chunks:
            if ch.name in (b"INST", b"PROP") and struct.unpack_from("<I", ch.body, 0)[0] in empty:
                continue
            chunks.append(ch)
        if empty:
            # class ids must stay dense 0..n-1: renumber
            live = sorted(cid for cid in self.classes if cid not in empty)
            remap = {old: new for new, old in enumerate(live)}
            for ch in chunks:
                if ch.name in (b"INST", b"PROP"):
                    old = struct.unpack_from("<I", ch.body, 0)[0]
                    if remap[old] != old:
                        ch.body[0:4] = struct.pack("<I", remap[old])
                        ch.dirty = True
        if getattr(self, "_sstr_dirty", False):
            vals = self.shared_strings()
            body = bytearray(struct.pack("<II", 0, len(vals)))
            for h, v in vals:
                body += h + _w_string(v)
            self.sstr.body = body
            self.sstr.dirty = True
        if self.tree_dirty:
            order = [k for k in self.prnt_order if k in self.ref_cid]
            body = bytearray(b"\x00" + struct.pack("<I", len(order)) + _write_refs(order)
                             + _write_refs([self.parent[k] for k in order]))
            self.prnt.body = body
            self.prnt.dirty = True
        nclasses = len(self.classes) - len(empty)
        ninst = sum(len(i.refs) for i in self.classes.values())
        self.header[16:24] = struct.pack("<ii", nclasses, ninst)
        with open(path, "wb") as f:
            f.write(self.header)
            for ch in chunks:
                f.write(ch.encode())

    # ------------------------------------------------------------------ attributes
    @staticmethod
    def parse_attributes(blob):
        """AttributesSerialize -> dict (common types only)."""
        out = {}
        if not blob:
            return out
        pos = 0
        n = struct.unpack_from("<I", blob, pos)[0]
        pos += 4
        for _ in range(n):
            k, pos = _r_string(blob, pos)
            t = blob[pos]
            pos += 1
            if t == 0x02:  # string
                v, pos = _r_string(blob, pos)
                v = v.decode("utf-8", "replace")
            elif t == 0x03:  # bool
                v = blob[pos] != 0
                pos += 1
            elif t == 0x05:  # float
                v = struct.unpack_from("<f", blob, pos)[0]
                pos += 4
            elif t == 0x06:  # double
                v = struct.unpack_from("<d", blob, pos)[0]
                pos += 8
            elif t == 0x09:  # UDim
                v = struct.unpack_from("<fi", blob, pos)
                pos += 8
            elif t == 0x0A:  # UDim2
                v = struct.unpack_from("<fifi", blob, pos)
                pos += 16
            elif t == 0x0E:  # BrickColor
                v = struct.unpack_from("<I", blob, pos)[0]
                pos += 4
            elif t == 0x0F:  # Color3
                v = struct.unpack_from("<3f", blob, pos)
                pos += 12
            elif t == 0x10:  # Vector2
                v = struct.unpack_from("<2f", blob, pos)
                pos += 8
            elif t == 0x11:  # Vector3
                v = struct.unpack_from("<3f", blob, pos)
                pos += 12
            elif t == 0x14:  # CFrame
                p = struct.unpack_from("<3f", blob, pos)
                pos += 12
                rid = blob[pos]
                pos += 1
                if rid == 0:
                    r = struct.unpack_from("<9f", blob, pos)
                    pos += 36
                else:
                    r = _rot_from_id(rid)
                v = CF(p, r)
            elif t == 0x15:  # EnumItem
                en, pos = _r_string(blob, pos)
                v = (en.decode(), struct.unpack_from("<I", blob, pos)[0])
                pos += 4
            elif t == 0x17:  # NumberSequence
                c = struct.unpack_from("<I", blob, pos)[0]
                pos += 4
                v = [struct.unpack_from("<3f", blob, pos + 12 * i) for i in range(c)]
                pos += 12 * c
            elif t == 0x19:  # ColorSequence
                c = struct.unpack_from("<I", blob, pos)[0]
                pos += 4
                v = [struct.unpack_from("<5f", blob, pos + 20 * i) for i in range(c)]
                pos += 20 * c
            elif t == 0x1B:  # NumberRange
                v = struct.unpack_from("<2f", blob, pos)
                pos += 8
            elif t == 0x1C:  # Rect
                v = struct.unpack_from("<4f", blob, pos)
                pos += 16
            elif t == 0x21:  # Font
                w, s = struct.unpack_from("<HB", blob, pos)
                pos += 3
                fam, pos = _r_string(blob, pos)
                cached, pos = _r_string(blob, pos)
                v = ("Font", fam, w, s, cached)
            else:
                raise ValueError("attribute type 0x%02x" % t)
            out[k.decode()] = v
        return out

    @staticmethod
    def build_attributes(d):
        out = bytearray(struct.pack("<I", len(d)))
        for k, v in d.items():
            out += _w_string(k.encode())
            if isinstance(v, bool):
                out += b"\x03" + bytes([1 if v else 0])
            elif isinstance(v, (int, float)):
                out += b"\x06" + struct.pack("<d", float(v))
            elif isinstance(v, str):
                out += b"\x02" + _w_string(v.encode())
            elif isinstance(v, CF):
                out += b"\x14" + struct.pack("<3f", *v.p)
                if v.rid:
                    out.append(v.rid)
                else:
                    out.append(0)
                    out += struct.pack("<9f", *v.r)
            elif isinstance(v, tuple) and len(v) == 2 and v[0] == "Color3":
                out += b"\x0F" + struct.pack("<3f", *v[1])
            elif isinstance(v, tuple) and len(v) == 2 and v[0] == "Vector3":
                out += b"\x11" + struct.pack("<3f", *v[1])
            else:
                raise ValueError("attribute %s: unsupported %r" % (k, v))
        return bytes(out)


def roundtrip_check(path):
    """Decode every column and re-encode it; report columns that do not match byte-for-byte."""
    with open(path, "rb") as f:
        data = f.read()
    doc = Doc(data)
    bad = 0
    for (cid, pname), ch in doc._raw_props.items():
        col = doc.column(cid, pname)
        if col.type not in CODECS:
            print("opaque %s.%s (type 0x%02x, %d bytes)" % (doc.classes[cid].name, pname, col.type, len(col.values[0].raw)))
            continue
        head = struct.pack("<I", cid) + _w_string(pname.encode()) + bytes([col.type])
        enc = head + CODECS[col.type][2](col.values, doc)
        if enc != bytes(ch.body):
            bad += 1
            print("MISMATCH %s.%s (%s)" % (doc.classes[cid].name, pname, CODECS[col.type][0]))
    print("columns checked: %d, mismatches: %d" % (len(doc._raw_props), bad))
    return doc


if __name__ == "__main__":
    import sys
    roundtrip_check(sys.argv[1])
