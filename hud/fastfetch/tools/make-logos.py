#!/usr/bin/env python3
"""BioVirus fastfetch logo candidates — 800x800, same ink+bloom treatment as the theme plates."""
import os, sys
from math import cos, sin, pi, hypot
from random import Random
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

S = 800
BG=(0x04,0x08,0x0A); BG_DARK=(0x01,0x03,0x04); GRID=(0x0B,0x1A,0x14)
GREEN=(0x4B,0xFF,0xA5); MUTED=(0x2E,0x8F,0x63); SEL=(0x12,0x40,0x2E); CYAN=(0x4B,0xE0,0xFF)
DIM=(0x63,0xA1,0x86); RED=(0xFF,0x4D,0x5E); MAG=(0xC7,0x7D,0xFF)
FONT="/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"
# Palette override for sibling themes:  BIOVIRUS_COLORS=<colors.toml>  (e.g. a recoloured sibling theme)
# Corner label:                         BIOVIRUS_SPECIMEN="SPECIMEN 001"
import re as _re
_KEYS={"accent":"GREEN","muted":"MUTED","selection":"SEL","cyan":"CYAN","red":"RED","magenta":"MAG",
       "dark_foreground":"DIM","background":"BG","darker_background":"BG_DARK","lighter_background":"GRID"}
if os.environ.get("BIOVIRUS_COLORS"):
    for line in open(os.environ["BIOVIRUS_COLORS"]):
        m=_re.match(r'^\s*([a-z_]+)\s*=\s*"#([0-9a-fA-F]{6})"',line)
        if m and m.group(1) in _KEYS:
            h=m.group(2); globals()[_KEYS[m.group(1)]]=(int(h[0:2],16),int(h[2:4],16),int(h[4:6],16))
SPECIMEN=os.environ.get("BIOVIRUS_SPECIMEN","SPECIMEN 001")
OUT=sys.argv[1] if len(sys.argv)>1 else "."

def font(sz): return ImageFont.truetype(FONT, sz)
def rgba(c,a): return (c[0],c[1],c[2],int(a))

def ground():
    sm=Image.new("RGB",(64,64)); px=sm.load()
    for y in range(64):
        for x in range(64):
            t=min(1.0,hypot(x-32,y-32)/40); t=t*t*(3-2*t)
            px[x,y]=tuple(int(BG[i]+(BG_DARK[i]-BG[i])*t) for i in range(3))
    return sm.resize((S,S),Image.BICUBIC).convert("RGBA")

def ink(img, fn, bloom=18, gain=0.8):
    layer=Image.new("RGBA",(S,S),(0,0,0,0)); fn(ImageDraw.Draw(layer))
    out=Image.alpha_composite(img,layer)
    if bloom:
        bl=layer.filter(ImageFilter.GaussianBlur(bloom))
        a=bl.getchannel("A").point(lambda v:int(v*gain))
        lit=Image.composite(bl.convert("RGB"),Image.new("RGB",(S,S),(0,0,0)),a)
        out=ImageChops.add(out.convert("RGB"),lit).convert("RGBA")
    return out

def haze(img, fn, blur=60, gain=0.5):
    layer=Image.new("RGBA",(S,S),(0,0,0,0)); fn(ImageDraw.Draw(layer))
    bl=layer.filter(ImageFilter.GaussianBlur(blur))
    a=bl.getchannel("A").point(lambda v:int(v*gain))
    lit=Image.composite(bl.convert("RGB"),Image.new("RGB",(S,S),(0,0,0)),a)
    return ImageChops.add(img.convert("RGB"),lit).convert("RGBA")

def lattice(img, step=100, tick=7, alpha=170):
    layer=Image.new("RGBA",(S,S),(0,0,0,0)); d=ImageDraw.Draw(layer)
    for y in range(step,S,step):
        for x in range(step,S,step):
            d.line([(x-tick,y),(x+tick,y)],fill=rgba(GRID,alpha)); d.line([(x,y-tick),(x,y+tick)],fill=rgba(GRID,alpha))
    return Image.alpha_composite(img,layer)

