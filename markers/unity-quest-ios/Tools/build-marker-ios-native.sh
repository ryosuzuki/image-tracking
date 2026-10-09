#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_framework="${MARKER_OPENCV_IOS:-/tmp/openclaw/dot-marker-unity/opencv-ios}"
task_build="/tmp/openclaw/dot-marker-unity/ios-native"
task_dest="$task_root/Assets/MarkerLab/Plugins/iOS"
mkdir -p "$task_build" "$task_dest"
xcrun --sdk iphoneos clang++ -target arm64-apple-ios16.0 -std=c++17 -O2 -F"$task_framework" -c "$task_root/Native/marker_core.cpp" -o "$task_build/core.o"
xcrun --sdk iphoneos clang++ -target arm64-apple-ios16.0 -std=c++17 -O2 -fobjc-arc -F"$task_framework" -c "$task_root/Native/marker_ios.mm" -o "$task_build/ios.o"
xcrun ar rcs "$task_dest/libmarker_core.a" "$task_build/core.o" "$task_build/ios.o"
xcrun lipo "$task_framework/opencv2.framework/opencv2" -thin arm64 -output "$task_dest/libopencv2.a"
