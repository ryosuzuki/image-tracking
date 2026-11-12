#!/usr/bin/env python3
"""Package only the prepared classroom source, redistributable assets and engine.
Explicit allowlist: never includes captures, editor caches, credentials or SDK auth.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

HERE = Path(__file__).resolve().parent
DIRECTORIES = [
    "unity/Assets/MRClass",
    "unity/Assets/SharedTracking",
    "unity/Assets/Plugins/Android/arm64-v8a",
    "unity/Native",
    "unity/Packages",
    "unity/ProjectSettings",
    "companion",
    "third-party",
]
FILES = [
    "README.md",
    "THIRD-PARTY.md",
    "prepare.py",
    "build-native.sh",
    "package.py",
    "render-videos.py",
    "requirements-tools.txt",
    "shared-source-manifest.json",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Use a new output; do not overwrite an existing delivery")
    for required in [
        "unity/Assets/Plugins/Android/arm64-v8a/libmarker_core.so",
        "unity/Assets/MRClass/Resources/ClassAvatar.glb",
    ]:
        if not (HERE / required).is_file():
            parser.error("Prepared runtime dependency missing: " + required)
    paths = [HERE / name for name in FILES]
    for name in DIRECTORIES:
        paths.extend(p for p in (HERE / name).rglob("*") if p.is_file())
    manifest = []
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, "x", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(set(paths)):
            if "__pycache__" in path.parts or path.name == ".DS_Store":
                continue
            if path.is_symlink() or any(
                word in path.name.lower()
                for word in ["devagentsettings", "keystore", ".jks", ".p12", ".pem"]
            ):
                raise ValueError("Disallowed package item: " + path.name)
            relative = str(path.relative_to(HERE))
            data = path.read_bytes()
            if relative == "README.md":
                data = data.replace(
                    b"../../docs/mr-class-lab/README.md",
                    b"https://github.com/ryosuzuki/image-tracking/tree/main/docs/mr-class-lab",
                )
            archive.writestr("mr-class-lab/" + relative, data)
            manifest.append(
                {
                    "path": relative,
                    "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(),
                }
            )
        archive.writestr(
            "mr-class-lab/package-manifest.json", json.dumps(manifest, indent=2) + "\n"
        )
    with zipfile.ZipFile(args.output) as archive:
        for record in manifest:
            if (
                hashlib.sha256(
                    archive.read("mr-class-lab/" + record["path"])
                ).hexdigest()
                != record["sha256"]
            ):
                raise ValueError("ZIP readback mismatch")
    print(
        json.dumps(
            {
                "files": len(manifest),
                "bytes": args.output.stat().st_size,
                "sha256": hashlib.sha256(args.output.read_bytes()).hexdigest(),
            }
        )
    )


if __name__ == "__main__":
    main()