def scanlines(img, spacing=3, alpha=22):
    layer=Image.new("RGBA",(S,S),(0,0,0,0)); d=ImageDraw.Draw(layer)
    for y in range(0,S,spacing): d.line([(0,y),(S,y)],fill=(0,0,0,alpha))
    return Image.alpha_composite(img,layer)

def ring(d,cx,cy,r,color,a,w=3): d.ellipse([cx-r,cy-r,cx+r,cy+r],outline=rgba(color,a),width=w)
def disc(d,cx,cy,r,color,a): d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=rgba(color,a))

def label(img, text, color=DIM, y=S-70, size=22, spacing=6):
    def fn(d):
        f=font(size); txt=" ".join(text) if spacing else text
        w=d.textlength(txt,font=f); d.text(((S-w)/2,y),txt,font=f,fill=rgba(color,230))
    return ink(img,fn,bloom=8,gain=0.5)

def finish(img,name):
    img=scanlines(img); p=os.path.join(OUT,name+".png"); img.convert("RGB").save(p); print(p)

# ---------------------------------------------------------------- 1. capsid
def capsid():
    img=lattice(ground()); cx=cy=S/2; R=170; rnd=Random(7)
    img=haze(img,lambda d:disc(d,cx,cy,R*1.4,GREEN,90),blur=90,gain=0.35)
    def spikes(d):
        for i in range(26):
            a=i/26*2*pi; L=R+62+rnd.randint(-10,14)
            x0,y0=cx+cos(a)*(R-4),cy+sin(a)*(R-4); x1,y1=cx+cos(a)*L,cy+sin(a)*L
            d.line([(x0,y0),(x1,y1)],fill=rgba(MUTED,230),width=5)
            disc(d,x1,y1,9,GREEN,255)
    def body(d):
        ring(d,cx,cy,R,GREEN,255,w=9); ring(d,cx,cy,R-34,MUTED,170,w=2)
        for i in range(14):
            a=i/14*2*pi+0.3; r=rnd.randint(30,105)
            disc(d,cx+cos(a)*r,cy+sin(a)*r,rnd.randint(6,13),GREEN,200)
        ring(d,cx,cy,52,GREEN,255,w=5)
    img=ink(img,spikes,bloom=14); img=ink(img,body,bloom=22)
    finish(label(img,"VIRION"),"capsid")

# ---------------------------------------------------------------- 2. biohazard trefoil (Nerd Font glyph, vector-true)
def trefoil():
    img=lattice(ground()); img=haze(img,lambda d:disc(d,S/2,S/2,300,GREEN,80),blur=110,gain=0.4)
    def glyph(d):
        f=font(560); g="\U000F00A7"; w=d.textlength(g,font=f)
        d.text(((S-w)/2,S/2-330),g,font=f,fill=rgba(GREEN,255))
    def rings(d):
        ring(d,S/2,S/2,335,MUTED,200,w=3); ring(d,S/2,S/2,352,SEL,255,w=8)
        for i in range(0,360,10):
            a=i*pi/180; L=18 if i%30==0 else 8
            d.line([(S/2+cos(a)*352,S/2+sin(a)*352),(S/2+cos(a)*(352+L),S/2+sin(a)*(352+L))],fill=rgba(MUTED,220),width=2)
    img=ink(img,rings,bloom=6,gain=0.4); img=ink(img,glyph,bloom=24,gain=0.7)
    finish(label(img,"BIOHAZARD",y=S-36,size=18),"trefoil")

