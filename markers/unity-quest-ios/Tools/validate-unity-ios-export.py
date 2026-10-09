#!/usr/bin/env python3
"""Guard actual iPhone build10 failures; static export checks, not device acceptance."""
import argparse
import pathlib
import re
parser = argparse.ArgumentParser()
parser.add_argument('--export', type=pathlib.Path)
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
settings = (root/'ios-unity/ProjectSettings/ProjectSettings.asset').read_text()
assert re.search(r'iPhone:\s+UNITY_XR_ARKIT_LOADER_ENABLED', settings), 'ARKit provider compile define absent'
assert re.search(r'stripEngineCode:\s+0', settings), 'Dynamically created primitive engine types may be stripped'
shader_meta = (root/'ios-unity/Assets/MarkerLab/MarkerSurface.shader.meta').read_text()
guid = re.search(r'guid: (\w+)',shader_meta).group(1)
graphics = (root/'ios-unity/ProjectSettings/GraphicsSettings.asset').read_text()
assert guid in graphics.split('m_AlwaysIncludedShaders:')[1].split('m_PreloadedShaders:')[0], 'Marker shader not explicitly retained'
link=(root/'ios-unity/Assets/MarkerLab/link.xml').read_text()
for dynamic_type in ('BoxCollider','SphereCollider','CapsuleCollider','MeshFilter','MeshRenderer'):
    assert 'UnityEngine.'+dynamic_type in link, 'Dynamic primitive managed preservation missing: '+dynamic_type
for name in ('MarkerInteraction.cs','PaperLearningMath.cs','IOSMarkerTracker.cs'):
    assert (root/'Assets/MarkerLab'/name).read_bytes()==(root/'ios-unity/Assets/MarkerLab'/name).read_bytes(), name+' slim source drift'
if args.export:
    export=args.export.resolve()
    archive=export/'Libraries/com.unity.xr.arkit/Runtime/iOS/Xcode2600/libUnityARKit.a'
    registration=export/'Libraries/com.unity.xr.arkit/Runtime/iOS/UnityARKit.m'
    assert archive.stat().st_size>100000, 'ARKit native archive absent'
    assert 'UnityARKit' in registration.read_text(), 'ARKit static registration source absent'
    project=(export/'Unity-iPhone.xcodeproj/project.pbxproj').read_text()
    assert 'libUnityARKit.a' in project and 'UnityARKit.m' in project, 'ARKit native link/registration absent'
    assert '$(DEVELOPER_DIR)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM_NAME)' in project, 'Xcode default Swift compatibility search path absent'
    assert 'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES' in project, 'Swift runtime embedding not configured'
    generated=(export/'Il2CppOutputProject/Source/il2cppOutput/Unity.XR.ARKit.cpp').read_text()
    assert 'UnityARKit_Session_Construct' in generated, 'Native ARKit APIs compiled as disabled stubs'
    physics=(export/'Il2CppOutputProject/Source/il2cppOutput/UnityEngine.PhysicsModule.cpp').read_text()
    assert 'SphereCollider' in physics and 'CapsuleCollider' in physics and 'BoxCollider' in physics, 'Dynamic primitive managed classes stripped'
    engine=(export/'Frameworks/UnityRuntime.framework/UnityRuntime').read_bytes()
    assert b'SphereCollider' in engine, 'SphereCollider absent from exported native engine'
    assert 'DEFAULT_CALL UnityARKit_Session_Construct' in generated, 'ARKit session construct must be actual native import, not managed stub'
print('PASS Unity iOS provider/primitive/shader/shared-source'+(' and actual native export' if args.export else '')+' integrity; not physical acceptance')
