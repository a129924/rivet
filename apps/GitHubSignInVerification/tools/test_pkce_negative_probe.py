"""全部為 fixture；不讀機密、不開真瀏覽器、不連 GitHub。"""
import contextlib
import io
import inspect
import subprocess
import tempfile
from pathlib import Path
import json
import socket
import threading
import unittest
import urllib.error
import urllib.parse
import warnings
from unittest import mock

import pkce_negative_probe as probe


def raw_callback(attempt, host="127.0.0.1:1234", query=None, method="GET", path="/oauth/callback", extra=""):
    if query is None:
        query = urllib.parse.urlencode({"state": attempt.state, "code": "fixture-code"})
    return (f"{method} {path}?{query} HTTP/1.1\r\nHost: {host}\r\n{extra}\r\n").encode()


def acquire_fixture(_client, attempt, _deadline):
    code = probe.callback_code(raw_callback(attempt), "127.0.0.1:1234", attempt)
    return code, "http://127.0.0.1:1234/oauth/callback"


class NegativeProbeTests(unittest.TestCase):
    def test_missing_really_omits_verifier_and_wrong_uses_distinct_proof(self):
        for case in ["missing", "wrong"]:
            attempt = probe.Attempt.create(case)
            form = probe.exchange_fields("fixture-id", "fixture-secret", "fixture-code", "redirect-fixture", attempt)
            if case == "missing":
                self.assertNotIn("code_verifier", form)
            else:
                self.assertEqual(len(form["code_verifier"]), 43)
                self.assertNotEqual(probe.challenge(form["code_verifier"]), probe.challenge(attempt.verifier))
            self.assertEqual(form["code"], "fixture-code")

    def test_fresh_attempts_and_same_authorization_conditions(self):
        first, second = probe.Attempt.create("missing"), probe.Attempt.create("wrong")
        self.assertNotEqual(first.state, second.state)
        self.assertNotEqual(first.verifier, second.verifier)
        for attempt in [first, second]:
            url = urllib.parse.urlsplit(probe.authorization_url("fixture-id", "redirect-fixture", attempt))
            self.assertEqual(url.scheme + "://" + url.netloc + url.path, probe.AUTH_URL)
            query = urllib.parse.parse_qs(url.query)
            self.assertEqual(query["code_challenge_method"], ["S256"])
            self.assertEqual(query["scope"], ["offline_access"])
            self.assertEqual(query["redirect_uri"], ["redirect-fixture"])
            self.assertEqual(query["code_challenge"], [probe.challenge(attempt.verifier)])

    def test_invalid_callbacks_do_not_consume_attempt(self):
        attempt = probe.Attempt.create("missing")
        fixtures = [
            raw_callback(attempt, host="evil.invalid"),
            raw_callback(attempt, path="/wrong"), raw_callback(attempt, method="POST"),
            raw_callback(attempt, path="http://evil.invalid/oauth/callback"),
            raw_callback(attempt, query="state=wrong&code=fixture"),
            raw_callback(attempt, query=f"state={attempt.state}&code=fixture&code=again"),
            raw_callback(attempt, query=f"state={attempt.state}&state={attempt.state}&code=x"),
            raw_callback(attempt, query=f"state={attempt.state}&code=x&error=denied"),
            raw_callback(attempt, query=f"state={attempt.state}&code="),
            raw_callback(attempt, query=f"state={attempt.state}"),
            raw_callback(attempt, query=f"state={attempt.state}&code=x#fragment"),
            raw_callback(attempt, query=f"state={attempt.state}&code=x&iss=https://evil.invalid"),
            raw_callback(attempt, extra="Content-Length: 1\r\n"),
            raw_callback(attempt, extra="Transfer-Encoding: chunked\r\n"),
            raw_callback(attempt, extra="Host: 127.0.0.1:1234\r\n"),
            raw_callback(attempt) + b"body", b"x" * 8193,
        ]
        for raw in fixtures:
            self.assertIsNone(probe.callback_code(raw, "127.0.0.1:1234", attempt))
            self.assertFalse(attempt.claimed)
        self.assertEqual(probe.callback_code(raw_callback(attempt), "127.0.0.1:1234", attempt), "fixture-code")
        self.assertIsNone(probe.callback_code(raw_callback(attempt), "127.0.0.1:1234", attempt))

    def test_denial_consumes_attempt_without_exchange(self):
        attempt = probe.Attempt.create("wrong")
        raw = raw_callback(attempt, query=f"state={attempt.state}&error=access_denied")
        with self.assertRaises(probe.Stop):
            probe.callback_code(raw, "127.0.0.1:1234", attempt)
        self.assertTrue(attempt.claimed)
        self.assertFalse(attempt.exchanged)

    def test_exchange_can_only_be_claimed_once_after_callback(self):
        attempt = probe.Attempt.create("missing")
        with self.assertRaises(probe.Stop):
            attempt.claim_exchange()
        acquire_fixture("fixture", attempt, None)
        attempt.claim_exchange()
        with self.assertRaises(probe.Stop):
            attempt.claim_exchange()

    def test_real_loopback_is_local_and_ignores_invalid_then_claims_once(self):
        attempt = probe.Attempt.create("wrong")
        failures, threads = [], []

        def opener(url):
            query = urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)
            target = urllib.parse.urlsplit(query["redirect_uri"][0])
            def browser_fixture():
                try:
                    for state in ["wrong-fixture-state", attempt.state]:
                        with socket.create_connection((target.hostname, target.port), timeout=2) as connection:
                            connection.sendall(raw_callback(attempt, host=target.netloc,
                                query=urllib.parse.urlencode({"state": state, "code": "fresh-fixture"})))
                            response = connection.recv(2048)
                            self.assertNotIn(b"fresh-fixture", response)
                            self.assertNotIn(attempt.state.encode(), response)
                except Exception:
                    failures.append(True)
            thread = threading.Thread(target=browser_fixture)
            threads.append(thread)
            thread.start()
            return True

        deadline = probe.Deadline(5)
        deadline.observer = mock.Mock()
        observed_urls = []
        def recording_opener(url):
            observed_urls.append(url)
            return opener(url)
        code, redirect = probe.authorize("fixture-id", attempt, deadline, opener=recording_opener)
        self.assertEqual(deadline.observer.observe_authorization.call_count, 1)
        self.assertTrue(deadline.observer.observe_authorization.call_args.args == (observed_urls[0], redirect))
        for thread in threads:
            thread.join(timeout=3)
            self.assertFalse(thread.is_alive())
        self.assertEqual(failures, [])
        self.assertEqual(code, "fresh-fixture")
        self.assertTrue(redirect.startswith("http://127.0.0.1:"))
        self.assertTrue(attempt.claimed)

    def test_loopback_connection_limit_and_browser_failure(self):
        attempt = probe.Attempt.create("missing")
        with self.assertRaises(probe.Stop):
            probe.authorize("fixture-id", attempt, probe.Deadline(), opener=lambda _url: False)
        threads = []
        def opener(url):
            redirect = urllib.parse.urlsplit(urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)["redirect_uri"][0])
            def fixture():
                for _ in range(2):
                    with socket.create_connection((redirect.hostname, redirect.port), timeout=2) as connection:
                        connection.sendall(b"GET /invalid HTTP/1.1\r\nHost: invalid\r\n\r\n")
                        connection.recv(2048)
            thread = threading.Thread(target=fixture)
            threads.append(thread)
            thread.start()
            return True
        with mock.patch.object(probe, "CONNECTION_LIMIT", 2):
            with self.assertRaisesRegex(probe.Stop, "callback_limit"):
                probe.authorize("fixture-id", attempt, probe.Deadline(5), opener=opener)
        for thread in threads:
            thread.join(timeout=3)
        self.assertFalse(attempt.claimed)

    def test_header_limit_and_per_connection_total_deadline(self):
        connection = mock.Mock()
        connection.recv.return_value = b"x" * 8193
        self.assertIsNone(probe.read_headers(connection, probe.Deadline()))
        now = [0]
        def slow_chunk(_size):
            now[0] += 3
            return b"x"
        connection.recv.side_effect = slow_chunk
        deadline = probe.Deadline(clock=lambda: now[0])
        self.assertIsNone(probe.read_headers(connection, deadline))
        self.assertEqual(connection.recv.call_count, 3)  # previous oversize + two 3s chunks

    def test_only_case_specific_verifier_error_and_accepted_http_can_pass(self):
        for error, case in [("missing_code_verifier", "missing"),
                            ("code_verifier_required", "missing"),
                            ("incorrect_code_verifier", "wrong")]:
            for status in [200, 201, 400]:
                self.assertEqual(probe.classify(status, json.dumps({"error": error}).encode(), case)["outcome"], "passed")
            for status in [302, 401, 500]:
                self.assertEqual(probe.classify(status, json.dumps({"error": error}).encode(), case)["outcome"], "indeterminate")
            opposite = "wrong" if case == "missing" else "missing"
            self.assertEqual(probe.classify(400, json.dumps({"error": error}).encode(), opposite)["outcome"], "indeterminate")
        for case in ["missing", "wrong", None]:
            self.assertEqual(probe.classify(400, b'{"error":"invalid_code_verifier"}', case)["outcome"], "indeterminate")

    def test_generic_code_rejection_is_never_pkce_pass(self):
        result = probe.classify(200, b'{"error":"bad_verification_code","error_description":"code_verifier is invalid"}')
        self.assertEqual(result["outcome"], "indeterminate")
        self.assertEqual(result["reason"], "generic_code_rejection")
        self.assertTrue(result["remote_rejected"])

    def test_any_token_key_fails_even_empty_mixed_wrong_type_or_duplicate(self):
        for body in [b'{"access_token":"fixture-token"}', b'{"refresh_token":null}',
                     b'{"error":"incorrect_code_verifier","access_token":""}',
                     b'{"refresh_token":42}', b'{"access_token":"x","access_token":"y"}']:
            result = probe.classify(200, body)
            self.assertEqual(result["outcome"], "failed")
            self.assertTrue(result["token_present"])
            self.assertNotIn("fixture-token", json.dumps(result))

    def test_configuration_unknown_malformed_and_mixed_never_pass(self):
        for body in [b'{"error":"incorrect_client_credentials"}', b'{"error":"redirect_uri_mismatch"}',
                     b'{"error":"fixture-secret"}', b'[]', b'not-json', b'{"error":42}',
                     b'{"error":"incorrect_code_verifier","scope":"success"}',
                     b'{"error":"incorrect_code_verifier","error_description":{}}',
                     b'{"error":"incorrect_code_verifier","error":"incorrect_code_verifier"}']:
            result = probe.classify(200, body)
            self.assertEqual(result["outcome"], "indeterminate")
            self.assertNotIn("fixture-secret", json.dumps(result))

    def test_one_exchange_no_retry_and_safe_context(self):
        calls, attempts = [], []
        def acquire(client, attempt, deadline):
            attempts.append(attempt)
            return acquire_fixture(client, attempt, deadline)
        def send(fields, _deadline):
            calls.append(fields)
            raise probe.Stop("network")
        result = probe.run_case("wrong", "fixture-id", "fixture-secret", acquire=acquire, send=send)
        self.assertEqual(len(calls), 1)
        self.assertEqual(result["reason"], "network")
        self.assertTrue(result["single_exchange"])
        self.assertTrue(result["fresh_attempt"])
        self.assertTrue(result["wrong_challenge_differs"])
        self.assertEqual(attempts[0].state, "")
        for value in ["fixture-id", "fixture-secret", "fixture-code"]:
            self.assertNotIn(value, json.dumps(result))

    def test_expired_attempt_never_sends(self):
        now = [0]
        def acquire(_client, attempt, _deadline):
            attempt.claimed = True
            now[0] = 301
            return "fixture-code", "redirect"
        send = mock.Mock()
        result = probe.run_case("missing", "fixture-id", "fixture-secret", acquire=acquire,
                                send=send, clock=lambda: now[0])
        send.assert_not_called()
        self.assertEqual(result["reason"], "timeout")

    def test_live_transport_fixed_endpoint_bounded_and_no_retry(self):
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.code = 400
        response.read.return_value = b'{"error":"missing_code_verifier"}'
        opener = mock.Mock()
        opener.open.return_value = response
        with mock.patch.object(probe, "make_opener", return_value=opener), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()) as budget:
            status, _body = probe.send_token({"code": "fixture&+", "client_secret": "fixture"}, probe.Deadline())
            self.assertEqual(status, 400)
            request = opener.open.call_args.args[0]
            self.assertEqual(request.full_url, probe.TOKEN_URL)
            self.assertEqual(request.method, "POST")
            self.assertEqual(urllib.parse.parse_qs(request.data.decode())["code"], ["fixture&+"])
            self.assertEqual(request.get_header("Accept"), "application/json")
            self.assertLessEqual(opener.open.call_args.kwargs["timeout"], 30)
            self.assertLessEqual(budget.call_args.args[0], 30)
            response.read.assert_called_once_with(probe.BODY_LIMIT + 1)
        response.read.return_value = b"x" * (probe.BODY_LIMIT + 1)
        with mock.patch.object(probe, "make_opener", return_value=opener), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            with self.assertRaisesRegex(probe.Stop, "response_limit"):
                probe.send_token({}, probe.Deadline())
        opener.open.side_effect = urllib.error.URLError("fixture-secret")
        opener.open.reset_mock()
        with mock.patch.object(probe, "make_opener", return_value=opener), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            with self.assertRaisesRegex(probe.Stop, "network"):
                probe.send_token({}, probe.Deadline())
        self.assertEqual(opener.open.call_count, 1)

    def test_no_redirect_proxy_or_cookie_handler(self):
        self.assertIsNone(probe.NoRedirect().redirect_request(None, None, 302, "", {}, "https://evil.invalid"))
        with mock.patch.object(probe.urllib.request, "build_opener") as build:
            probe.make_opener()
            self.assertEqual(build.call_args.args[0].proxies, {})
        opener = probe.make_opener()
        self.assertTrue(any(isinstance(handler, probe.NoRedirect) for handler in opener.handlers))
        self.assertFalse(any(isinstance(handler, probe.urllib.request.HTTPCookieProcessor) for handler in opener.handlers))

    def test_no_tty_and_invalid_args_never_prompt_or_echo(self):
        for args in [["--case", "missing"], ["--client-secret", "fixture-secret"]]:
            stdout, stderr = io.StringIO(), io.StringIO()
            with mock.patch.object(probe.sys.stdin, "isatty", return_value=False), \
                 mock.patch.object(probe.getpass, "getpass") as prompt, \
                 contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                self.assertEqual(probe.main(args), 2)
            prompt.assert_not_called()
            self.assertNotIn("fixture-secret", stdout.getvalue() + stderr.getvalue())
            self.assertNotIn("Traceback", stdout.getvalue() + stderr.getvalue())

    def test_hidden_input_and_unexpected_errors_are_sanitized(self):
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr), \
             mock.patch.object(probe.sys.stdin, "isatty", return_value=True), \
             mock.patch.object(probe.sys.stderr, "isatty", return_value=True), \
             mock.patch.object(probe.getpass, "getpass", side_effect=RuntimeError("fixture-secret")):
            self.assertEqual(probe.main(["--case", "wrong"]), 2)
        self.assertEqual(json.loads(stdout.getvalue())["reason"], "internal_error")
        self.assertNotIn("fixture-secret", stdout.getvalue() + stderr.getvalue())

    def test_getpass_fallback_warning_aborts_before_plain_input_or_authorization(self):
        for warn_at in [1, 2]:
            calls = []
            def unsafe_prompt(_prompt):
                calls.append(True)
                if len(calls) == warn_at:
                    warnings.warn("fixture-secret", probe.getpass.GetPassWarning)
                    self.fail("warning must abort before fallback input")
                return "fixture-client-id"
            stdout, stderr = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr), \
                 mock.patch.object(probe.sys.stdin, "isatty", return_value=True), \
                 mock.patch.object(probe.sys.stderr, "isatty", return_value=True), \
                 mock.patch.object(probe.getpass, "getpass", side_effect=unsafe_prompt), \
                 mock.patch.object(probe, "run_case") as run:
                self.assertEqual(probe.main(["--case", "missing"]), 2)
            run.assert_not_called()
            self.assertEqual(json.loads(stdout.getvalue())["reason"], "input_unavailable")
            for sentinel in ["fixture-secret", "fixture-client-id", "Traceback", "Warning"]:
                self.assertNotIn(sentinel, stdout.getvalue() + stderr.getvalue())

    def test_hard_timer_restores_enclosing_budget(self):
        with mock.patch.object(probe.signal, "getsignal", return_value=probe.signal.SIG_DFL), \
             mock.patch.object(probe.signal, "getitimer", return_value=(12, 0)), \
             mock.patch.object(probe.signal, "signal") as handler, \
             mock.patch.object(probe.signal, "setitimer") as timer, \
             mock.patch.object(probe.time, "monotonic", side_effect=[10, 12]):
            with probe.time_budget(5):
                callback = handler.call_args.args[1]
                with self.assertRaisesRegex(probe.Stop, "timeout"):
                    callback(None, None)
            self.assertEqual(timer.call_args.args, (probe.signal.ITIMER_REAL, 10))

    def test_safe_report_field_allowlist_and_interrupt(self):
        def interrupted(*_args):
            raise KeyboardInterrupt()
        result = probe.run_case("missing", "fixture-id", "fixture-secret", acquire=interrupted)
        self.assertEqual(result["reason"], "cancelled")
        self.assertFalse(result["single_exchange"])
        self.assertEqual(set(result), {"case", "outcome", "reason", "http_status", "remote_error",
            "remote_rejected", "token_present", "fresh_attempt", "callback_claimed", "single_exchange",
            "verifier_field_omitted", "wrong_challenge_differs", "diagnostic_version",
            "diagnostic_class", "description_class", "description_present",
            "description_mentions_verifier", "signals_conflict", "pkce_rejection_proven",
            "description_match_source", "local_checks", "description_mentions_challenge",
            "description_mentions_pkce", "description_has_missing_word", "description_has_mismatch_word",
            "description_has_invalid_word", "description_has_expired_word",
            "description_has_client_word", "description_has_redirect_word"})

    def test_fixed_description_templates_and_normalization(self):
        expected_counts = {"verifier_required": 5, "verifier_mismatch": 5,
                           "verifier_invalid_unspecified": 4, "code_problem": 2,
                           "configuration": 1, "redirect": 1, "auth": 1}
        self.assertEqual({key: len(value) for key, value in probe.DESCRIPTIONS.items()}, expected_counts)
        for category, templates in probe.DESCRIPTIONS.items():
            for text in templates:
                for normalized in [text, "  " + text.upper().replace(" ", "  ") + ".  "]:
                    for case in ["missing", "wrong"]:
                        body = json.dumps({"error": "invalid_grant", "error_description": normalized}).encode()
                        result = probe.classify(400, body, case)
                        self.assertEqual(result["description_class"], category)
                        expected = (case, category) in {("missing", "verifier_required"), ("wrong", "verifier_mismatch")}
                        self.assertEqual(result["pkce_rejection_proven"], expected)
                        self.assertEqual(result["outcome"] == "passed", expected)
                        self.assertEqual(result["diagnostic_version"], 3)

    def test_known_generic_refinement_unknown_and_conflicts(self):
        descriptions = {"verifier_required": "code_verifier is required",
                        "verifier_mismatch": "code_verifier is incorrect",
                        "code_problem": "the code passed is incorrect or expired",
                        "configuration": "the client_id and/or client_secret passed are incorrect"}
        for error in ["invalid_grant", "invalid_request", "bad_verification_code", "invalid_code_verifier"]:
            for case, category in [("missing", "verifier_required"), ("wrong", "verifier_mismatch")]:
                result = probe.classify(400, json.dumps({"error": error, "error_description": descriptions[category]}).encode(), case)
                self.assertTrue(result["pkce_rejection_proven"])
        strong = {"missing_code_verifier": "verifier_required", "code_verifier_required": "verifier_required",
                  "incorrect_code_verifier": "verifier_mismatch", "incorrect_client_credentials": "configuration",
                  "invalid_client": "configuration", "unauthorized_client": "configuration",
                  "invalid_scope": "configuration", "redirect_uri_mismatch": "redirect", "access_denied": "auth"}
        for error, category in strong.items():
            for desc_category, text in descriptions.items():
                result = probe.classify(400, json.dumps({"error": error, "error_description": text}).encode(), "missing")
                self.assertEqual(result["signals_conflict"], category != desc_category)
                if category != desc_category:
                    self.assertEqual(result["outcome"], "indeterminate")
                    self.assertFalse(result["pkce_rejection_proven"])
        for error in ["fixture-private-error", "server_error", "temporarily_unavailable", "unsupported_grant_type"]:
            result = probe.classify(400, json.dumps({"error": error, "error_description": descriptions["verifier_required"]}).encode(), "missing")
            self.assertEqual(result["outcome"], "indeterminate")
            self.assertNotIn("fixture-private-error", json.dumps(result))

    def test_keyword_negation_extra_text_and_long_description_are_not_evidence(self):
        for text in ["code_verifier", "code_verifier is not required", "code_verifier is required fixture-secret",
                     "fixture-secret code_verifier is required", "code_verifier is required..", "x" * 513]:
            result = probe.classify(400, json.dumps({"error": "invalid_grant", "error_description": text}).encode(), "missing")
            self.assertEqual(result["outcome"], "indeterminate")
            self.assertEqual(result["description_class"], "unknown")
            self.assertEqual(result["description_mentions_verifier"], "code_verifier" in text)
            self.assertNotIn("fixture-secret", json.dumps(result))
        for text in [None, 42, {"private": "fixture-secret"}, ["fixture-secret"]]:
            result = probe.classify(400, json.dumps({"error": "invalid_grant", "error_description": text}).encode(), "missing")
            self.assertEqual(result["diagnostic_class"], "json")
            self.assertTrue(result["description_present"])
            self.assertEqual(result["description_class"], "unknown")
            self.assertNotIn("fixture-secret", json.dumps(result))
            self.assertFalse(result["pkce_rejection_proven"])

    def test_v2_diagnostic_categories_and_stdout_redaction(self):
        for error, category in [("bad_verification_code", "code_problem"), ("invalid_grant", "code_problem"),
                                ("invalid_client", "configuration"), ("redirect_uri_mismatch", "redirect"),
                                ("access_denied", "auth"), ("invalid_code_verifier", "verifier_invalid_unspecified")]:
            self.assertEqual(probe.classify(400, json.dumps({"error": error}).encode(), "missing")["diagnostic_class"], category)
        self.assertEqual(probe.classify(500, b'{"error":"missing_code_verifier"}', "missing")["diagnostic_class"], "http")
        for reason, category in [("network", "network"), ("timeout", "timeout"), ("authorization_refused", "auth"), ("response_limit", "http")]:
            def send(*_args):
                raise probe.Stop(reason)
            result = probe.run_case("missing", "fixture-id", "fixture-secret", acquire=acquire_fixture, send=send)
            self.assertEqual(result["diagnostic_class"], category)
            self.assertEqual(result["diagnostic_version"], 3)
        body = b'{"error":"fixture-private-error","error_description":"fixture-private-description code_verifier"}'
        stdout, stderr = io.StringIO(), io.StringIO()
        actual_run = probe.run_case
        def fixture_run(case, client, secret):
            return actual_run(case, client, secret, acquire=acquire_fixture, send=lambda *_args: (400, body))
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr), \
             mock.patch.object(probe.sys.stdin, "isatty", return_value=True), \
             mock.patch.object(probe.sys.stderr, "isatty", return_value=True), \
             mock.patch.object(probe.getpass, "getpass", side_effect=["fixture-id", "fixture-secret"]), \
             mock.patch.object(probe, "run_case", side_effect=fixture_run):
            self.assertEqual(probe.main(["--case", "missing"]), 2)
        output = stdout.getvalue() + stderr.getvalue()
        for sentinel in ["fixture-private-error", "fixture-private-description", "fixture-id", "fixture-secret", "fixture-code", "Traceback"]:
            self.assertNotIn(sentinel, output)
        report = json.loads(stdout.getvalue().splitlines()[-1])
        self.assertEqual(report["remote_error"], "unknown")
        self.assertTrue(report["description_mentions_verifier"])
        self.assertFalse(report["pkce_rejection_proven"])

    def observed_run(self, case="wrong", mutate_request=None, mutate_url=None, elapsed=0,
                     body=b'{"error":"invalid_grant","error_description":"The code verifier does not match the code challenge supplied in the authorization request."}',
                     duplicate=False):
        now = [0]
        deadline_ref = []
        actual_observations = []
        original_observe = probe.PreparedRequestObserver.observe_token
        def track_observation(observer, request):
            actual_observations.append(request)
            original_observe(observer, request)
        request_class = probe.urllib.request.Request
        def acquire(client, attempt, deadline):
            deadline_ref.append(deadline)
            redirect = "http://127.0.0.1:1234/oauth/callback"
            url = probe.authorization_url(client, redirect, attempt)
            if mutate_url:
                url = mutate_url(url)
            deadline.observer.observe_authorization(url, redirect)
            if duplicate:
                deadline.observer.observe_authorization(url, redirect)
            return acquire_fixture(client, attempt, deadline)
        def request(*args, **kwargs):
            value = request_class(*args, **kwargs)
            if mutate_request:
                mutate_request(value)
            now[0] = elapsed
            return value
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.code, response.read.return_value = 400, body
        opener = mock.Mock()
        opener.open.return_value = response
        with mock.patch.object(probe.urllib.request, "Request", side_effect=request), \
             mock.patch.object(probe.PreparedRequestObserver, "observe_token", track_observation), \
             mock.patch.object(probe, "make_opener", return_value=opener), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            result = probe.run_case(case, "fixture-id", "fixture-secret", acquire=acquire, clock=lambda: now[0])
        self.assertIsNone(deadline_ref[0].observer)
        self.assertEqual(opener.open.call_count, 1)
        self.assertEqual(len(actual_observations), 1)
        self.assertIs(actual_observations[0], opener.open.call_args.args[0])
        return result

    def test_v3_full_grammar_aliases_quotes_suffixes_and_legacy_priority(self):
        for verifier, challenge in [("code verifier", "code challenge"),
                                    ("code-verifier", "code-challenge"), ("code_verifier", "code_challenge")]:
            for quote in ["", "'", '"', "`"]:
                for prefix in ["", "pkce verification failed: ", "pkce validation failed: "]:
                    for suffix in ["", " supplied in the authorization request", " provided with authorization request",
                                   " sent during the authorization request", " associated with the authorization code",
                                   " for this authorization request"]:
                        text = prefix + "the " + quote + verifier + quote + " does not match the " + quote + challenge + quote + suffix
                        report = probe.classify(400, json.dumps({"error":"invalid_grant","error_description":text}).encode(), "wrong")
                        self.assertEqual(report["description_class"], "verifier_mismatch")
                        self.assertEqual(report["outcome"], "passed")
        for text in ["code verifier is required", "the 'code-verifier' parameter is missing",
                     "missing required `code verifier` parameter", "code verifier was not provided"]:
            report=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":text}).encode(),"missing")
            self.assertEqual(report["description_class"],"verifier_required")
            self.assertEqual(report["outcome"],"passed")
        for verb in ["doesn't match", "did not match"]:
            report=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":"code verifier supplied "+verb+" code challenge"}).encode(),"wrong")
            self.assertEqual(report["description_match_source"],"bounded_grammar")
        for text in ["the code verifier was invalid", "code-verifier is incorrect", "pkce verification failed"]:
            report=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":text}).encode(),"wrong")
            self.assertEqual(report["description_class"],"verifier_invalid_unspecified")
            self.assertFalse(report["pkce_rejection_proven"])
        exact=probe.classify(400,b'{"error":"invalid_grant","error_description":"code_verifier is incorrect"}',"wrong")
        self.assertEqual(exact["description_class"],"verifier_mismatch")
        self.assertEqual(exact["description_match_source"],"legacy_exact")

    def test_v3_rejects_negation_free_tail_bad_quotes_unknown_and_case_conflict(self):
        for text in ["code verifier does not match code challenge but it is valid", "code verifier is not required",
                     "if code verifier does not match code challenge", "code verifier may be invalid",
                     "'code verifier does not match code challenge", "code verifier does not match code challenge'",
                     "code verifier matches code challenge", "code verifier does not match code challenge; fixture-private"]:
            result=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":text}).encode(),"wrong")
            self.assertEqual(result["outcome"],"indeterminate")
            self.assertEqual(result["description_match_source"],"none")
        text="code verifier does not match code challenge for this authorization request"
        for error, case in [("fixture-private-error","wrong"),("invalid_client","wrong"),("invalid_grant","missing")]:
            result=probe.classify(400,json.dumps({"error":error,"error_description":text}).encode(),case)
            self.assertFalse(result["pkce_rejection_proven"])
            self.assertNotIn("fixture-private",json.dumps(result))

    def test_v3_hints_are_ascii_bounded_and_never_proof(self):
        text="PKCE: missing required code verifier; mismatch code challenge invalid expired client_id redirect_uri fixture-private"
        result=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":text}).encode(),"wrong")
        for key in ["description_mentions_verifier","description_mentions_challenge","description_mentions_pkce",
                    "description_has_missing_word","description_has_mismatch_word","description_has_invalid_word",
                    "description_has_expired_word","description_has_client_word","description_has_redirect_word"]:
            self.assertTrue(result[key])
        self.assertEqual(result["outcome"],"indeterminate")
        self.assertNotIn("fixture-private",json.dumps(result))
        for text in ["prefix_code_verifier_suffix unexpired clientish redirector", "x"*513+" code_verifier"]:
            report=probe.classify(400,json.dumps({"error":"invalid_grant","error_description":text}).encode(),"wrong")
            self.assertFalse(report["description_mentions_verifier"])
            self.assertFalse(report["description_has_expired_word"])
            self.assertFalse(report["description_has_client_word"])
            self.assertFalse(report["description_has_redirect_word"])

    def test_v3_observes_real_prepared_request_and_allows_consistent_wrong(self):
        result=self.observed_run()
        checks=result["local_checks"]
        for key in ["authorization_observed","token_request_observed","authorization_shape_valid",
                    "token_request_shape_valid","client_id_same","redirect_same","code_same"]:
            self.assertTrue(checks[key])
        self.assertEqual(checks["local_consistency"],"consistent")
        self.assertEqual(checks["submitted_verifier"],"valid_different")
        self.assertEqual(result["outcome"],"passed")
        self.assertEqual(result["description_match_source"],"bounded_grammar")

    def test_v3_prepared_body_mutations_are_not_case_inferences(self):
        for key,value,failed_check in [("client_id","other-client","client_id_same"),
                                      ("redirect_uri","http://127.0.0.1:5678/oauth/callback","redirect_same"),
                                      ("code","other-code","code_same"),("client_secret","other-secret","token_request_shape_valid")]:
            def mutate(request):
                fields=dict(urllib.parse.parse_qsl(request.data.decode()))
                fields[key]=value
                request.data=urllib.parse.urlencode(fields).encode()
            result=self.observed_run(mutate_request=mutate)
            self.assertFalse(result["local_checks"][failed_check])
            self.assertEqual(result["local_checks"]["local_consistency"],"inconsistent")
            self.assertEqual(result["outcome"],"indeterminate")
            self.assertFalse(result["pkce_rejection_proven"])
        def omit(request):
            fields=dict(urllib.parse.parse_qsl(request.data.decode()))
            fields.pop("code_verifier")
            request.data=urllib.parse.urlencode(fields).encode()
        result=self.observed_run(mutate_request=omit)
        self.assertEqual(result["local_checks"]["submitted_verifier"],"omitted")
        self.assertEqual(result["outcome"],"indeterminate")
        for mutation in [lambda r: setattr(r,"method","GET"),
                         lambda r: setattr(r,"data",r.data+b"&code_verifier=duplicate"),
                         lambda r: setattr(r,"data",r.data.replace(b"code_verifier=",b"code_verifier=%21"))]:
            result=self.observed_run(mutate_request=mutation)
            self.assertEqual(result["local_checks"]["local_consistency"],"inconsistent")
            self.assertFalse(result["pkce_rejection_proven"])

    def test_v3_actual_url_mutation_and_duplicate_observation_are_rejected(self):
        result=self.observed_run(mutate_url=lambda url:url.replace("code_challenge_method=S256","code_challenge_method=plain"))
        self.assertFalse(result["local_checks"]["authorization_shape_valid"])
        self.assertEqual(result["outcome"],"indeterminate")
        result=self.observed_run(duplicate=True)
        self.assertEqual(result["local_checks"]["local_consistency"],"inconsistent")
        self.assertEqual(result["outcome"],"indeterminate")

    def test_v3_unobserved_is_not_consistent_and_token_failure_keeps_priority(self):
        result=probe.run_case("wrong","fixture-id","fixture-secret",acquire=acquire_fixture,
                              send=lambda *_args:(400,b'{"error":"incorrect_code_verifier"}'))
        self.assertEqual(result["local_checks"]["local_consistency"],"unobserved")
        self.assertEqual(result["outcome"],"indeterminate")
        self.assertFalse(result["pkce_rejection_proven"])
        result=self.observed_run(duplicate=True,body=b'{"access_token":"fixture-private-token"}')
        self.assertEqual(result["outcome"],"failed")
        self.assertNotIn("fixture-private-token",json.dumps(result))

    def test_v3_time_buckets_are_callback_return_to_preparation_not_code_age(self):
        for elapsed,bucket,consistent in [(0,"under_5s",True),(4.999,"under_5s",True),(5,"under_30s",True),
                                          (29.999,"under_30s",True),(30,"older",True),(-1,"unobserved",False)]:
            result=self.observed_run(elapsed=elapsed)
            self.assertEqual(result["local_checks"]["callback_return_to_request_prepared"],bucket)
            self.assertEqual(result["local_checks"]["local_consistency"]=="consistent",consistent)

    def test_v3_public_rfc_vector_and_observer_clear(self):
        self.assertEqual(probe.challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),"E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        a=probe.Attempt.create("wrong")
        observer=probe.PreparedRequestObserver(a,"fixture-id","fixture-secret",lambda:0)
        observer.observe_authorization(probe.authorization_url("fixture-id","http://127.0.0.1:1234/oauth/callback",a),"http://127.0.0.1:1234/oauth/callback")
        observer.callback_returned("fixture-code","http://127.0.0.1:1234/oauth/callback")
        observer.clear()
        self.assertEqual(observer.authorization,{})
        self.assertEqual(observer.client_id,"")
        self.assertEqual(observer.secret,"")
        self.assertEqual(observer.code,"")
        self.assertIsNone(observer.returned_at)

    def test_v3_same_original_verifier_and_header_mutation_cannot_pass(self):
        attempt=probe.Attempt.create("wrong")
        original_verifier=attempt.verifier
        def mutate(request):
            fields=dict(urllib.parse.parse_qsl(request.data.decode()))
            fields["code_verifier"]=original_verifier
            request.data=urllib.parse.urlencode(fields).encode()
        with mock.patch.object(probe.Attempt,"create",return_value=attempt):
            result=self.observed_run(mutate_request=mutate)
        self.assertEqual(result["local_checks"]["submitted_verifier"],"valid_same")
        self.assertEqual(result["outcome"],"indeterminate")
        result=self.observed_run(mutate_request=lambda r:r.add_header("Content-Type","application/json"))
        self.assertFalse(result["local_checks"]["token_request_shape_valid"])
        self.assertFalse(result["pkce_rejection_proven"])

    def test_v3_failure_always_detaches_and_clears_observer_context(self):
        captured=[]
        def acquire(client,attempt,deadline):
            observer=deadline.observer
            redirect="http://127.0.0.1:1234/oauth/callback"
            observer.observe_authorization(probe.authorization_url(client,redirect,attempt),redirect)
            captured.append((observer,deadline))
            raise RuntimeError("fixture-private-exception")
        result=probe.run_case("wrong","fixture-id","fixture-secret",acquire=acquire)
        observer,deadline=captured[0]
        self.assertIsNone(deadline.observer)
        self.assertEqual(observer.authorization,{})
        for value in [observer.client_id,observer.secret,observer.code,observer.redirect,observer.callback_redirect]:
            self.assertEqual(value,"")
        self.assertIsNone(observer.attempt)
        self.assertIsNone(observer.clock)
        self.assertIsNone(observer.returned_at)
        self.assertEqual(result["outcome"],"indeterminate")
        self.assertNotIn("fixture-private-exception",json.dumps(result))



