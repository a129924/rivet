#!/usr/bin/env python3
"""Synthetic runner control-flow evidence; never calls Security or builds a host."""
import contextlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import unittest
from unittest.mock import patch

EXPERIMENT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EXPERIMENT / 'scripts'))
import run_probe


class ControlledSignalCleanup(unittest.TestCase):
    def exercise(self, stop_signal):
        live = set()
        writes = []
        deletes = []
        repeated = []
        out = EXPERIMENT / 'evidence' / ('synthetic-' + stop_signal.name.lower() + '.json')

        def fake_build(app, rebuilt=False):
            executable = app / 'Contents/MacOS/keychain-probe'
            executable.parent.mkdir(parents=True, exist_ok=True)
            executable.write_text('synthetic host; never executed')
            return executable

        def fake_identity(app):
            return {'signatureValid': True, 'adHoc': True, 'profilePresent': False,
                    '_requirement': 'synthetic', '_entitlements': b'', '_bundleID': 'synthetic'}

        def fake_run(argv, **kwargs):
            mode, item = argv[1], argv[3]
            if mode == 'write-a':
                live.add(item)
                writes.append(item)
                os.kill(os.getpid(), stop_signal)
                raise AssertionError('signal should enter runner exception path')
            if mode == 'delete':
                repeated.append(stop_signal.name)
                os.kill(os.getpid(), stop_signal)
                live.discard(item)
                deletes.append(item)
                data = {'deleted': True}
            elif mode == 'read-absent':
                if item in live:
                    raise AssertionError('item was not deleted')
                data = {'absent': True}
            elif mode == 'synthetic-check':
                data = {'synthetic': True}
            else:
                raise AssertionError('unexpected mode: ' + mode)
            return subprocess.CompletedProcess(argv, 0, json.dumps(data) + '\n', '')

        original_handlers = {s: signal.getsignal(s) for s in (signal.SIGINT, signal.SIGTERM)}
        try:
            with patch.object(sys, 'argv', ['run_probe.py', '--backend', 'legacy', '--out', str(out)]), \
                 patch.object(run_probe, 'build', fake_build), \
                 patch.object(run_probe, 'identity', fake_identity), \
                 patch.object(run_probe.subprocess, 'run', fake_run), \
                 contextlib.redirect_stdout(io.StringIO()):
                result = run_probe.main()
        finally:
            for s, handler in original_handlers.items():
                signal.signal(s, handler)
        report = json.loads(out.read_text())
        report['syntheticHarness'] = {
            'synthetic': True, 'realKeychainOperations': False,
            'scope': 'runner signal control flow only; fake build, identity and subprocess',
            'signalAtWrite': stop_signal.name, 'repeatedSignalDuringDelete': repeated,
            'allWrittenItemsTrackedAndDeleted': writes == deletes and not live,
            'expectedRunnerExitCode': 1, 'actualRunnerExitCode': result}
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        self.assertEqual(result, 1)  # Interrupted full run is not a complete normal run.
        self.assertEqual(report['stopReason'], 'controlledSignalStop:' + stop_signal.name)
        self.assertTrue(report['cleanupComplete'])
        self.assertEqual(len(writes), 1)
        self.assertEqual(writes, deletes)
        self.assertFalse(live)
        self.assertEqual(repeated, [stop_signal.name])
        self.assertEqual([x['namespace'] for x in report['cleanup']], writes)
        self.assertTrue(all(x['absenceConfirmed'] for x in report['cleanup']))
        self.assertEqual(len(report['sourceSHA256']), 3)

    def test_sigterm_during_write_and_repeated_during_cleanup(self):
        self.exercise(signal.SIGTERM)

    def test_sigint_during_write_and_repeated_during_cleanup(self):
        self.exercise(signal.SIGINT)


if __name__ == '__main__':
    unittest.main()