# ---------------------------------------------------------------- 3. double helix
def helix():
    img=lattice(ground()); cx=S/2
    img=haze(img,lambda d:d.rectangle([cx-140,60,cx+140,S-60],fill=rgba(GREEN,70)),blur=90,gain=0.35)
    def strands(d):
        pts1=[];pts2=[]
        for y in range(70,S-70,4):
            t=(y-70)/120*pi; x=sin(t)*120
            pts1.append((cx+x,y)); pts2.append((cx-x,y))
        d.line(pts1,fill=rgba(GREEN,255),width=8,joint="curve"); d.line(pts2,fill=rgba(CYAN,230),width=8,joint="curve")
    def rungs(d):
        for y in range(90,S-70,30):
            t=(y-70)/120*pi; x=sin(t)*120; c=abs(cos(t))
            col=GREEN if c>0.5 else MUTED
            d.line([(cx+x,y),(cx-x,y)],fill=rgba(col,int(120+130*c)),width=3)
            disc(d,cx+x,y,5,GREEN,255); disc(d,cx-x,y,5,CYAN,255)
    def calls(d):
        f=font(18); rnd=Random(3); bases="ACGT"
        for i,y in enumerate(range(100,S-90,42)):
            d.text((cx+190,y-9),rnd.choice(bases)+rnd.choice(bases)+rnd.choice(bases),font=f,fill=rgba(DIM,200))
            d.text((cx-250,y-9),f"{i*3+1:03d}",font=f,fill=rgba(SEL,255))
    img=ink(img,rungs,bloom=10,gain=0.5); img=ink(img,strands,bloom=20); img=ink(img,calls,bloom=0)
    finish(img,"helix")

# ---------------------------------------------------------------- 4. petri / mitosis
def mitosis():
    img=lattice(ground()); cx=cy=S/2; R=300
    img=haze(img,lambda d:disc(d,cx,cy,R,GREEN,60),blur=80,gain=0.4)
    def dish(d):
        ring(d,cx,cy,R,MUTED,230,w=4); ring(d,cx,cy,R-16,SEL,255,w=2)
        for i in range(0,360,15):
            a=i*pi/180; d.line([(cx+cos(a)*(R-16),cy+sin(a)*(R-16)),(cx+cos(a)*(R-6),cy+sin(a)*(R-6))],fill=rgba(MUTED,200),width=2)
    def cells(d):
        for sx,col in ((-95,GREEN),(95,GREEN)):
            x=cx+sx
            d.ellipse([x-120,cy-100,x+120,cy+100],outline=rgba(col,255),width=7)
            ring(d,x,cy,38,CYAN,240,w=5); disc(d,x,cy,14,CYAN,255)
            rnd=Random(int(x))
            for _ in range(9):
                a=rnd.random()*2*pi; r=rnd.randint(50,85); disc(d,x+cos(a)*r,cy+sin(a)*r*0.8,rnd.randint(4,8),MUTED,220)
        d.line([(cx,cy-96),(cx,cy+96)],fill=rgba(GREEN,255),width=5)
    def membrane(d):
        d.ellipse([cx-235,cy-125,cx+235,cy+125],outline=rgba(MUTED,120),width=3)
    img=ink(img,dish,bloom=6,gain=0.4); img=ink(img,membrane,bloom=14,gain=0.5); img=ink(img,cells,bloom=20)
    finish(label(img,"MITOSIS"),"mitosis")

