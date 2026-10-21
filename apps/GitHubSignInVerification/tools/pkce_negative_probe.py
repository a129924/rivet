"""獨立、單次反向 PKCE 驗證；不載入正式 OAuth 或先前配置。"""
import base64
import contextlib
import dataclasses
import getpass
import hashlib
import json
import math
import re
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
# Q §9：事前固定；live 後不可為配合結果擴張。
ERROR_CLASSES = {
    "missing_code_verifier": "verifier_required",
    "code_verifier_required": "verifier_required",
    "incorrect_code_verifier": "verifier_mismatch",
    "invalid_code_verifier": "verifier_invalid_unspecified",
    "incorrect_client_credentials": "configuration",
    "invalid_client": "configuration", "unauthorized_client": "configuration",
    "invalid_scope": "configuration", "redirect_uri_mismatch": "redirect",
    "access_denied": "auth", "bad_verification_code": "code_problem",
    "invalid_grant": "code_problem", "invalid_request": "unknown",
    "unsupported_grant_type": "unknown", "server_error": "unknown",
    "temporarily_unavailable": "unknown",
}
SAFE_ERRORS = {value: value for value in ERROR_CLASSES}
REFINABLE_ERRORS = {"invalid_request", "invalid_grant", "bad_verification_code", "invalid_code_verifier"}
STRONG_CLASSES = {"configuration", "redirect", "auth", "verifier_required", "verifier_mismatch"}
DESCRIPTIONS = {
    "verifier_required": (
        "missing required parameter: code_verifier", "the code_verifier is required",
        "code_verifier is required", "the code_verifier parameter is required",
        "invalid request: missing code_verifier"),
    "verifier_mismatch": (
        "the code_verifier does not match the code_challenge",
        "code_verifier does not match code_challenge", "the code_verifier passed is incorrect",
        "code_verifier is incorrect", "invalid request: code_verifier does not match code_challenge"),
    "verifier_invalid_unspecified": (
        "invalid parameter: code_verifier", "the code_verifier is invalid", "invalid code_verifier",
        "the code_verifier parameter is invalid or missing"),
    "code_problem": ("the code passed is incorrect or expired", "the authorization code is invalid or expired"),
    "configuration": ("the client_id and/or client_secret passed are incorrect",),
    "redirect": ("the redirect_uri must match the registered callback url for this application",),
    "auth": ("the user denied access to your application",),
}
DESCRIPTION_CLASSES = {text: category for category, texts in DESCRIPTIONS.items() for text in texts}
STOP_CLASSES = {"network": "network", "timeout": "timeout", "authorization_refused": "auth",
                "response_limit": "http"}
SAFE_REASONS = {
    "verifier_rejected", "token_returned", "generic_code_rejection", "configuration_rejected",
    "unknown_error", "unexpected_response", "http_unconfirmed", "network", "timeout",
    "browser_unavailable", "authorization_refused", "callback_limit", "response_limit",
    "input_unavailable", "cancelled", "internal_error", "local_observation_unconfirmed",
}
AUTH_URL = "https://github.com/login/oauth/authorize"
TOKEN_URL = "https://github.com/login/oauth/access_token"
HEADER_LIMIT = 8192
BODY_LIMIT = 65536
CONNECTION_LIMIT = 16


# §11: finite fields/phrases only. No raw phrase is returned.
VERIFIER_ALIASES = ("code_verifier", "code verifier", "code-verifier")
CHALLENGE_ALIASES = ("code_challenge", "code challenge", "code-challenge")
HINT_WORDS = {
    "description_mentions_verifier": VERIFIER_ALIASES,
    "description_mentions_challenge": CHALLENGE_ALIASES,
    "description_mentions_pkce": ("pkce",),
    "description_has_missing_word": ("missing", "required", "not provided"),
    "description_has_mismatch_word": ("mismatch", "mismatched", "does not match", "doesn't match", "did not match"),
    "description_has_invalid_word": ("invalid", "incorrect"),
    "description_has_expired_word": ("expired",),
    "description_has_client_word": ("client", "client_id", "client_secret"),
    "description_has_redirect_word": ("redirect", "redirect_uri"),
}


