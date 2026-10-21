"""獨立、單次反向 PKCE 驗證；不載入正式 OAuth 或先前配置。"""
import base64
import contextlib
import dataclasses
import getpass
import hashlib
import json
import secrets
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import warnings

CASES = {"missing", "wrong"}
VERIFIER_ERRORS = {
    "missing_code_verifier", "incorrect_code_verifier",
    "invalid_code_verifier", "code_verifier_required",
}
CONFIG_ERRORS = {"incorrect_client_credentials", "redirect_uri_mismatch", "unverified_user_email"}
SAFE_REASONS = {
    "verifier_rejected", "token_returned", "generic_code_rejection", "configuration_rejected",
    "unknown_error", "unexpected_response", "http_unconfirmed", "network", "timeout",
    "browser_unavailable", "authorization_refused", "callback_limit", "response_limit",
    "input_unavailable", "cancelled", "internal_error",
}
AUTH_URL = "https://github.com/login/oauth/authorize"
TOKEN_URL = "https://github.com/login/oauth/access_token"
HEADER_LIMIT = 8192
BODY_LIMIT = 65536
CONNECTION_LIMIT = 16


class Stop(Exception):
    """只攜帶預定分類；不包裝 underlying error。"""


def challenge(verifier):
    return base64.urlsafe_b64encode(hashlib.sha256(verifier.encode("ascii")).digest()).decode().rstrip("=")


@dataclasses.dataclass(repr=False)
class Attempt:
    case: str
    state: str
    verifier: str
    wrong_verifier: str
    claimed: bool = False
    exchanged: bool = False

    @classmethod
    def create(cls, case):
        if case not in CASES:
            raise Stop("input_unavailable")
        verifier = secrets.token_urlsafe(32)
        wrong = secrets.token_urlsafe(32)
        while challenge(wrong) == challenge(verifier):
            wrong = secrets.token_urlsafe(32)
        return cls(case, secrets.token_urlsafe(32), verifier, wrong)

    def claim_exchange(self):
        if self.exchanged or not self.claimed:
            raise Stop("internal_error")
        self.exchanged = True

    def clear(self):
        self.state = self.verifier = self.wrong_verifier = ""


class Deadline:
    def __init__(self, seconds=300, clock=time.monotonic):
        self.clock = clock
        self.end = clock() + seconds

    def remaining(self):
        value = self.end - self.clock()
        if value <= 0:
            raise Stop("timeout")
        return value


@contextlib.contextmanager
def time_budget(seconds):
    """macOS main thread：硬性限制整段 I/O，避免慢速分段延長 timeout。"""
    previous_handler = signal.getsignal(signal.SIGALRM)
    previous_timer = signal.getitimer(signal.ITIMER_REAL)
    started = time.monotonic()

    def expire(_signum, _frame):
        raise Stop("timeout")

    signal.signal(signal.SIGALRM, expire)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous_handler)
        if previous_timer[0] > 0:
            signal.setitimer(signal.ITIMER_REAL, max(0.001, previous_timer[0] - (time.monotonic() - started)))


def authorization_url(client_id, redirect, attempt):
    return AUTH_URL + "?" + urllib.parse.urlencode({
        "client_id": client_id, "redirect_uri": redirect, "scope": "offline_access",
        "state": attempt.state, "code_challenge": challenge(attempt.verifier),
        "code_challenge_method": "S256",
    })


def exchange_fields(client_id, secret, code, redirect, attempt):
    fields = {"client_id": client_id, "client_secret": secret, "code": code, "redirect_uri": redirect}
    if attempt.case == "wrong":
        fields["code_verifier"] = attempt.wrong_verifier
    return fields


