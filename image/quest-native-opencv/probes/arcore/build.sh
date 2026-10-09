#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
TASK_JDK="${TASK_JDK:-/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents/PlaybackEngines/AndroidPlayer/OpenJDK}"
TASK_SDK="${TASK_SDK:-/path/to/android-sdk}"
export JAVA_HOME="$TASK_JDK"
export PATH="$TASK_JDK/bin:$PATH"
BT="$TASK_SDK/build-tools/35.0.0"
ANDROID="$TASK_SDK/platforms/android-35/android.jar"
mkdir -p build/arcore-probe/deps build/arcore-probe/classes build/arcore-probe/dex build/arcore-probe/package/lib/arm64-v8a
AAR=build/arcore-probe/deps/arcore-1.53.0.aar
if [ ! -f "$AAR" ]; then curl -LsSf -o "$AAR" https://dl.google.com/dl/android/maven2/com/google/ar/core/1.53.0/core-1.53.0.aar;fi
EXPECTED=a1eae2d21dfc03862e1ed08a12bf4d522836ca9c4b55efbf6d3266230e406095
[ "$(shasum -a 256 "$AAR" | awk '{print $1}')" = "$EXPECTED" ] || { echo 'ARCore dependency hash mismatch'; exit 1; }
unzip -oq "$AAR" classes.jar 'jni/arm64-v8a/*' -d build/arcore-probe/deps/sdk
javac -source 8 -target 8 -classpath "$ANDROID:build/arcore-probe/deps/sdk/classes.jar" -d build/arcore-probe/classes probes/arcore/ProbeActivity.java
jar cf build/arcore-probe/app-classes.jar -C build/arcore-probe/classes .
"$BT/d8" --lib "$ANDROID" --min-api 29 --output build/arcore-probe/dex build/arcore-probe/app-classes.jar build/arcore-probe/deps/sdk/classes.jar
"$BT/aapt" package -f -M probes/arcore/AndroidManifest.xml -I "$ANDROID" -F build/arcore-probe/app-unsigned.apk
cp build/arcore-probe/dex/classes.dex build/arcore-probe/package/
cp build/arcore-probe/deps/sdk/jni/arm64-v8a/*.so build/arcore-probe/package/lib/arm64-v8a/
(cd build/arcore-probe/package && zip -qr ../app-unsigned.apk classes.dex lib)
"$BT/zipalign" -f 4 build/arcore-probe/app-unsigned.apk build/arcore-probe/app-aligned.apk
"$BT/apksigner" sign --ks /path/to/home/.android/debug.keystore --ks-pass pass:android --key-pass pass:android --out build/arcore-probe/quest-arcore-probe.apk build/arcore-probe/app-aligned.apk
"$BT/apksigner" verify build/arcore-probe/quest-arcore-probe.apk
shasum -a 256 build/arcore-probe/quest-arcore-probe.apk
