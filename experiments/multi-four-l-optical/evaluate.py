import cv2,numpy as np,json,pathlib,sys
from multi_detector import detect_multi
root=pathlib.Path(sys.argv[1]);rows=json.loads((root/'capture.json').read_text());out=[]
for r in rows:
 im=cv2.imread(str(root/f'{r["sample"]:04}.jpg'));q=detect_multi(im);t=r['hostElapsed'];expected=2 if t<12 or t>=25 else 4
 if 'overlap' in root.name:expected=2
 phase='overlap' if 'overlap' in root.name else ('two-static' if t<6 else 'two-motion' if t<12 else 'four-static' if t<18 else 'four-motion' if t<25 else 'overlap')
 out.append({'sample':r['sample'],'elapsed':t,'phase':phase,'expectedDisplayed':expected,'detected':len(q),'exactCount':len(q)==expected,'quads':[a.tolist() for a in q]})
(root/'multi-detections.json').write_text(json.dumps(out,indent=2));summary={}
for phase in dict.fromkeys(x['phase'] for x in out):
 ss=[x for x in out if x['phase']==phase];summary[phase]={'samples':len(ss),'exactCount':sum(x['exactCount'] for x in ss),'countHistogram':{str(n):sum(x['detected']==n for x in ss) for n in sorted(set(x['detected'] for x in ss))}}
(root/'multi-summary.json').write_text(json.dumps(summary,indent=2));print(summary)
