#!/bin/bash
set -euo pipefail
if [ "$#" -ne 3 ]; then echo 'Usage: bash pull.sh SERIAL teaching-take-YYYYMMDD-HHMMSS-mmm LOCAL_DEST'; exit 2; fi
serial="$1"; take="$2"; dest="$3"
case "$take" in teaching-take-*) ;; *) echo 'Select an exact teaching-take directory'; exit 2;; esac
if [[ "$take" == *'/'* || "$take" == *'..'* ]]; then echo 'Invalid take'; exit 2; fi
adb -s "$serial" get-state | grep -qx device
if [ -e "$dest/$take" ]; then echo 'Destination exists; choose a new destination'; exit 2; fi
mkdir -p "$dest"
adb -s "$serial" pull "/sdcard/Android/data/org.openclaw.markertrackinglab/files/$take" "$dest/"
echo 'Original remains on Quest. No upload or deletion was performed.'
