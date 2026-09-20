"""MENZİLİM web/mağaza simgelerini üretir.

Geometri assets/brand/menzilim_mark.svg ile birebir aynıdır; SVG değişirse
buradaki sabitler de güncellenmelidir.

Kullanım: python tools/render_brand_icons.py   (gereksinim: Pillow)
"""
import os
from PIL import Image, ImageDraw

SS = 8  # supersampling

# SVG (viewBox 64) ile birebir aynı geometri
STEM_TOP, STEM_BOTTOM = 18.0, 54.0
LEFT_X, RIGHT_X = 13.0, 51.0
RING_C = (32.0, 43.0)
RING_R = 10.5
RING_W = 3.4
DOT_R = 2.9
STROKE = 6.4
DIAG_L = (24.6, 35.6)
DIAG_R = (39.4, 35.6)


def draw_mark(size, color, bg=None, pad_ratio=0.0):
    """size: kenar (px). pad_ratio: sembolün etrafındaki boşluk oranı."""
    canvas = size * SS
    img = Image.new("RGBA", (canvas, canvas), bg if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    inner = canvas * (1 - 2 * pad_ratio)
    scale = inner / 64.0
    off = canvas * pad_ratio

    def P(x, y):
        return (off + x * scale, off + y * scale)

    def round_line(p1, p2, width):
        w = width * scale
        d.line([P(*p1), P(*p2)], fill=color, width=int(round(w)))
        for p in (p1, p2):  # yuvarlak uçlar
            cx, cy = P(*p)
            d.ellipse([cx - w / 2, cy - w / 2, cx + w / 2, cy + w / 2], fill=color)

    round_line((LEFT_X, STEM_BOTTOM), (LEFT_X, STEM_TOP), STROKE)
    round_line((RIGHT_X, STEM_BOTTOM), (RIGHT_X, STEM_TOP), STROKE)
    round_line((LEFT_X, STEM_TOP), DIAG_L, STROKE)
    round_line((RIGHT_X, STEM_TOP), DIAG_R, STROKE)

    cx, cy = P(*RING_C)
    r = RING_R * scale
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color,
              width=max(1, int(round(RING_W * scale))))
    dr = DOT_R * scale
    d.ellipse([cx - dr, cy - dr, cx + dr, cy + dr], fill=color)

    return img.resize((size, size), Image.LANCZOS)


def rounded_icon(size, pad_ratio=0.22, radius_ratio=0.2234, bg=(103, 80, 164, 255)):
    canvas = size * SS
    base = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle([0, 0, canvas - 1, canvas - 1],
                        radius=canvas * radius_ratio, fill=bg)
    base = base.resize((size, size), Image.LANCZOS)
    mark = draw_mark(size, (255, 255, 255, 255), pad_ratio=pad_ratio)
    return Image.alpha_composite(base, mark)


if __name__ == "__main__":
    web = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web")

    rounded_icon(32, pad_ratio=0.18).save(os.path.join(web, "favicon.png"))
    rounded_icon(192, pad_ratio=0.18).save(os.path.join(web, "icons", "Icon-192.png"))
    rounded_icon(512, pad_ratio=0.18).save(os.path.join(web, "icons", "Icon-512.png"))
    # Maskable: güvenli alan için daha fazla boşluk, tam kare zemin.
    rounded_icon(192, pad_ratio=0.28, radius_ratio=0.0).save(
        os.path.join(web, "icons", "Icon-maskable-192.png"))
    rounded_icon(512, pad_ratio=0.28, radius_ratio=0.0).save(
        os.path.join(web, "icons", "Icon-maskable-512.png"))
    print("web ikonlari uretildi")
