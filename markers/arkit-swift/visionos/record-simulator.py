#!/usr/bin/env python3
"""Record the real visionOS Simulator framebuffer and mode-review stills."""
import argparse
import json
from pathlib import Path
import signal
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument("--device", default="DA9E3112-67AC-4DDE-8F42-776139F3E710")
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
bundle = "org.programmablereality.visionpaperlab"
root = Path(__file__).resolve().parent

def sim(*parts, **kwargs):
    return subprocess.run(["xcrun", "simctl", *parts], check=True, **kwargs)

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "--json"]))
matching = [(runtime, d) for runtime, ds in devices["devices"].items() for d in ds if d["udid"] == args.device]
if len(matching) != 1 or "xrOS" not in matching[0][0] or matching[0][1]["state"] != "Booted":
    raise SystemExit("Expected a booted visionOS / xrOS Simulator; refusing another platform.")
sim("install", args.device, str(root / "build/VisionPaperLab.app"))
subprocess.run(["xcrun", "simctl", "terminate", args.device, bundle], capture_output=True)
log = args.output / "record-simulator.log"
# CoreSimulator's IO service cannot write directly through the Storage volume symlink.
# Capture on the local filesystem, then copy finalized outputs to durable storage.
Path("/tmp/openclaw").mkdir(parents=True, exist_ok=True)
staging = Path(tempfile.mkdtemp(prefix="visionos-paper-lab-", dir="/tmp/openclaw"))
raw = staging / "visionos-paper-lab-raw.mov"
with log.open("w") as recording_log:
    recorder = subprocess.Popen(["xcrun", "simctl", "io", args.device, "recordVideo", "--codec=h264", "--force", str(raw)], stdout=recording_log, stderr=recording_log)
    try:
        deadline = time.monotonic() + 20
        while "Recording started" not in log.read_text():
            if recorder.poll() is not None or time.monotonic() > deadline:
                raise RuntimeError("Simulator recording did not start: " + log.read_text())
            time.sleep(0.1)
        sim("launch", args.device, bundle)
        container = Path(subprocess.check_output(["xcrun", "simctl", "get_app_container", args.device, bundle, "data"], text=True).strip())
        metrics = container / "Documents/visionos-demo-metrics.json"
        # Use the app's own elapsed clock; immersive-space startup is variable.
        # Installation may retain metrics from an earlier run, so first observe the reset.
        deadline = time.monotonic() + 25
        while True:
            try:
                if json.loads(metrics.read_text())[-1]["time"] < 2:
                    break
            except (FileNotFoundError, json.JSONDecodeError, IndexError):
                pass
            if time.monotonic() > deadline:
                raise RuntimeError("The immersive demo did not start / reset its clock.")
            time.sleep(0.1)
        stills = [(2,"math-aligned"), (11,"math-moving"), (17,"incline-released"), (25,"incline-moving"), (30,"pendulum-swing"), (38,"pendulum-moving"), (40.5,"trebuchet-prepared"), (43,"trebuchet-low-launch"), (49.5,"trebuchet-high-impact"), (58,"trebuchet-moving"), (62,"trebuchet-final")]
        for seconds, name in stills:
            deadline = time.monotonic() + 30
            while True:
                try:
                    if json.loads(metrics.read_text())[-1]["time"] >= seconds:
                        break
                except (json.JSONDecodeError, IndexError):
                    pass
                if time.monotonic() > deadline:
                    raise RuntimeError("The demo clock stopped before " + name)
                time.sleep(0.1)
            still = staging / (name + ".png")
            sim("io", args.device, "screenshot", str(still), capture_output=True)
            shutil.copy2(still, args.output / still.name)
            print(f"Captured {name} at {seconds}s", flush=True)
    finally:
        recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=30)
if recorder.returncode:
    raise SystemExit(f"Recorder failed ({recorder.returncode}): {log.read_text()}")
container = Path(subprocess.check_output(["xcrun", "simctl", "get_app_container", args.device, bundle, "data"], text=True).strip())
metrics = container / "Documents/visionos-demo-metrics.json"
(args.output / "visionos-demo-metrics.json").write_bytes(metrics.read_bytes())
(args.output / "simulator-device.json").write_text(json.dumps({"runtime":matching[0][0], **matching[0][1]}, indent=2) + "\n")
delivered = args.output / "visionos-paper-lab-raw.mov"
shutil.copy2(raw, delivered)
print("Finalized " + str(delivered), flush=True)
