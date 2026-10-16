#!/usr/bin/env python3
"""Adversarial synthetic trust ownership paths; no Security calls or trust mutations."""
import contextlib
import io
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

EXPERIMENT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EXPERIMENT / 'scripts'))
import run_self_signed_probe as runner


class Function:
    def __init__(self, function):
        self.function = function

    def __call__(self, *args):
        return self.function(*args)


class TrustCleanupOwnership(unittest.TestCase):
    def exercise(self, outcome):
        removals = []
        state = {'foreign': False, 'ours': False, 'path': None}
        absent = {name: {'absent': True} for name in ('user', 'admin', 'system')}

        def create(path, _length, _password, _prompt, _access, output):
            state['path'] = Path(path.decode())
            state['path'].write_text('synthetic keychain')
            output._obj.value = 1
            return 0

        def delete(_keychain):
            state['path'].unlink()
            return 0

        class Security:
            SecKeychainCreate = Function(create)
            SecKeychainDelete = Function(delete)

        def fake_run(argv, **_kwargs):
            name = Path(argv[0]).name
            if name == 'security' and argv[1] in ('default-keychain', 'list-keychains'):
                return subprocess.CompletedProcess(argv, 0, b'synthetic stable settings', b'')
            if name == 'security' and argv[1] == 'import':
                return subprocess.CompletedProcess(argv, 0, b'', b'')
            if name == 'openssl':
                for flag in ('-keyout', '-out'):
                    if flag in argv:
                        Path(argv[argv.index(flag) + 1]).write_bytes(b'synthetic material')
                return subprocess.CompletedProcess(argv, 0, b'', b'')
            if name == 'swiftc':
                Path(argv[argv.index('-o') + 1]).write_bytes(b'synthetic helper')
                return subprocess.CompletedProcess(argv, 0, b'', b'')
            if name == 'trust-probe':
                mode = argv[1]
                code = 0
                if mode == 'inspect':
                    data = absent if not state['ours'] and not state['foreign'] else {
                        **absent, 'user': {'absent': False, 'codeSigningOnly': True}}
                elif mode == 'add-code-signing':
                    if outcome == 'declined':
                        state['foreign'] = True  # A second baseline rejects a foreign setting.
                        data, code = {'mutationAttempted': False}, 2
                    else:
                        state['ours'] = True  # Failed return/timeout can follow a partial mutation.
                        if outcome == 'timeout':
                            raise subprocess.TimeoutExpired(argv, 60)
                        data, code = {'mutationAttempted': True, 'status': -1}, 1
                elif mode == 'remove-user':
                    removals.append(mode)
                    if state['foreign']:
                        raise AssertionError('foreign trust must never be removed')
                    state['ours'] = False
                    data = {'status': 0}
                else:
                    raise AssertionError('unexpected trust mode')
                return subprocess.CompletedProcess(argv, code, json.dumps(data), '')
            raise AssertionError('unexpected external command; no host/OAuth execution permitted')

        original = {s: signal.getsignal(s) for s in (signal.SIGINT, signal.SIGTERM)}
        with tempfile.TemporaryDirectory(prefix='E005-synthetic-trust-') as directory:
            out = Path(directory) / 'report.json'
            try:
                with patch.object(sys, 'argv', ['probe', '--pem-import', '--trust-code-signing', '--out', str(out)]), \
                     patch.object(runner.ctypes, 'CDLL', lambda _path: Security()), \
                     patch.object(runner.subprocess, 'run', fake_run), \
                     contextlib.redirect_stdout(io.StringIO()):
                    result = runner.main()
            finally:
                for s, handler in original.items():
                    signal.signal(s, handler)
            report = json.loads(out.read_text())
        self.assertEqual(result, 1)
        self.assertTrue(report['cleanupComplete'])
        self.assertEqual(report['commands'], [])
        if outcome == 'declined':
            self.assertEqual(removals, [])
            self.assertTrue(state['foreign'])
            self.assertEqual(report['stopReason'], 'helperDeclinedTrustMutation')
        else:
            self.assertEqual(removals, ['remove-user'])
            self.assertFalse(state['ours'])
            self.assertTrue(report['trustRemovalVerifiedAbsent'])

    def test_helper_declines_mutation_preserves_foreign_trust(self):
        self.exercise('declined')

    def test_partial_failed_add_is_removed_and_absence_verified(self):
        self.exercise('partial')

    def test_add_timeout_still_removes_partial_trust(self):
        self.exercise('timeout')


if __name__ == '__main__':
    unittest.main()
