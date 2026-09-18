#!/usr/bin/env python3
"""BioVirus — the Limine boot-menu plate.

Composed around where Limine actually draws (measured in QEMU/OVMF, see
preview.sh): the entry tree is CENTRED, x ~31-66 %, y ~42-62 % as snapshots
accumulate; branding sits at y 6 %, the help rows at 10-16 %, the countdown
at 92 %. All of that column stays dark. The art lives at the sides and the
corners, and a pair of HUD brackets frames the menu zone generously enough
that a longer snapshot line cannot poke out of them.

Drawing helpers are the theme's own (../theme/tools/make-plates.py): ink =
sharp + added bloom, haze = light only. Same palette override so a sibling theme
can render its contagion variant:

    python3 make-boot-plate.py [--colors <colors.toml>] [--prefix <name>]
                               [--specimen <label>] [outdir]
"""

import importlib.util
import os
import sys
from math import cos, pi, sin
from random import Random

from PIL import Image, ImageChops, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
# The plate library ships with the theme (tools/make-plates.py). Look for a
# checkout at ../theme first, then the installed theme.
_candidates = [os.path.join(HERE, "..", "theme", "tools", "make-plates.py"),
               os.path.expanduser("~/.config/omarchy/themes/biovirus/tools/make-plates.py")]
_plates = next((c for c in _candidates if os.path.exists(c)), None)
if not _plates:
    sys.exit("make-plates.py not found: clone TierTek/omarchy-biovirus-theme to ../theme "
             "or install the theme first")
_spec = importlib.util.spec_from_file_location("plates", _plates)
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

W, H = P.W, P.H
TREFOIL = "\U000F00A7"  # nf-md-biohazard, JetBrainsMono Nerd Font


def rgba(c, a):
    return P.rgba(c, a)


def ring(d, cx, cy, r, color, alpha, width=3):
    P.ring(d, cx, cy, r, color, alpha, width)


def reticle(img, cx, cy, R, specimen):
    """The fastfetch HUD reticle, scaled up: ticks, crosshair stubs, brackets, trefoil."""
    G, M, DIM, RED = P.GREEN, P.MUTED, P.MUTED, P.RED
    img = P.haze(img, lambda d: d.ellipse(
        [cx - R * 0.6, cy - R * 0.6, cx + R * 0.6, cy + R * 0.6], fill=rgba(G, 110)),
        blur=int(R * 0.3), gain=0.45)

    def hud(d):
        ring(d, cx, cy, R, G, 255, width=4)
        ring(d, cx, cy, R - 34, M, 170, width=2)
        ring(d, cx, cy, R * 0.42, M, 120, width=1)
        for i in range(0, 360, 5):
            a = i * pi / 180
            L = R * 0.09 if i % 45 == 0 else R * 0.035 if i % 15 == 0 else R * 0.018
            d.line([(cx + cos(a) * (R - L), cy + sin(a) * (R - L)),
                    (cx + cos(a) * R, cy + sin(a) * R)],
                   fill=rgba(G if i % 45 == 0 else M, 240), width=3 if i % 45 == 0 else 2)
        g = R * 0.5  # crosshair stubs, gapped around the glyph
        for (x0, y0, x1, y1) in ((cx - R - 40, cy, cx - g, cy), (cx + g, cy, cx + R + 40, cy),
                                 (cx, cy - R - 40, cx, cy - g), (cx, cy + g, cx, cy + R + 40)):
            d.line([(x0, y0), (x1, y1)], fill=rgba(M, 220), width=3)

    def glyph(d):
        f = P.font(int(R * 1.05))
        bb = d.textbbox((0, 0), TREFOIL, font=f)
        d.text((cx - (bb[0] + bb[2]) / 2, cy - (bb[1] + bb[3]) / 2),
               TREFOIL, font=f, fill=rgba(G, 255))

    def text(d):
        f, fs = P.font(30), P.font(24)
        d.text((cx - R - 40, cy - R - 120), "BSL-4", font=f, fill=rgba(G, 255))
        d.text((cx - R - 40, cy - R - 84), specimen, font=fs, fill=rgba(DIM, 230))
        t = "LOCK"
        d.text((cx + R + 40 - d.textlength(t, font=f), cy - R - 120), t, font=f, fill=rgba(RED, 255))
        t = "● CONTAINED"
        d.text((cx + R + 40 - d.textlength(t, font=fs), cy - R - 84), t, font=fs, fill=rgba(DIM, 230))

    img = P.ink(img, hud, bloom=10, gain=0.45)
    img = P.ink(img, glyph, bloom=36, gain=0.7)
    img = P.ink(img, text, bloom=8, gain=0.4)
    return img


def capsid(img, cx, cy, r, alpha_scale=1.0, spikes=48, seed=1):
    """A spiked virion silhouette, drawn dim — depth furniture, not a subject."""
    G, M = P.GREEN, P.MUTED
    rnd = Random(seed)

    def body(d):
        ring(d, cx, cy, r, M, int(200 * alpha_scale), width=3)
        ring(d, cx, cy, r * 0.62, M, int(110 * alpha_scale), width=2)
        for i in range(spikes):
            a = i / spikes * 2 * pi + rnd.random() * 0.02
            L = r * 0.16
            x0, y0 = cx + cos(a) * r, cy + sin(a) * r
            x1, y1 = cx + cos(a) * (r + L), cy + sin(a) * (r + L)
            d.line([(x0, y0), (x1, y1)], fill=rgba(M, int(190 * alpha_scale)), width=2)
            d.ellipse([x1 - 6, y1 - 6, x1 + 6, y1 + 6], fill=rgba(G, int(190 * alpha_scale)))

    return P.ink(img, body, bloom=14, gain=0.35 * alpha_scale)


