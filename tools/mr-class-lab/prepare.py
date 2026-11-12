#!/usr/bin/env python3
"""Prepare the single classroom project using the existing marker engine.
No private assets, downloads, browser state or credentials are copied.
"""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / "markers/unity-quest-ios"
DEST = HERE / "unity"


def main():
    if not SOURCE.exists():
        manifest = HERE / "shared-source-manifest.json"
        if not manifest.is_file():
            raise SystemExit(
                "Use the full repository checkout or the verified prepared-project ZIP"
            )
        for record in json.loads(manifest.read_text()):
            target = (HERE / record["destination"]).resolve()
            if (
                not target.is_relative_to(HERE.resolve())
                or hashlib.sha256(target.read_bytes()).hexdigest() != record["sha256"]
            ):
                raise SystemExit("Prepared shared source failed integrity check")
        print("Verified existing prepared shared sources against manifest")
        return
    items = {
        "Assets/MarkerLab/MarkerBoard.cs": "Assets/SharedTracking/MarkerBoard.cs",
        "Assets/MarkerLab/MarkerCameraCalibration.cs": "Assets/SharedTracking/MarkerCameraCalibration.cs",
        "Assets/MarkerLab/MarkerPoseMath.cs": "Assets/SharedTracking/MarkerPoseMath.cs",
        "Assets/DedicatedTracker/MeasuredTrackingAccess.cs": "Assets/SharedTracking/MeasuredTrackingAccess.cs",
        "Assets/MarkerLab/Resources/marker-board.json": "Assets/SharedTracking/Resources/marker-board.json",
        "Native/marker_core.cpp": "Native/marker_core.cpp",
        "Native/marker_driver.cpp": "Native/marker_driver.cpp",
    }
    records = []
    for src, dst in items.items():
        original, target = SOURCE / src, DEST / dst
        data = original.read_bytes()
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() and target.read_bytes() != data:
            raise SystemExit(
                f"Changed generated source: {target}; reconcile before replacing"
            )
        target.write_bytes(data)
        records.append(
            {
                "source": str(original.relative_to(ROOT)),
                "destination": str(target.relative_to(HERE)),
                "sha256": hashlib.sha256(data).hexdigest(),
            }
        )
    (HERE / "shared-source-manifest.json").write_text(
        json.dumps(records, indent=2) + "\n"
    )
    print(f"Prepared {len(records)} exact shared tracking files")


if __name__ == "__main__":
    main()
