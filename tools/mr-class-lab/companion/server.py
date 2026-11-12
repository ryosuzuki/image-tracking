#!/usr/bin/env python3
"""Explicit local/LAN scene relay. No cloud, microphone capture or inference here."""
import argparse
import binascii
import hmac
import json
import math
import secrets
import struct
import threading
import zlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DEFAULT = dict(
    session="",
    revision=0,
    study=0,
    step=0,
    book=0,
    x=0,
    y=0,
    z=0,
    rotation=0,
    reveal=0,
    animate=False,
    caption="",
    translation="",
    captionSource="typed",
    color="#42d7b0",
    textureRevision=0,
)


def validate(value):
    if not isinstance(value, dict) or set(value) - set(DEFAULT):
        raise ValueError("Unknown scene fields")
    out = DEFAULT | value
    for key, lo, hi in [("study", 0, 5), ("step", 0, 3), ("book", 0, 4)]:
        if type(out[key]) is not int or not lo <= out[key] <= hi:
            raise ValueError(f"Invalid {key}")
    for key, lo, hi in [
        ("x", -0.6, 0.6),
        ("y", -0.3, 0.6),
        ("z", -0.4, 0.4),
        ("rotation", -36000, 36000),
        ("reveal", 0, 1),
    ]:
        v = out[key]
        if type(v) not in (int, float) or not math.isfinite(v) or not lo <= v <= hi:
            raise ValueError(f"Invalid {key}")
    if type(out["animate"]) is not bool:
        raise ValueError("Invalid animate")
    for key in ("caption", "translation"):
        if not isinstance(out[key], str) or len(out[key]) > 240:
            raise ValueError(f"Invalid {key}")
    if out["captionSource"] not in ("typed", "browser-speech", "authored-event"):
        raise ValueError("Invalid input source")
    c = out["color"]
    if (
        not isinstance(c, str)
        or len(c) != 7
        or c[0] != "#"
        or any(x not in "0123456789abcdefABCDEF" for x in c[1:])
    ):
        raise ValueError("Invalid color")
    return out


def validate_png(data):
    """Validate the bounded RGB/RGBA PNG emitted by the companion canvas."""
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Companion exports PNG only")
    pos, header, compressed, ended = 8, None, bytearray(), False
    while pos < len(data):
        if pos + 12 > len(data):
            raise ValueError("Truncated PNG chunk")
        size, kind = struct.unpack(">I4s", data[pos : pos + 8])
        end = pos + 12 + size
        if end > len(data):
            raise ValueError("Truncated PNG payload")
        payload = data[pos + 8 : pos + 8 + size]
        crc = struct.unpack(">I", data[pos + 8 + size : end])[0]
        if binascii.crc32(kind + payload) & 0xFFFFFFFF != crc:
            raise ValueError("Invalid PNG checksum")
        if header is None and kind != b"IHDR":
            raise ValueError("PNG header missing")
        if kind == b"IHDR":
            if header is not None or size != 13:
                raise ValueError("Invalid PNG header")
            width, height, depth, color, compression, filtering, interlace = (
                struct.unpack(">IIBBBBB", payload)
            )
            if (
                not 0 < width <= 2048
                or not 0 < height <= 2048
                or depth != 8
                or color not in (2, 6)
                or compression
                or filtering
                or interlace
            ):
                raise ValueError("Use a bounded, non-interlaced 8-bit RGB/RGBA PNG")
            header = (width, height, 3 if color == 2 else 4)
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            if size or end != len(data):
                raise ValueError("Invalid PNG end")
            ended = True
            break
        pos = end
    if not ended or not compressed or header is None:
        raise ValueError("Incomplete PNG")
    width, height, channels = header
    stride = width * channels + 1
    decoder = zlib.decompressobj()
    pixels = decoder.decompress(compressed, stride * height + 1)
    if (
        len(pixels) != stride * height
        or not decoder.eof
        or decoder.unused_data
        or any(pixels[i] > 4 for i in range(0, len(pixels), stride))
    ):
        raise ValueError("Invalid PNG image stream")


class Relay(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, room):
        super().__init__(address, Handler)
        self.room, self.state, self.texture, self.mime = (
            room,
            DEFAULT.copy(),
            None,
            "image/png",
        )
        self.state["session"] = secrets.token_hex(8)
        self.lock = threading.Lock()


class Handler(BaseHTTPRequestHandler):
    server_version = "MRClass/1"

    def setup(self):
        super().setup()
        self.connection.settimeout(4)

    def log_message(self, *_):
        pass  # No room codes, captions, provider tokens or personal text in logs.

    def send_data(self, code, data, mime="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(data)

    def reply(self, code, value):
        self.send_data(code, json.dumps(value, allow_nan=False).encode())

    def authorized(self):
        room = parse_qs(urlparse(self.path).query).get("room", [""])[0]
        return hmac.compare_digest(room.encode(), self.server.room.encode())

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            return self.send_data(
                200,
                Path(__file__).with_name("index.html").read_bytes(),
                "text/html; charset=utf-8",
            )
        if not self.authorized():
            return self.reply(403, {"error": "Enter the room code shown by this relay"})
        with self.server.lock:
            if path == "/state":
                return self.reply(200, self.server.state)
            if path == "/texture.png" and self.server.texture:
                return self.send_data(200, self.server.texture, self.server.mime)
        self.reply(404, {"error": "Not found"})

    def do_POST(self):
        if not self.authorized():
            return self.reply(403, {"error": "Wrong room code"})
        origin = self.headers.get("Origin")
        if origin and urlparse(origin).netloc != self.headers.get("Host"):
            return self.reply(403, {"error": "Cross-origin update rejected"})
        path = urlparse(self.path).path
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if size <= 0 or size > (8 * 1048576 if path == "/texture.png" else 8192):
                raise ValueError("Invalid body length")
            body = self.rfile.read(size)
            if len(body) != size:
                raise ValueError("Incomplete body")
            with self.server.lock:
                if path == "/state":
                    state = validate(json.loads(body))
                    state["revision"] = self.server.state["revision"] + 1
                    state["session"] = self.server.state["session"]
                    state["textureRevision"] = self.server.state["textureRevision"]
                    self.server.state = state
                    return self.reply(200, state)
                if path == "/texture.png":
                    validate_png(body)
                    self.server.texture = body
                    self.server.state["textureRevision"] += 1
                    self.server.state["revision"] += 1
                    return self.reply(200, self.server.state)
        except (
            ValueError,
            TypeError,
            KeyError,
            UnicodeError,
            struct.error,
            zlib.error,
        ) as exc:
            return self.reply(400, {"error": str(exc)})
        self.reply(404, {"error": "Not found"})


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bind", default="127.0.0.1")
    p.add_argument("--port", type=int, default=8897)
    p.add_argument("--room", default=None)
    p.add_argument(
        "--lan",
        action="store_true",
        help="Explicitly allow non-loopback binding on your classroom LAN",
    )
    a = p.parse_args()
    if a.bind not in ("127.0.0.1", "localhost", "::1") and not a.lan:
        p.error("Non-loopback binding requires --lan")
    room = a.room or secrets.token_hex(3)
    if not 4 <= len(room) <= 32 or not room.isalnum():
        p.error("Use an alphanumeric room code, 4–32 characters")
    server = Relay((a.bind, a.port), room)
    print(f"MR Class companion: http://{a.bind}:{a.port}/   room: {room}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
