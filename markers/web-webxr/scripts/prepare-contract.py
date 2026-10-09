import json,random,pathlib,math
root=pathlib.Path(__file__).resolve().parents[1]
rng=random.Random(20261009);words=[]
def swapped(w):return w[:1]+w[4:]+w[1:4]
def distance(a,b):return sum(x!=y for x,y in zip(a,b))
while len(words)<8:
 w=[rng.randrange(4) for _ in range(7)]
 if len(set(w))!=4 or distance(w,swapped(w))<4:continue
 if any(min(distance(w,q),distance(w,swapped(q)))<4 for q in words):continue
 words.append(w)
contract={'version':'dot-aruco-20261009-v1','description':'Independently implemented Dynamicland-inspired colored-dot L codes; not official Realtalk format.','cornerCenterExtentM':0.12,'paperSizeM':0.14,'dotSpacingM':0.008,'dotRadiusM':0.0024,'palette':[{'name':'red','hex':'#e53935'},{'name':'green','hex':'#19a85b'},{'name':'blue','hex':'#245fe5'},{'name':'black','hex':'#111111'}],'dotOrder':['center','u1','u2','u3','v1','v2','v3'],'cornerFrames':[{'corner':0,'center':[0,0],'u':[1,0],'v':[0,1]},{'corner':1,'center':[0.12,0],'u':[0,1],'v':[-1,0]},{'corner':2,'center':[0.12,0.12],'u':[-1,0],'v':[0,-1]},{'corner':3,'center':[0,0.12],'u':[0,-1],'v':[1,0]}],'markers':[{'id':id,'cornerCodes':words[n*4:n*4+4]} for n,id in enumerate([7,8])],'aruco':{'dictionary':'DICT_4X4_50','ids':[7,8],'blackSquareSizeM':0.12,'borderBits':1,'quietZoneM':0.01},'pose':{'coordinates':'camera: +x right, +y down, +z forward; marker: +x right,+y down,+z toward back of paper','fullPerspective':'require four decoded corners or at least4 independently identified non-collinear dot correspondences','intrinsics':'native measured intrinsics; browser uncalibrated by default (explicit) until matching calibration input; no fabricated camera-to-XR transform'},'tracking':{'displayHoldMs':650,'inputFreshMs':160,'oldEpochInvalidated':True},'scene':{'name':'interactive solar + cube','actions':['pause/resume','rotate','scale','explode/reset']}}
(root/'marker-contract.json').write_text(json.dumps(contract,indent=2)+'\n')
for m in contract['markers']:
 s=['<svg xmlns="http://www.w3.org/2000/svg" width="140mm" height="140mm" viewBox="0 0 140 140"><rect width="140" height="140" fill="white"/>']
 for cf,word in zip(contract['cornerFrames'],m['cornerCodes']):
  c=[10+1000*v for v in cf['center']]
  for j,color in enumerate(word):
   du=j if j<4 else 0;dv=j-3 if j>=4 else 0
   x=c[0]+8*(du*cf['u'][0]+dv*cf['v'][0]);y=c[1]+8*(du*cf['u'][1]+dv*cf['v'][1])
   s.append(f'<circle cx="{x:g}" cy="{y:g}" r="2.4" fill="{contract["palette"][color]["hex"]}"/>')
 s.append(f'<text x="70" y="67" text-anchor="middle" font-family="sans-serif" font-size="6" fill="#111">DOT {m["id"]}</text><text x="70" y="77" text-anchor="middle" font-family="sans-serif" font-size="3.2" fill="#444">120 mm corner-center extent</text></svg>')
 (root/f'public/markers/dots-{m["id"]}.svg').write_text(''.join(s))
print(json.dumps(contract['markers']));print(root/'marker-contract.json')
