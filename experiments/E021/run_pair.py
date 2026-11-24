"""Run one HTTP/1.1 loopback control/cancellation pair against the built probe."""

import json
import os
from pathlib import Path
import selectors
import socket
import subprocess
import sys
import time


def remaining(deadline):
    return max(0, deadline - time.monotonic())


def read_request(connection, deadline):
    request = b""
    while b"\r\n\r\n" not in request and len(request) < 8192:
        connection.settimeout(remaining(deadline))
        chunk = connection.recv(4096)
        if not chunk:
            break
        request += chunk
    return request.startswith(b"GET /probe HTTP/1.1\r\n") and request.endswith(b"\r\n\r\n")


def collect(process, connection, cancel, deadline, observation):
    with selectors.DefaultSelector() as selector:
        selector.register(process.stdout, selectors.EVENT_READ, "client")
        if cancel:
            selector.register(connection, selectors.EVENT_READ, "peer")
        output = b""
        while selector.get_map() and (seconds := remaining(deadline)) > 0:
            for key, _ in selector.select(seconds):
                if key.data == "client":
                    chunk = os.read(process.stdout.fileno(), 4096)
                    output += chunk
                    if not chunk or b"\n" in output or len(output) >= 8192:
                        selector.unregister(process.stdout)
                        if b"\n" in output:
                            observation["client"] = json.loads(output)
                else:
                    try:
                        data = connection.recv(1024)
                    except ConnectionResetError:
                        observation["peer"] = "reset"
                    else:
                        observation["peer"] = "data" if data else "eof"
                    selector.unregister(connection)


def run_case(executable, cancel):
    observation = {
        "case": "cancel" if cancel else "control",
        "fullRequest": False,
        "responseSent": False,
        "peer": None,
        "client": None,
    }
    deadline = time.monotonic() + 10
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.bind(("127.0.0.1", 0))
        server.listen(1)
        server.settimeout(remaining(deadline))
        with subprocess.Popen(
            [str(executable), str(server.getsockname()[1])],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0,
        ) as process:
            try:
                connection, _ = server.accept()
                with connection:
                    observation["fullRequest"] = read_request(connection, deadline)
                    if observation["fullRequest"]:
                        process.stdin.write(b"cancel\n" if cancel else b"release\n")
                        process.stdin.flush()
                        if not cancel:
                            connection.settimeout(remaining(deadline))
                            connection.sendall(
                                b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n"
                                b"Connection: close\r\n\r\nok"
                            )
                            observation["responseSent"] = True
                        collect(process, connection, cancel, deadline, observation)
                        if observation["client"] is not None and remaining(deadline) > 0:
                            process.stdin.write(b"finish\n")
                            process.stdin.flush()
                            observation["exitCode"] = process.wait(timeout=remaining(deadline))
            except (OSError, ValueError, subprocess.TimeoutExpired) as error:
                observation["setupError"] = type(error).__name__
            finally:
                if process.poll() is None:
                    process.kill()
    return observation


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: run_pair.py <built TransportCancellationProbe>")
    executable = Path(sys.argv[1]).resolve(strict=True)
    for cancel in (False, True):
        print(json.dumps(run_case(executable, cancel), sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
