#!/usr/bin/env python3
"""Independent OpenCV dictionary and rendered-PDF checks; not a physical print test."""
import argparse, json, math, subprocess, tempfile
from pathlib import Path
import cv2
import fitz
import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
MM=72/25.4

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('pdf_output',type=Path);a=p.parse_args()
    manifest=json.loads((HERE/'manifest.json').read_text())
    web=json.loads((REPO/'markers/web-webxr/marker-contract.json').read_text())
    native=json.loads((REPO/'markers/unity-quest-ios/docs/marker-lab/marker-contract.json').read_text())
    assert web==native, 'Native/browser marker contract changed; re-audit'
    dictionary=cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
    detector=cv2.aruco.ArucoDetector(dictionary)
    cases=[]
    for target in manifest['targets']:
        pixels=np.asarray(Image.open(HERE/f'{target["name"]}.png').convert('RGB'))
        if target['kind']=='aruco':
            independent=cv2.aruco.generateImageMarker(dictionary,target['id'],600)
            assert np.array_equal(pixels[50:650,50:650,0],independent),'ArUco bits differ from independent OpenCV dictionary'
            _,ids,_=detector.detectMarkers(pixels)
            assert ids is not None and ids.flatten().tolist()==[target['id']]
        elif target['kind']=='negative':
            assert np.all(pixels==255), 'Negative target field is not blank'
        cases.append({'name':target['name'],'rgba':Image.fromarray(pixels).convert('RGBA').tobytes().hex(),'width':700,'height':700,'expected':target['id'] if target['kind']=='dots' else None,'testDots':target['kind'] in ('dots','negative')})
    for paper,(w,h) in manifest['paperSizes'].items():
        doc=fitz.open(a.pdf_output/f'mr-image-tracking-kit-{paper}.pdf')
        assert len(doc)==6
        for i,page in enumerate(doc):
            assert math.isclose(page.rect.width,w*MM,abs_tol=.002)
            assert math.isclose(page.rect.height,h*MM,abs_tol=.002)
            # Verify actual rendered target dimensions/identity rather than only source metadata.
            target=manifest['targets'][i]
            field=fitz.Rect((w-140)/2*MM,56*MM,(w+140)/2*MM,196*MM)
            pix=page.get_pixmap(matrix=fitz.Matrix(5/MM,5/MM),clip=field,alpha=False)
            im=np.frombuffer(pix.samples,np.uint8).reshape(pix.height,pix.width,pix.n)
            if target['kind']=='aruco':
                _,ids,_=detector.detectMarkers(im)
                assert ids is not None and ids.flatten().tolist()==[target['id']], 'PDF raster identity failed'
            # ReportLab PDF geometry contains an exact 100 mm x .4 mm ruler.
            rulers=[r for d in page.get_drawings() for r in d['items'] if r[0]=='re' and abs(r[1].width-100*MM)<.002 and abs(r[1].height-.4*MM)<.002]
            assert len(rulers)==1, 'PDF ruler geometry is not 100 mm'
            cases.append({'name':f'{paper}-{target["name"]}','rgba':Image.fromarray(im[:,:,:3]).convert('RGBA').tobytes().hex(),'width':pix.width,'height':pix.height,'expected':target['id'] if target['kind']=='dots' else None,'testDots':target['kind'] in ('dots','negative')})
    with tempfile.TemporaryDirectory(prefix='mr-kit-verify-') as tmp:
        inputs=Path(tmp)/'inputs.json';inputs.write_text(json.dumps(cases))
        js="""import fs from 'node:fs';import {ColoredDotsTracker} from './markers/web-webxr/src/colored-dots.js';const [contractPath,casesPath]=process.argv.slice(1);const tracker=new ColoredDotsTracker(JSON.parse(fs.readFileSync(contractPath)));for(const c of JSON.parse(fs.readFileSync(casesPath))){if(!c.testDots)continue;const observations=tracker.detect({width:c.width,height:c.height,data:new Uint8ClampedArray(Buffer.from(c.rgba,'hex'))});const ids=observations.map(o=>o.id);if(JSON.stringify(ids)!==JSON.stringify(c.expected===null?[]:[c.expected]))throw Error(c.name+': unexpected IDs '+ids);}console.log('Source and A4/Letter rendered-PDF dots/negative observations pass');"""
        subprocess.run(['node','--input-type=module','-e',js,str(REPO/'markers/web-webxr/marker-contract.json'),str(inputs)],cwd=REPO,check=True)
    print(json.dumps({'checks':['native/web contract equality','OpenCV independent ArUco7/8 bits and IDs','source and rendered-PDF colored-dot IDs','negative cropped target rejection','12 PDF page boxes and exact 100mm ruler'],'physicalPrinting':False,'liveTracking':False,'pages':12},indent=2))

if __name__=='__main__':main()
