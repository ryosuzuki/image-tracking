#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/../.." && pwd)"
staging_dir=/tmp/openclaw/paper-suite-visualqa
mkdir -p "$staging_dir/VisualQA.app"
if [ "$#" -ne 1 ]; then echo 'Usage: render-simulator.sh simulator-udid (isolated, already booted)' >&2; exit 2; fi
simulator_id="$1"
python3 - "$staging_dir/VisualQA.app/Info.plist" <<'PY'
import plistlib,sys
with open(sys.argv[1],'wb') as f:
 plistlib.dump({'CFBundleIdentifier':'edu.colorado.paperlab.visualqa','CFBundleExecutable':'VisualQA','CFBundleName':'VisualQA','CFBundlePackageType':'APPL','MinimumOSVersion':'18.0','UILaunchScreen':{},'UIDeviceFamily':[1],'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False}},f)
PY
xcrun swiftc -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -target arm64-apple-ios18.0-simulator -parse-as-library "$project_dir/tools/native-paper/VisualQA.swift" "$project_dir/ios/Sources/PaperApplicationScene.swift" "$project_dir/ios/Sources/PaperApplicationState.swift" "$project_dir/ios/Sources/SourcePhysicsDynamics.swift" -o "$staging_dir/VisualQA.app/VisualQA"
codesign --force --sign - "$staging_dir/VisualQA.app"
xcrun simctl install "$simulator_id" "$staging_dir/VisualQA.app"
xcrun simctl launch "$simulator_id" edu.colorado.paperlab.visualqa
printf 'Twenty-three scene PNGs appear in app Documents after about 50 seconds. Simulator-only output.\n'
xcrun simctl get_app_container "$simulator_id" edu.colorado.paperlab.visualqa data
