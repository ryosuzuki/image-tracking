#!/usr/bin/env bash
set -euo pipefail
: "${ANDROID_NDK_ROOT:?Set Android NDK location}"
: "${VUFORIA_INCLUDE_DIR:?Set private official SDK include directory}"
: "${CMAKE_BIN:=cmake}"
root="$(cd "$(dirname "$0")/.." && pwd)"
"$CMAKE_BIN" -S "$root/Native" -B "$root/Native/build" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-29 -DANDROID_STL=c++_shared -DCMAKE_BUILD_TYPE=Release -DVUFORIA_INCLUDE_DIR="$VUFORIA_INCLUDE_DIR"
"$CMAKE_BIN" --build "$root/Native/build" --parallel 4
mkdir -p "$root/Assets/Plugins/Android/arm64-v8a"
cp "$root/Native/build/libquforia.so" "$root/Assets/Plugins/Android/arm64-v8a/"

runtime="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt"
runtime_file="$(find "$runtime" -path '*/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so' -print -quit)"
if [ -z "$runtime_file" ]; then echo "Android C++ shared runtime missing" >&2; exit 1; fi
cp "$runtime_file" "$root/Assets/Plugins/Android/arm64-v8a/"
