import json, tempfile, unittest, math
from pathlib import Path
from prepare_lab import prepare


class CaptureContract(unittest.TestCase):
    def make(self, root, kind="unity-lh-y-up-meters"):
        root.mkdir()
        (root / "frame.jpg").write_bytes(b"explicit fixture bytes")
        s = {
            "id": "test",
            "synthetic": True,
            "coordinateSystem": kind,
            "intrinsics": {
                "width": 100,
                "height": 100,
                "fx": 80,
                "fy": 80,
                "cx": 45,
                "cy": 52,
            },
            "frames": [
                {
                    "time": 0,
                    "position": [0, 1, 0],
                    "rotation": [0, 0, 0, 1],
                    "image": "frame.jpg",
                },
                {
                    "time": 2,
                    "position": [0.2, 1, 0],
                    "rotation": [0, 0, 0, 1],
                    "image": "frame.jpg",
                },
            ],
        }
        (root / "session.json").write_text(json.dumps(s))
        return s

    def test_copies_source_timeline_and_bytes_without_modifying_original(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            self.make(r / "in")
            old = (r / "in/session.json").read_bytes()
            s = prepare(r / "in", r / "out")
            self.assertEqual(s["frames"][1]["time"], 2)
            self.assertEqual(
                (r / "out/frames/00001.jpg").read_bytes(), b"explicit fixture bytes"
            )
            self.assertEqual((r / "in/session.json").read_bytes(), old)

    def test_three_to_unity_reflection_not_double_transform(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            s = self.make(r / "in", "three-rh-y-up-meters-camera-minus-z")
            s["frames"][0]["position"] = [1, 2, -3]
            s["frames"][0]["rotation"] = [0, math.sin(0.2), 0, math.cos(0.2)]
            (r / "in/session.json").write_text(json.dumps(s))
            converted = prepare(r / "in", r / "out")
            self.assertEqual(converted["frames"][0]["position"], [1, 2, 3])
            self.assertAlmostEqual(
                converted["frames"][0]["rotation"][1], -math.sin(0.2)
            )

    def test_existing_output_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            self.make(r / "in")
            (r / "out").mkdir()
            with self.assertRaisesRegex(ValueError, "never overwrite"):
                prepare(r / "in", r / "out")

    def test_escaping_source_image_rejected_before_output(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            s = self.make(r / "in")
            (r / "outside.jpg").write_bytes(b"private")
            s["frames"][0]["image"] = "../outside.jpg"
            (r / "in/session.json").write_text(json.dumps(s))
            with self.assertRaisesRegex(ValueError, "Unsafe image"):
                prepare(r / "in", r / "out")
            self.assertFalse((r / "out").exists())

    def test_nonmonotonic_time_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            s = self.make(r / "in")
            s["frames"][1]["time"] = 0
            (r / "in/session.json").write_text(json.dumps(s))
            with self.assertRaisesRegex(ValueError, "Non-increasing"):
                prepare(r / "in", r / "out")

    def test_unknown_coordinates_not_guessed(self):
        with tempfile.TemporaryDirectory() as d:
            r = Path(d)
            self.make(r / "in", "unknown")
            with self.assertRaisesRegex(ValueError, "Unsupported"):
                prepare(r / "in", r / "out")


if __name__ == "__main__":
    unittest.main()
