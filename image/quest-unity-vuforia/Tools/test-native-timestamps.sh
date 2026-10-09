#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_binary="$(mktemp /tmp/openclaw-vuforia-timestamps.XXXXXX)"
trap 'rm -f "$test_binary"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -I "$root/Native/src" \
  "$root/Native/tests/frame_timestamp_gate_test.cpp" -o "$test_binary"
"$test_binary"
echo 'Vuforia native timestamp gate: passed'
