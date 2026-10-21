"""全部為 fixture；不讀機密、不開真瀏覽器、不連 GitHub。"""
import contextlib
import io
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

        code, redirect = probe.authorize("fixture-id", attempt, probe.Deadline(5), opener=opener)
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
            "description_mentions_verifier", "signals_conflict", "pkce_rejection_proven"})

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
                        self.assertEqual(result["diagnostic_version"], 2)

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
            self.assertEqual(result["diagnostic_version"], 2)
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


if __name__ == "__main__":
    unittest.main()
