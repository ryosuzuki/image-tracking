#!/usr/bin/env python3
"""Build authored actual-size SVG/PNG targets and A4/Letter PDFs. No device access."""
import argparse, hashlib, html, json
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
MM = 72 / 25.4

def primitives(kind, ident, contract):
    shapes = [('rect', (0, 0, 140, 140), '#ffffff')]
    if kind == 'aruco':
        source = REPO / f'markers/web-webxr/public/markers/aruco-{ident}.png'
        image = Image.open(source).convert('L')
        if image.size != (700, 700):
            raise ValueError('Unexpected source marker size')
        # Existing 700 px artwork: 50 px white quiet zone + 600 px 6x6 marker.
        for row in range(6):
            for col in range(6):
                if image.getpixel((100 + 100 * col, 100 + 100 * row)) < 128:
                    shapes.append(('rect', (10 + 20 * col, 10 + 20 * row, 20, 20), '#000000'))
    elif kind == 'dots':
        marker = next(m for m in contract['markers'] if m['id'] == ident)
        for frame, word in zip(contract['cornerFrames'], marker['cornerCodes']):
            cx, cy = [10 + 1000 * v for v in frame['center']]
            for j, color in enumerate(word):
                u, v = (j, 0) if j < 4 else (0, j - 3)
                spacing = contract['dotSpacingM'] * 1000
                x = cx + spacing * (u * frame['u'][0] + v * frame['v'][0])
                y = cy + spacing * (u * frame['u'][1] + v * frame['v'][1])
                shapes.append(('circle', (x, y, contract['dotRadiusM'] * 1000), contract['palette'][color]['hex']))
    elif kind == 'natural':
        # Authored asymmetric geometry, not a registered SDK image database.
        for i in range(27):
            x, y = 8 + ((i * 37) % 121), 8 + ((i * 53) % 121)
            if i % 2:
                shapes.append(('circle', (x, y, 2 + i % 5), ['#151515', '#245fe5', '#e53935'][i % 3]))
            else:
                shapes.append(('rect', (x, y, 4 + i % 7, 3 + i % 9), '#151515'))
        shapes.extend([('text', (18, 40, 11, 'IMAGE / 01'), '#151515'), ('text', (19, 108, 7, 'ASYMMETRY'), '#245fe5')])
    elif kind == 'negative':
        # Feature-poor uniform field. Page labels are outside the target.
        pass
    else:
        raise ValueError(kind)
    return shapes

def svg(shapes, w, h):
    result = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}mm" height="{h}mm" viewBox="0 0 {w} {h}">']
    for shape, values, color in shapes:
        if shape == 'rect':
            x, y, rw, rh = values
            result.append(f'<rect x="{x}" y="{y}" width="{rw}" height="{rh}" fill="{color}"/>')
        elif shape == 'circle':
            x, y, r = values
            result.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>')
        elif shape == 'text':
            x, y, size, text = values
            result.append(f'<text x="{x}" y="{y}" font-family="Arial,sans-serif" font-size="{size}" fill="{color}">{html.escape(text)}</text>')
    return ''.join(result) + '</svg>\n'

def shifted(shapes, dx, dy):
    return [(s, (v[0] + dx, v[1] + dy, *v[2:]), c) for s, v, c in shapes]

def raster(shapes, w=140, h=140, ppm=5):
    im = Image.new('RGB', (round(w * ppm), round(h * ppm)), 'white')
    draw = ImageDraw.Draw(im)
    for s, v, c in shapes:
        x, y = v[0] * ppm, v[1] * ppm
        if s == 'rect':
            draw.rectangle((x, y, x + v[2]*ppm - 1, y + v[3]*ppm - 1), fill=c)
        elif s == 'circle':
            r=v[2]*ppm
            draw.ellipse((x-r,y-r,x+r,y+r),fill=c)
        else:
            draw.text((x, y-v[2]*ppm), v[3], fill=c, font_size=round(v[2]*ppm))
    return im

