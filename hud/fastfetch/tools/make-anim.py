#!/usr/bin/env python3
"""Animated reticle: outer tick ring rotates slowly, trefoil glow breathes, a radar sweep circles. 36 frames -> GIF."""
import sys, os
from math import cos, sin, pi
from PIL import Image, ImageDraw, ImageFilter, ImageChops

import importlib.util
spec = importlib.util.spec_from_file_location('ml', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'make-logos.py'))
ml = importlib.util.module_from_spec(spec); _argv=sys.argv; sys.argv=['x','/tmp']; spec.loader.exec_module(ml); sys.argv=_argv
S=ml.S; GREEN=ml.GREEN; MUTED=ml.MUTED; RED=ml.RED; DIM=ml.DIM; SEL=ml.SEL
N=36
# BIOVIRUS_TRANSPARENT=1: render on pure black with no vignette/lattice, then turn black into
# alpha (a = max(r,g,b), colour un-premultiplied) so the glow composites over the terminal
# background instead of sitting in an opaque dark plate. Output is an APNG (GIF has only 1-bit
# transparency, which gives the halo a hard edge); kitten icat animates APNG the same as GIF.
TRANSPARENT = os.environ.get("BIOVIRUS_TRANSPARENT") == "1"

def black_to_alpha(img):
    r,g,b,_ = img.convert("RGBA").split()
    a = ImageChops.lighter(ImageChops.lighter(r,g),b)
    ap = a.load(); px = img.convert("RGB").load(); w,h = img.size
    out = Image.new("RGBA",(w,h),(0,0,0,0)); op = out.load()
    for y in range(h):
        for x in range(w):
            al = ap[x,y]
            if al:
                cr,cg,cb = px[x,y]
                op[x,y] = (min(255,cr*255//al), min(255,cg*255//al), min(255,cb*255//al), al)
    return out

def frame(i):
    t=i/N
    img=Image.new("RGBA",(S,S),(0,0,0,255)) if TRANSPARENT else ml.lattice(ml.ground()); cx=cy=S/2; R=290
    glow=0.30+0.20*(0.5+0.5*sin(2*pi*t))            # breathing halo
    img=ml.haze(img,lambda d:ml.disc(d,cx,cy,170,GREEN,120),blur=70,gain=glow)
    rot=t*2*pi/24                                    # ticks drift one 15-degree step per loop
    def hud(d):
        ml.ring(d,cx,cy,R,GREEN,255,w=3); ml.ring(d,cx,cy,R-30,MUTED,180,w=1)
        for k in range(0,360,5):
            a=k*pi/180+rot; L=26 if k%45==0 else 10 if k%15==0 else 5
            d.line([(cx+cos(a)*(R-L),cy+sin(a)*(R-L)),(cx+cos(a)*R,cy+sin(a)*R)],fill=ml.rgba(GREEN if k%45==0 else MUTED,240),width=2)
        for (x0,y0,x1,y1) in ((cx-R-40,cy,cx-150,cy),(cx+150,cy,cx+R+40,cy),(cx,cy-R-40,cx,cy-150),(cx,cy+150,cx,cy+R+40)):
            d.line([(x0,y0),(x1,y1)],fill=ml.rgba(MUTED,220),width=2)
        for sx in (-1,1):
            for sy in (-1,1):
                x=cx+sx*(R+60); y=cy+sy*(R+60)
                d.line([(x,y),(x-sx*40,y)],fill=ml.rgba(GREEN,255),width=4); d.line([(x,y),(x,y-sy*40)],fill=ml.rgba(GREEN,255),width=4)
    def sweep(d):
        # radar wedge trailing 40 degrees behind the sweep line, inside the inner ring
        a0=t*2*pi
        for j in range(40):
            a=a0-j*pi/180; al=int(70*(1-j/40))
            d.line([(cx,cy),(cx+cos(a)*(R-32),cy+sin(a)*(R-32))],fill=ml.rgba(GREEN,al),width=3)
        d.line([(cx,cy),(cx+cos(a0)*(R-32),cy+sin(a0)*(R-32))],fill=ml.rgba(GREEN,200),width=2)
    def glyph(d):
        f=ml.font(300); g="\U000F00A7"; bb=d.textbbox((0,0),g,font=f)
        d.text((cx-(bb[0]+bb[2])/2, cy-(bb[1]+bb[3])/2),g,font=f,fill=ml.rgba(GREEN,255))
    def text(d):
        f=ml.font(20); fs=ml.font(16)
        d.text((cx-R-40,cy-R-106),"BSL-4",font=f,fill=ml.rgba(GREEN,255))
        d.text((cx-R-40,cy-R-82),ml.SPECIMEN,font=fs,fill=ml.rgba(DIM,230))
        w=d.textlength("LOCK",font=f); d.text((cx+R+40-w,cy-R-106),"LOCK",font=f,fill=ml.rgba(RED,255))
        blink = "● CONTAINED" if (i//9)%2==0 else "○ CONTAINED"
        w=d.textlength(blink,font=fs); d.text((cx+R+40-w,cy-R-82),blink,font=fs,fill=ml.rgba(DIM,230))
    img=ml.ink(img,hud,bloom=8,gain=0.45); img=ml.ink(img,sweep,bloom=10,gain=0.5)
    img=ml.ink(img,glyph,bloom=24,gain=0.55+0.3*(0.5+0.5*sin(2*pi*t))); img=ml.ink(img,text,bloom=6,gain=0.4)
    img=ml.scanlines(img)
    img=img.convert("RGB").resize((480,480),Image.LANCZOS)
    return black_to_alpha(img) if TRANSPARENT else img

frames=[frame(i) for i in range(N)]
outdir=sys.argv[1] if len(sys.argv)>1 else '.'
if TRANSPARENT:
    out=os.path.join(outdir, 'biovirus-reticle-anim.png')
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=110, loop=0, optimize=True)
    still=os.path.join(outdir, 'biovirus-reticle.png'); frames[0].save(still)
    print(still, os.path.getsize(still)//1024, "KiB")
else:
    pal=frames[0].quantize(colors=128, method=Image.MEDIANCUT)
    q=[f.quantize(palette=pal, dither=Image.NONE) for f in frames]
    out=os.path.join(outdir, 'biovirus-reticle.gif')
    q[0].save(out, save_all=True, append_images=q[1:], duration=110, loop=0, optimize=True)
print(out, os.path.getsize(out)//1024, "KiB")