def field_pattern(aliases):
    values = [re.escape(quote + alias + quote) for alias in aliases for quote in ("", "'", '\"', "`")]
    return "(?:" + "|".join(values) + ")"


V_FIELD, C_FIELD = field_pattern(VERIFIER_ALIASES), field_pattern(CHALLENGE_ALIASES)
GRAMMAR_PREFIX = r"(?:pkce verification failed: |pkce validation failed: )?"
MISMATCH_SUFFIX = (r"(?: (?:supplied|provided|sent) (?:in|with|during) (?:the )?authorization request"
                   r"| associated with (?:the )?authorization code| for (?:this|the) authorization request)?")
GRAMMAR = (
    ("verifier_required", GRAMMAR_PREFIX + rf"(?:(?:the )?{V_FIELD}(?: parameter)? (?:is required|is missing|was not provided)|missing (?:required )?{V_FIELD}(?: parameter)?)"),
    ("verifier_mismatch", GRAMMAR_PREFIX + rf"(?:the )?{V_FIELD}(?: (?:provided|supplied))? (?:does not match|doesn't match|did not match) (?:the )?{C_FIELD}" + MISMATCH_SUFFIX),
    ("verifier_invalid_unspecified", GRAMMAR_PREFIX + rf"(?:the )?{V_FIELD}(?: parameter)? (?:is|was) (?:incorrect|invalid)"),
    ("verifier_invalid_unspecified", r"pkce verification failed"),
)


def description_metadata(text):
    hints = {key: False for key in HINT_WORDS}
    if not isinstance(text, str) or len(text) > 512:
        return "unknown", "none", hints
    normalized = " ".join(text.strip().lower().split())
    if normalized.endswith("."):
        normalized = normalized[:-1]
    for key, words in HINT_WORDS.items():
        hints[key] = any(re.search(r"(?<![A-Za-z0-9_])" + re.escape(word) + r"(?![A-Za-z0-9_])", normalized)
                         is not None for word in words)
    if normalized in DESCRIPTION_CLASSES:
        return DESCRIPTION_CLASSES[normalized], "legacy_exact", hints
    for category, pattern in GRAMMAR:
        if re.fullmatch(pattern, normalized):
            return category, "bounded_grammar", hints
    return "unknown", "none", hints


def empty_local_checks():
    return {"authorization_observed": False, "token_request_observed": False,
            "authorization_shape_valid": False, "token_request_shape_valid": False,
            "client_id_same": False, "redirect_same": False, "code_same": False,
            "submitted_verifier": "unobserved", "callback_return_to_request_prepared": "unobserved",
            "local_consistency": "unobserved"}


