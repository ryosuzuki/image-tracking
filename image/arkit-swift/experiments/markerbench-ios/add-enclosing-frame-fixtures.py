"""Generated contour-topology regressions; never live-camera evidence. Requires cv2."""
from pathlib import Path
import cv2,json,numpy as np
root=Path(__file__).parent/'fixtures'
manifest=json.loads((root/'manifest.json').read_text())
for source,name in [('dots-front','dots-enclosing-bezel-full'),('dots-occluded','dots-enclosing-bezel-three'),('dots-two-corners','dots-enclosing-bezel-two'),('dots-blank','dots-enclosing-bezel-blank')]:
 original=next(t for t in manifest['tests'] if t['name']==source)
 image=cv2.imread(str(root/original['file']))
 cv2.rectangle(image,(8,8),(image.shape[1]-9,image.shape[0]-9),(15,15,15),8)
 filename=name+'.png';cv2.imwrite(str(root/filename),image)
 item=dict(original,name=name,file=filename,source='generated-calibrated-projection-with-enclosing-dark-bezel-not-camera',synthetic=True)
 manifest['tests']=[t for t in manifest['tests'] if t['name']!=name]+[item]
name='aruco-disallowed-id15'
image=np.full((720,960,3),235,np.uint8)
marker=cv2.aruco.generateImageMarker(cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50),15,240)
image[240:480,360:600]=cv2.cvtColor(marker,cv2.COLOR_GRAY2BGR)
cv2.imwrite(str(root/(name+'.png')),image)
item={'name':name,'mode':'aruco','file':name+'.png','K':[1000,1000,480,360],'expectedID':None,'detectedDictionaryID':15,'synthetic':True,'source':'generated-valid-dictionaryID15-rejected-by-sharedcontract7and8-allowlist'}
manifest['tests']=[t for t in manifest['tests'] if t['name']!=name]+[item]
(root/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('Retained existing fixtures; added four enclosure checks and one disallowed-ID check')
