import tempfile,pathlib,json,unittest
from export_take import validate
class CaptureTest(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=pathlib.Path(self.tmp.name)
  (self.root/'calibration.json').write_text(json.dumps({'width':640,'height':480,'intrinsics':[500,500,281,219]}))
  (self.root/'capture.json').write_text(json.dumps({'schema':'paper-lab-capture-v1','complete':True,'frames':2}))
  self.rows=[{'image':f'frame-{i:05}.jpg','captureIndex':i,'epochMicroseconds':100+i,'sensorPosition':dict(x=0,y=0,z=0),'sensorRotation':dict(x=0,y=0,z=0,w=1),'headTracked':False} for i in range(2)]
  for r in self.rows:(self.root/r['image']).write_bytes(b'\xff\xd8\xff\xd9')
  self.write()
 def write(self):(self.root/'frames.jsonl').write_text('\n'.join(json.dumps(r) for r in self.rows))
 def tearDown(self):self.tmp.cleanup()
 def test_preserves_invalid_tracking_diagnostics_without_spatial_claim(self):self.assertEqual(len(validate(self.root)[1]),2)
 def test_rejects_timestamp_reuse(self):self.rows[1]['epochMicroseconds']=100;self.write();self.assertRaises(ValueError,validate,self.root)
 def test_rejects_wrong_frame_pair(self):self.rows[1]['image']='../room.jpg';self.write();self.assertRaises(ValueError,validate,self.root)
 def test_rejects_pose_nan(self):self.rows[0]['sensorPosition']['x']=float('nan');self.write();self.assertRaises(ValueError,validate,self.root)
 def test_rejects_incomplete(self):(self.root/'capture.json').write_text(json.dumps({'schema':'paper-lab-capture-v1','complete':False,'frames':2}));self.assertRaises(ValueError,validate,self.root)
 def test_rejects_missing_image(self):(self.root/self.rows[1]['image']).unlink();self.assertRaises(FileNotFoundError,validate,self.root)
if __name__=='__main__':unittest.main()