# ---------------------------------------------------------------- 5. containment reticle (HUD)
def reticle():
    img=lattice(ground()); cx=cy=S/2; R=290
    img=haze(img,lambda d:disc(d,cx,cy,160,GREEN,120),blur=70,gain=0.45)
    def hud(d):
        ring(d,cx,cy,R,GREEN,255,w=3); ring(d,cx,cy,R-30,MUTED,180,w=1)
        for i in range(0,360,5):
            a=i*pi/180; L=26 if i%45==0 else 10 if i%15==0 else 5
            d.line([(cx+cos(a)*(R-L),cy+sin(a)*(R-L)),(cx+cos(a)*R,cy+sin(a)*R)],fill=rgba(GREEN if i%45==0 else MUTED,240),width=2)
        # crosshair with a gap in the middle
        for (x0,y0,x1,y1) in ((cx-R-40,cy,cx-110,cy),(cx+110,cy,cx+R+40,cy),(cx,cy-R-40,cx,cy-110),(cx,cy+110,cx,cy+R+40)):
            d.line([(x0,y0),(x1,y1)],fill=rgba(MUTED,220),width=2)
        # corner brackets
        for sx in (-1,1):
            for sy in (-1,1):
                x=cx+sx*(R+60); y=cy+sy*(R+60)
                d.line([(x,y),(x-sx*40,y)],fill=rgba(GREEN,255),width=4); d.line([(x,y),(x,y-sy*40)],fill=rgba(GREEN,255),width=4)
    def subject(d):
        rnd=Random(11); r=78
        ring(d,cx,cy,r,GREEN,255,w=7)
        for i in range(16):
            a=i/16*2*pi; d.line([(cx+cos(a)*r,cy+sin(a)*r),(cx+cos(a)*(r+30),cy+sin(a)*(r+30))],fill=rgba(MUTED,240),width=4); disc(d,cx+cos(a)*(r+30),cy+sin(a)*(r+30),6,GREEN,255)
        for _ in range(7):
            a=rnd.random()*2*pi; rr=rnd.randint(15,50); disc(d,cx+cos(a)*rr,cy+sin(a)*rr,rnd.randint(5,9),GREEN,210)
    def text(d):
        f=font(20); fs=font(16)
        d.text((cx-R-40,cy-R-96),"BSL-4",font=f,fill=rgba(GREEN,255))
        d.text((cx-R-40,cy-R-70),SPECIMEN,font=fs,fill=rgba(DIM,230))
        t="LOCK"; w=d.textlength(t,font=f); d.text((cx+R+40-w,cy-R-96),t,font=f,fill=rgba(RED,255))
        t="● CONTAINED"; w=d.textlength(t,font=fs); d.text((cx+R+40-w,cy-R-70),t,font=fs,fill=rgba(DIM,230))
    img=ink(img,hud,bloom=8,gain=0.45); img=ink(img,subject,bloom=22); img=ink(img,text,bloom=6,gain=0.4)
    finish(img,"reticle")

def reticle_trefoil():
    img=lattice(ground()); cx=cy=S/2; R=290
    img=haze(img,lambda d:disc(d,cx,cy,170,GREEN,120),blur=70,gain=0.45)
    def hud(d):
        ring(d,cx,cy,R,GREEN,255,w=3); ring(d,cx,cy,R-30,MUTED,180,w=1)
        for i in range(0,360,5):
            a=i*pi/180; L=26 if i%45==0 else 10 if i%15==0 else 5
            d.line([(cx+cos(a)*(R-L),cy+sin(a)*(R-L)),(cx+cos(a)*R,cy+sin(a)*R)],fill=rgba(GREEN if i%45==0 else MUTED,240),width=2)
        for (x0,y0,x1,y1) in ((cx-R-40,cy,cx-150,cy),(cx+150,cy,cx+R+40,cy),(cx,cy-R-40,cx,cy-150),(cx,cy+150,cx,cy+R+40)):
            d.line([(x0,y0),(x1,y1)],fill=rgba(MUTED,220),width=2)
        for sx in (-1,1):
            for sy in (-1,1):
                x=cx+sx*(R+60); y=cy+sy*(R+60)
                d.line([(x,y),(x-sx*40,y)],fill=rgba(GREEN,255),width=4); d.line([(x,y),(x,y-sy*40)],fill=rgba(GREEN,255),width=4)
    def glyph(d):
        f=font(300); g="\U000F00A7"; bb=d.textbbox((0,0),g,font=f)
        d.text((cx-(bb[0]+bb[2])/2, cy-(bb[1]+bb[3])/2),g,font=f,fill=rgba(GREEN,255))
    def text(d):
        f=font(20); fs=font(16)
        d.text((cx-R-40,cy-R-106),"BSL-4",font=f,fill=rgba(GREEN,255))
        d.text((cx-R-40,cy-R-82),SPECIMEN,font=fs,fill=rgba(DIM,230))
        t="LOCK"; w=d.textlength(t,font=f); d.text((cx+R+40-w,cy-R-106),t,font=f,fill=rgba(RED,255))
        t="● CONTAINED"; w=d.textlength(t,font=fs); d.text((cx+R+40-w,cy-R-82),t,font=fs,fill=rgba(DIM,230))
    img=ink(img,hud,bloom=8,gain=0.45); img=ink(img,glyph,bloom=24,gain=0.7); img=ink(img,text,bloom=6,gain=0.4)
    finish(img,"reticle-trefoil")

