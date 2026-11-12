#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")" && pwd)"
task_cache="${MR_CLASS_DEPS:-/tmp/openclaw/mr-class-deps}"
task_ndk="${MR_CLASS_NDK:-/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents/PlaybackEngines/AndroidPlayer/NDK}"
python3 "$task_root/prepare.py"
mkdir -p "$task_cache"
task_zip="$task_cache/opencv-4.12.0-android-sdk.zip"
if [ ! -f "$task_zip" ]; then curl --fail --location --retry 2 https://github.com/opencv/opencv/releases/download/4.12.0/opencv-4.12.0-android-sdk.zip -o "$task_zip"; fi
printf '%s  %s\n' fd7f2332331b4eb8b67e55137281cfb16823c9399d90deb9cfa3476783b99e35 "$task_zip" | shasum -a 256 --check --status
if [ ! -d "$task_cache/OpenCV-android-sdk" ]; then unzip -oq "$task_zip" -d "$task_cache"; fi
task_compiler="$task_ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android29-clang++"
task_dest="$task_root/unity/Assets/Plugins/Android/arm64-v8a"
mkdir -p "$task_dest"
cp "$task_ndk/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" "$task_dest/"
cp "$task_cache/OpenCV-android-sdk/sdk/native/libs/arm64-v8a/libopencv_java4.so" "$task_dest/"
"$task_compiler" -std=c++17 -shared -fPIC -O2 "$task_root/unity/Native/marker_core.cpp" -I"$task_cache/OpenCV-android-sdk/sdk/native/jni/include" -L"$task_dest" -lopencv_java4 -Wl,-soname,libmarker_core.so -o "$task_dest/libmarker_core.so"
shasum -a 256 "$task_dest/"*.so