def draw_pdf(canvas, shapes, h):
    from reportlab.lib.colors import HexColor
    for s, v, color in shapes:
        canvas.setFillColor(HexColor(color))
        x,y=v[0]*MM,(h-v[1])*MM
        if s=='rect':canvas.rect(x,y-v[3]*MM,v[2]*MM,v[3]*MM,stroke=0,fill=1)
        elif s=='circle':canvas.circle(x,y,v[2]*MM,stroke=0,fill=1)
        else:
            canvas.setFont('Helvetica',v[2]*MM)
            canvas.drawString(x,y,v[3])

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--pdf-output', type=Path, required=True, help='Explicit output path; PDFs are not committed to Git')
    a=p.parse_args()
    contract_path=REPO/'markers/web-webxr/marker-contract.json'
    contract=json.loads(contract_path.read_text())
    expected=(contract['cornerCenterExtentM'],contract['paperSizeM'],contract['dotSpacingM'],contract['dotRadiusM'],contract['aruco']['blackSquareSizeM'])
    if expected != (.12,.14,.008,.0024,.12):raise ValueError('Re-audit changed dimensions before generating')
    kit=[('aruco',7),('aruco',8),('dots',7),('dots',8),('natural',1),('negative',0)]
    manifest={'version':1,'units':'mm','actualSize':True,'physicalPrintingPerformed':False,'sourceContractSha256':hashlib.sha256(contract_path.read_bytes()).hexdigest(),'paperSizes':{'a4':[210,297],'letter':[215.9,279.4]},'targets':[]}
    for kind,ident in kit:
        name=f'{kind}-{ident}'
        shapes=primitives(kind,ident,contract)
        (HERE/f'{name}.svg').write_text(svg(shapes,140,140))
        raster(shapes).save(HERE/f'{name}.png')
        native='existing marker mode; physical stereo acceptance pending' if kind in ('aruco','dots') else 'not registered in native app; exercise/negative control only'
        mapping='Existing app: choose lesson manually. Proposed: molecule/card animation by unique ID.' if kind in ('aruco','dots') else 'Proposed natural-image training exercise' if kind=='natural' else 'Expect no marker in cropped target field'
        manifest['targets'].append({'name':name,'kind':kind,'id':ident if kind in ('aruco','dots') else None,'dictionary':'DICT_4X4_50' if kind=='aruco' else 'dot-aruco-20261009-v1' if kind=='dots' else None,'targetFieldMm':[140,140],'metricExtentMm':120 if kind in ('aruco','dots') else None,'metricDefinition':'outer black square' if kind=='aruco' else 'adjacent corner-center distance' if kind=='dots' else 'no calibrated tracking size','quietZoneMm':10 if kind=='aruco' else None,'currentNativeMode':native,'targetContentMapping':mapping})
    a.pdf_output.mkdir(parents=True,exist_ok=True)
    from reportlab.pdfgen.canvas import Canvas
    for paper,(w,h) in manifest['paperSizes'].items():
        canvas=Canvas(str(a.pdf_output/f'mr-image-tracking-kit-{paper}.pdf'),pagesize=(w*MM,h*MM),invariant=True)
        canvas.setTitle(f'MR Image Tracking Printable Kit v1 - {paper.upper()}')
        for target in manifest['targets']:
            name=target['name'];kind=target['kind'];ident=target['id'] or (1 if kind=='natural' else 0)
            x=(w-140)/2; y=56
            page=[('rect',(0,0,w,h),'#ffffff'),('text',(18,20,5,'MR Image Tracking / Printable Kit v1'),'#111111'),('text',(18,31,4,name.upper()),'#111111'),('text',(18,41,3,'ACTUAL SIZE / 100% / no fit-to-page / color for dots'),'#111111')]
            page+=shifted(primitives(kind,ident,contract),x,y)
            label='120 mm outer black square / DICT_4X4_50' if kind=='aruco' else '120 mm corner-center span / 8 mm spacing / 2.4 mm radius' if kind=='dots' else 'AUTHORED EXERCISE: not registered with native app' if kind=='natural' else 'NEGATIVE CONTROL: crop the white target field only'
            page.append(('text',(18,210,3,label),'#111111'))
            page.append(('text',(18,220,3,'Existing marker lesson is chosen manually; ID-to-model mapping is proposed.'),'#111111'))
            page.append(('text',(18,230,3,'Check the 100 mm ruler below with a physical ruler before testing.'),'#111111'))
            page.append(('rect',(18,239,100,.4),'#111111'))
            for i in range(11):
                page.append(('rect',(18+i*10,236,.3,6 if i%5==0 else 4),'#111111'))
            page.extend([('text',(18,249,3,'0'),'#111111'),('text',(111,249,3,'100 mm'),'#111111')])
            (HERE/f'{paper}-{name}.svg').write_text(svg(page,w,h))
            draw_pdf(canvas,page,h);canvas.showPage()
        canvas.save()
    manifest['pdfNames']=['mr-image-tracking-kit-a4.pdf','mr-image-tracking-kit-letter.pdf']
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(json.dumps({'targets':len(kit),'pagesPerPdf':len(kit),'pdfOutput':str(a.pdf_output)}))

if __name__=='__main__':main()