def callback_code(raw, host, attempt):
    """無效 callback 不 claim；不記錄或 echo request bytes。"""
    if attempt.claimed or len(raw) > HEADER_LIMIT or not raw.endswith(b"\r\n\r\n"):
        return None
    try:
        lines = raw.decode("ascii").split("\r\n")
        method, target, version = lines[0].split(" ")
        if method != "GET" or version not in {"HTTP/1.0", "HTTP/1.1"} or not target.startswith("/"):
            return None
        headers = {}
        for line in lines[1:-2]:
            key, value = line.split(":", 1)
            key = key.strip().lower()
            if key in headers:
                return None
            headers[key] = value.strip()
        if headers.get("host") != host or "transfer-encoding" in headers:
            return None
        if headers.get("content-length", "0") != "0":
            return None
        url = urllib.parse.urlsplit(target)
        if url.scheme or url.netloc or url.fragment or url.path != "/oauth/callback":
            return None
        pairs = urllib.parse.parse_qsl(url.query, keep_blank_values=True, strict_parsing=True, max_num_fields=16)
        query = dict(pairs)
        if len(query) != len(pairs) or not secrets.compare_digest(query.get("state", ""), attempt.state):
            return None
        if "iss" in query and query["iss"] != "https://github.com/login/oauth":
            return None
        has_code, has_error = "code" in query, "error" in query
        if has_code == has_error or not query.get("code" if has_code else "error"):
            return None
        attempt.claimed = True
        if has_error:
            raise Stop("authorization_refused")
        return query["code"]
    except (ValueError, UnicodeError):
        return None


def read_headers(connection, deadline):
    data = bytearray()
    end = deadline.clock() + min(5, deadline.remaining())
    while b"\r\n\r\n" not in data:
        remaining = min(end - deadline.clock(), deadline.remaining())
        if remaining <= 0:
            return None
        connection.settimeout(remaining)
        chunk = connection.recv(min(1024, HEADER_LIMIT + 1 - len(data)))
        if not chunk:
            return None
        data.extend(chunk)
        if len(data) > HEADER_LIMIT:
            return None
    # Request bodies and pipelined bytes are not accepted.
    if not data.endswith(b"\r\n\r\n"):
        return None
    return bytes(data)


def static_reply(connection, valid):
    body = ("反向驗證已收到回呼，請回終端查看安全分類。" if valid else "無效的本機回呼。").encode()
    response = (f"HTTP/1.1 {200 if valid else 400} Result\r\nContent-Type: text/plain; charset=utf-8\r\n"
                f"Content-Length: {len(body)}\r\nCache-Control: no-store\r\n"
                "Referrer-Policy: no-referrer\r\nConnection: close\r\n\r\n").encode() + body
    try:
        connection.sendall(response)
    except OSError:
        pass


def open_browser(url):
    try:
        result = subprocess.run(["/usr/bin/open", url], stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, timeout=10, check=False)
        return result.returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def authorize(client_id, attempt, deadline, opener=open_browser):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(8)
        host = f"127.0.0.1:{listener.getsockname()[1]}"
        redirect = f"http://{host}/oauth/callback"
        if not opener(authorization_url(client_id, redirect, attempt)):
            raise Stop("browser_unavailable")
        accepted = 0
        while accepted < CONNECTION_LIMIT:
            listener.settimeout(min(5, deadline.remaining()))
            try:
                connection, _address = listener.accept()
            except socket.timeout:
                continue
            accepted += 1
            with connection:
                try:
                    raw = read_headers(connection, deadline)
                    code = callback_code(raw, host, attempt) if raw else None
                    static_reply(connection, code is not None)
                    if code is not None:
                        return code, redirect
                except Stop:
                    static_reply(connection, attempt.claimed)
                    raise
                except (socket.timeout, OSError):
                    continue
        raise Stop("callback_limit")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def make_opener():
    # Empty proxy handler ignores env; no cookie processor, cache, retry or redirect handler.
    return urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())


def send_token(fields, deadline):
    timeout = min(30, deadline.remaining())
    request = urllib.request.Request(TOKEN_URL, data=urllib.parse.urlencode(fields).encode(),
                                     headers={"Accept": "application/json",
                                              "Content-Type": "application/x-www-form-urlencoded",
                                              "Cache-Control": "no-store"}, method="POST")
    try:
        with time_budget(timeout):
            try:
                response = make_opener().open(request, timeout=timeout)
            except urllib.error.HTTPError as error:
                response = error
            with response:
                body = response.read(BODY_LIMIT + 1)
                if len(body) > BODY_LIMIT:
                    raise Stop("response_limit")
                deadline.remaining()
                return response.code, body
    except Stop:
        raise
    except (OSError, urllib.error.URLError, ValueError):
        raise Stop("network") from None


def strict_object(body, allow_duplicates=False):
    def pairs(values):
        result = {}
        for key, value in values:
            if key in result and not allow_duplicates:
                raise ValueError()
            result[key] = value
        return result

    def invalid_constant(_value):
        raise ValueError()

    try:
        value = json.loads(body, object_pairs_hook=pairs, parse_constant=invalid_constant)
        return value if isinstance(value, dict) else None
    except (ValueError, UnicodeError, RecursionError):
        return None


