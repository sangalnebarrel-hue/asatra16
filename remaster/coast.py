"""Coastline model shared by the Python map pipeline (prop placement, previews) and the Luau
terrain builder (src/ServerStorage/ParadiseTerrain.luau implements the same formulas).

Coordinates: studs, island top at y = 0, sea level SEA.
"""
import math

SEA = -4.0
# Island top footprint (union of axis-aligned rectangles: x0, z0, x1, z1)
FOOTPRINT = [
    (-86.0, -252.0, 86.0, -228.0),
    (-102.0, -228.0, 102.0, -204.0),
    (-138.0, -204.0, 138.0, -180.0),
    (-180.0, -180.0, 180.0, 168.0),
    (-194.0, 168.0, 194.0, 180.0),
    (-192.0, 180.0, 192.0, 516.0),
    (-216.0, 516.0, 216.0, 720.0),
    (-204.0, 720.0, 204.0, 744.0),
    (-194.0, 744.0, 194.0, 758.0),
]
# Terrain written voxel-by-voxel inside this box; the open ocean beyond is filled in blocks.
NEAR = (-640.0, -720.0, 640.0, 1200.0)
FAR = 2400.0          # ocean half-extent around the island centre
CENTER = (0.0, 300.0)
FLOOR = -40.0


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)


def nearest(x, z):
    """Distance to the footprint and the nearest footprint point."""
    best, bx, bz = 1e18, x, z
    for x0, z0, x1, z1 in FOOTPRINT:
        cx = min(max(x, x0), x1)
        cz = min(max(z, z0), z1)
        d = (x - cx) ** 2 + (z - cz) ** 2
        if d < best:
            best, bx, bz = d, cx, cz
    return math.sqrt(best), bx, bz


def beach_weight(px, pz):
    """1 = sandy beach, 0 = rocky shore; by the nearest footprint point."""
    w = 1.0
    # north end around the giant dog: rocky
    w = min(w, smoothstep(-200.0, -120.0, pz) * 0.85 + 0.15)
    # east shore beside the lab and the lot: cliffs
    if px > 150.0:
        w = min(w, 1.0 - 0.85 * smoothstep(400.0, 470.0, pz))
    return w


def noise(x, z):
    return (0.9 * math.sin(x * 0.031 + z * 0.017) + 0.6 * math.sin(x * 0.013 - z * 0.027 + 1.7)
            + 0.4 * math.sin((x + z) * 0.051 + 0.3))


def beach_profile(d):
    if d < 6.0:
        return -0.45 - 0.25 * (d / 6.0)
    if d < 40.0:
        return -0.7 - 3.6 * smoothstep(6.0, 40.0, d)
    if d < 120.0:
        return -4.3 - 13.7 * smoothstep(40.0, 120.0, d)
    if d < 320.0:
        return -18.0 - 18.0 * smoothstep(120.0, 320.0, d)
    return -36.0 - 4.0 * smoothstep(320.0, 600.0, d)


def rock_profile(d):
    if d < 30.0:
        return -3.0 - 19.0 * smoothstep(0.0, 30.0, d)
    if d < 320.0:
        return -22.0 - 14.0 * smoothstep(30.0, 320.0, d)
    return -36.0 - 4.0 * smoothstep(320.0, 600.0, d)


def height(x, z):
    """Seabed / beach surface height, or None inside the island footprint."""
    d, px, pz = nearest(x, z)
    if d <= 0.0:
        return None
    w = beach_weight(px, pz)
    h = beach_profile(d) * w + rock_profile(d) * (1.0 - w)
    h += noise(x, z) * smoothstep(12.0, 40.0, d) * (1.0 if d < 300 else 0.5)
    return h


def surface_material(x, z, h):
    d, px, pz = nearest(x, z)
    w = beach_weight(px, pz)
    if w < 0.45 and h > -26.0:
        return "Rock"
    if h > SEA + 0.6:
        return "Sand"
    if h > -20.0:
        return "Sand"
    return "Sand" if (int(x // 64) + int(z // 64)) % 3 else "Ground"


def is_land(x, z):
    return nearest(x, z)[0] <= 0.0


OUTLINE = [(-194, 758), (194, 758), (194, 744), (204, 744), (204, 720), (216, 720), (216, 516), (192, 516), (192, 180), (194, 180), (194, 168), (180, 168), (180, -180), (138, -180), (138, -204), (102, -204), (102, -228), (86, -228), (86, -252), (-86, -252), (-86, -228), (-102, -228), (-102, -204), (-138, -204), (-138, -180), (-180, -180), (-180, 168), (-194, 168), (-194, 180), (-192, 180), (-192, 516), (-216, 516), (-216, 720), (-204, 720), (-204, 744), (-194, 744)]


def perimeter_points(spacing, d_lo, d_hi, rng):
    """Points around the island at a random distance in [d_lo, d_hi] from the footprint, about `spacing` apart.
    Returns (x, z, d, px, pz) shuffled."""
    out = []
    n = len(OUTLINE)
    # outline is clockwise seen from above (+Y), outward normal = left of the direction of travel in x/z
    for i in range(n):
        ax, az = OUTLINE[i]
        bx, bz = OUTLINE[(i + 1) % n]
        ex, ez = bx - ax, bz - az
        length = math.hypot(ex, ez)
        if length < 1:
            continue
        ux, uz = ex / length, ez / length
        nx, nz = uz, -ux  # candidate normal; flipped below if it points inside
        mx, mz = (ax + bx) / 2 + nx * 2, (az + bz) / 2 + nz * 2
        if is_land(mx, mz):
            nx, nz = -nx, -nz
        t = rng.uniform(0, spacing)
        while t < length + d_hi:
            d = rng.uniform(d_lo, d_hi)
            s = t - d_hi / 2
            x = ax + ux * s + nx * d
            z = az + uz * s + nz * d
            dd, px, pz = nearest(x, z)
            if d_lo - 0.5 <= dd <= d_hi + 0.5:
                out.append((x, z, dd, px, pz))
            t += spacing * rng.uniform(0.8, 1.2)
    rng.shuffle(out)
    return out


# ---- Paradise Lagoon (the old quarry hole); mirrors ParadiseTerrain.LagoonHeight
LAGOON_REGION = (40.0, 544.0, 200.0, 724.0)
LAGOON_BASIN = (60.0, 562.0, 172.0, 704.0, 26.0)
LAGOON_FLOOR = -11.0


def lagoon_distance(x, z):
    b0, b1, b2, b3, r = LAGOON_BASIN
    cx, cz = (b0 + b2) / 2, (b1 + b3) / 2
    hx, hz = (b2 - b0) / 2 - r, (b3 - b1) / 2 - r
    qx, qz = abs(x - cx) - hx, abs(z - cz) - hz
    outside = math.sqrt(max(qx, 0) ** 2 + max(qz, 0) ** 2) + min(max(qx, qz), 0) - r
    return -outside


def lagoon_height(x, z):
    g = LAGOON_REGION
    if x < g[0] or x > g[2] or z < g[1] or z > g[3]:
        return None
    s = lagoon_distance(x, z)
    if s <= 0:
        return -0.35
    if s < 7:
        return -0.35 - 3.65 * smoothstep(0, 7, s)
    return -4 + (LAGOON_FLOOR + 4) * smoothstep(7, 26, s) + 0.4 * math.sin(x * 0.11 + z * 0.07)
