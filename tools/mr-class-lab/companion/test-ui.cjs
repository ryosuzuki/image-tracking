const fs = require("fs");
const vm = require("vm");
const assert = require("assert/strict");
const { spawn } = require("child_process");
const path = require("path").join(__dirname, "index.html");
const html = fs.readFileSync(path, "utf8");
const source = html.match(/<script>([\s\S]*)<\/script>/)[1];
const delay = (ms) => new Promise((r) => setTimeout(r, ms));
const expectFixed = true;
const report = {
  method:
    "Node VM DOM harness, actual local HTTP relay; no browser/profile/desktop use",
  checks: [],
};
let processHandle;
async function start(port = 0) {
  processHandle = spawn(
    "python3",
    ["-B", require("path").join(__dirname, "relay_fixture.py"), String(port)],
    { stdio: ["ignore", "pipe", "pipe"] },
  );
  const serverPort = await new Promise((resolve, reject) => {
    processHandle.once("error", reject);
    processHandle.stdout.once("data", (data) =>
      resolve(Number(data.toString().trim())),
    );
    processHandle.stderr.once("data", (data) => reject(Error(data.toString())));
  });
  return `http://127.0.0.1:${serverPort}`;
}
async function stop() {
  const p = processHandle;
  await new Promise((resolve) => {
    p.once("exit", resolve);
    p.kill("SIGTERM");
  });
  processHandle = null;
}
function client(base) {
  const nodes = new Map();
  const intervals = [];
  const graphics = new Proxy(
    {},
    {
      get: (obj, key) => obj[key] || (() => {}),
      set: (obj, key, value) => {
        obj[key] = value;
        return true;
      },
    },
  );
  function get(id) {
    if (!nodes.has(id))
      nodes.set(id, {
        id,
        value: id === "room" ? "qa1234" : id === "color" ? "#42d7b0" : "",
        selectedIndex: 0,
        checked: false,
        textContent: "",
        append() {},
        getContext: () => graphics,
      });
    return nodes.get(id);
  }
  let holdNextPost = 0;
  let holdNextGet = 0;
  const ctx = vm.createContext({
    document: {
      getElementById: get,
      activeElement: null,
      createElement: (tag) => ({ tag, append() {}, click() {} }),
    },
    location: { origin: base, search: "" },
    URL,
    URLSearchParams,
    Blob,
    window: { addEventListener() {} },
    setInterval: (fn) => {
      intervals.push(fn);
      return intervals.length;
    },
    setTimeout,
    clearTimeout,
    fetch: async (url, options) => {
      const posting = options?.method === "POST";
      const wait = posting ? holdNextPost : holdNextGet;
      if (posting) holdNextPost = 0;
      else holdNextGet = 0;
      const result = await fetch(base + url, options);
      if (wait) await delay(wait);
      return result;
    },
  });
  vm.runInContext(source, ctx, { filename: path });
  get("room").value = "qa1234";
  return {
    get,
    run: (code) => vm.runInContext(code, ctx),
    poll: () => intervals[0](),
    holdPost: (ms) => (holdNextPost = ms),
    holdGet: (ms) => (holdNextGet = ms),
    state: () => JSON.parse(vm.runInContext("JSON.stringify(state)", ctx)),
  };
}
async function state(base) {
  return (await fetch(base + "/state?room=qa1234")).json();
}
async function post(base, value) {
  return (
    await fetch(base + "/state?room=qa1234", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(value),
    })
  ).json();
}
(async () => {
  let base = await start();
  const a = client(base),
    b = client(base);
  await a.run("connect()");
  await b.run("connect()");
  assert.equal(a.state().session, b.state().session);
  a.get("study").selectedIndex = 4;
  a.get("study").onchange();
  await delay(100);
  await b.poll();
  assert.equal(b.state().study, 4);
  a.get("x").value = ".35";
  a.get("x").oninput();
  await delay(160);
  await b.poll();
  assert.equal(b.state().x, 0.35);
  a.get("caption").value = "Local QA caption";
  a.get("translation").value = "Local supplied translation";
  a.get("captionSend").onclick();
  await delay(100);
  await b.poll();
  assert.equal(b.state().caption, "Local QA caption");
  assert.equal(b.state().translation, "Local supplied translation");
  report.checks.push({
    name: "two_client_study_slider_caption",
    pass: true,
    serverState: await state(base),
  });
  a.get("reset").onclick();
  await delay(100);
  await b.poll();
  assert.equal(b.state().x, 0);
  assert.equal(b.state().caption, "");
  report.checks.push({ name: "reset_visible_to_second_client", pass: true });
  a.get("study").selectedIndex = 0;
  a.get("study").onchange();
  await delay(100);
  a.holdPost(250);
  a.get("action").onclick();
  a.get("action").onclick();
  await delay(350);
  await b.poll();
  const observed = await state(base);
  report.checks.push({
    name: "rapid_actions_while_post_pending",
    pass: observed.book === 2,
    expectedBook: 2,
    actualBook: observed.book,
    clientBook: a.state().book,
    secondClientBook: b.state().book,
  });
  assert.equal(
    observed.book,
    expectFixed ? 2 : 1,
    expectFixed
      ? "Lost-action regression remains"
      : "Known lost-action bug did not reproduce",
  );
  // Slider mutates immediately but sends after an 80 ms debounce. A pending
  // action response that arrives inside that window must not erase the edit.
  a.holdPost(50);
  a.get("action").onclick();
  a.get("x").value = ".42";
  a.get("x").oninput();
  await delay(220);
  await b.poll();
  const sliderObserved = await state(base);
  report.checks.push({
    name: "slider_edit_inside_pending_post_debounce",
    pass: sliderObserved.x === 0.42,
    expectedX: 0.42,
    actualX: sliderObserved.x,
    clientX: a.state().x,
  });
  a.holdGet(150);
  const stalePoll = a.poll();
  await delay(25);
  a.get("action").onclick();
  await delay(75);
  const newest = await state(base);
  await stalePoll;
  report.checks.push({
    name: "older_poll_response_after_newer_post",
    pass: a.state().revision === newest.revision,
    expectedRevision: newest.revision,
    actualRevision: a.state().revision,
    expectedBook: newest.book,
    actualBook: a.state().book,
  });
  await a.poll();
  const old = a.state();
  await stop();
  await a.poll();
  assert.match(a.get("connection").textContent, /Connection lost/);
  report.checks.push({
    name: "stopped_relay_error",
    pass: true,
    text: a.get("connection").textContent,
  });
  base = await start(Number(new URL(base).port));
  // Bring fresh server to exactly the old revision, with a distinct scene.
  let fresh = await state(base);
  for (let i = 0; i < old.revision; i++)
    fresh = await post(base, {
      ...fresh,
      book: 4,
      caption: "Fresh relay state",
    });
  assert.equal(fresh.revision, old.revision);
  assert.notEqual(fresh.session, old.session);
  await a.poll();
  const after = a.state();
  report.checks.push({
    name: "relay_restart_equal_revision",
    pass: after.session === fresh.session,
    oldSession: old.session,
    newSession: fresh.session,
    clientSession: after.session,
    revision: fresh.revision,
    expectedBook: fresh.book,
    actualBook: after.book,
    connectionLabel: a.get("connection").textContent,
  });
  assert.equal(
    after.session,
    expectFixed ? fresh.session : old.session,
    expectFixed
      ? "Equal-revision restart regression remains"
      : "Known equal-revision restart bug did not reproduce",
  );
  if (expectFixed) assert.match(a.get("connection").textContent, /Connected/);
  // A new revision applies scene, proving the same client connection recovered transport.
  await post(base, { ...fresh, book: 3 });
  await a.poll();
  assert.equal(a.state().book, 3);
  assert.equal(a.state().session, fresh.session);
  report.checks.push({ name: "recovery_after_revision_changes", pass: true });
  await stop();
  assert.ok(
    report.checks.every((x) => x.pass),
    "A companion regression failed",
  );
  if (process.env.MR_CLASS_QA_REPORT)
    fs.writeFileSync(
      process.env.MR_CLASS_QA_REPORT,
      JSON.stringify(report, null, 2) + "\n",
    );
  console.log(JSON.stringify(report, null, 2));
})().catch(async (e) => {
  if (processHandle) await stop();
  console.error(e);
  process.exitCode = 1;
});
