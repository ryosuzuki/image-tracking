#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_JDK="${TASK_JDK:-/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents/PlaybackEngines/AndroidPlayer/OpenJDK}"
TASK_SDK="${TASK_SDK:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
export JAVA_HOME="$TASK_JDK"
export PATH="$TASK_JDK/bin:$PATH"
BT="$TASK_SDK/build-tools/35.0.0"
ANDROID="$TASK_SDK/platforms/android-35/android.jar"
mkdir -p build/deps build/classes build/dex build/package/lib/arm64-v8a
AAR=build/deps/opencv-4.12.0.aar
if [ ! -f "$AAR" ]; then curl -L --fail -o "$AAR" https://repo.maven.apache.org/maven2/org/opencv/opencv/4.12.0/opencv-4.12.0.aar; fi
EXPECTED=f71846a313388d9da667a59be1e921669fcf792d1ba264b3898253ca789bc3f0
ACTUAL=$(shasum -a 256 "$AAR" | awk '{print $1}')
[ "$ACTUAL" = "$EXPECTED" ] || { echo 'OpenCV dependency hash mismatch'; exit 1; }
unzip -o -q "$AAR" classes.jar 'jni/arm64-v8a/*' -d build/deps/opencv
javac -source 8 -target 8 -classpath "$ANDROID:build/deps/opencv/classes.jar" -d build/classes src/org/openclaw/questimagelab/*.java
jar cf build/app-classes.jar -C build/classes .
"$BT/d8" --lib "$ANDROID" --min-api 29 --output build/dex build/app-classes.jar build/deps/opencv/classes.jar
"$BT/aapt" package -f -M AndroidManifest.xml -I "$ANDROID" -A assets -F build/app-unsigned.apk
cp build/dex/classes.dex build/package/
cp build/deps/opencv/jni/arm64-v8a/*.so build/package/lib/arm64-v8a/
(cd build/package && zip -q -r ../app-unsigned.apk classes.dex lib)
"$BT/zipalign" -f 4 build/app-unsigned.apk build/app-aligned.apk
"$BT/apksigner" sign --ks "${TASK_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}" --ks-pass pass:android --key-pass pass:android --out build/quest-native-image-lab.apk build/app-aligned.apk
"$BT/apksigner" verify build/quest-native-image-lab.apk
shasum -a 256 build/quest-native-image-lab.apk