class SemanticReviewTests(unittest.TestCase):
    # Development fixtures only. Independent U04 holdout and expected labels are not read here.
    def output(self, **changes):
        value = {"protocol_version": 1, "semantic_category": "verifier_mismatch_asserted",
                 "review_status": "confirmed", "reveal_started": True, "user_confirmed": True}
        value.update(changes)
        return json.dumps(value).encode()

    def test_privacy_gate_known_context_forms_and_unknown_limits(self):
        secret = "synthetic<private>&value"
        forms = [secret, secret.upper(), urllib.parse.quote(secret, safe=""),
                 urllib.parse.quote_plus(secret), probe.html.escape(secret),
                 json.dumps(secret)[1:-1], probe.base64.b64encode(secret.encode()).decode(),
                 probe.base64.urlsafe_b64encode(secret.encode()).decode().rstrip("="),
                 "".join("&#%d;" % ord(char) for char in secret),
                 "".join("\\u%04x" % ord(char) for char in secret)]
        for value in forms:
            self.assertFalse(probe.privacy_allowed("Provider says " + value, [secret]))
        for value in ["https://example.invalid/a", "www.example.invalid", "line\nsecret", "a\x00b", "a\u202eb",
                      "A" * 24, "x" * 4097, "\ud800"]:
            self.assertFalse(probe.privacy_allowed(value, ()))
        self.assertTrue(probe.privacy_allowed("The request was refused because its verifier differed.", ()))
        self.assertTrue(probe.privacy_allowed("No active grant was found.", ()))

    def test_candidate_strict_shape_size_and_token_rejection(self):
        invalid = [b'{"error":"invalid_grant","error_description":"safe","access_token":""}',
                   b'{"error":"invalid_grant","error_description":"safe","extra":"x"}',
                   b'{"error":"invalid_grant","error":"invalid_client","error_description":"safe"}',
                   b'{"error":"invalid_grant","error_description":7}', b'\xff',
                   b'{"error":"invalid_grant","error_description":"safe"} trailing']
        for raw in invalid:
            candidate = probe.SemanticCandidate()
            probe.prepare_semantic_candidate(400, raw, (), candidate)
            self.assertEqual(candidate.description, "")
        raw = json.dumps({"error": "invalid_grant", "error_description": "A harmless sentence."}).encode()
        candidate = probe.SemanticCandidate()
        probe.prepare_semantic_candidate(400, raw, (), candidate)
        self.assertEqual(candidate.description, "A harmless sentence.")
        probe.prepare_semantic_candidate(500, raw, (), candidate)
        self.assertEqual(candidate.description, "")
        for value in ["é" * 2049, "synthetic-private-context"]:
            raw = json.dumps({"error": "invalid_grant", "error_description": value}).encode()
            probe.prepare_semantic_candidate(400, raw, ["synthetic-private-context"], candidate)
            self.assertEqual(candidate.description, "")

    def test_output_strict_schema_types_and_status_consistency(self):
        self.assertEqual(probe.validate_semantic_output(self.output())["semantic_category"], "verifier_mismatch_asserted")
        invalid = [self.output(protocol_version=True), self.output(semantic_category={}),
                   self.output(review_status=[]), self.output(reveal_started=1),
                   self.output(extra="private"), self.output(review_status="declined"),
                   self.output(reveal_started=False), self.output(user_confirmed=False),
                   b'{"protocol_version":1,"protocol_version":1}', b'\xff', b'{} trailing', b'x' * 513]
        for raw in invalid:
            self.assertEqual(probe.validate_semantic_output(raw)["semantic_category"], "indeterminate")
            self.assertEqual(probe.validate_semantic_output(raw)["reason"], "helper_protocol")
        self.assertEqual(probe.validate_semantic_output(self.output(), 1)["reason"], "helper_protocol")

    def test_confirmed_abstention_does_not_become_proof(self):
        observation = probe.validate_semantic_output(self.output(semantic_category="indeterminate"))
        self.assertEqual(observation["review_status"], "confirmed")
        self.assertEqual(observation["semantic_category"], "indeterminate")
        result = probe.safe_result()
        before = (result["outcome"], result["pkce_rejection_proven"])
        result["provider_semantic_observation"] = observation
        self.assertEqual(before, (result["outcome"], result["pkce_rejection_proven"]))

    def test_strong_error_conflicts_are_separate_attestation_axis(self):
        for category in ["configuration", "redirect", "auth"]:
            observation = probe.validate_semantic_output(self.output())
            result = probe.apply_semantic_conflict(observation, category)
            self.assertEqual(result["review_status"], "conflict")
            self.assertEqual(result["semantic_category"], "indeterminate")
        observation = probe.validate_semantic_output(self.output(semantic_category="client_redirect_configuration_asserted"))
        self.assertEqual(probe.apply_semantic_conflict(observation, "configuration")["review_status"], "confirmed")

    def test_unconfirmed_cleanup_never_launches_helper(self):
        candidate = probe.SemanticCandidate("Safe sentence.", "unknown", "ready")
        helper = mock.Mock()
        result = probe.review_semantic_candidate(candidate, helper)
        helper.assert_not_called()
        self.assertEqual(result["reason"], "cleanup_unconfirmed")
        self.assertEqual(candidate.description, "")

    def test_run_case_cleans_context_before_review_and_preserves_outcome(self):
        captured = {}
        def acquire(client, attempt, deadline):
            captured.update(attempt=attempt, observer=deadline.observer, deadline=deadline)
            attempt.claimed = True
            return "synthetic-code", "http://127.0.0.1:1234/oauth/callback"
        def send(fields, _deadline):
            captured["fields"] = fields
            return 400, b'{"error":"invalid_grant","error_description":"No active grant was found."}'
        candidate = probe.SemanticCandidate()
        result = probe.run_case("wrong", "synthetic-client", "synthetic-secret", acquire, send,
                                semantic_candidate=candidate)
        def helper(description):
            self.assertEqual(captured["attempt"].state, "")
            self.assertEqual(captured["fields"], {})
            self.assertIsNone(captured["deadline"].observer)
            self.assertEqual(captured["observer"].client_id, "")
            self.assertTrue(candidate.description == "")
            return probe.validate_semantic_output(self.output(semantic_category="grant_or_code_asserted"))
        before = (result["outcome"], result["pkce_rejection_proven"])
        result["provider_semantic_observation"] = probe.review_semantic_candidate(candidate, helper)
        self.assertEqual(result["provider_semantic_observation"]["semantic_category"], "grant_or_code_asserted")
        self.assertEqual(before, (result["outcome"], result["pkce_rejection_proven"]))

    def test_cleanup_and_gate_failures_never_reveal_or_log_sentinels(self):
        candidate = probe.SemanticCandidate()
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            def unavailable(*_args):
                raise ValueError("synthetic-private-exception")
            result = probe.run_case("wrong", "synthetic-client", "synthetic-secret", acquire=unavailable,
                                    semantic_candidate=candidate)
            helper = mock.Mock()
            observation = probe.review_semantic_candidate(candidate, helper)
        helper.assert_not_called()
        safe = json.dumps([result, observation]) + out.getvalue() + err.getvalue()
        for sentinel in ["synthetic-client", "synthetic-secret", "synthetic-private-exception", "Traceback"]:
            self.assertNotIn(sentinel, safe)

    def test_default_path_never_launches_helper(self):
        with mock.patch.object(probe, "launch_semantic_helper") as helper:
            probe.run_case("missing", "fixture-id", "fixture-secret", acquire=acquire_fixture,
                           send=lambda *_: (400, b'{"error":"invalid_grant"}'))
        helper.assert_not_called()

    def test_calibration_command_has_no_network_or_credentials(self):
        with mock.patch.object(probe, "calibrate_semantic_review", return_value=0) as calibration, \
             mock.patch.object(probe, "run_case", side_effect=AssertionError()), \
             mock.patch.object(probe.getpass, "getpass", side_effect=AssertionError()), \
             mock.patch.object(probe, "authorize", side_effect=AssertionError()), \
             mock.patch.object(probe, "send_token", side_effect=AssertionError()):
            self.assertEqual(probe.main(["--calibrate-semantic-review"]), 0)
            calibration.assert_called_once_with()

    def test_calibration_projection_never_returns_expected_labels(self):
        # Schema-only synthetic records, not the independent U04 holdout or its answers.
        raw = json.dumps({"schema_version": 1, "cases": [
            {"id": f"u{index:02d}", "description": "A harmless synthetic sentence.",
             "expected_category": {"opaque-not-read": True}} for index in range(1, 17)]}).encode()
        descriptions = probe.calibration_descriptions(raw)
        self.assertEqual(descriptions, ["A harmless synthetic sentence."] * 16)
        self.assertNotIn("opaque-not-read", json.dumps(descriptions))

    def test_helper_runtime_stderr_is_never_forwarded(self):
        candidate = probe.SemanticCandidate("Safe text.", "unknown", "ready", True)
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            observation = probe.review_semantic_candidate(candidate,
                helper=lambda _: (_ for _ in ()).throw(ValueError("synthetic-secret-exception")))
        self.assertNotIn("synthetic-secret-exception", json.dumps(observation) + out.getvalue() + err.getvalue())



class SemanticCleanupAndHelperProtocolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scratch = tempfile.TemporaryDirectory(prefix="rivet-semantic-test-")
        cls.binary = str(Path(cls.scratch.name) / "semantic-check")
        source = Path(probe.__file__).with_name("pkce_semantic_review.swift")
        compiled = subprocess.run(["/usr/bin/xcrun", "swiftc", "-swift-version", "6", str(source), "-o", cls.binary],
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
        if compiled.returncode:
            raise AssertionError("private helper synthetic compile failed")

    @classmethod
    def tearDownClass(cls):
        cls.scratch.cleanup()

    def test_swift_exact_protocol_rejects_duplicate_escaped_bool_and_invalid_input(self):
        valid = b'{"protocol_version":1,"description":"Harmless synthetic text."}'
        invalid = [b'{"protocol_version":true,"description":"safe"}',
                   b'{"protocol_version":1.0,"description":"safe"}',
                   b'{"protocol_version":1,"description":"safe","description":"other"}',
                   b'{"protocol_version":1,"description":"safe","descrip\\u0074ion":"other"}',
                   b'{"protocol_version":1,"description":"safe","extra":1}',
                   b'{"protocol_version":1,"description":null}', valid+b'{}', b'\xff',
                   json.dumps({"protocol_version":1,"description":"x"*4097}).encode(), b'x'*16385]
        for raw in [valid] + invalid:
            result = subprocess.run([self.binary, "--protocol-check"], input=raw,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=3)
            self.assertEqual(result.returncode == 0, raw == valid)
            self.assertLessEqual(len(result.stdout), 512)
            self.assertNotIn(b'Harmless synthetic', result.stdout+result.stderr)
            self.assertFalse(json.loads(result.stdout)["reveal_started"])
            self.assertFalse(json.loads(result.stdout)["user_confirmed"])

    def test_send_frame_drops_request_body_and_response_references(self):
        captured = {}
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.read.return_value = b'{"error":"invalid_grant"}'
        response.code = 400
        def open_request(*_args, **_kwargs):
            captured["frame"] = inspect.currentframe().f_back
            return response
        opener = mock.Mock()
        opener.open.side_effect = open_request
        with mock.patch.object(probe, "make_opener", return_value=opener), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            probe.send_token({"code":"fixture-code"}, probe.Deadline())
        # Mock internals may add a frame: walk only to the actual private send frame.
        frame = captured["frame"]
        while frame is not None and frame.f_code.co_name != "send_token":
            frame = frame.f_back
        self.assertIsNotNone(frame)
        self.assertIsNone(frame.f_locals["request"])
        self.assertIsNone(frame.f_locals["response"])
        self.assertEqual(frame.f_locals["body"], b"")

    def test_main_configuration_is_cleared_before_any_helper_launch(self):
        captured = {}
        def fake_run(_case, _client, _secret, semantic_candidate):
            semantic_candidate.description = "Harmless synthetic sentence."
            semantic_candidate.reason = "ready"
            semantic_candidate.cleanup_completed = True
            return probe.safe_result()
        def fake_review(candidate):
            parent = inspect.currentframe().f_back
            while parent is not None and parent.f_code.co_name != "main":
                parent = parent.f_back
            self.assertIsNotNone(parent)
            captured["client"] = parent.f_locals["client_id"]
            captured["secret"] = parent.f_locals["secret"]
            candidate.clear()
            return probe.semantic_unknown("human_unavailable", "declined")
        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(probe.sys.stdin, "isatty", return_value=True), \
             mock.patch.object(probe.sys.stderr, "isatty", return_value=True), \
             mock.patch.object(probe.getpass, "getpass", side_effect=["fixture-client", "fixture-secret"]), \
             mock.patch.object(probe, "run_case", side_effect=fake_run), \
             mock.patch.object(probe, "review_semantic_candidate", side_effect=fake_review), \
             contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            probe.main(["--case","wrong","--review-semantics"])
        self.assertEqual(captured, {"client":"", "secret":""})
        self.assertNotIn("fixture-client", out.getvalue()+err.getvalue())
        self.assertNotIn("fixture-secret", out.getvalue()+err.getvalue())



class SemanticParentProcessTests(unittest.TestCase):
    def process(self, raw):
        child = mock.MagicMock()
        child.__enter__.return_value = child
        child.stdin = io.BytesIO()
        child.stdout = io.BytesIO(raw)
        child.returncode = 0
        child.poll.return_value = 0
        return child

    def test_anonymous_pipe_only_and_empty_stderr_required(self):
        raw = b'{"protocol_version":1,"semantic_category":"indeterminate","review_status":"confirmed","reveal_started":true,"user_confirmed":true}'
        child = self.process(raw)
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.object(probe.subprocess, "run", return_value=mock.Mock(returncode=0)), \
             mock.patch.object(probe.subprocess, "Popen", return_value=child) as popen, \
             mock.patch.object(probe, "read_helper_output", return_value=raw), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()), \
             contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            result = probe.launch_semantic_helper("A synthetic private sentence.")
        self.assertEqual(result["review_status"], "confirmed")
        self.assertEqual(popen.call_args.kwargs["stdin"], subprocess.PIPE)
        self.assertEqual(popen.call_args.kwargs["stderr"], subprocess.PIPE)
        self.assertNotIn("synthetic private", str(popen.call_args))
        self.assertEqual(stdout.getvalue()+stderr.getvalue(), "")

    def test_helper_oversize_output_is_killed_and_unknown(self):
        child = self.process(b'x'*513)
        with mock.patch.object(probe.subprocess, "run", return_value=mock.Mock(returncode=0)), \
             mock.patch.object(probe.subprocess, "Popen", return_value=child), \
             mock.patch.object(probe, "read_helper_output", side_effect=probe.Stop("helper_protocol")), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            result = probe.launch_semantic_helper("Harmless text.")
        child.kill.assert_called_once()
        self.assertEqual(result["reason"], "helper_protocol")
        self.assertEqual(result["semantic_category"], "indeterminate")

    def test_parent_watchdog_is_unknown_and_kills_helper(self):
        child = self.process(b'')
        child.stdout = mock.Mock()
        child.stdout.read.side_effect = probe.Stop("timeout")
        with mock.patch.object(probe.subprocess, "run", return_value=mock.Mock(returncode=0)), \
             mock.patch.object(probe.subprocess, "Popen", return_value=child), \
             mock.patch.object(probe, "read_helper_output", side_effect=probe.Stop("timeout")), \
             mock.patch.object(probe, "time_budget", return_value=contextlib.nullcontext()):
            result = probe.launch_semantic_helper("Harmless text.")
        child.kill.assert_called_once()
        self.assertEqual(result["review_status"], "expired")
        self.assertFalse(result["user_confirmed"])