class PreparedRequestObserver:
    """Private passive observer. Sensitive comparisons stay in memory; only report escapes."""
    def __init__(self, attempt, client_id, secret, clock):
        self.attempt, self.client_id, self.secret, self.clock = attempt, client_id, secret, clock
        self.authorization = {}
        self.code = self.redirect = self.callback_redirect = ""
        self.returned_at = None
        self.duplicate = False
        self.report = empty_local_checks()

    @staticmethod
    def unique_form(value):
        pairs = urllib.parse.parse_qsl(value, keep_blank_values=True, strict_parsing=True, max_num_fields=8)
        result = dict(pairs)
        if len(result) != len(pairs):
            raise ValueError()
        return result

    def observe_authorization(self, url, redirect):
        if self.report["authorization_observed"]:
            self.duplicate = True
            return
        self.report["authorization_observed"] = True
        self.redirect = redirect
        try:
            parsed = urllib.parse.urlsplit(url)
            self.authorization = self.unique_form(parsed.query)
            expected = {"client_id": self.client_id, "redirect_uri": redirect, "scope": "offline_access",
                        "state": self.attempt.state, "code_challenge": challenge(self.attempt.verifier),
                        "code_challenge_method": "S256"}
            self.report["authorization_shape_valid"] = (
                parsed.scheme + "://" + parsed.netloc + parsed.path == AUTH_URL
                and not parsed.fragment and parsed.username is None and parsed.password is None
                and self.authorization == expected)
        except (ValueError, TypeError, UnicodeError):
            self.report["authorization_shape_valid"] = False

    def callback_returned(self, code, redirect):
        if self.returned_at is not None:
            self.duplicate = True
            return
        self.code, self.callback_redirect, self.returned_at = code, redirect, self.clock()

    def observe_token(self, request):
        if self.report["token_request_observed"]:
            self.duplicate = True
            return
        self.report["token_request_observed"] = True
        if self.returned_at is not None:
            elapsed = self.clock() - self.returned_at
            if math.isfinite(elapsed) and elapsed >= 0:
                self.report["callback_return_to_request_prepared"] = (
                    "under_5s" if elapsed < 5 else "under_30s" if elapsed < 30 else "older")
        try:
            fields = self.unique_form(request.data.decode("ascii"))
            required = {"client_id", "client_secret", "code", "redirect_uri"}
            headers = {key.lower(): value for key, value in request.header_items()}
            self.report["token_request_shape_valid"] = (
                request.full_url == TOKEN_URL and request.get_method() == "POST"
                and headers.get("accept") == "application/json"
                and headers.get("content-type") == "application/x-www-form-urlencoded"
                and headers.get("cache-control") == "no-store"
                and required <= set(fields) <= required | {"code_verifier"}
                and all(fields[key] for key in required) and fields["client_secret"] == self.secret)
            self.report["client_id_same"] = fields.get("client_id") == self.authorization.get("client_id") == self.client_id
            self.report["redirect_same"] = fields.get("redirect_uri") == self.authorization.get("redirect_uri") == self.callback_redirect == self.redirect
            self.report["code_same"] = bool(self.code) and fields.get("code") == self.code
            verifier = fields.get("code_verifier")
            if verifier is None:
                submission = "omitted"
            elif re.fullmatch(r"[A-Za-z0-9_-]{43}", verifier) is None:
                submission = "invalid"
            elif verifier == self.attempt.verifier:
                submission = "valid_same"
            elif challenge(verifier) != self.authorization.get("code_challenge"):
                submission = "valid_different"
            else:
                submission = "invalid"
            self.report["submitted_verifier"] = submission
        except (ValueError, TypeError, UnicodeError, AttributeError):
            self.report["submitted_verifier"] = "invalid"
            self.report["token_request_shape_valid"] = False

    def snapshot(self):
        report = dict(self.report)
        if self.duplicate:
            report["local_consistency"] = "inconsistent"
        elif report["authorization_observed"] and report["token_request_observed"]:
            expected = "omitted" if self.attempt.case == "missing" else "valid_different"
            valid = all(report[key] for key in ("authorization_shape_valid", "token_request_shape_valid",
                                                "client_id_same", "redirect_same", "code_same"))
            valid = valid and report["submitted_verifier"] == expected
            valid = valid and report["callback_return_to_request_prepared"] != "unobserved"
            report["local_consistency"] = "consistent" if valid else "inconsistent"
        return report

    def clear(self):
        self.authorization.clear()
        self.client_id = self.secret = self.code = self.redirect = self.callback_redirect = ""
        self.returned_at = self.attempt = self.clock = None


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
        self.observer = None
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
        url = authorization_url(client_id, redirect, attempt)
        if deadline.observer is not None:
            deadline.observer.observe_authorization(url, redirect)
        if not opener(url):
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
    if deadline.observer is not None:
        deadline.observer.observe_token(request)
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


def safe_result(reason="unexpected_response", category="json"):
    return {"outcome": "indeterminate", "reason": reason, "http_status": None,
            "remote_error": "unknown", "remote_rejected": False, "token_present": False,
            "diagnostic_version": 3, "diagnostic_class": category,
            "description_class": "absent", "description_present": False,
            "description_mentions_verifier": False, "signals_conflict": False,
            "pkce_rejection_proven": False, "description_match_source": "not_applicable",
            "local_checks": empty_local_checks(), **{key: False for key in HINT_WORDS}}


