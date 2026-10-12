#!/usr/bin/env python3
"""Build fonts/PolybarIcons.ttf: small icons for polybar that no installed font has.

  U+E000-U+E00B  a wireframe globe, 12 frames of a west-to-east spin (loops seamlessly)
  U+E010         the Tailscale logo (3x3 dots), connected
  U+E011         the Tailscale logo, dimmed down to the middle row (off)
  U+F0000+       colour country flags, see FLAGS (codepoint = 0xF0000 + 26*first + second letter)

Run:  python3 bin/build-polybar-icons.py   (then `make install-fonts` or fc-cache)
"""
import math
from pathlib import Path

from fontTools.colorLib.builder import buildCOLR, buildCPAL
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM, ADV = 1000, 1000
CX, CY, R, STROKE = 500, 350, 430, 85
FRAMES = 12
SPACING = 45  # degrees between meridians
STEPS = 72


def ellipse(cx, cy, rx, ry, clockwise):
    pts = [
        (cx + rx * math.cos(2 * math.pi * i / STEPS), cy + ry * math.sin(2 * math.pi * i / STEPS))
        for i in range(STEPS)
    ]
    return pts[::-1] if clockwise else pts


def draw(pen, pts):
    pen.moveTo((round(pts[0][0]), round(pts[0][1])))
    for x, y in pts[1:]:
        pen.lineTo((round(x), round(y)))
    pen.closePath()


def ring(pen, cx, cy, rx, ry, w):
    """An elliptical ring; solid bar when too thin to have a hole."""
    draw(pen, ellipse(cx, cy, rx, ry, clockwise=True))
    if rx - w > 8 and ry - w > 8:
        draw(pen, ellipse(cx, cy, rx - w, ry - w, clockwise=False))


def bar(pen, x0, y0, x1, y1):
    pen.moveTo((x0, y0))
    pen.lineTo((x0, y1))
    pen.lineTo((x1, y1))
    pen.lineTo((x1, y0))
    pen.closePath()


def arc(pen, a, w, r):
    """The front half of a meridian: a half-ellipse bulging to x = a (signed), as a stroked band."""
    phis = [math.radians(-90 + 180 * i / 40) for i in range(41)]
    left = [(CX + a * math.cos(p) - w / 2, CY + r * math.sin(p)) for p in phis]
    right = [(CX + a * math.cos(p) + w / 2, CY + r * math.sin(p)) for p in reversed(phis)]
    draw(pen, left + right)  # up the left edge, down the right edge: clockwise


