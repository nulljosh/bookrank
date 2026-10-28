"""Kernel Sans: Geist (Vercel with basement.studio, SIL Open Font License 1.1, no reserved name), renamed, with its
full stop redrawn as the Kernel mark: a seed, round on top and pointed at the base.

Geist is the brief (Joshua, 2026-10-28): proportional, sans serif, between San Francisco and Helvetica. Same method
as Coda's Quip Sans: pinned release, renamed, OFL shipped beside the fonts, Vercel's copyright kept in the name
table. The full stop is the one glyph drawn here, so every sentence ends on the mark. Four weights, Latin only,
every build the same bytes.

    uv run --with fonttools --with brotli python3 scripts/gen_font.py           # fonts/KernelSans-*.{ttf,woff2} + OFL.txt
    uv run --with fonttools --with brotli python3 scripts/gen_font.py --check   # named, licensed, proportional, mark drawn
"""
import io
import os
import sys
import urllib.request

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "fonts")
SOURCE = "https://cdn.jsdelivr.net/npm/@fontsource/geist-sans@5.3.0/"
WEIGHTS = {"Regular": 400, "Medium": 500, "Semibold": 600, "Bold": 700}
COPYRIGHT = "Copyright 2023 Vercel, in collaboration with basement.studio. Kernel Sans is Geist, renamed."
LICENSE = "This Font Software is licensed under the SIL Open Font License, Version 1.1."
K = 0.5523  # cubic circle constant


def fetch(path):
    """Bytes of one file from the pinned Geist release."""
    with urllib.request.urlopen(SOURCE + path, timeout=60) as r:
        return r.read()


def seed(pen, cx, cy, r, tip):
    """The mark: a half circle of radius r on top of (cx, cy), flanks curving down to a point at y = tip."""
    pen.moveTo((cx, tip))
    pen.curveTo((cx - 0.42 * r, tip + 0.06 * (cy - tip)), (cx - r, cy - 0.5 * (cy - tip)), (cx - r, cy))
    pen.curveTo((cx - r, cy + K * r), (cx - K * r, cy + r), (cx, cy + r))
    pen.curveTo((cx + K * r, cy + r), (cx + r, cy + K * r), (cx + r, cy))
    pen.curveTo((cx + r, cy - 0.5 * (cy - tip)), (cx + 0.42 * r, tip + 0.06 * (cy - tip)), (cx, tip))
    pen.closePath()


def redraw_period(font):
    """Replace the full stop with the seed, inside the original's advance so spacing never moves."""
    glyphs = font.getGlyphSet()
    cff = font["CFF "].cff
    top = cff.topDictIndex[0]
    name = font.getBestCmap()[ord(".")]
    bp = BoundsPen(glyphs)
    glyphs[name].draw(bp)
    x0, y0, x1, y1 = bp.bounds
    width = font["hmtx"][name][0]
    r = (x1 - x0) / 2
    pen = T2CharStringPen(width, None)
    seed(pen, (x0 + x1) / 2, y0 + 1.24 * r, r, y0 - 0.03 * (y1 - y0))   # sits on the baseline, 12 percent taller
    top.CharStrings[name] = pen.getCharString(private=top.Private, globalSubrs=cff.GlobalSubrs)


def rename(font, style):
    """Give the outlines the Kernel Sans name, with the copyright and the OFL in the name table."""
    names = {0: COPYRIGHT, 13: LICENSE, 14: "https://openfontlicense.org", 1: "Kernel Sans", 2: style, 3: f"KernelSans-{style}", 4: f"Kernel Sans {style}",
             5: "Version 1.000", 6: f"KernelSans-{style}", 16: "Kernel Sans", 17: style}
    table = font["name"]
    table.names = []
    for nid, text in names.items():
        table.setName(text, nid, 3, 1, 0x409)
        table.setName(text, nid, 1, 0, 0)
    cff = font["CFF "].cff
    cff.fontNames = [f"KernelSans-{style}"]
    top = cff.topDictIndex[0]
    top.FullName, top.FamilyName = f"Kernel Sans {style}", "Kernel Sans"
    top.Notice, top.Copyright = COPYRIGHT, COPYRIGHT
    font["head"].created = font["head"].modified = 3_700_000_000   # fixed, so every build is the same bytes
    font["OS/2"].achVendID = "KRNL"


def to_bytes(font, flavor):
    """The font as OTF (flavor None) or WOFF2 bytes."""
    font.flavor = flavor
    buf = io.BytesIO()
    font.save(buf, reorderTables=False)
    return buf.getvalue()


def check():
    """Self-check of the shipped files."""
    assert os.path.exists(os.path.join(OUT, "OFL.txt")), "the OFL must ship with the fonts"
    for style in WEIGHTS:
        for ext in ("otf", "woff2"):
            f = TTFont(os.path.join(OUT, f"KernelSans-{style}.{ext}"))
            assert f["name"].getDebugName(1) == "Kernel Sans" and f["name"].getDebugName(6) == f"KernelSans-{style}"
            assert "Vercel" in f["name"].getDebugName(0), "the original copyright must stay in the name table"
            assert "Open Font License" in (f["name"].getDebugName(13) or ""), "license text missing"
            cmap, hmtx = f.getBestCmap(), f["hmtx"]
            assert hmtx[cmap[ord("i")]][0] < hmtx[cmap[ord("m")]][0], "letters are not proportional"
            assert hmtx[cmap[ord("1")]][0] < hmtx[cmap[ord("0")]][0], "figures are not proportional"
            glyphs = f.getGlyphSet()
            bp = BoundsPen(glyphs)
            glyphs[cmap[ord(".")]].draw(bp)
            x0, y0, x1, y1 = bp.bounds
            assert y0 <= 0 < y1 and y1 - y0 > x1 - x0, "the full stop is not the seed"
            assert 0 <= x0 and x1 <= hmtx[cmap[ord(".")]][0], "the seed spills out of its advance"
    print(f"font ok: Kernel Sans (Geist, OFL), {len(WEIGHTS)} weights, full stop is the seed")


def main():
    """Fetch Geist, redraw its full stop, rename it, write every weight and the license; or run the check."""
    if "--check" in sys.argv:
        return check()
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "OFL.txt"), "wb") as f:
        f.write(fetch("LICENSE"))
    for style, weight in WEIGHTS.items():
        font = TTFont(io.BytesIO(fetch(f"files/geist-sans-latin-{weight}-normal.woff2")))
        redraw_period(font)
        rename(font, style)
        for ext, flavor in (("otf", None), ("woff2", "woff2")):
            with open(os.path.join(OUT, f"KernelSans-{style}.{ext}"), "wb") as f:
                f.write(to_bytes(font, flavor))
        print(f"KernelSans-{style}: Geist {weight}")


if __name__ == "__main__":
    main()
