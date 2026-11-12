export function validateLab(s) {
  if (s.coordinateSystem !== "unity-lh-y-up-meters")
    throw Error("Unsupported coordinates; run prepare_lab.py");
  const k = s.intrinsics;
  if (
    !k ||
    !["width", "height", "fx", "fy", "cx", "cy"].every((x) =>
      Number.isFinite(k[x]),
    ) ||
    Math.min(k.width, k.height, k.fx, k.fy) <= 0
  )
    throw Error("Invalid calibration");
  let previous = -1;
  for (const f of s.frames) {
    if (!Number.isFinite(f.time) || f.time < 0 || f.time <= previous)
      throw Error("Invalid source timeline");
    previous = f.time;
    if (
      ![f.position, f.rotation].every(
        (p, i) =>
          Array.isArray(p) &&
          p.length === (i ? 4 : 3) &&
          p.every(Number.isFinite),
      )
    )
      throw Error("Invalid pose");
    if (Math.abs(Math.hypot(...f.rotation) - 1) > 0.02)
      throw Error("Invalid quaternion");
    if (!/^frames\/[\w.-]+\.(png|jpe?g)$/i.test(f.image))
      throw Error("Unsafe image path");
  }
  if (!s.frames.length) throw Error("Empty capture");
  const ids = new Set();
  for (const a of s.annotations) {
    if (ids.has(a.id)) throw Error("Duplicate anchor");
    ids.add(a.id);
    if (
      !Array.isArray(a.position) ||
      a.position.length !== 3 ||
      !a.position.every(Number.isFinite) ||
      !Number.isFinite(a.triggerTime) ||
      !Number.isFinite(a.radius) ||
      a.radius <= 0 ||
      a.radius > 2 ||
      typeof a.label !== "string" ||
      a.label.length > 240
    )
      throw Error("Invalid anchor");
  }
  return s;
}
export function frameIndex(frames, t) {
  let lo = 0,
    hi = frames.length;
  while (lo < hi) {
    const mid = (lo + hi) >> 1;
    if (frames[mid].time <= t) lo = mid + 1;
    else hi = mid;
  }
  return Math.max(0, lo - 1);
}
export function activity(t, a) {
  return t >= a.triggerTime ? "highlight" : "waiting";
}
