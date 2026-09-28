"""Generates every Veil icon asset from the vector wordmark.

The wordmark is set in Outfit (SIL Open Font License 1.1, see OFL.txt) and
converted to outlines, so no font is shipped inside the app itself.

Run from the repo root with fonttools, uharfbuzz, cairosvg and Pillow:
    python tool/icon/gen_icons.py
"""

import io
import os
from pathlib import Path

import cairosvg
import uharfbuzz as hb
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
FONT = Path(__file__).with_name("Outfit[wght].ttf")
WEIGHT = 500

VARIANTS = {
    # (background, wordmark)
    "light": ("#F3F2EE", "#7A808A"),
    "dark": ("#868686", "#FFFFFF"),
}


class Outline:
    """Shaped text as outlines in font units, y pointing down, ink box at 0,0."""

    def __init__(self, text, weight):
        blob = hb.Blob.from_file_path(str(FONT))
        face = hb.Face(blob)
        font = hb.Font(face)
        font.set_variations({"wght": weight})
        buf = hb.Buffer()
        buf.add_str(text)
        buf.guess_segment_properties()
        hb.shape(font, buf, {"kern": True, "liga": True})
        tt = instancer.instantiateVariableFont(TTFont(str(FONT)), {"wght": weight})
        self.glyphs = tt.getGlyphSet()
        order = tt.getGlyphOrder()
        self.items = []
        x = 0
        for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
            self.items.append((order[info.codepoint], x + pos.x_offset, pos.y_offset))
            x += pos.x_advance
        bp = BoundsPen(self.glyphs)
        self._draw(bp, (1, 0, 0, 1, 0, 0))
        x0, y0, x1, y1 = bp.bounds
        self.width = x1 - x0
        self.height = y1 - y0
        self._origin = (x0, y1)

    def _draw(self, pen, transform):
        for name, gx, gy in self.items:
            t = TransformPen(pen, transform)
            self.glyphs[name].draw(TransformPen(t, (1, 0, 0, 1, gx, gy)))

    def path(self, cx, cy, width):
        """SVG path data with the ink box centred on (cx, cy) at `width`."""
        s = width / self.width
        x0, ytop = self._origin
        tx = cx - self.width * s / 2 - x0 * s
        ty = cy - self.height * s / 2 + ytop * s
        pen = SVGPathPen(self.glyphs, ntos=lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
        self._draw(pen, (s, 0, 0, -s, tx, ty))
        return pen.getCommands()


WORD = Outline("Veil", WEIGHT)
MONO = Outline("V", 600)


def svg(size, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {size} {size}">{body}</svg>'
    )


def png(svg_text, px):
    data = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=px, output_height=px)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def rounded_icon(variant, size=1024, inset=0.0, radius=0.225, word=0.6, shape="square"):
    bg, fg = VARIANTS[variant]
    pad = size * inset
    body = size - 2 * pad
    if shape == "circle":
        plate = f'<circle cx="{size/2}" cy="{size/2}" r="{body/2}" fill="{bg}"/>'
    else:
        r = body * radius
        plate = f'<rect x="{pad}" y="{pad}" width="{body}" height="{body}" rx="{r}" fill="{bg}"/>'
    rim = ""
    if variant == "light":
        # Keeps the off-white plate visible on white backgrounds.
        if shape == "circle":
            rim = f'<circle cx="{size/2}" cy="{size/2}" r="{body/2 - size*0.004}" fill="none" stroke="#000" stroke-opacity="0.08" stroke-width="{size*0.008}"/>'
        else:
            rim = (f'<rect x="{pad+size*0.004}" y="{pad+size*0.004}" width="{body-size*0.008}" '
                   f'height="{body-size*0.008}" rx="{body*radius}" fill="none" stroke="#000" '
                   f'stroke-opacity="0.08" stroke-width="{size*0.008}"/>')
    d = WORD.path(size / 2, size / 2, body * word)
    return svg(size, plate + rim + f'<path d="{d}" fill="{fg}"/>')


