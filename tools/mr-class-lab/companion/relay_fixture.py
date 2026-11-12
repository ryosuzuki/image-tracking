import importlib.util
import sys
from pathlib import Path

source = Path(__file__).with_name("server.py")
spec = importlib.util.spec_from_file_location("mr_relay", source)
relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay)
server = relay.Relay(("127.0.0.1", int(sys.argv[1])), "qa1234")
print(server.server_port, flush=True)
server.serve_forever()
