#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p build/VisionPaperLab.app
xcrun swiftc -sdk "$(xcrun --sdk xrsimulator --show-sdk-path)" -target arm64-apple-xros2.0-simulator -emit-executable Sources/App.swift -o build/VisionPaperLab.app/VisionPaperLab -framework SwiftUI -framework RealityKit -framework UIKit -parse-as-library
cp Info.plist Resources/*.png build/VisionPaperLab.app/
codesign --force --sign - build/VisionPaperLab.app
