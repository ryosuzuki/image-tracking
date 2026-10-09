import unittest,cv2,numpy as np
from four_l import page,detect
class Checks(unittest.TestCase):
 def test_page(self):self.assertEqual(len(detect(page())),4)
 def test_blank(self):self.assertIsNone(detect(np.full((600,800,3),255,np.uint8)))
 def test_hidden(self):
  im=page();cv2.rectangle(im,(100,80),(240,210),(255,255,255),-1);self.assertIsNone(detect(im))
 def test_two_pages(self):
  im=np.hstack([page(),page()]);self.assertIsNone(detect(im))
 def test_rotation(self):
  im=cv2.rotate(page(),cv2.ROTATE_180);self.assertEqual(len(detect(im)),4)
if __name__=='__main__':unittest.main()
