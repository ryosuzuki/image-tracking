import * as THREE from "../capture-viewer/three.module.js";
import { projection } from "../capture-viewer/replay-math.mjs";
import { validateLab, frameIndex, activity } from "./model.mjs";
const el = (id) => document.getElementById(id),
  renderer = new THREE.WebGLRenderer({
    canvas: el("output"),
    alpha: true,
    antialias: true,
    preserveDrawingBuffer: true,
  });
renderer.setPixelRatio(1);
const scene = new THREE.Scene(),
  camera = new THREE.PerspectiveCamera(),
  objects = new THREE.Group();
scene.add(objects);
let lab,
  urls = new Map(),
  images = new Map(),
  time = 0,
  playing = false,
  manual = false,
  last = 0,
  mode = "note",
  serial = 0;
function texture(text) {
  const c = document.createElement("canvas");
  c.width = 768;
  c.height = 192;
  const d = c.getContext("2d");
  d.fillStyle = "#09202ce8";
  d.fillRect(0, 0, 768, 192);
  d.font = "bold 36px sans-serif";
  d.fillStyle = "white";
  for (let i = 0; i < 3; i++)
    d.fillText(text.slice(i * 32, (i + 1) * 32), 18, 50 + i * 48);
  return new THREE.CanvasTexture(c);
}
function rebuild() {
  while (objects.children.length) {
    const o = objects.children[0];
    o.geometry?.dispose();
    o.material?.map?.dispose();
    o.material?.dispose();
    objects.remove(o);
  }
  for (const a of lab.annotations) {
    const g = new THREE.Group();
    g.position.set(a.position[0], a.position[1], -a.position[2]);
    const sphere = new THREE.Mesh(
      new THREE.SphereGeometry(a.radius, 24, 12),
      new THREE.MeshBasicMaterial({ color: 0x5bd6a6, wireframe: true }),
    );
    g.add(sphere);
    const note = new THREE.Sprite(
      new THREE.SpriteMaterial({ map: texture(a.label), depthTest: true }),
    );
    note.scale.set(0.7, 0.175, 1);
    note.position.y = 0.22;
    g.add(note);
    g.userData = { annotation: a, sphere, note };
    objects.add(g);
  }
}
async function draw(t) {
  if (!lab) return;
  time = Math.max(0, Math.min(t, lab.frames.at(-1).time));
  const n = frameIndex(lab.frames, time),
    f = lab.frames[n],
    ticket = ++serial;
  let image = images.get(f.image);
  if (!image) {
    image = new Image();
    image.src = urls.get(f.image);
    await image.decode();
    images.set(f.image, image);
  }
  if (ticket !== serial) return;
  const k = lab.intrinsics;
  renderer.setSize(k.width, k.height, false);
  const bg = new THREE.Texture(image);
  bg.colorSpace = THREE.SRGBColorSpace;
  bg.needsUpdate = true;
  scene.background?.dispose();
  scene.background = bg;
  camera.projectionMatrix.fromArray(
    projection([k.fx, k.fy, k.cx, k.cy], k.width, k.height, 0.03, 50),
  );
  camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
  camera.position.set(f.position[0], f.position[1], -f.position[2]);
  camera.quaternion.set(
    -f.rotation[0],
    -f.rotation[1],
    f.rotation[2],
    f.rotation[3],
  );
  for (const o of objects.children) {
    const active =
      mode === "menu"
        ? manual
        : mode === "event" &&
          activity(time, o.userData.annotation) === "highlight";
    o.userData.sphere.material.color.set(active ? 0xffbf47 : 0x5bd6a6);
    o.userData.note.visible = mode !== "event" || active;
  }
  renderer.render(scene, camera);
  el("time").value = time;
  el("clock").textContent =
    `${time.toFixed(2)}s / ${lab.frames.at(-1).time.toFixed(2)}s`;
  el("badge").textContent = lab.synthetic
    ? "SYNTHETIC FIXTURE — not Quest footage"
    : `Recorded capture: ${lab.id}`;
  el("status").textContent =
    `Source frame ${n + 1}/${lab.frames.length} | ${f.image}\n${lab.provenance}\n${mode === "event" ? activity(time, lab.annotations[0]) : mode === "menu" ? "Button state: " + manual : "Static world anchor; no object-motion tracking"}`;
  window.labState = {
    time,
    frame: n,
    anchors: structuredClone(lab.annotations),
    manual,
    mode,
  };
}
async function load(data, fileURLs) {
  validateLab(data);
  for (const f of data.frames)
    if (!fileURLs.has(f.image)) throw Error("Missing image: " + f.image);
  for (const u of urls.values()) URL.revokeObjectURL(u);
  urls = fileURLs;
  images.clear();
  lab = data;
  manual = false;
  playing = false;
  time = 0;
  const a = lab.annotations[0];
  if (!a) throw Error("At least one authored anchor required");
  for (const [key, value] of [
    ["label", a.label],
    ["x", a.position[0]],
    ["y", a.position[1]],
    ["z", a.position[2]],
    ["trigger", a.triggerTime],
  ])
    el(key).value = value;
  el("time").max = lab.frames.at(-1).time;
  rebuild();
  await draw(0);
}
function report(error) {
  el("status").textContent = "Cannot load: " + error.message;
  playing = false;
}
el("files").onchange = async (e) => {
  try {
    const files = [...e.target.files],
      config = files.find((f) => f.name === "lab.json");
    if (!config) throw Error("No lab.json; run prepare_lab.py first");
    const prefix = config.webkitRelativePath.slice(0, -config.name.length),
      map = new Map();
    for (const f of files)
      if (f.webkitRelativePath.startsWith(prefix))
        map.set(
          f.webkitRelativePath.slice(prefix.length),
          URL.createObjectURL(f),
        );
    await load(JSON.parse(await config.text()), map);
  } catch (e) {
    report(e);
  }
};
el("sample").onclick = async () => {
  const c = document.createElement("canvas");
  c.width = 960;
  c.height = 720;
  const d = c.getContext("2d");
  d.fillStyle = "#263a43";
  d.fillRect(0, 0, 960, 720);
  d.strokeStyle = "#45616a";
  for (let x = 0; x < 960; x += 60) {
    d.beginPath();
    d.moveTo(x, 0);
    d.lineTo(x, 720);
    d.stroke();
  }
  for (let y = 0; y < 720; y += 60) {
    d.beginPath();
    d.moveTo(0, y);
    d.lineTo(960, y);
    d.stroke();
  }
  d.fillStyle = "white";
  d.font = "28px sans-serif";
  d.fillText("Synthetic calibration fixture — no physical room", 35, 650);
  const blob = await new Promise((r) => c.toBlob(r, "image/png"));
  const frames = Array.from({ length: 41 }, (_, i) => ({
    time: i / 5,
    position: [Math.sin((i / 40) * Math.PI * 2) * 0.15, 1.5, 0],
    rotation: [0, 0, 0, 1],
    image: "frames/sample.png",
  }));
  try {
    await load(
      {
        version: 1,
        id: "synthetic",
        synthetic: true,
        coordinateSystem: "unity-lh-y-up-meters",
        intrinsics: {
          width: 960,
          height: 720,
          fx: 680,
          fy: 680,
          cx: 470,
          cy: 355,
        },
        frames,
        annotations: [
          {
            id: "anchor-1",
            label: "A world-anchored note",
            position: [0, 1.5, 1.5],
            radius: 0.04,
            triggerTime: 3,
          },
        ],
        provenance:
          "Synthetic camera trajectory and authored geometry; no measured room or live AI.",
      },
      new Map([["frames/sample.png", URL.createObjectURL(blob)]]),
    );
  } catch (e) {
    report(e);
  }
};
el("play").onclick = () => {
  playing = !playing;
  el("play").textContent = playing ? "Pause" : "Play";
};
el("time").oninput = () => {
  playing = false;
  draw(+el("time").value).catch(report);
};
el("reset").onclick = () => {
  manual = false;
  playing = false;
  draw(0).catch(report);
};
el("mode").onchange = () => {
  mode = el("mode").value;
  manual = false;
  el("menu").hidden = mode !== "menu";
  draw(time).catch(report);
};
el("action").onclick = () => {
  manual = !manual;
  draw(time).catch(report);
};
el("apply").onclick = () => {
  if (!lab) return;
  const edited = structuredClone(lab);
  Object.assign(edited.annotations[0], {
    label: el("label").value,
    position: ["x", "y", "z"].map((x) => Number(el(x).value)),
    triggerTime: Number(el("trigger").value),
  });
  try {
    validateLab(edited);
    lab = edited;
    rebuild();
    draw(time).catch(report);
  } catch (e) {
    report(e);
  }
};
el("save").onclick = () => {
  if (!lab) return;
  const a = document.createElement("a"),
    u = URL.createObjectURL(
      new Blob([JSON.stringify(lab, null, 2)], { type: "application/json" }),
    );
  a.href = u;
  a.download = "lab.json";
  a.click();
  setTimeout(() => URL.revokeObjectURL(u), 1000);
};
function tick(now) {
  if (playing && lab) {
    const t = time + (now - last) / 1000;
    if (t > lab.frames.at(-1).time) {
      playing = false;
      el("play").textContent = "Play";
    } else draw(t).catch(report);
  }
  last = now;
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);
window.recordedContextLab = {
  load,
  draw,
  get data() {
    return lab;
  },
};

