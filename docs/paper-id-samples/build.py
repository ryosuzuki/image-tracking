from pathlib import Path
import qrcode, html, json
from PIL import Image,ImageDraw,ImageFont
root=Path('/Users/ryosuzuki/Storage/projects/image-tracking/docs/paper-id-samples'); root.mkdir(parents=True,exist_ok=True)
out=Path('/Users/ryosuzuki/.openclaw/workspace/stuff/2026/2026-10-09'); out.mkdir(parents=True,exist_ok=True)
colors=['#dc3030','#176ec6','#e6aa00','#20894e']
families=[('余白QR','QR / margin'),('白黒固定セル','Mono / fixed cells'),('白黒点線','Mono / dashed'),('色の点線','Color / dashed'),('小型マス目','Custom / matrix'),('枠組み込み','Custom / border')]
labels=['右上','下中央','左余白','左右に同じID','上下に同じID']
font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',19)
small=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',14)
cards=[]; svgs=[]; rows=[]
for i in range(30):
 f,v=divmod(i,5); pid=f'paper-{i+1:03}'; im=Image.new('RGB',(360,440),'white'); d=ImageDraw.Draw(im); shapes=[]
 def rect(x,y,w,h,c='#111'):
  shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>'); d.rectangle((x,y,x+w-1,y+h-1),fill=c)
 def text(x,y,s,size=18,c='#777'):
  shapes.append(f'<text x="{x}" y="{y}" font-family="sans-serif" font-size="{size}" fill="{c}">{html.escape(s)}</text>'); d.text((x,y-size),s,font=font if size>14 else small,fill=c)
 # Consistent corner geometry; ID lives outside content rectangle.
 for x,y,sx,sy in [(22,22,1,1),(338,22,-1,1),(22,418,1,-1),(338,418,-1,-1)]:
  rect(x if sx==1 else x-30,y if sy==1 else y-6,30,6);rect(x if sx==1 else x-6,y if sy==1 else y-30,6,30)
 rect(67,113,226,1,'#ccc'); rect(67,351,226,1,'#ccc')
 text(80,158,'PAGE CONTENT',21)
 if not(f==0 and v in [2,3]): text(80,181,'Independent of ID',14)
 for n in range(7): rect(125 if f==0 and v in [2,3] else 80,205+n*17,110-(n%3)*12 if f==0 and v in [2,3] else 170-(n%3)*24,3,'#ddd')
 text(80,333,pid,18,'#333')
 bits=[int(c) for c in f'{i+1:08b}']; bits += [sum(bits)%2,1]
 if f==0:
  positions=[[(238,38)],[(142,357)],[(30,170)],[(30,170),(248,170)],[(142,32),(142,357)]][v]
  qr=qrcode.QRCode(version=1,error_correction=qrcode.constants.ERROR_CORRECT_M,box_size=1,border=4);qr.add_data(pid);qr.make(fit=False);m=qr.get_matrix(); scale=2.8
  for x,y in positions:
   # quiet zone explicitly white, total 81 px incl four-module border
   rect(x,y,82,82,'white')
   for yy,row in enumerate(m):
    for xx,b in enumerate(row):
     if b: rect(x+xx*scale,y+yy*scale,scale,scale)
  # Render exact QR into raster, avoiding fractional module rounding.
  for x,y in positions: im.paste(qr.make_image().convert('RGB').resize((87,87),Image.Resampling.NEAREST),(int(x),int(y)))
 elif f in (1,2,3):
  for n,b in enumerate(bits):
   if v==0: x,y=65+n*23,52; w,h=(17,17) if f==1 else (16,8)
   elif v==1: x,y=65+n*23,382;w,h=16,10
   elif v==2: x,y=37,74+n*28;w,h=10,19
   elif v==3: x,y=305,74+n*28;w,h=10,19
   else: x,y=(65+(n%5)*45,52 if n<5 else 382);w,h=28,10
   if f==3: rect(x,y,w,h,colors[(i+n*3)%4])
   elif b:rect(x,y,w,h)
   else:rect(x,y,w,h,'#ddd')
  rect(59,77,5,5) # orientation cue outside content
 elif f==4:
  x,y=[(267,43),(146,368),(22,174),(270,175),(146,38)][v];cell=8
  # conceptual matrix deliberately not QR/AprilTag; solid outer border and code cells
  rect(x,y,56,56)
  rect(x+cell,y+cell,40,40,'white')
  for n in range(25):
   if ((i+1)*37 >> (n%10))&1:rect(x+cell+(n%5)*cell,y+cell+(n//5)*cell,cell,cell)
 else:
  # explicit border-integrated variants: paired bits, colored pairs, repeated edge, segmented corners, wide/narrow.
  for n,b in enumerate(bits):
   if v==0:rect(62+n*24,30,14,7,'#111' if b else '#ddd')
   elif v==1:rect(62+n*24,30,14,7,colors[(i+n)%4]);rect(62+n*24,399,14,7,colors[(i+n)%4])
   elif v==2:rect(34,70+n*28,8,18,'#111' if b else '#ddd');rect(318,70+n*28,8,18,'#111' if b else '#ddd')
   elif v==3:
    x=65+(n%5)*46;y=30 if n<5 else 399;rect(x,y,27,7,'#111' if b else '#ddd')
   else:rect(65+n*23,30,16 if b else 6,12)
 text(24,435,f'{i+1:02}  {families[f][1]}',14,'#222')
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 440" role="img" aria-label="{pid}"><rect width="360" height="440" fill="white"/>'+''.join(shapes)+'</svg>'
 svgs.append(svg);cards.append(im)
 subtype=labels[v] if f==0 else ['上辺','下辺','左辺','右辺','分散／反復'][v]
 if f==5:subtype=['上辺二値','上下色反復','左右二値反復','上下分散','長短バー'][v]
 status='標準QR・読取対象' if f==0 else '独自案・読取器未実装'
 rows.append(f'<article data-family="{f}"><h2>{i+1:02} {families[f][0]} · {subtype}</h2>{svg}<p class="status">{status}</p><p>ID: <code>{pid}</code> · 中の画像はIDに無関係</p></article>')
page='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>紙IDの30案 — L字＋余白コード</title><style>*{box-sizing:border-box}body{font-family:system-ui,sans-serif;background:#f3f4f6;color:#222;margin:0;padding:24px}header{max-width:1050px;margin:auto}h1{font-size:26px}p{line-height:1.6}nav{display:flex;flex-wrap:wrap;gap:8px;margin:16px 0}button{padding:10px 16px;border:1px solid #bbb;background:white;border-radius:6px;cursor:pointer}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(270px,1fr));gap:20px;max-width:1500px;margin:auto}article{background:white;padding:16px;border-radius:8px}h2{font-size:16px}svg{width:100%;max-height:440px;border:1px solid #eee}.status{font-weight:600;font-size:14px}article p{font-size:13px}article[hidden]{display:none}@media print{body{background:white;padding:0}header{display:none}.grid{display:block}article{break-after:page;padding:0;border:0;width:190mm;height:275mm}svg{max-height:none;height:240mm}h2{margin:0}article p{margin:3px}}</style><header><h1>黒いL字＋紙ID：30種類の配置サンプル</h1><p>紙の位置は四隅の黒L字、IDは余白のコード。本文の画像マッチングは不要。最初の5案だけ標準QRです。残り25案は独自コードの見た目提案で、QR・AprilTag・ArUcoではありません。認識器や誤り訂正の実装・性能検証は未実施です。</p><p>QRの実機性能もこの配置では未検証。灰色セルは白セル位置の説明用で、実装時は白にします。印刷時は1枚につき1ページ。コードを切らずに余白ごと印刷してください。</p><nav><button onclick="filter(-1)">全30案</button>'''+''.join(f'<button onclick="filter({i})">{n[0]} × 5</button>' for i,n in enumerate(families))+'''<button onclick="window.print()">表示中の案を印刷／PDF保存</button></nav></header><main class="grid">'''+''.join(rows)+'''</main><script>function filter(n){document.querySelectorAll('article').forEach(a=>a.hidden=n>=0&&+a.dataset.family!==n)}</script></html>'''
(root/'index.html').write_text(page)
(root/'README.md').write_text('''# Paper ID placement samples\n\n30 visual concepts preserving four black L corners and page-content-independent IDs.\n5 standard version-1 QR samples contain paper-001 through paper-005; remaining 25 custom concepts do not yet have decoders and are not QR/AprilTag/ArUco. No physical-device performance claims are made.\n\nGallery is standalone inline HTML/SVG. Print stylesheet produces one card per page. Source generator is build.py; needs Pillow and qrcode.\n\nOwnership: thirty_id_samples. Integration target: origin/main. Authoritative path: docs/paper-id-samples/. Validation: 30 articles, 6 groups of 5; standard QR matrix generated by qrcode. Preview PNG and PDF outside repo in dated flat stuff directory.\n''')
(root/'build.py').write_text(Path(__file__).read_text())
# Six-by-five overview, English captions avoid raster font fallback.
thumbs=[]
for j,c in enumerate(cards):
 t=c.resize((252,308),Image.Resampling.LANCZOS);thumbs.append(t)
preview=Image.new('RGB',(6*272,5*336+65),'#e8ebef');pd=ImageDraw.Draw(preview);pd.text((20,15),'30 PAPER-ID IDEAS  |  5 standard QR + 25 untested custom concepts',font=font,fill='#111')
for j,t in enumerate(thumbs):f,v=divmod(j,5);preview.paste(t,(f*272+10,v*336+65))
preview.save(out/'paper-id-thirty-overview.png');cards[0].save(out/'paper-id-thirty-samples.pdf',save_all=True,append_images=cards[1:],resolution=60)
assert page.count('<article ')==30
print('Built 30 cards, 6 groups, overview and 30-page PDF.')
