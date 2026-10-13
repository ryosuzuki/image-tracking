# Natural image — Unity Quest

## Implementation

- Target form: **Natural image**
- Engine: **ARToolKitX / Meta XR**
- Platform: **Unity Quest**
- Upstream source: https://github.com/ryosuzuki/quest-artoolkit-stereo at `8ca0247edca4b50a8b872fe6eb6b15476c909b52`
- This is a separate source snapshot, not a submodule. Existing upstream repositories were not modified. Public release edits remove private environment/evidence and non-redistributable assets.

## Run

Run from this folder. For required private assets, see the root [asset instructions](../../ASSETS.md).

```sh
Unity -batchmode -nographics -quit -projectPath "$PWD" -executeMethod DedicatedBuild.Android -logFile /tmp/image-tracking-unity.log
```

Node projects use their pinned package-lock. Unity projects require Unity6000.4.5f1 and corresponding Android/iOS modules. Swift requires full Xcode and matching SDK. iOS physical builds require your own authorized signing configuration. Quest requires camera/headset-camera permission, valid positional tracking and supported camera hardware/runtime. No signing credentials or Vuforia licenses are included.

## Scope and acceptance

Stereo world-space source; physical alignment acceptance remains unverified in this organization task.

This consolidation validates copied source inventory, privacy gates and scoped software checks. It does not rerun physical camera, binocular, printed-paper or finger/controller acceptance. Historical upstream acceptance records are not reproduced as fresh evidence. The preserved app catalogs depend on optional private educational figures and generated models, which are deliberately not public.

## License

Original LICENSE, third-party licenses, legal notices and source headers are retained where present. If upstream has no top-level license, no new license is inferred. Dependencies retain their own terms; this repo does not relicense them.
