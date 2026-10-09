#!/bin/bash
set -euo pipefail
task_cache="${MARKER_DEPS_CACHE:-/tmp/openclaw/dot-marker-unity}"
mkdir -p "$task_cache"
task_fetch() {
 local name="$1" digest="$2"
 if [ ! -f "$task_cache/$name" ]; then curl --fail --location --retry 2 "https://github.com/opencv/opencv/releases/download/4.12.0/$name" -o "$task_cache/$name"; fi
 printf '%s  %s\n' "$digest" "$task_cache/$name" | shasum -a 256 --check --status
}
task_fetch opencv-4.12.0-android-sdk.zip fd7f2332331b4eb8b67e55137281cfb16823c9399d90deb9cfa3476783b99e35
task_fetch opencv-4.12.0-ios-framework.zip 86b42c9f141cd9169b91be2fc380b0e556a88a95c98ccc8e7aef8349ab74cf70
unzip -oq "$task_cache/opencv-4.12.0-android-sdk.zip" -d "$task_cache"
mkdir -p "$task_cache/opencv-ios"
unzip -oq "$task_cache/opencv-4.12.0-ios-framework.zip" -d "$task_cache/opencv-ios"
printf 'Verified OpenCV4.12.0 dependencies in %s\n' "$task_cache"
