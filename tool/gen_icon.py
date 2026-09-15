from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

root = Path(__file__).resolve().parents[1]
out = root / "assets" / "icon"
out.mkdir(parents=True, exist_ok=True)
S = 1024
SS = 4  # supersampling
size = S * SS

NAVY = (11, 29, 51)
AQUA = (31, 182, 201)
MINT = (120, 230, 240)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def drop_path(cx, cy, r, tip_h, n=400):
    """Smooth teardrop: circle of radius r centred at (cx, cy) with a tip tip_h above it."""
    pts = []
    tip = (cx, cy - r - tip_h)
    # tangent angle where the straight edges meet the circle
    a = math.asin(r / (r + tip_h))
    start = -math.pi / 2 + a
    end = 3 * math.pi / 2 - a
    for i in range(n + 1):
        t = start + (end - start) * i / n
        pts.append((cx + r * math.cos(t), cy + r * math.sin(t)))
    pts.append(tip)
    return pts


def wave_fill(mask_pts, level_y, amp, wavelength, phase, canvas):
    """Return an L mask of the region inside mask_pts and below a sine wave at level_y."""
    shape = Image.new("L", canvas, 0)
    ImageDraw.Draw(shape).polygon(mask_pts, fill=255)
    wave = Image.new("L", canvas, 0)
    poly = [(x, level_y + amp * math.sin(2 * math.pi * x / wavelength + phase)) for x in range(0, canvas[0] + 1, 8)]
    poly += [(canvas[0], canvas[1]), (0, canvas[1])]
    ImageDraw.Draw(wave).polygon(poly, fill=255)
    return Image.composite(shape, Image.new("L", canvas, 0), wave)


def background():
    bg = Image.new("RGB", (size, size))
    px = bg.load()
    for y in range(0, size, SS):
        for x in range(0, size, SS):
            t = (x + y) / (size * 2)
            c = lerp(NAVY, AQUA, t ** 1.1)
            for dy in range(SS):
                for dx in range(SS):
                    px[x + dx, y + dy] = c
    return bg


def drop_layer():
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx, cy, r = size / 2, size * 0.60, size * 0.20
    pts = drop_path(cx, cy, r, size * 0.24)

    # soft shadow
    shadow = Image.new("L", (size, size), 0)
    ImageDraw.Draw(shadow).polygon([(x + size * 0.012, y + size * 0.02) for x, y in pts], fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.02))
    layer.paste((0, 20, 40, 255), mask=shadow)

    # white body
    body = Image.new("L", (size, size), 0)
    ImageDraw.Draw(body).polygon(pts, fill=255)
    layer.paste((255, 255, 255, 255), mask=body)

    # two-tone wave water inside the drop
    back = wave_fill(pts, cy + r * 0.05, r * 0.10, size * 0.42, 1.2, (size, size))
    layer.paste(MINT + (255,), mask=back)
    front = wave_fill(pts, cy + r * 0.18, r * 0.09, size * 0.36, -0.4, (size, size))
    layer.paste(AQUA + (255,), mask=front)

    # highlight
    d = ImageDraw.Draw(layer)
    hx, hy = cx - r * 0.45, cy - r * 0.55
    d.ellipse((hx - r * 0.13, hy - r * 0.24, hx + r * 0.13, hy + r * 0.24), fill=(255, 255, 255, 235))
    d.ellipse((hx - r * 0.06, hy + r * 0.36, hx + r * 0.06, hy + r * 0.48), fill=(255, 255, 255, 200))
    return layer


bg = background().convert("RGBA")
mask = Image.new("L", (size, size), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
bg.putalpha(mask)
drop = drop_layer()
icon = Image.alpha_composite(bg, drop).resize((S, S), Image.LANCZOS)
icon.save(out / "icon.png")

# adaptive foreground: content inside the safe zone (66% of canvas)
fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
small = drop.resize((int(size * 0.92), int(size * 0.92)), Image.LANCZOS)
fg.paste(small, ((size - small.width) // 2, (size - small.height) // 2), small)
fg.resize((S, S), Image.LANCZOS).save(out / "icon_adaptive_fg.png")
print("ok")
