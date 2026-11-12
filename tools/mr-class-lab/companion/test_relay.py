import importlib.util
import json
import threading
import unittest
import urllib.error
import urllib.request
import struct
import zlib
import random
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "relay", Path(__file__).with_name("server.py")
)
relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay)


class EndToEnd(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = relay.Relay(("127.0.0.1", 0), "class123")
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = "http://127.0.0.1:" + str(cls.server.server_port)

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, path="/state?room=class123", body=None, headers=None):
        req = urllib.request.Request(
            self.base + path,
            data=None if body is None else json.dumps(body).encode(),
            headers=headers or {},
        )
        with urllib.request.urlopen(req) as response:
            return json.load(response)

    def test_two_independent_clients_observe_state_and_revision(self):
        old = self.request()
        new = self.request(body=old | {"study": 4, "x": 0.35, "rotation": 64})
        observed = self.request()
        self.assertEqual(new, observed)
        self.assertEqual(observed["revision"], old["revision"] + 1)
        self.assertEqual(observed["x"], 0.35)

    def test_wrong_room_cannot_read_or_write(self):
        for body in [None, relay.DEFAULT]:
            with self.assertRaises(urllib.error.HTTPError) as cm:
                self.request("/state?room=other", body)
            self.assertEqual(cm.exception.code, 403)

    def test_malformed_state_does_not_mutate_scene(self):
        before = self.request()
        for patch in [
            {"x": float("nan")},
            {"study": 999},
            {"caption": "x" * 241},
            {"unexpected": "command"},
            {"animate": "true"},
        ]:
            with self.assertRaises(urllib.error.HTTPError) as cm:
                self.request(body=before | patch)
            self.assertEqual(cm.exception.code, 400)
            self.assertEqual(self.request(), before)

    def test_cross_origin_cannot_mutate(self):
        with self.assertRaises(urllib.error.HTTPError) as cm:
            self.request(body=relay.DEFAULT, headers={"Origin": "https://example.com"})
        self.assertEqual(cm.exception.code, 403)

    def test_texture_roundtrip_and_malformed_rejection(self):
        def chunk(tag, payload):
            return (
                struct.pack(">I", len(payload))
                + tag
                + payload
                + struct.pack(">I", zlib.crc32(tag + payload))
            )

        def png(w, h, pixels):
            rows = b"".join(
                b"\0" + pixels[y * w * 3 : (y + 1) * w * 3] for y in range(h)
            )
            return (
                b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(rows))
                + chunk(b"IEND", b"")
            )

        def post(data):
            request = urllib.request.Request(
                self.base + "/texture.png?room=class123",
                data=data,
                headers={"Content-Type": "image/png"},
            )
            with urllib.request.urlopen(request) as response:
                return json.load(response)

        for data in [
            png(2, 2, b"\xff\0\0" * 4),
            png(1024, 1024, random.Random(1126).randbytes(1024 * 1024 * 3)),
        ]:
            received = post(data)
            self.assertGreater(received["textureRevision"], 0)
            with urllib.request.urlopen(
                self.base + "/texture.png?room=class123"
            ) as response:
                self.assertEqual(response.read(), data)
        before = self.request()
        with self.assertRaises(urllib.error.HTTPError) as cm:
            post(b"\x89PNG\r\n\x1a\n" + b"not-ihdr" + struct.pack(">II", 1, 1))
        self.assertEqual(cm.exception.code, 400)
        self.assertEqual(self.request(), before)


if __name__ == "__main__":
    unittest.main()
