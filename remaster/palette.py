"""Paradise palette: warm sand, lush lawns, pastel plaster, terracotta, white trims, neon nights."""

LAWN = (98, 172, 68)
LAWN_DEEP = (82, 156, 62)
LAWN_YARD = (88, 162, 64)
SAND = (238, 214, 168)
SAND_WET = (212, 186, 138)
PAVE = (236, 222, 198)
PAVE_WARM = (226, 207, 178)
PAVE_ROSE = (232, 200, 182)
TRAVERTINE = (246, 238, 222)
SOIL = (92, 66, 46)

TERRACOTTA = (206, 104, 70)
TERRACOTTA_DARK = (170, 84, 58)
TEAL = (34, 170, 172)
TEAL_DARK = (22, 112, 122)
TEAL_ROOF = (48, 138, 140)

WHITE = (250, 248, 242)
CREAM = (250, 241, 222)
GOLD = (232, 184, 82)
BRONZE = (168, 120, 70)

PLASTER = {
    "coral": (255, 178, 152),
    "mint": (172, 230, 206),
    "peach": (255, 210, 164),
    "lavender": (208, 190, 240),
    "sky": (166, 216, 242),
    "lemon": (255, 236, 166),
    "rose": (250, 192, 208),
    "cream": (250, 241, 222),
    "seafoam": (150, 222, 214),
    "apricot": (255, 196, 140),
}
PASTELS = ["coral", "mint", "peach", "lavender", "sky", "lemon", "rose", "seafoam", "apricot"]

WOOD_DECK = (178, 130, 88)
WOOD_DARK = (118, 80, 52)
WOOD_PALE = (214, 176, 128)
ROCK = (116, 106, 98)
ROCK_DARK = (84, 78, 74)
ROCK_MOSS = (92, 110, 78)

LEAVES = [(40, 128, 70), (52, 142, 72), (66, 156, 74), (84, 170, 74), (34, 116, 78)]
PALM_TRUNK = (156, 118, 80)
PALM_RING = (128, 94, 62)
PALM_LEAF = [(58, 148, 62), (70, 162, 66), (48, 134, 64), (86, 172, 70)]
COCONUT = (98, 70, 44)

FLOWERS = [(255, 92, 140), (255, 196, 64), (255, 255, 255), (255, 128, 72), (196, 112, 255), (255, 70, 90)]

NEON_PINK = (255, 66, 168)
NEON_CYAN = (48, 232, 255)
NEON_ORANGE = (255, 152, 52)
NEON_YELLOW = (255, 232, 96)
NEON_PURPLE = (176, 96, 255)
NEON_LIME = (150, 255, 90)
NEONS = [NEON_PINK, NEON_CYAN, NEON_ORANGE, NEON_YELLOW, NEON_PURPLE]

WATER_DEEP = (18, 92, 128)
WATER_SHALLOW = (40, 190, 196)


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]