let recorder, recordStream;
el("record").onclick = () => {
  if (recorder?.state === "recording") {
    recorder.stop();
    return;
  }
  if (!lab) {
    report(Error("Load a capture first"));
    return;
  }
  if (!globalThis.MediaRecorder || !renderer.domElement.captureStream) {
    report(Error("Browser video recording unsupported"));
    return;
  }
  const type = [
    "video/webm;codecs=vp9",
    "video/webm;codecs=vp8",
    "video/webm",
  ].find((x) => MediaRecorder.isTypeSupported(x));
  if (!type) {
    report(Error("No supported WebM codec"));
    return;
  }
  const chunks = [],
    videoCanvas = document.createElement("canvas");
  videoCanvas.width = renderer.domElement.width;
  videoCanvas.height = renderer.domElement.height + 70;
  const ctx = videoCanvas.getContext("2d");
  function copy() {
    if (recorder?.state !== "recording") return;
    ctx.drawImage(renderer.domElement, 0, 0);
    ctx.fillStyle = "#0a1d25";
    ctx.fillRect(0, videoCanvas.height - 70, videoCanvas.width, 70);
    ctx.fillStyle = "white";
    ctx.font = "20px sans-serif";
    ctx.fillText(
      (lab.synthetic ? "SYNTHETIC FIXTURE" : "RECORDED " + lab.id) +
        " | source " +
        time.toFixed(2) +
        "s",
      15,
      videoCanvas.height - 42,
    );
    ctx.fillText(
      "Authored replay / browser input; no live Quest or AI; no audio",
      15,
      videoCanvas.height - 15,
    );
    requestAnimationFrame(copy);
  }
  recordStream = videoCanvas.captureStream(15);
  recorder = new MediaRecorder(recordStream, { mimeType: type });
  recorder.ondataavailable = (e) => {
    if (e.data.size) chunks.push(e.data);
  };
  recorder.onstop = () => {
    for (const t of recordStream.getTracks()) t.stop();
    el("record").textContent = "Record derivative WebM";
    const a = document.createElement("a"),
      u = URL.createObjectURL(new Blob(chunks, { type }));
    a.href = u;
    a.download = "authored-recorded-context.webm";
    a.click();
    setTimeout(() => URL.revokeObjectURL(u), 1000);
  };
  recorder.start();
  copy();
  el("record").textContent = "Stop and save WebM";
};
