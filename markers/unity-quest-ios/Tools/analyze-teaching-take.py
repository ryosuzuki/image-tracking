#!/usr/bin/env python3
"""Summarize private numeric marker telemetry; never certify optical/stereo accuracy."""
import argparse
import json
import math
from pathlib import Path


def summarize(records):
    last_stamp = None
    previous_sequence = None
    violations = []
    frames = detections = fresh = reliable = 0
    applications = set()
    timestamps = []
    for index, frame in enumerate(records):
        frames += 1
        sequence = frame.get("sequence")
        stamp = frame.get("imageTimestampNanoseconds")
        if not type(sequence) is int or (previous_sequence is not None and sequence <= previous_sequence):
            violations.append({"frame": index, "gate": "sequence-not-increasing"})
        previous_sequence = sequence if type(sequence) is int else previous_sequence
        if not type(stamp) is int or stamp <= 0 or (last_stamp is not None and stamp <= last_stamp):
            violations.append({"frame": index, "gate": "capture-time-not-increasing"})
        else:
            timestamps.append(stamp)
        last_stamp = stamp if type(stamp) is int else last_stamp
        age = frame.get("frameAgeSeconds")
        valid_age = isinstance(age, (int, float)) and math.isfinite(age) and -.01 <= age < .16
        target_id = frame.get("id")
        if type(target_id) is not int or target_id < -1:
            violations.append({"frame": index, "gate": "invalid-target-id"})
        identified = type(target_id) is int and target_id >= 0
        detections += frame.get("status") == 1
        fresh += identified
        reliable += frame.get("sessionReliable") is True
        if identified and not (frame.get("status") == 1 and frame.get("capturePoseValid") is True and valid_age):
            violations.append({"frame": index, "gate": "accepted-id-without-fresh-valid-pose"})
        if frame.get("controlsAllowed") is True and not (identified and frame.get("sessionReliable") is True):
            violations.append({"frame": index, "gate": "interaction-without-reliable-fresh-id"})
        # Unknown/missing flags do not count as a passed live-headset readiness gate.
        if frame.get("sessionReliable") is True and not all(frame.get(k) is True for k in ("hmdPresent", "headTracked", "cameraPlaying")):
            violations.append({"frame": index, "gate": "reliable-without-current-head-camera-flags"})
        application = frame.get("application")
        if isinstance(application, str):
            applications.add(application)
    return {
        "frames": frames,
        "detectorPositiveFrames": detections,
        "freshAcceptedIdFrames": fresh,
        "sessionReliableFrames": reliable,
        "applicationsObserved": sorted(applications),
        "captureSpanSeconds": (timestamps[-1] - timestamps[0]) / 1e9 if len(timestamps) > 1 else 0,
        "telemetryGate": "pass" if frames and not violations else "fail",
        "violations": violations,
        "physicalAcceptance": "unverified: numeric telemetry cannot establish correct ID, printed-paper accuracy, binocular alignment or actual interaction",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path, help="Private frames.jsonl from the teaching baseline")
    args = parser.parse_args()
    with args.frames.open() as stream:
        result = summarize(json.loads(line) for line in stream if line.strip())
    print(json.dumps(result, indent=2, allow_nan=False))
    return 0 if result["telemetryGate"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