# ---------------------------------------------------------------- 6. outbreak node graph
def outbreak():
    img=lattice(ground()); cx=cy=S/2; rnd=Random(5)
    nodes=[(cx,cy)]
    for i in range(8):
        a=i/8*2*pi+0.2; r=rnd.randint(190,270); nodes.append((cx+cos(a)*r,cy+sin(a)*r))
    for i in range(10):
        a=rnd.random()*2*pi; r=rnd.randint(300,360); nodes.append((cx+cos(a)*r,cy+sin(a)*r))
    img=haze(img,lambda d:disc(d,cx,cy,120,RED,120),blur=70,gain=0.5)
    def edges(d):
        for i in range(1,9): d.line([nodes[0],nodes[i]],fill=rgba(MUTED,220),width=2)
        for i in range(9,len(nodes)):
            j=rnd.randint(1,8); d.line([nodes[j],nodes[i]],fill=rgba(SEL,255),width=2)
    def dots(d):
        for i,(x,y) in enumerate(nodes):
            if i==0: ring(d,x,y,26,RED,255,w=4); disc(d,x,y,10,RED,255)
            elif i<9: ring(d,x,y,12,GREEN,255,w=3); disc(d,x,y,4,GREEN,255)
            else: disc(d,x,y,5,MUTED,230)
    def pulses(d):
        for r in (60,110,170): ring(d,cx,cy,r,RED,int(160-r*0.6),w=2)
    img=ink(img,edges,bloom=6,gain=0.4); img=ink(img,pulses,bloom=12,gain=0.5); img=ink(img,dots,bloom=18)
    finish(label(img,"OUTBREAK",color=RED),"outbreak")

# ---------------------------------------------------------------- 7. sariel, re-plated (existing duotone, ring + bloom)
def sariel(src):
    img=lattice(ground())
    por=Image.open(src).convert("L").resize((S,S))
    # duotone BG->GREEN via MUTED, then vignette to a circle so it sits in a dish like the others
    lut=[]
    for v in range(256):
        t=v/255
        if t<0.70: a=t/0.70; c=tuple(int(BG_DARK[i]+(SEL[i]-BG_DARK[i])*a) for i in range(3))
        elif t<0.90: a=(t-0.70)/0.20; c=tuple(int(SEL[i]+(MUTED[i]-SEL[i])*a) for i in range(3))
        else: a=(t-0.90)/0.10; c=tuple(int(MUTED[i]+(GREEN[i]-MUTED[i])*a) for i in range(3))
        lut.append(c)
    col=Image.new("RGB",(S,S)); px=col.load(); pp=por.load()
    for y in range(S):
        for x in range(S): px[x,y]=lut[pp[x,y]]
    mask=Image.new("L",(S,S),0); ImageDraw.Draw(mask).ellipse([70,70,S-70,S-70],fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(18))
    img=Image.composite(col.convert("RGBA"),img,mask)
    img=ink(img,lambda d:(ring(d,S/2,S/2,S/2-70,GREEN,255,w=4),ring(d,S/2,S/2,S/2-50,SEL,255,w=2)),bloom=14,gain=0.5)
    finish(img,"sariel")

if __name__=="__main__":
    os.makedirs(OUT,exist_ok=True)
    capsid(); trefoil(); helix(); mitosis(); reticle(); reticle_trefoil(); outbreak()
    src=os.path.expanduser("~/.config/fastfetch.disabled/sariel-source.jpeg")
    if os.path.exists(src): sariel(src)
