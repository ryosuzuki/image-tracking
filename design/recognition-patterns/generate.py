"""Deterministic concept sketches, NOT encoded or validated tracking targets."""
from pathlib import Path
from html import escape
import random

ROOT = Path(__file__).resolve().parent
NAMES = ['Color-dot corners', 'Asymmetric black dots', 'Square fiducial',
         'Four independent corner tags', 'Hybrid tag + illustration',
         'Coded border', 'Detachable ID tab', 'Redundant tag strip',
         'Concentric ring code', 'Radial petal code', 'Asymmetric constellation',
         'Letterform mosaic', 'Nonrepeating texture frame', 'Illustrated feature map',
         'Multi-scale target', 'Split ID / pose card', 'Shared tabletop reference',
         'Folded multi-face target', 'Temporal screen code', 'IR / spectral pattern']

def rect(x,y,w,h,fill='#142d3b',rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" rx="{rx}"/>'
def circle(x,y,r,fill='#142d3b'):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>'
def line(x,y,a,b,color='#142d3b',width=3):
    return f'<path d="M{x} {y}L{a} {b}" stroke="{color}" stroke-width="{width}" fill="none"/>'
def text(x,y,s,size=12,color='#142d3b'):
    return f'<text x="{x}" y="{y}" font-family="Helvetica,Arial,sans-serif" font-size="{size}" fill="{color}">{escape(s)}</text>'
def tag(x,y,size,seed):
    # Deliberately schematic; no claim of a valid ArUco/AprilTag dictionary ID.
    r=random.Random(seed); unit=size/7
    s=rect(x,y,size,size)
    for row in range(1,6):
        for col in range(1,6):
            if r.getrandbits(1): s+=rect(x+col*unit,y+row*unit,unit,unit,'white')
    return s
def art():
    return ('<path d="M95 142L115 87L145 124L168 79L201 143Z" fill="#bfdccf"/>'
            +circle(179,99,11,'#e5ad47')+line(110,151,207,151,'#628b8f',2))
def pattern(n):
    s=rect(55,45,195,130,'#fff',5)
    if n==1:
        for x,y,c in [(69,59,'#e95949'),(236,59,'#28a684'),(236,161,'#397fdf'),(69,161,'#e7ae25')]: s+=circle(x,y,9,c)
    elif n==2:
        for x,y,r in [(70,60,10),(232,61,7),(232,160,11),(70,158,5)]: s+=circle(x,y,r)
    elif n==3: s+=tag(113,64,94,3)
    elif n==4:
        for k,(x,y) in enumerate([(61,51),(210,51),(210,135),(61,135)]): s+=tag(x,y,34,k+4)
    elif n==5: s+=art()+tag(61,51,32,5)+tag(211,136,32,6)
    elif n==6:
        r=random.Random(n)
        for i in range(32):
            if r.getrandbits(1): s+=rect(61+i*5.7,50,4,9)
            if r.getrandbits(1): s+=rect(61+i*5.7,161,4,9)
        for i in range(17):
            if r.getrandbits(1): s+=rect(60,61+i*5.7,9,4)
            if r.getrandbits(1): s+=rect(235,61+i*5.7,9,4)
    elif n==7: s+=art()+rect(240,75,44,49,'#e5ad47')+tag(247,82,30,7)
    elif n==8:
        for i in range(5): s+=tag(65+i*36,55,28,8+i)
        s+=text(76,147,'Redundant ID + pose',14)
    elif n==9:
        for r in [51,42,33,24,15]: s+=circle(154,110,r,'#142d3b' if r%2 else 'white')
        s+=rect(151,56,11,24,'#e5ad47')
    elif n==10:
        import math
        for i in range(9):
            a=i*2*math.pi/9; s+=circle(round(154+43*math.cos(a),2),round(110+43*math.sin(a),2),7 if i%3 else 12)
        s+=circle(154,110,10,'#e5ad47')
    elif n==11:
        pts=[(71,59),(127,66),(226,58),(94,105),(179,94),(228,145),(141,158),(68,160)]
        for x,y in pts: s+=circle(x,y,5)
        s+=line(71,59,127,66,'#b0c4cb',1)+line(127,66,179,94,'#b0c4cb',1)
    elif n==12:
        for x,y,t in [(70,82,'R7'),(172,80,'K2'),(92,132,'X9'),(189,157,'B4')]: s+=text(x,y,t,27)
    elif n==13:
        r=random.Random(n)
        for i in range(95):
            x=r.randrange(60,245); y=r.randrange(50,170)
            if x<83 or x>222 or y<72 or y>149: s+=line(x,y,x+r.randrange(-4,7),y+r.randrange(-4,7),'#142d3b',2)
    elif n==14:
        s+=art()+text(69,66,'A',13)+text(226,162,'B',17)+circle(78,128,9,'#df6c54')
        s+=line(68,154,99,79,'#427990',3)+line(209,76,236,106,'#427990',3)
    elif n==15: s+=tag(69,62,96,15)+tag(185,56,45,16)+tag(211,123,25,17)+tag(179,143,15,18)
    elif n==16:
        s+=tag(69,55,42,16)+text(121,82,'ID',16)
        for x,y in [(72,157),(228,157),(228,58)]: s+=circle(x,y,6)
        s+=line(120,100,201,145,'#427990',2)+text(121,121,'pose anchors',12)
    elif n==17:
        s=rect(35,40,235,145,'#bfdccf',8)
        for i,(x,y) in enumerate([(42,47),(234,47),(42,149),(234,149)]): s+=tag(x,y,28,17+i)
        s+=rect(92,73,51,77,'white')+rect(166,97,68,51,'white')+text(101,103,'A',18)+text(180,125,'B',18)
    elif n==18:
        s='<path d="M64 68L157 42L157 153L64 179Z" fill="#fff"/><path d="M157 42L244 69L244 179L157 153Z" fill="#bfdccf"/>'
        s+=tag(87,84,42,18)+tag(181,84,42,19)+line(157,42,157,153,'#628b8f',2)
    elif n==19:
        for i in range(3): s+=rect(58+i*64,75,56,72,'#e5eef2',3)+tag(65+i*64,87,42,19+i)+text(74+i*64,164,f't{i}',12)
    elif n==20:
        s+=text(70,74,'Visible: clean page',14)
        for x,y in [(72,99),(225,100),(225,159),(72,158)]: s+=circle(x,y,8,'#cbc8e4')
        s+=text(93,132,'IR layer (concept)',12,'#71638f')
    return s

def svg(body,w,h):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'

board=rect(0,0,1320,1350,'#edf3f5')+text(24,36,'20 recognition design concepts',27)
board+=text(24,61,'Schematic proposals, not detector-ready targets. Reliability has not been measured.',15)
for i,name in enumerate(NAMES,1):
    body=rect(0,0,312,232,'#e5eef2',8)+text(12,27,f'{i:02d}  {name}',15)+pattern(i)+text(12,215,'CONCEPT / NOT VALIDATED',10,'#5c737d')
    slug=name.lower().replace(' / ','-').replace(' + ','-').replace(' ','-')
    (ROOT/f'{i:02d}-{slug}.svg').write_text(svg(body,312,232))
    x=24+((i-1)%4)*324; y=85+((i-1)//4)*246
    board+=f'<g transform="translate({x} {y})">{body}</g>'
(ROOT/'recognition-patterns-20.svg').write_text(svg(board,1320,1350))
print('Generated 20 individual SVG concepts and one contact sheet.')
