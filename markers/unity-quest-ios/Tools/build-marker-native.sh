#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
opencv_root="${MARKER_OPENCV_ANDROID:-/tmp/openclaw/dot-marker-unity/OpenCV-android-sdk}"
ndk_root="${MARKER_NDK:-/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents/PlaybackEngines/AndroidPlayer/NDK}"
task_compiler="$ndk_root/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android29-clang++"
task_dest="$task_root/Assets/MarkerLab/Plugins/Android/arm64-v8a"
mkdir -p "$task_dest" "$task_root/Builds"
cp "$ndk_root/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "$task_dest/"
cp "$opencv_root/sdk/native/libs/arm64-v8a/libopencv_java4.so" "$task_dest/"
"$task_compiler" -std=c++17 -shared -fPIC -O2 "$task_root/Native/marker_core.cpp" -I"$opencv_root/sdk/native/jni/include" -L"$task_dest" -lopencv_java4 -Wl,-soname,libmarker_core.so -o "$task_dest/libmarker_core.so"
"$task_compiler" -std=c++17 -O2 "$task_root/Native/marker_driver.cpp" -I"$opencv_root/sdk/native/jni/include" -L"$task_dest" -lopencv_java4 -lmarker_core -o "$task_root/Builds/marker-driver"
