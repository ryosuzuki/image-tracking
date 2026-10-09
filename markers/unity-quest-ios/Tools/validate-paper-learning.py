#!/usr/bin/env python3
"""Compile content and execute independent C# teaching-model checks; no device access."""
import argparse
import pathlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--unity-root', default='/Applications/Unity/Hub/Editor/6000.4.5f1/Unity.app/Contents')
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
unity = pathlib.Path(args.unity_root)
scripting = unity / 'Resources/Scripting'
references = scripting / 'UnityReferenceAssemblies/unity-4.8-api'
managed = unity / 'PlaybackEngines/MacStandaloneSupport/Variations/mono/Managed'
base = [str(scripting / 'NetCoreRuntime/dotnet'), str(scripting / 'DotNetSdkRoslyn/csc.dll'), '-nologo', '-nostdlib+']
base += ['-r:' + str(references / name) for name in ('mscorlib.dll', 'System.dll', 'System.Core.dll', 'Facades/netstandard.dll')]
staging = pathlib.Path('/tmp/openclaw/paper-model-validation')
staging.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(dir=staging) as directory:
    output = pathlib.Path(directory)
    subprocess.run(base + ['-target:library', '-out:' + str(output / 'content.dll')]
                   + ['-r:' + str(managed / name) for name in ('UnityEngine.CoreModule.dll', 'UnityEngine.TextRenderingModule.dll', 'UnityEngine.PhysicsModule.dll')]
                   + [str(root / 'Assets/MarkerLab/MarkerInteraction.cs'), str(root / 'Assets/MarkerLab/PaperLearningMath.cs')], check=True)
    subprocess.run(base + ['-define:PAPER_LEARNING_TEST', '-out:' + str(output / 'models.exe')]
                   + [str(root / 'Assets/MarkerLab/PaperLearningMath.cs'), str(root / 'Assets/MarkerLab/Tests/PaperLearningModelChecks.cs')], check=True)
    subprocess.run([str(scripting / 'MonoBleedingEdge/bin/mono'), str(output / 'models.exe')], check=True)
    calibration = root / 'Assets/MarkerLab/MarkerCameraCalibration.cs'
    if calibration.is_file():
        subprocess.run(base + ['-define:PAPER_CAMERA_TEST', '-out:' + str(output / 'camera.exe')]
                       + [str(calibration), str(root / 'Assets/MarkerLab/Tests/MarkerCameraCalibrationChecks.cs')], check=True)
        subprocess.run([str(scripting / 'MonoBleedingEdge/bin/mono'), str(output / 'camera.exe')], check=True)
print('Content compilation passed; mathematical checks are implementation evidence, not physical/stereo acceptance.')