def classify(status, body, case=None):
    result = safe_result()
    result["http_status"] = status if type(status) is int and 100 <= status <= 599 else None
    obj = strict_object(body, allow_duplicates=True)
    if obj is None:
        return result
    # Presence is factual even when token/shape/duplicate guards reject the payload.
    result["description_present"] = "error_description" in obj
    if result["description_present"]:
        result["description_class"] = "unknown"
        result["description_match_source"] = "none"
    if "access_token" in obj or "refresh_token" in obj:
        result.update(outcome="failed", reason="token_returned", token_present=True,
                      diagnostic_class="token_returned", description_match_source="not_applicable")
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
    result["remote_error"] = SAFE_ERRORS.get(error, "unknown")
    result["description_present"] = "error_description" in obj
    if result["description_present"]:
        category, source, hints = description_metadata(obj["error_description"])
        result.update(description_class=category, description_match_source=source, **hints)
    if type(status) is not int or not (200 <= status <= 299 or status == 400):
        result.update(reason="http_unconfirmed", diagnostic_class="http")
        return result
    category = ERROR_CLASSES.get(error, "unknown")
    description_class = result["description_class"]
    if category in STRONG_CLASSES and description_class not in {"absent", "unknown", category}:
        result["signals_conflict"] = True
    elif error in REFINABLE_ERRORS and description_class in {"verifier_required", "verifier_mismatch"}:
        category = description_class
    result["diagnostic_class"] = category
    expected = {"missing": "verifier_required", "wrong": "verifier_mismatch"}.get(case)
    if expected is not None and category == expected and not result["signals_conflict"]:
        result.update(outcome="passed", reason="verifier_rejected", pkce_rejection_proven=True)
    elif category == "code_problem":
        result["reason"] = "generic_code_rejection"
    elif category in {"configuration", "redirect"}:
        result["reason"] = "configuration_rejected"
    elif category == "auth":
        result["reason"] = "authorization_refused"
    else:
        result["reason"] = "unknown_error"
    return result


def run_case(case, client_id, secret, acquire=authorize, send=send_token, clock=time.monotonic):
    attempt = Attempt.create(case)
    result = safe_result("internal_error", "unknown")
    observer = PreparedRequestObserver(attempt, client_id, secret, clock)
    deadline = None
    try:
        deadline = Deadline(clock=clock)
        deadline.observer = observer
        code, redirect = acquire(client_id, attempt, deadline)
        observer.callback_returned(code, redirect)
        deadline.remaining()
        attempt.claim_exchange()
        fields = exchange_fields(client_id, secret, code, redirect, attempt)
        status, body = send(fields, deadline)
        deadline.remaining()
        result = classify(status, body, case)
    except Stop as error:
        reason = error.args[0] if error.args else "internal_error"
        result["reason"] = reason if reason in SAFE_REASONS else "internal_error"
    except KeyboardInterrupt:
        result["reason"] = "cancelled"
    except Exception:
        result["reason"] = "internal_error"
    finally:
        if deadline is not None:
            deadline.observer = None
        result["local_checks"] = observer.snapshot()
        if result["outcome"] == "passed" and result["local_checks"]["local_consistency"] != "consistent":
            result.update(outcome="indeterminate", pkce_rejection_proven=False, reason="local_observation_unconfirmed")
        observer.clear()
        if not result["remote_rejected"] and not result["token_present"]:
            result["diagnostic_class"] = STOP_CLASSES.get(result["reason"], result["diagnostic_class"])
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
        print(json.dumps(safe_result("input_unavailable", "unknown"), sort_keys=True))
        return 2
    result = safe_result("input_unavailable", "unknown")
    result["case"] = args[1]
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
    if not result["remote_rejected"] and not result["token_present"]:
        result["diagnostic_class"] = STOP_CLASSES.get(result["reason"], result["diagnostic_class"])
    print(json.dumps(result, sort_keys=True))
    return {"passed": 0, "failed": 1, "indeterminate": 2}[result["outcome"]]


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())
