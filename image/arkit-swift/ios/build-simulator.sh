#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p build/PaperLab.app
xcrun swiftc -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -target arm64-apple-ios18.0-simulator -emit-executable Sources/*.swift -o build/PaperLab.app/PaperLab -framework UIKit -framework SceneKit -framework ARKit -parse-as-library
cp Info.plist Resources/*.png build/PaperLab.app/
if [ -d Resources/SciencePages ]; then cp -R Resources/SciencePages build/PaperLab.app/; fi
codesign --force --sign - build/PaperLab.app
