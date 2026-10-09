#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
task_jdk=/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents/PlaybackEngines/AndroidPlayer/OpenJDK
task_sdk=/path/to/android-sdk
task_ndk=$task_sdk/ndk/27.2.12479018
task_opencv=/tmp/openclaw/dot-marker-unity/OpenCV-android-sdk
task_cc=$task_ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android29-clang++
task_bt=$task_sdk/build-tools/35.0.0
task_android=$task_sdk/platforms/android-35/android.jar
mkdir -p build/classes build/dex build/package/lib/arm64-v8a
cp "$task_ndk/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" build/package/lib/arm64-v8a/
cp "$task_opencv/sdk/native/libs/arm64-v8a/libopencv_java4.so" build/package/lib/arm64-v8a/
"$task_cc" -std=c++17 -shared -fPIC -O2 native/marker_core.cpp -I"$task_opencv/sdk/native/jni/include" -Lbuild/package/lib/arm64-v8a -lopencv_java4 -Wl,-soname,libmarker_core.so -o build/package/lib/arm64-v8a/libmarker_core.so
"$task_cc" -std=c++17 -shared -fPIC -O2 native/probe_jni.cpp -Lbuild/package/lib/arm64-v8a -lmarker_core -Wl,-soname,libprobe_jni.so -o build/package/lib/arm64-v8a/libprobe_jni.so
export JAVA_HOME=$task_jdk
export PATH="$task_jdk/bin:$PATH"
"$task_jdk/bin/javac" -source 8 -target 8 -classpath "$task_android" -d build/classes src/org/openclaw/questmarkeropticalprobe/*.java
"$task_jdk/bin/jar" cf build/app-classes.jar -C build/classes .
"$task_bt/d8" --lib "$task_android" --min-api 29 --output build/dex build/app-classes.jar
"$task_bt/aapt" package -f -M AndroidManifest.xml -I "$task_android" -A assets -F build/app-unsigned.apk
cp build/dex/classes.dex build/package/
(cd build/package && zip -q -r ../app-unsigned.apk classes.dex lib)
"$task_bt/zipalign" -f 4 build/app-unsigned.apk build/app-aligned.apk
"$task_bt/apksigner" sign --ks /path/to/home/.android/debug.keystore --ks-pass pass:android --key-pass pass:android --out build/quest-marker-optical-probe.apk build/app-aligned.apk
"$task_bt/apksigner" verify build/quest-marker-optical-probe.apk
shasum -a 256 build/quest-marker-optical-probe.apk native/marker_core.cpp assets/marker-contract.json
