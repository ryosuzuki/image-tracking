#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
for task_name in IOSMarkerTracker.cs MarkerBoard.cs MarkerInteraction.cs PaperLearningMath.cs MarkerPoseMath.cs MarkerSurface.shader; do
 cp "$task_root/Assets/MarkerLab/$task_name" "$task_root/ios-unity/Assets/MarkerLab/$task_name"
done
cp "$task_root/Assets/DedicatedTracker/MeasuredTrackingAccess.cs" "$task_root/ios-unity/Assets/MarkerLab/MeasuredTrackingAccess.cs"
cp "$task_root/Assets/MarkerLab/Resources/marker-board.json" "$task_root/ios-unity/Assets/MarkerLab/Resources/marker-board.json"
cp "$task_root/Assets/MarkerLab/Plugins/iOS/libmarker_core.a" "$task_root/ios-unity/Assets/MarkerLab/Plugins/iOS/"
cp "$task_root/Assets/MarkerLab/Plugins/iOS/libopencv2.a" "$task_root/ios-unity/Assets/MarkerLab/Plugins/iOS/"