def menu_brackets(img):
    """Corner brackets around the zone Limine draws the entry tree in.

    Generous on purpose: x 25-73 %, y 33-72 %. The tree is centred, so even a
    60-character snapshot line (960 px at 2x2) spans only x 33-67 %.
    """
    G, M = P.GREEN, P.MUTED
    x0, x1 = 0.25 * W, 0.73 * W
    y0, y1 = 0.33 * H, 0.72 * H
    arm = 110

    def frame(d):
        for (x, y, sx, sy) in ((x0, y0, 1, 1), (x1, y0, -1, 1), (x0, y1, 1, -1), (x1, y1, -1, -1)):
            d.line([(x, y), (x + sx * arm, y)], fill=rgba(G, 235), width=4)
            d.line([(x, y), (x, y + sy * arm)], fill=rgba(G, 235), width=4)
        # faint rails top and bottom, gapped in the middle so the text never rides them
        for y in (y0, y1):
            d.line([(x0 + arm + 40, y), (x0 + (x1 - x0) * 0.36, y)], fill=rgba(M, 90), width=2)
            d.line([(x1 - (x1 - x0) * 0.36, y), (x1 - arm - 40, y)], fill=rgba(M, 90), width=2)
        f = P.font(22)
        d.text((x0 + arm + 40, y0 - 34), "KERNEL SELECT", font=f, fill=rgba(M, 230))
        t = "AWAITING OPERATOR"
        d.text((x1 - arm - 40 - d.textlength(t, font=f), y1 + 12), t, font=f, fill=rgba(M, 230))

    return P.ink(img, frame, bloom=8, gain=0.4)


def readouts(img, specimen):
    """Corner labels, in the plates' voice."""
    G, M, DIM, CY = P.GREEN, P.MUTED, P.MUTED, P.CYAN
    fl, fs = P.font(30), P.font(22)

    def text(d):
        d.text((0.045 * W, 0.045 * H), "BOOT SEQUENCE  //  CONTAINMENT", font=fl, fill=rgba(G, 240))
        d.text((0.045 * W, 0.045 * H + 42), f"SPECIMEN  {specimen}", font=fs, fill=rgba(DIM, 220))
        # scale bar, bottom-left, like the TEM plates
        x, y = 0.045 * W, 0.93 * H
        d.line([(x, y), (x + 300, y)], fill=rgba(M, 230), width=2)
        for xx in (x, x + 150, x + 300):
            d.line([(xx, y - 10), (xx, y + 10)], fill=rgba(M, 230), width=2)
        d.text((x, y + 18), "200 nm", font=fs, fill=rgba(DIM, 220))
        # bottom-right: firmware-ish status column
        lines = [("UEFI", "LIMINE"), ("ESP", "vfat  2G"), ("ROOT", "luks2 + btrfs"), ("VITALS", "████████░░")]
        y = 0.83 * H
        for k, v in lines:
            d.text((0.90 * W - 260, y), k, font=fs, fill=rgba(DIM, 200))
            d.text((0.90 * W - 120, y), v, font=fs, fill=rgba(G if k == "VITALS" else CY, 220))
            y += 34

    return P.ink(img, text, bloom=6, gain=0.35)


def main():
    args = sys.argv[1:]
    specimen = os.uname().nodename
    outdir = HERE
    while args:
        a = args.pop(0)
        if a == "--colors":
            P.load_colors(args.pop(0))
        elif a == "--prefix":
            P.PREFIX = args.pop(0)
        elif a == "--specimen":
            specimen = args.pop(0)
        else:
            outdir = a

    img = P.ground(focus=(0.78, 0.5), spread=0.9)
    img = Image.alpha_composite(img, P.grid_layer(step=120, tick=9, alpha=120))

    # depth: soft blobs, then dim capsids drifting at the left edge
    def blobs(d):
        for cx, cy, r, a in [(0.12 * W, 0.70 * H, 320, 70), (0.80 * W, 0.50 * H, 420, 40),
                             (0.45 * W, 0.92 * H, 260, 40)]:
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgba(P.MUTED, a))
    img = P.haze(img, blobs, 120, gain=0.5)
    img = capsid(img, 0.10 * W, 0.62 * H, 150, alpha_scale=0.9, seed=3)
    img = capsid(img, 0.055 * W, 0.34 * H, 70, alpha_scale=0.5, spikes=28, seed=4)
    img = capsid(img, 0.20 * W, 0.86 * H, 95, alpha_scale=0.6, spikes=36, seed=5)

    img = reticle(img, 0.875 * W, 0.50 * H, 300, specimen.upper())
    img = menu_brackets(img)
    img = readouts(img, specimen)

    P.finish(img, "boot.png", outdir)


if __name__ == "__main__":
    main()
