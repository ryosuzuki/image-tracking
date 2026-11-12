#!/usr/bin/env python3
"""Copy an explicitly supplied normalized capture into a private, offline lab.
Never searches private storage or uploads anything. Originals remain unchanged.
"""
import argparse, hashlib, json, math, shutil
from pathlib import Path


def vector(value, n):
    if (
        not isinstance(value, list)
        or len(value) != n
        or not all(isinstance(x, (int, float)) and math.isfinite(x) for x in value)
    ):
        raise ValueError("Invalid finite pose vector")
    return value


def prepare(source, destination):
    source = Path(source).resolve()
    destination = Path(destination).resolve()
    if destination.exists():
        raise ValueError("Use a new destination; never overwrite a capture")
    s = json.loads((source / "session.json").read_text())
    kind = s.get("coordinateSystem")
    if kind not in ["unity-lh-y-up-meters", "three-rh-y-up-meters-camera-minus-z"]:
        raise ValueError("Unsupported coordinate convention; no guessed transforms")
    k = s["intrinsics"]
    if (
        not all(
            isinstance(k.get(x), (int, float)) and math.isfinite(k[x])
            for x in ["width", "height", "fx", "fy", "cx", "cy"]
        )
        or min(k["width"], k["height"], k["fx"], k["fy"]) <= 0
    ):
        raise ValueError("Invalid calibration")
    rows = []
    previous = -1
    files = []
    for f in s["frames"]:
        t = f.get("time", f.get("t"))
        p = vector(f["position"], 3)[:]
        q = vector(f.get("rotation", f.get("quaternion")), 4)[:]
        if (
            not isinstance(t, (int, float))
            or not math.isfinite(t)
            or t < 0
            or t <= previous
        ):
            raise ValueError("Non-increasing capture time")
        if abs(math.sqrt(sum(x * x for x in q)) - 1) > 0.02:
            raise ValueError("Invalid unit quaternion")
        if kind.startswith("three"):
            p[2] = -p[2]
            q = [-q[0], -q[1], q[2], q[3]]
        rel = Path(f["image"])
        image = (source / rel).resolve()
        if (
            rel.is_absolute()
            or not image.is_relative_to(source)
            or image.suffix.lower() not in [".png", ".jpg", ".jpeg"]
        ):
            raise ValueError("Unsafe image path")
        if not image.is_file():
            raise ValueError("Missing source image")
        rows.append(
            {
                "time": t,
                "position": p,
                "rotation": q,
                "image": f"frames/{len(rows):05d}" + image.suffix.lower(),
            }
        )
        files.append(image)
        previous = t
    if not rows:
        raise ValueError("Empty capture")
    # Explicit manual seed, not a recognized object or measured surface.
    first = rows[0]
    x, y, z = first["position"]
    qx, qy, qz, qw = first["rotation"]
    forward = [
        2 * (qx * qz + qw * qy),
        2 * (qy * qz - qw * qx),
        1 - 2 * (qx * qx + qy * qy),
    ]
    anchor = [x + forward[0] * 1.2, y + forward[1] * 1.2, z + forward[2] * 1.2]
    output = {
        "version": 1,
        "id": s.get("id", s.get("name", source.name)),
        "synthetic": bool(s.get("synthetic", False)),
        "coordinateSystem": "unity-lh-y-up-meters",
        "intrinsics": k,
        "frames": rows,
        "annotations": [
            {
                "id": "anchor-1",
                "label": "Edit this anchored note",
                "position": anchor,
                "radius": 0.04,
                "triggerTime": rows[len(rows) // 2]["time"],
            }
        ],
        "provenance": "Recorded camera replay; annotation is manually authored. No recognition, hand/depth inference or live Quest claim.",
    }
    destination.mkdir(parents=True)
    (destination / "frames").mkdir()
    for f, image in zip(rows, files):
        shutil.copyfile(image, destination / f["image"])
    (destination / "lab.json").write_text(json.dumps(output, indent=2) + "\n")
    (destination / "source-receipt.json").write_text(
        json.dumps(
            {
                "sourceSessionSha256": hashlib.sha256(
                    (source / "session.json").read_bytes()
                ).hexdigest(),
                "sourceConvention": kind,
                "sourceFrames": len(rows),
                "sourceModified": False,
                "audioCopied": False,
                "handsCopied": False,
                "roomMeshCopied": False,
            },
            indent=2,
        )
        + "\n"
    )
    return output


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("source")
    p.add_argument("destination")
    a = p.parse_args()
    s = prepare(a.source, a.destination)
    print(
        json.dumps(
            {
                "frames": len(s["frames"]),
                "duration": s["frames"][-1]["time"],
                "coordinateSystem": s["coordinateSystem"],
            }
        )
    )