def classify(status, body):
    result = {"outcome": "indeterminate", "reason": "unexpected_response",
              "http_status": status if type(status) is int and 100 <= status <= 599 else None,
              "remote_error": "unknown", "remote_rejected": False, "token_present": False}
    obj = strict_object(body, allow_duplicates=True)
    if obj is None:
        return result
    if "access_token" in obj or "refresh_token" in obj:
        result.update(outcome="failed", reason="token_returned", token_present=True)
        return result
    obj = strict_object(body)
    if obj is None:
        return result
    error = obj.get("error")
    if not isinstance(error, str) or not error or set(obj) - {"error", "error_description", "error_uri"}:
        return result
    if any(not isinstance(value, str) for value in obj.values()):
        return result
    result["remote_rejected"] = True
    known = VERIFIER_ERRORS | CONFIG_ERRORS | {"bad_verification_code"}
    result["remote_error"] = error if error in known else "unknown"
    if type(status) is not int or not (200 <= status <= 299 or status == 400):
        result["reason"] = "http_unconfirmed"
    elif error in VERIFIER_ERRORS:
        result.update(outcome="passed", reason="verifier_rejected")
    elif error == "bad_verification_code":
        result["reason"] = "generic_code_rejection"
    elif error in CONFIG_ERRORS:
        result["reason"] = "configuration_rejected"
    else:
        result["reason"] = "unknown_error"
    return result


def run_case(case, client_id, secret, acquire=authorize, send=send_token, clock=time.monotonic):
    attempt = Attempt.create(case)
    result = {"outcome": "indeterminate", "reason": "internal_error", "http_status": None,
              "remote_error": "unknown", "remote_rejected": False, "token_present": False}
    try:
        deadline = Deadline(clock=clock)
        code, redirect = acquire(client_id, attempt, deadline)
        deadline.remaining()
        attempt.claim_exchange()
        fields = exchange_fields(client_id, secret, code, redirect, attempt)
        status, body = send(fields, deadline)
        deadline.remaining()
        result = classify(status, body)
    except Stop as error:
        reason = error.args[0] if error.args else "internal_error"
        result["reason"] = reason if reason in SAFE_REASONS else "internal_error"
    except KeyboardInterrupt:
        result["reason"] = "cancelled"
    except Exception:
        result["reason"] = "internal_error"
    finally:
        result.update(case=case, fresh_attempt=True, callback_claimed=attempt.claimed,
                      single_exchange=attempt.exchanged, verifier_field_omitted=case == "missing",
                      wrong_challenge_differs=(challenge(attempt.verifier) != challenge(attempt.wrong_verifier))
                      if case == "wrong" else None)
        attempt.clear()
    return result


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if args == ["--help"]:
        print("用法：python3 -B pkce_negative_probe.py --case missing|wrong；只在本機TTY隱藏輸入配置。")
        return 0
    if len(args) != 2 or args[0] != "--case" or args[1] not in CASES:
        print('{"outcome":"indeterminate","reason":"input_unavailable"}')
        return 2
    result = {"case": args[1], "outcome": "indeterminate", "reason": "input_unavailable"}
    client_id = secret = ""
    try:
        if not sys.stdin.isatty() or not sys.stderr.isatty():
            raise Stop("input_unavailable")
        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            client_id = getpass.getpass("Client ID（隱藏輸入）: ")
            secret = getpass.getpass("Client Secret（隱藏輸入）: ")
        if not client_id or not secret or len(client_id) > 1024 or len(secret) > 4096:
            raise Stop("input_unavailable")
        print("請只完成這一次新授權；回呼後返回終端。勿複製瀏覽器URL或配置。", flush=True)
        with time_budget(300):
            result = run_case(args[1], client_id, secret)
    except Stop as error:
        reason = error.args[0] if error.args else "internal_error"
        result["reason"] = reason if reason in SAFE_REASONS else "internal_error"
    except getpass.GetPassWarning:
        result["reason"] = "input_unavailable"
    except (KeyboardInterrupt, EOFError):
        result["reason"] = "cancelled"
    except Exception:
        result["reason"] = "internal_error"
    finally:
        client_id = secret = ""
    print(json.dumps(result, sort_keys=True))
    return {"passed": 0, "failed": 1, "indeterminate": 2}[result["outcome"]]


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())
