#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p vendor
archive=$(mktemp /tmp/markerbench-opencv.XXXXXX.zip)
curl --fail --location --silent --show-error https://github.com/opencv/opencv/releases/download/4.12.0/opencv-4.12.0-ios-framework.zip -o "$archive"
printf '86b42c9f141cd9169b91be2fc380b0e556a88a95c98ccc8e7aef8349ab74cf70  %s\n' "$archive" | shasum -a 256 -c -
unzip -q -o "$archive" -d vendor
# Dependency archive remains a task temp artifact; framework is intentionally not committed.
