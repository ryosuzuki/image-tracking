# Recorded Context Lab — November 17, 2026

[Integrated slide draft](https://docs.google.com/presentation/d/1DbdiDnopds4HnkiJBAJIzfd56HetCuLEiJg8uDkgmcY/edit) · [Instructor run sheet](INSTRUCTOR.md) · [Observed verification](VERIFICATION.md)

**Build one situated interaction, not a gallery of pretend paper replicas.**

This joins the previous image/paper-tracking, reality-to-digital and AR+AI lectures. Start from a recorded physical context; author one anchored interaction; inspect exactly the same camera observations and anchor data in a browser and Unity. The core exercise runs without a headset, server or AI key. Quest is used to acquire context; deploying the new behavior back into live Quest MR is a separate acceptance step, not supplied by replay.

## One class, one deliverable

A pair submits **one 20–30 second interaction demo**, editable `lab.json`, a source change in Unity or JavaScript, and a short evidence sheet. Show before → actual input → visible change → reset. Name what was measured, manually authored, inferred, scripted, and still untested. A moving camera alone does not establish object tracking.

Choose one variation:

1. **Situated note:** put an instruction at a relevant world location. Move through the *recorded* viewpoints and verify parallax. Explain why it belongs there.
2. **Object action:** use the real browser/Unity button to change the annotation's highlight. This is a genuine prototype input, not recognized hand contact or live model reasoning.
3. **Timed assistance:** trigger the note at a source timestamp. Seek backward and verify it resets. This is an authored event, not a claim of proactive AI.

Keep the same context and annotation throughout. Replace one layer with real recognition, measured hand contact or a model only after the basic loop works.

## Start in five minutes

```sh
git clone https://github.com/ryosuzuki/image-tracking.git
cd image-tracking
python3 -m http.server 8080 --bind 127.0.0.1 --directory docs
```

Open `http://127.0.0.1:8080/recorded-context-lab/`. Click **Try the labeled synthetic fixture**. Play, pause, seek; change text/position; switch the three interaction modes. The fixture is **not a room recording or headset test**. No npm install is needed; the existing MIT-licensed Three.js copy is reused.

## Use a real capture, privately

Use only your own or explicitly permitted recording. An MP4 alone is insufficient for calibrated replay. You need the associated image exposures, camera pose, intrinsics and coordinate convention.

The converter accepts the two **existing normalized session** formats:

- AgentHands trial `session.json`: `unity-lh-y-up-meters`, `time`/`rotation`.
- Spatial Capture editor session: `three-rh-y-up-meters-camera-minus-z`, `t`/`quaternion`.

It does **not** accept a raw `.rgba`/ZIP or ordinary phone video directly. First use the owning recorder's importer. Do not invent depth or camera poses to make an MP4 appear compatible.

```sh
python3 tools/recorded-context-lab/prepare_lab.py \
  /absolute/private/normalized-session /absolute/private/new-lab-folder
```

Select the **new lab folder** in the viewer. It contains `lab.json`, `frames/` and a source receipt. Originals are not edited. Unknown coordinates, broken/missing image paths, non-unit rotations and invalid timestamps fail rather than being guessed. The initial annotation is a manual seed 1.2m in front of the first camera, **not a measured surface or recognized object**. Place it appropriately and explain your placement method.

Edit the note and its XYZ metre coordinates; click **Apply edit**. To continue in Unity, **Download lab.json**, then replace only the derived folder's `lab.json`. Keep a baseline copy for comparison. The same JSON is consumed by both implementations; meshes/fonts are deliberately not pixel-identical.

**Record derivative WebM** captures the prototype canvas locally; press Play, operate the real button, then stop/save. It captures no microphone audio. It is a resampled derivative, not a new higher-rate sensor capture. Source observations retain their original timestamps; preserve that distinction in your report.

## Open the Unity starter

1. Install **Unity 6000.4.5f1** in Unity Hub. Android Build Support is needed for the *existing Quest capture app*, not this desktop replay exercise.
2. Add/open `tools/recorded-context-lab/unity` as a project. Wait for import. The minimal project requires no paid assets, OpenCV or AI key.
3. Press Play. A missing-capture instruction is expected on a fresh clone.
4. Choose **Tools → Recorded Context Lab → Open capture in Play Mode**. Select the prepared private folder containing `lab.json`.
5. Use Play/Pause, the source-time slider, Note/Button/Time, Toggle highlight and Reset. Inspect `Assets/RecordedContext/RecordedContextPlayer.cs`.
6. Modify one action in `Seek()` or `OnGUI()`, not the calibration matrix. Retest at the same source timestamps and save your source diff.

The Unity project is a **desktop recorded-camera player**, not a new Quest APK and not live passthrough. The image is the recorded sensor viewpoint, not current stereo eye views. Its `lab.json` anchors can inform live placement, but coordinate origins must be registered; copying a matrix into a different headset session does not align rooms.

Command-line verification/render (explicit private paths):

```sh
MR_LAB_CAPTURE=/absolute/private/lab-folder \
MR_LAB_OUTPUT=/absolute/private/new-check-output \
/path/to/Unity -batchmode -quit \
  -projectPath tools/recorded-context-lab/unity \
  -buildTarget StandaloneOSX -executeMethod LabTools.Verify \
  -logFile /absolute/private/unity-check.log
```

## Where Quest and the previous lectures fit

- **Image tracking / printed paper:** [existing native capture APK and guide](../../tools/teaching-capture/README.md), [print kit](../lecture-hub/print-kit/), [paper-capture viewer](../capture-viewer/). This lightweight recorder has **no room mesh, hands, depth or microphone**. Its format is different; do not feed it to this converter.
- **Full recorded context:** [Spatial Capture recorder/editor](https://github.com/ryosuzuki/quest-spatial-studio). Preserve its own app/package/capture/import guide. Existing complete normalized sessions can be used here.
- **Object recognition:** [existing on-device Quest YOLO source](https://github.com/ryosuzuki/digital-twin/tree/main/implementations/quest-ondevice-yolo). Recognition, 3D localization and anchor persistence are separate capabilities. Do not call a fixed note an object recognizer.
- **Avatars:** use a properly licensed rigged character and its actual animation clip; start with the earlier Mixamo/Unity instructions. An avatar is an output representation, not inferred human motion.
- **AR+AI / AgentHands:** compare the original author video to the explicitly labeled local implementation. Source [Revive](https://github.com/ryosuzuki/revive). Not all paper features, model replacements or physical acceptance are established. Do not present a scripted classroom trigger as an autonomous agent.

## Before calling it successful

Run `node --test docs/recorded-context-lab/model.test.mjs` and `python3 -m unittest discover -s tools/recorded-context-lab -p 'test_*.py'`. Then verify actual visible output, not tests alone:

- Load the same permitted take in both engines. Check the same initial and later frame.
- Move in the recorded view: the authored world position must not move with the camera.
- Use the real button; reset; seek backward through the timed trigger.
- Save/reload `lab.json`; verify the edited text and coordinates persist.
- Record the exact capture ID, source timestamps, software revision, errors and limitations.
- For a **live** Quest claim, separately verify installation, permissions, normal room setup, head translation/rotation, look-away/return, registration, input and reset on the actual device. Replay is not that test.

No private frames, room coordinates, audio, transcripts, keys or device logs belong in this public repository. Public examples use only the labeled synthetic fixture. Keep student submissions and real-room media in the approved course-private workflow.