def globe(frame):
    """A wireframe globe turning west to east. Only meridians on the near side are drawn,
    so they sweep across from one edge to the other, which reads as rotation (not pulsing)."""
    pen = TTGlyphPen(None)
    ring(pen, CX, CY, R, R, STROKE)  # outline
    inner = R - STROKE / 2
    bar(pen, CX - inner, CY - STROKE // 2, CX + inner, CY + STROKE // 2)  # equator
    for lat in (-35, 35):  # latitude lines, a bit thinner
        y = CY + inner * math.sin(math.radians(lat))
        half = inner * math.cos(math.radians(lat))
        bar(pen, CX - half, y - STROKE // 3, CX + half, y + STROKE // 3)
    theta = SPACING * frame / FRAMES  # one frame step; the pattern repeats every SPACING degrees
    for k in range(360 // SPACING):
        psi = (theta + SPACING * k + 180) % 360 - 180  # longitude relative to the viewer
        if abs(psi) < 90:
            arc(pen, inner * math.sin(math.radians(psi)), STROKE * 0.8, inner)
    return pen.glyph()


def dots(rows):
    pen = TTGlyphPen(None)
    for row in rows:
        for col in range(3):
            draw(pen, ellipse(200 + 300 * col, 650 - 300 * row, 105, 105, clockwise=True))
    return pen.glyph()


# --- flags -------------------------------------------------------------------------
# Colour glyphs (COLRv0): each flag is a stack of single-colour layers. Flags live at
# U+F0000 + the two letters of the country code, packed as (A-Z) -> 0-25: cp = 0xF0000 + a*26 + b.
FW, FH, FX, FY = 900, 600, 50, 50  # flag box inside the em square
PALETTE = {
    "white": "#FFFFFF", "red": "#D52B1E", "blue": "#00247D", "navy": "#012169", "black": "#000000",
    "gold": "#FFCE00", "green": "#009739", "orange": "#F6A800", "lblue": "#0072C6", "yellow": "#FFD100",
    "edge": "#8A8D9F", "dgreen": "#006847", "skyblue": "#75AADB",
}
COLORS = list(PALETTE)


def rect(x0, y0, x1, y1):  # fractions of the flag box, y up; clockwise
    X = lambda v: round(FX + v * FW)
    Y = lambda v: round(FY + v * FH)
    return [(X(x0), Y(y0)), (X(x0), Y(y1)), (X(x1), Y(y1)), (X(x1), Y(y0))]


def band(p0, p1, half):  # a diagonal stripe from p0 to p1 (flag fractions), half-width in fractions
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = (x1 - x0) * FW, (y1 - y0) * FH
    n = math.hypot(dx, dy)
    ox, oy = -dy / n * half * FH, dx / n * half * FH
    X = lambda v: FX + v * FW
    Y = lambda v: FY + v * FH
    return [(X(x0) + ox, Y(y0) + oy), (X(x1) + ox, Y(y1) + oy), (X(x1) - ox, Y(y1) - oy), (X(x0) - ox, Y(y0) - oy)]


def disc(cx, cy, r):
    return ellipse(FX + cx * FW, FY + cy * FH, r * FH, r * FH, clockwise=True)


def star(cx, cy, r, points=7):
    pts = []
    for i in range(points * 2):
        rad = r * FH if i % 2 == 0 else r * FH * 0.42
        a = math.pi / 2 - math.pi * i / points
        pts.append((FX + cx * FW + rad * math.cos(a), FY + cy * FH + rad * math.sin(a)))
    return pts[::-1]


def union_jack(x0, y0, x1, y1):
    """Union Jack squeezed into a box (fractions), as layers."""
    w, h = x1 - x0, y1 - y0
    X = lambda v: x0 + v * w
    Y = lambda v: y0 + v * h
    return [
        ("navy", [rect(x0, y0, x1, y1)]),
        ("white", [band((x0, y0), (x1, y1), 0.075 * h), band((x0, y1), (x1, y0), 0.075 * h),
                   rect(x0, Y(0.38), x1, Y(0.62)), rect(X(0.4), y0, X(0.6), y1)]),
        ("red", [band((x0, y0), (x1, y1), 0.03 * h), band((x0, y1), (x1, y0), 0.03 * h),
                 rect(x0, Y(0.44), x1, Y(0.56)), rect(X(0.44), y0, X(0.56), y1)]),
    ]


def edge():  # a thin light frame, so white and dark-blue parts stay visible on a dark bar
    return [(FX - 14, FY - 14), (FX - 14, FY + FH + 14), (FX + FW + 14, FY + FH + 14), (FX + FW + 14, FY - 14)]


def cross(bg, fg, inner=None, off=0.36, w=0.16):
    layers = [(bg, [rect(0, 0, 1, 1)]), (fg, [rect(0, 0.5 - w / 2, 1, 0.5 + w / 2), rect(off - w / 2, 0, off + w / 2, 1)])]
    if inner:
        layers.append((inner, [rect(0, 0.5 - w / 4, 1, 0.5 + w / 4), rect(off - w / 4, 0, off + w / 4, 1)]))
    return layers


def tri_h(*cols):
    return [(c, [rect(0, i / len(cols), 1, (i + 1) / len(cols))]) for i, c in enumerate(reversed(cols))]


def tri_v(*cols):
    return [(c, [rect(i / len(cols), 0, (i + 1) / len(cols), 1)]) for i, c in enumerate(cols)]


def stars_south(extra=()):
    return [("white", [star(0.25, 0.23, 0.11)] + [star(x, y, r, 5) for x, y, r in extra])]


FLAGS = {
    "DE": tri_h("black", "red", "gold"),
    "FR": tri_v("blue", "white", "red"),
    "NL": tri_h("red", "white", "lblue"),
    "JP": [("white", [rect(0, 0, 1, 1)]), ("red", [disc(0.5, 0.5, 0.3)])],
    "GB": union_jack(0, 0, 1, 1),
    "AU": union_jack(0, 0.5, 0.5, 1) and ([("navy", [rect(0, 0, 1, 1)])] + union_jack(0, 0.5, 0.5, 1)[1:]
          + [("white", [star(0.25, 0.23, 0.11), star(0.75, 0.78, 0.07), star(0.62, 0.52, 0.055, 5),
                         star(0.88, 0.52, 0.055, 5), star(0.75, 0.3, 0.055, 5), star(0.82, 0.42, 0.04, 5)])]),
    "US": [("red", [rect(0, 0, 1, 1)]),
           ("white", [rect(0, i / 13, 1, (i + 1) / 13) for i in range(1, 13, 2)]),
           ("navy", [rect(0, 6 / 13, 0.4, 1)]),
           ("white", [star(0.05 + 0.06 * c, 0.58 + 0.07 * r, 0.025, 5) for r in range(5) for c in range(6)])],
    "CA": [("red", [rect(0, 0, 0.25, 1), rect(0.75, 0, 1, 1)]), ("white", [rect(0.25, 0, 0.75, 1)]),
           ("red", [[(FX + FW * 0.5, FY + FH * 0.82), (FX + FW * 0.64, FY + FH * 0.5),
                     (FX + FW * 0.5, FY + FH * 0.18), (FX + FW * 0.36, FY + FH * 0.5)]])],
}

FLAGS.update({
    "IT": tri_v("green", "white", "red"), "IE": tri_v("green", "white", "orange"),
    "BE": tri_v("black", "yellow", "red"), "RO": tri_v("blue", "yellow", "red"),
    "AT": tri_h("red", "white", "red"), "HU": tri_h("red", "white", "green"),
    "BG": tri_h("white", "green", "red"), "LT": tri_h("yellow", "green", "red"),
    "EE": tri_h("lblue", "black", "white"), "PL": tri_h("white", "red"), "UA": tri_h("lblue", "yellow"),
    "LU": tri_h("red", "white", "skyblue"), "ES": [("red", [rect(0, 0, 1, 1)]), ("yellow", [rect(0, 0.25, 1, 0.75)])],
    "CH": [("red", [rect(0, 0, 1, 1)]), ("white", [rect(0.4, 0.2, 0.6, 0.8), rect(0.25, 0.4, 0.75, 0.6)])],
    "SE": cross("lblue", "yellow"), "DK": cross("red", "white"), "FI": cross("white", "lblue"),
    "NO": cross("red", "white", "navy"),
    "SG": [("red", [rect(0, 0.5, 1, 1)]), ("white", [rect(0, 0, 1, 0.5), disc(0.2, 0.75, 0.17)]), ("red", [disc(0.25, 0.75, 0.15)])],
    "HK": [("red", [rect(0, 0, 1, 1)]), ("white", [disc(0.5, 0.5, 0.2)])],
    "IN": [("orange", [rect(0, 2 / 3, 1, 1)]), ("white", [rect(0, 1 / 3, 1, 2 / 3)]), ("dgreen", [rect(0, 0, 1, 1 / 3)]),
           ("navy", [disc(0.5, 0.5, 0.1)])],
    "BR": [("dgreen", [rect(0, 0, 1, 1)]),
           ("yellow", [[(FX + FW * 0.5, FY + FH * 0.9), (FX + FW * 0.92, FY + FH * 0.5), (FX + FW * 0.5, FY + FH * 0.1), (FX + FW * 0.08, FY + FH * 0.5)]]),
           ("navy", [disc(0.5, 0.5, 0.22)])],
    "AR": [("skyblue", [rect(0, 0, 1, 1)]), ("white", [rect(0, 1 / 3, 1, 2 / 3)]), ("yellow", [disc(0.5, 0.5, 0.07)])],
    "MX": [("dgreen", [rect(0, 0, 1 / 3, 1)]), ("white", [rect(1 / 3, 0, 2 / 3, 1)]), ("red", [rect(2 / 3, 0, 1, 1)]), ("gold", [disc(0.5, 0.5, 0.1)])],
    "NZ": [("navy", [rect(0, 0, 1, 1)]), *union_jack(0, 0.5, 0.5, 1)[1:],
           ("red", [star(0.75, 0.3, 0.07, 5), star(0.85, 0.52, 0.06, 5), star(0.63, 0.5, 0.06, 5), star(0.75, 0.75, 0.06, 5)]),
           ],
})


def main():
    glyphs = {".notdef": TTGlyphPen(None).glyph(), "space": TTGlyphPen(None).glyph()}
    cmap = {0x20: "space"}
    for f in range(FRAMES):
        name = f"globe{f}"
        glyphs[name] = globe(f)
        cmap[0xE000 + f] = name
    glyphs["tailscale_on"], cmap[0xE010] = dots([0, 1, 2]), "tailscale_on"
    glyphs["tailscale_off"], cmap[0xE011] = dots([1]), "tailscale_off"

    colr = {}
    for code, layers in FLAGS.items():
        layers = [("edge", [edge()])] + layers
        base = f"flag_{code}"
        glyphs[base] = TTGlyphPen(None).glyph()  # empty fallback for apps without colour-font support
        cmap[0xF0000 + (ord(code[0]) - 65) * 26 + (ord(code[1]) - 65)] = base
        colr[base] = []
        for n, (color, shapes) in enumerate(layers):
            pen = TTGlyphPen(None)
            for shape in shapes:
                draw(pen, shape)
            layer = f"{base}.{n}"
            glyphs[layer] = pen.glyph()
            colr[base].append((layer, COLORS.index(color)))

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(list(glyphs))
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    glyf = fb.font["glyf"]
    metrics = {}
    for n in glyphs:  # the left-side bearing must equal each glyph's real left edge, or renderers shift it
        g = glyf[n]
        g.recalcBounds(glyf)
        metrics[n] = (ADV, g.xMin if g.numberOfContours else 0)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=800, descent=-200)
    fb.setupNameTable({"familyName": "PolybarIcons", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=800, sTypoDescender=-200, usWinAscent=800, usWinDescent=200)
    fb.setupPost()
    fb.font["COLR"] = buildCOLR(colr, version=0)
    fb.font["CPAL"] = buildCPAL([[tuple(int(PALETTE[c][i:i + 2], 16) / 255 for i in (1, 3, 5)) + (1.0,) for c in COLORS]])
    out = Path(__file__).resolve().parent.parent / "fonts" / "PolybarIcons.ttf"
    fb.save(out)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
