# Pembuat ikon launcher DilRecord. Jalankan (butuh Pillow):
#   python3 tool/launcher_icon.py <MaterialIcons-Regular.otf> <folder-output>
# Font ikon ada di cache Flutter:
#   <flutter>/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf
# lalu salin hasilnya ke mipmap-* / AppIcon.appiconset.
"""Ikon DilRecord: logo dompet (sama seperti splash) di dalam ubin bergaris
tebal dengan bayangan keras, di atas latar kuning.

Semua koordinat dalam unit kanvas 1024; dirender 4x lalu diperkecil.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

ICON_FONT = sys.argv[1]
OUT = sys.argv[2]
SS = 4  # supersampling

# Icons.account_balance_wallet_rounded — ikon yang dipakai splash screen.
WALLET = chr(0xF520)

YELLOW = (255, 210, 63)
INK = (22, 22, 22)
TILE = (232, 245, 233)  # AppPalette.light.accent — warna ubin di splash


def s(v):
    return int(round(v * SS))


def tile(draw, x, y, size):
    """Ubin persegi: bayangan keras diagonal, garis tepi tebal, isi warna."""
    k = size / 560
    radius, border, shadow = 64 * k, 40 * k, 44 * k
    draw.rounded_rectangle(
        [s(x + shadow), s(y + shadow), s(x + size + shadow),
         s(y + size + shadow)], radius=s(radius), fill=INK)
    draw.rounded_rectangle([s(x), s(y), s(x + size), s(y + size)],
                           radius=s(radius), fill=INK)
    draw.rounded_rectangle(
        [s(x + border), s(y + border), s(x + size - border),
         s(y + size - border)], radius=s(radius - border * 0.6), fill=TILE)


def wallet(draw, x, y, size, color=INK):
    """Glyph dompet di tengah ubin (± setengah lebar ubin, seperti splash)."""
    glyph = size * 0.7
    font = ImageFont.truetype(ICON_FONT, s(glyph))
    cx, cy = s(x + size / 2), s(y + size / 2)
    draw.text((cx, cy), WALLET, font=font, fill=color, anchor='mm')


def render(box, *, bg=None, mono=False):
    W = s(1024)
    img = Image.new('RGBA', (W, W), bg or (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x, y, size = box
    if mono:
        # Ikon bertema Android 13+: hanya alpha yang dipakai — garis ubin +
        # dompet sebagai siluet.
        k = size / 560
        d.rounded_rectangle([s(x), s(y), s(x + size), s(y + size)],
                            radius=s(64 * k), fill=INK)
        hole = Image.new('L', (W, W), 0)
        ImageDraw.Draw(hole).rounded_rectangle(
            [s(x + 40 * k), s(y + 40 * k), s(x + size - 40 * k),
             s(y + size - 40 * k)], radius=s(40 * k), fill=255)
        img.paste((0, 0, 0, 0), mask=hole)
        wallet(d, x, y, size)
    else:
        tile(d, x, y, size)
        wallet(d, x, y, size)
    return img.resize((1024, 1024), Image.LANCZOS)


# Ikon penuh (iOS & Android lama). Ubin+bayangan dipusatkan optis.
render((210, 210, 560), bg=YELLOW + (255,)).convert('RGB').save(
    f'{OUT}/icon-full.png')
# Adaptive Android: isi harus muat di lingkaran aman 66/108 → lebih kecil.
render((322, 322, 360)).save(f'{OUT}/icon-foreground.png')
render((322, 322, 360), mono=True).save(f'{OUT}/icon-monochrome.png')
