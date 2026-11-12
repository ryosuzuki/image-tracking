# Verification — Recorded Context Lab

Verified2026-11-12. Owner: Ryo's implementation agent. Integration target: `ryosuzuki/image-tracking`, `origin/main`; authoritative paths are this directory and `tools/recorded-context-lab/`, plus the root README entry. Existing recorder source, packages and recordings were not changed.

| Check | Observed result | Limit |
|---|---|---|
| Python capture adapter |6 regression tests pass, including source preservation, coordinate reflection, unsafe path rejection and no-overwrite |Normalized sessions only; not raw camera ZIP ingestion |
| New browser state tests |4 tests pass: irregular source time, backward reset, invalid data/path, identity checks |Numerical/state fixtures, not physical accuracy |
| Existing projection tests |4 tests pass, including off-center intrinsics and coordinate conversion |Math tests, not independent measured registration |
| Actual source data |Ada trial184 observations and an older Ryo Quest take915 observations prepared and loaded |Private sources not distributed in public Git |
| Browser behavior |Actual local files loaded; anchor positions retained over seeks; real button toggled/reset; text edited and downloaded; no JS page errors |No live object detector, hand contact, depth, model inference or network collaboration |
| Unity |Pinned6000.4.5f1 imported and executed actual private capture; three images rendered; camera pose, unchanged world point, backward seek and off-center matrix checked |Desktop replay, not new Quest APK or current stereo eye views |
| Visual QA |Actual browser/synthetic/private previews and Unity initial/active/reset frames inspected; initial large marker reduced to avoid unnecessary obstruction |Manual anchor seed, not surface hit or recognition; engine appearance differs |
| Video export |Actual browser MediaRecorder feature exercised; synthetic and private interactions exported, converted toMP4 and fully decoded; provenance caption rendered in output |Resampled derivative, no microphone; not extra sensor observations or physical test |
| Slides |28-slide native Google deck built from prior course template, notes included; all-page PDF overview inspected; original9 research embeds retained |Original author videos remain external references; copied embed does not establish fresh full playback verification |
| Privacy |Only synthetic screenshot and source/docs included; private frames and logs remain outside checkout |Local input access is user-authorized, not a sharing/consent service |

## Deliberately not claimed

This starter does not ingest hand/depth/mesh tracks, recognize physical objects, reproduce AgentHands, run a live AI agent, port annotations automatically into a different headset origin, or measure physical alignment. It does not supply a new accepted Quest APK. Acquisition uses the existing recorder and its own acceptance record; desktop replay and live execution are separate steps.

The teaching materials do not alter the official syllabus, assignment due dates, student submissions or prior lecture decks. The new slide draft is kept in the existing limited-access course working folder rather than broadening access to private media.