class SemanticStderrBoundaryTests(unittest.TestCase):
    # Real anonymous pipes exercise ready/EOF/backpressure, never a Human or OAuth helper.
    def child(self, script):
        return subprocess.Popen([probe.sys.executable, "-c", script], stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def test_valid_stdout_plus_any_stderr_is_unknown_and_never_echoed(self):
        valid = b'{"protocol_version":1,"semantic_category":"verifier_mismatch_asserted","review_status":"confirmed","reveal_started":true,"user_confirmed":true}'
        script = "import sys,os;sys.stdin.buffer.read();os.write(1,"+repr(valid)+");os.write(2,b'synthetic-private-stderr')"
        output, error = io.StringIO(), io.StringIO()
        child = self.child(script)
        try:
            with mock.patch.object(probe.subprocess, "run", return_value=mock.Mock(returncode=0)), \
                 mock.patch.object(probe.subprocess, "Popen", return_value=child), \
                 contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
                result = probe.launch_semantic_helper("Harmless synthetic text.")
        finally:
            if child.poll() is None:
                child.kill()
            child.wait()
        self.assertEqual(result["reason"], "helper_protocol")
        self.assertEqual(result["semantic_category"], "indeterminate")
        self.assertNotIn("synthetic-private-stderr", json.dumps(result)+output.getvalue()+error.getvalue())

    def test_unbounded_stderr_cannot_fill_pipe_or_hang_collector(self):
        child = self.child("import os\nwhile True: os.write(2, b'x' * 65536)")
        try:
            with self.assertRaisesRegex(probe.Stop, "helper_protocol"):
                probe.read_helper_output(child, 2)
        finally:
            child.kill()
            child.wait(timeout=2)
            child.stdin.close()
            child.stdout.close()
            child.stderr.close()

    def test_idle_pipes_use_watchdog_without_waiting_for_eof(self):
        child = self.child("import time;time.sleep(10)")
        try:
            with self.assertRaisesRegex(probe.Stop, "timeout"):
                probe.read_helper_output(child, 0.02)
        finally:
            child.kill()
            child.wait(timeout=2)
            child.stdin.close()
            child.stdout.close()
            child.stderr.close()



class InstalledTranslationCoreTests(unittest.TestCase):
    # Controlled stubs only; never invoke the installed engine or read independent holdout.
    def test_private_core_bounds_timeout_cancellation_and_late_result(self):
        source = Path(probe.__file__).with_name("pkce_semantic_review.swift").read_text()
        core = source.split("// V_NORMAL_ENTRY", 1)[0]
        harness = r"""
func delayedSyntheticResult() async -> LocalTranslationResult {
  await withCheckedContinuation { continuation in
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.04) {
      continuation.resume(returning: LocalTranslationResult(status: "translated", text: "受控合成文字。"))
    }
  }
}
Task {
  var checks: [String: Bool] = [:]
  checks["valid_chinese"] = translatedTextAllowed("受控合成文字。")
  checks["empty_rejected"] = !translatedTextAllowed("   ")
  checks["limit_rejected"] = !translatedTextAllowed(String(repeating: "中", count: 2731))
  checks["url_rejected"] = !translatedTextAllowed("https://example.invalid")
  checks["bidi_rejected"] = !translatedTextAllowed("中\u{202e}文")
  checks["control_rejected"] = !translatedTextAllowed("中\n文")
  checks["opaque_rejected"] = !translatedTextAllowed(String(repeating: "x", count: 24))
  let valid = await translateForReview("Controlled source.", operation: { _ in
    LocalTranslationResult(status: "translated", text: "受控合成文字。")
  })
  checks["controlled_translation"] = valid.status == "translated"
  let bad = await translateForReview("Controlled source.", operation: { _ in
    LocalTranslationResult(status: "translated", text: "https://example.invalid")
  })
  checks["controlled_invalid_rejected"] = bad.status == "translation_failed" && bad.text.isEmpty
  let timed = await translateForReview("Controlled source.", seconds: 0.005, operation: { _ in
    await delayedSyntheticResult()
  })
  checks["deadline_not_waiting_for_worker"] = timed.status == "timed_out" && timed.text.isEmpty
  try? await Task.sleep(for: .milliseconds(60))
  checks["late_did_not_replace_result"] = timed.status == "timed_out" && timed.text.isEmpty
  let task = Task {
    await translateForReview("Controlled source.", operation: { _ in await delayedSyntheticResult() })
  }
  task.cancel()
  let cancelled = await task.value
  checks["cancelled_no_text"] = cancelled.status == "cancelled" && cancelled.text.isEmpty
  let invalidSource = await translateForReview(String(repeating: "x", count: 4097), operation: { _ in
    LocalTranslationResult(status: "translated", text: "不應使用。")
  })
  checks["source_limit"] = invalidSource.status == "translation_failed" && invalidSource.text.isEmpty
  FileHandle.standardOutput.write(try! JSONSerialization.data(withJSONObject: checks))
  exit(checks.values.allSatisfy { $0 } ? 0 : 1)
}
dispatchMain()
"""
        with tempfile.TemporaryDirectory(prefix="rivet-translation-core-") as folder:
            path = Path(folder) / "main.swift"
            path.write_text(core + harness)
            binary = str(Path(folder) / "core-tests")
            compiled = subprocess.run(["/usr/bin/xcrun", "swiftc", "-swift-version", "6", str(path), "-o", binary],
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
            self.assertEqual(compiled.returncode, 0, "controlled core harness compile failed")
            result = subprocess.run([binary], stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, b"")
        checks = json.loads(result.stdout)
        self.assertEqual(len(checks), 13)
        self.assertTrue(all(value is True for value in checks.values()))


if __name__ == "__main__":
    unittest.main()