def tray_icon(variant, status, size=256):
    bg, fg = VARIANTS[variant]
    r = size * 0.24
    opacity = 0.55 if status == 1 else 1.0
    stroke = ""
    if variant == "light":
        stroke = f' stroke="#000" stroke-opacity="0.18" stroke-width="{size*0.03}"'
    body = (f'<g opacity="{opacity}"><rect x="{size*0.03}" y="{size*0.03}" width="{size*0.94}" '
            f'height="{size*0.94}" rx="{r}" fill="{bg}"{stroke}/>')
    d = MONO.path(size / 2, size / 2, size * 0.5)
    body += f'<path d="{d}" fill="{fg}"/></g>'
    if status == 3:
        cx = cy = size * 0.78
        body += (f'<circle cx="{cx}" cy="{cy}" r="{size*0.2}" fill="{bg}"/>'
                 f'<circle cx="{cx}" cy="{cy}" r="{size*0.13}" fill="{fg}"/>')
    return svg(size, body)


def tray_template(px, size=256):
    """macOS menu bar template: a black plate with the V knocked out (alpha only)."""
    r = size * 0.24
    plate = png(svg(size, f'<rect x="{size*0.03}" y="{size*0.03}" width="{size*0.94}" '
                          f'height="{size*0.94}" rx="{r}" fill="#000"/>'), px)
    glyph = png(svg(size, f'<path d="{MONO.path(size / 2, size / 2, size * 0.5)}" fill="#000"/>'), px)
    alpha = ImageChops.subtract(plate.getchannel("A"), glyph.getchannel("A"))
    out = Image.new("RGBA", plate.size, (0, 0, 0, 0))
    out.putalpha(alpha)
    return out


def save_ico(svg_text, path, sizes):
    images = [png(svg_text, s) for s in sizes]
    big = images[-1]
    big.save(path, format="ICO", sizes=[(s, s) for s in sizes], append_images=images[:-1])


def vector_drawable(path_data, color, viewport=108, size_dp=108):
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/icon/gen_icons.py; Veil wordmark set in Outfit (OFL-1.1). -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="{size_dp}dp"
    android:height="{size_dp}dp"
    android:viewportWidth="{viewport}"
    android:viewportHeight="{viewport}">
    <path
        android:fillColor="{color}"
        android:pathData="{path_data}" />
</vector>
"""


def write(path, data):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, str):
        path.write_text(data)
    else:
        path.write_bytes(data)


def adaptive(foreground, background, monochrome=True):
    mono = f'\n    <monochrome android:drawable="@drawable/{foreground}" />' if monochrome else ""
    return f"""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/{background}" />
    <foreground android:drawable="@drawable/{foreground}" />{mono}
