import test from "node:test";
import assert from "node:assert/strict";
import { validateLab, frameIndex, activity } from "./model.mjs";
const sample = () => ({
  coordinateSystem: "unity-lh-y-up-meters",
  intrinsics: { width: 640, height: 480, fx: 400, fy: 410, cx: 310, cy: 250 },
  frames: [0, 0.11, 0.4].map((time) => ({
    time,
    position: [0, 1, 0],
    rotation: [0, 0, 0, 1],
    image: "frames/a.jpg",
  })),
  annotations: [
    {
      id: "one",
      label: "Note",
      position: [0, 1, 1],
      radius: 0.1,
      triggerTime: 0.2,
    },
  ],
});
test("irregular source observations are not fabricated/interpolated", () => {
  const s = validateLab(sample());
  assert.equal(frameIndex(s.frames, 0.3), 1);
  assert.equal(frameIndex(s.frames, -1), 0);
  assert.equal(frameIndex(s.frames, 10), 2);
});
test("backward seek deterministically resets authored event", () => {
  const a = sample().annotations[0];
  assert.equal(activity(0.4, a), "highlight");
  assert.equal(activity(0, a), "waiting");
});
test("private path and nonfinite poses rejected", () => {
  let s = sample();
  s.frames[0].image = "../private.jpg";
  assert.throws(() => validateLab(s), /Unsafe/);
  s = sample();
  s.frames[0].position[0] = NaN;
  assert.throws(() => validateLab(s), /pose/);
});
test("no guessed convention or duplicate identity", () => {
  let s = sample();
  s.coordinateSystem = "unknown";
  assert.throws(() => validateLab(s), /coordinates/);
  s = sample();
  s.annotations.push(s.annotations[0]);
  assert.throws(() => validateLab(s), /Duplicate/);
});
