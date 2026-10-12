import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("analyzer", Path(__file__).with_name("analyze-teaching-take.py"))
analyzer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyzer)


class TelemetryGates(unittest.TestCase):
    def frame(self, **changes):
        row = dict(sequence=0, imageTimestampNanoseconds=1000000000,
                   frameAgeSeconds=.03, id=8, status=1, capturePoseValid=True,
                   controlsAllowed=True, sessionReliable=True, hmdPresent=True,
                   headTracked=True, cameraPlaying=True, application="Solar")
        row.update(changes)
        return row

    def test_fresh_stream_does_not_claim_physical_success(self):
        result = analyzer.summarize([self.frame(), self.frame(sequence=1, imageTimestampNanoseconds=1100000000)])
        self.assertEqual(result["telemetryGate"], "pass")
        self.assertEqual(result["captureSpanSeconds"], .1)
        self.assertIn("unverified", result["physicalAcceptance"])

    def test_stale_and_invalid_pose_rejected(self):
        for changes in ({"frameAgeSeconds": .2}, {"capturePoseValid": False}, {"frameAgeSeconds": float("nan")}):
            self.assertEqual(analyzer.summarize([self.frame(**changes)])["telemetryGate"], "fail")

    def test_duplicate_timestamp_rejected(self):
        self.assertEqual(analyzer.summarize([self.frame(), self.frame(sequence=1)])["telemetryGate"], "fail")

    def test_untracked_interaction_rejected(self):
        self.assertEqual(analyzer.summarize([self.frame(sessionReliable=False)])["telemetryGate"], "fail")

    def test_no_head_readiness_inferred(self):
        self.assertEqual(analyzer.summarize([self.frame(headTracked=False)])["telemetryGate"], "fail")

    def test_negative_detection_is_not_failure(self):
        result = analyzer.summarize([self.frame(id=-1, status=0, controlsAllowed=False)])
        self.assertEqual(result["telemetryGate"], "pass")
        self.assertEqual(result["freshAcceptedIdFrames"], 0)

    def test_malformed_time_is_rejected_without_inference(self):
        result = analyzer.summarize([self.frame(sequence="unknown", imageTimestampNanoseconds="unknown"), self.frame()])
        self.assertEqual(result["telemetryGate"], "fail")

    def test_invalid_field_types_do_not_poison_next_row(self):
        for field in ("sequence", "imageTimestampNanoseconds", "id"):
            for value in (None, True, False, "unknown", 1.5):
                with self.subTest(field=field, value=value):
                    bad = self.frame(**{field: value})
                    result = analyzer.summarize([bad, self.frame(sequence=1, imageTimestampNanoseconds=1100000000)])
                    self.assertEqual(result["telemetryGate"], "fail")
            bad = self.frame()
            del bad[field]
            self.assertEqual(analyzer.summarize([bad, self.frame(sequence=1, imageTimestampNanoseconds=1100000000)])["telemetryGate"], "fail")

    def test_empty_take_fails(self):
        self.assertEqual(analyzer.summarize([])["telemetryGate"], "fail")


if __name__ == "__main__":
    unittest.main()
