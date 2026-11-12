#!/usr/bin/env python3
"""Encode actual Unity verifier frames, with explicit replay/input provenance.
Never opens a camera, changes calibration or publishes personal recordings.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont

NAMES = [
    "Registered book guidance",
    "Physical stroke tutorial",
    "Captions from explicit input",
    "Wipe a 3D portal",
    "Screen to AR parameters",
    "Skinned avatar animation",
]


def run(args):
    result = subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(result.stderr.decode(errors="replace"))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("verification", type=Path)
    p.add_argument("output", type=Path)
    p.add_argument("--font", type=Path)
    a = p.parse_args()
    root = a.verification.resolve()
    report = json.loads((root / "verification.json").read_text())
    ids = sorted(set(row["capture"] for row in report["results"]))
    if a.output.exists():
        p.error("Use a new output directory")
    font = a.font or next(
        (
            x
            for x in [
                Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
            ]
            if x.is_file()
        ),
        None,
    )
    if not font or not shutil.which("ffmpeg"):
        p.error("ffmpeg and an explicit readable --font are required")
    a.output.mkdir(parents=True)
    manifest = {
        "kind": "actual Unity rendering over recorded Quest camera; authored programmatic inputs; measured source view held after 0.5s; not live AR or physical controller evidence",
        "fps": 10,
        "videos": [],
    }
    for capture in ids:
        source = (root / capture).resolve()
        if not source.is_relative_to(root):
            raise ValueError("Invalid capture output path")
        clips = []
        for study, title in enumerate(NAMES):
            frames = source / f"study-{study}-frames"
            if (
                len(list(frames.glob("*.png"))) != 60
                or not (frames / "source-frame-map.csv").is_file()
            ):
                raise ValueError("Missing exact 60-frame Unity render / source map")
            output = a.output / f"{capture}-study-{study}.mp4"
            text = f"{study+1:02d}  {title} / recorded camera + authored Unity behavior"
            bars = []
            with Image.open(frames / "0000.png") as first:
                width = first.width
            for phase, color in [
                ("Baseline / measured source view held after 0.5 s", "#95b9cf"),
                ("Test input applied / measured source view held / not live AR", "#73dfb9"),
                ("Reset / same measured source view", "#ffbc47"),
            ]:
                image = Image.new("RGB", (width, 100), "#0b1420")
                draw = ImageDraw.Draw(image)
                draw.text(
                    (24, 14), text, font=ImageFont.truetype(str(font), 24), fill="white"
                )
                draw.text(
                    (24, 51), phase, font=ImageFont.truetype(str(font), 20), fill=color
                )
                bar = a.output / f"{capture}-study-{study}-bar-{len(bars)}.png"
                image.save(bar)
                bars.append(bar)
            vf = "[0:v]pad=iw:ih+100:0:100:color=0x0b1420[base];[base][1:v]overlay=0:0:enable='lt(t,1.5)'[p1];[p1][2:v]overlay=0:0:enable='between(t,1.5,4.499)'[p2];[p2][3:v]overlay=0:0:enable='gte(t,4.5)'[out]"
            command = [
                "ffmpeg",
                "-v",
                "error",
                "-framerate",
                "10",
                "-i",
                str(frames / "%04d.png"),
            ]
            for bar in bars:
                command += ["-loop", "1", "-i", str(bar)]
            command += [
                "-filter_complex",
                vf,
                "-map",
                "[out]",
                "-frames:v",
                "60",
                "-r",
                "10",
                "-c:v",
                "libx264",
                "-preset",
                "fast",
                "-crf",
                "19",
                "-pix_fmt",
                "yuv420p",
                "-movflags",
                "+faststart",
                str(output),
            ]
            run(command)
            clips.append(output)
        listing = a.output / f"{capture}-concat.txt"
        listing.write_text(
            "".join(
                "file '" + str(path.resolve()).replace("'", "'\\''") + "'\n"
                for path in clips
            )
        )
        combined = a.output / f"{capture}-unity-component-replay.mp4"
        run(
            [
                "ffmpeg",
                "-v",
                "error",
                "-f",
                "concat",
                "-safe",
                "0",
                "-i",
                str(listing),
                "-c",
                "copy",
                "-movflags",
                "+faststart",
                str(combined),
            ]
        )
        run(["ffmpeg", "-v", "error", "-i", str(combined), "-f", "null", "-"])
        metadata = json.loads(
            subprocess.check_output(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-count_frames",
                    "-select_streams",
                    "v:0",
                    "-show_entries",
                    "stream=width,height,nb_read_frames:format=duration",
                    "-of",
                    "json",
                    str(combined),
                ]
            )
        )
        if int(metadata["streams"][0]["nb_read_frames"]) != 360:
            raise ValueError("Final replay video frame count differs")
        manifest["videos"].append(
            {
                "capture": capture,
                "path": str(combined.resolve()),
                "bytes": combined.stat().st_size,
                "sha256": hashlib.sha256(combined.read_bytes()).hexdigest(),
                "decode": "complete",
                "probe": metadata,
            }
        )
    (a.output / "video-verification.json").write_text(
        json.dumps(manifest, indent=2) + "\n"
    )
    print(
        json.dumps(
            {
                "videos": len(manifest["videos"]),
                "decode": "all complete",
                "frames_per_video": 360,
            }
        )
    )


if __name__ == "__main__":
    main()
