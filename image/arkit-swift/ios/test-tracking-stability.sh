#!/bin/zsh
set -eu
cd "${0:A:h}"
checks_dir=$(mktemp -d /tmp/openclaw-tracking-checks.XXXXXX)
xcrun swiftc Sources/TrackingStability.swift Tests/TrackingStabilityChecks.swift -o "$checks_dir/checks"
"$checks_dir/checks"
# Keep the small executable in /tmp as recoverable verification evidence.