</adaptive-icon>
"""


def main():
    res = Path("android/app/src/main/res")
    # Adaptive foreground: 108dp canvas, the wordmark stays well inside the
    # 66dp safe zone so every mask shape keeps it whole.
    fg_path = WORD.path(54, 54, 52)
    colors = []
    for variant, (bg, fg) in VARIANTS.items():
        suffix = "" if variant == "light" else "_dark"
        write(res / f"drawable/ic_launcher_foreground{suffix}.xml", vector_drawable(fg_path, fg))
        colors.append(f'    <color name="ic_launcher_background{suffix}">{bg}</color>')
        write(res / f"mipmap-anydpi-v26/ic_launcher{suffix}.xml",
              adaptive(f"ic_launcher_foreground{suffix}", f"ic_launcher_background{suffix}"))
        write(res / f"mipmap-anydpi-v26/ic_launcher{suffix}_round.xml",
              adaptive(f"ic_launcher_foreground{suffix}", f"ic_launcher_background{suffix}"))
        for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
            for old in ("webp", "png"):
                for name in (f"ic_launcher{suffix}", f"ic_launcher{suffix}_round"):
                    p = ROOT / res / f"mipmap-{density}/{name}.{old}"
                    if p.exists():
                        p.unlink()
            square = png(rounded_icon(variant, inset=0.04, word=0.56), px)
            circle = png(rounded_icon(variant, inset=0.04, word=0.56, shape="circle"), px)
            buf = io.BytesIO(); square.save(buf, "PNG")
            write(res / f"mipmap-{density}/ic_launcher{suffix}.png", buf.getvalue())
            buf = io.BytesIO(); circle.save(buf, "PNG")
            write(res / f"mipmap-{density}/ic_launcher{suffix}_round.png", buf.getvalue())
    write(res / "values/ic_launcher_background.xml",
          '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n' + "\n".join(colors) + "\n</resources>\n")

    # Android TV launcher and banner (light design).
    write(res / "drawable/ic_launcher_foreground_tv.xml",
          vector_drawable(fg_path, VARIANTS["light"][1]))
    for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        for old in ("webp", "png"):
            p = ROOT / res / f"mipmap-television-{density}/ic_launcher.{old}"
            if p.exists():
                p.unlink()
        buf = io.BytesIO(); png(rounded_icon("light", inset=0.04, word=0.56), px).save(buf, "PNG")
        write(res / f"mipmap-television-{density}/ic_launcher.png", buf.getvalue())
    bg, fg = VARIANTS["light"]
    banner = (f'<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180" viewBox="0 0 320 180">'
              f'<rect width="320" height="180" fill="{bg}"/><path d="{WORD.path(160, 90, 150)}" fill="{fg}"/></svg>')
    write(res / "mipmap-xhdpi/ic_banner.png", cairosvg.svg2png(bytestring=banner.encode()))

    # Notification / quick-settings tile glyphs (alpha only on Android).
    v24 = MONO.path(12, 12, 15)
    write("android/service/src/main/res/drawable/ic.xml", vector_drawable(v24, "#FFFFFF", 24, 24))
    write("android/service/src/main/res/drawable/ic_service.xml",
          vector_drawable(v24, VARIANTS["light"][1], 24, 24))

    # Flutter assets: in-app icons, runtime window icons and tray icons.
    ico_sizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]
    for variant in VARIANTS:
        suffix = "" if variant == "light" else "_dark"
        icon = rounded_icon(variant, inset=0.02, word=0.58)
        buf = io.BytesIO(); png(icon, 512).save(buf, "PNG")
        write(f"assets/images/icon{suffix}.png", buf.getvalue())
        save_ico(icon, ROOT / f"assets/images/icon{suffix}.ico", ico_sizes)
        win_dir = f"assets/images/tray/windows{suffix}"
        unix_dir = f"assets/images/tray/unix{suffix}"
        for status in (1, 2, 3):
            t = tray_icon(variant, status)
            (ROOT / win_dir).mkdir(parents=True, exist_ok=True)
            save_ico(t, ROOT / f"{win_dir}/status_{status}.ico", [16, 20, 24, 32, 40, 48, 64])
            for scale, px in {"": 18, "2.0x/": 36, "3.0x/": 54, "4.0x/": 72}.items():
                buf = io.BytesIO(); png(t, px).save(buf, "PNG")
                write(f"{unix_dir}/{scale}status_{status}.png", buf.getvalue())
        if variant == "light":
            save_ico(icon, ROOT / "windows/runner/resources/app_icon.ico", ico_sizes)

    # macOS: Big Sur icon grid (824px plate on a 1024px canvas), template tray
    # icons, and Dock icons the in-app icon switcher applies at runtime.
    appiconset = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    mac_inset = (1024 - 824) / 2 / 1024
    for px in (16, 32, 64, 128, 256, 512, 1024):
        buf = io.BytesIO(); png(rounded_icon("light", inset=mac_inset, word=0.58), px).save(buf, "PNG")
        write(f"{appiconset}/app_icon_{px}.png", buf.getvalue())
    for variant in VARIANTS:
        suffix = "" if variant == "light" else "_dark"
        buf = io.BytesIO(); png(rounded_icon(variant, inset=mac_inset, word=0.58), 512).save(buf, "PNG")
        write(f"assets/images/macos/dock{suffix}.png", buf.getvalue())
    for scale, px in {"": 18, "2.0x/": 36, "3.0x/": 54, "4.0x/": 72}.items():
        buf = io.BytesIO(); tray_template(px).save(buf, "PNG")
        write(f"assets/images/tray/macos/{scale}status_1.png", buf.getvalue())

    # Preview sheet and master SVGs for reference.
    for variant in VARIANTS:
        write(f"tool/icon/veil_{variant}.svg", rounded_icon(variant, inset=0.0, radius=0.0, word=0.6))


if __name__ == "__main__":
    os.chdir(ROOT)
    main()
