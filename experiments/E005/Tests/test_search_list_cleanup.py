#!/usr/bin/env python3
"""Synthetic lease ownership/concurrency tests; never call macOS Security."""
from pathlib import Path
import subprocess
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from run_self_signed_probe import SearchListLease


class SearchListCleanup(unittest.TestCase):
    def fixture(self, failure=None):
        original = ('/synthetic/first.keychain-db', '/synthetic/second.keychain-db')
        state = {'default': b'synthetic default', 'paths': original, 'writes': []}
        def read():
            return state['default'], state['paths']
        def write(paths):
            state['writes'].append(paths)
            state['paths'] = tuple(paths)
            if len(state['writes']) == 1 and failure:
                if failure == 'timeout':
                    raise subprocess.TimeoutExpired('synthetic write', 10)
                raise RuntimeError('controlledSignalStop:SIGTERM' if failure == 'signal' else 'partialWriteFailed')
        lease = SearchListLease('/synthetic/own.keychain', read(), read, write)
        return lease, state, original

    def test_normal_restores_exact_order_and_default(self):
        lease, state, original = self.fixture()
        lease.append()
        self.assertTrue(lease.facts['appendReadbackVerified'])
        self.assertTrue(lease.cleanup())
        self.assertEqual(state['paths'], original)
        self.assertTrue(lease.facts['defaultUnchanged'])

    def test_baseline_conflict_never_mutates(self):
        lease, state, _ = self.fixture()
        state['paths'] += ('/synthetic/foreign.keychain-db',)
        with self.assertRaisesRegex(RuntimeError, 'searchListBaselineConflict'):
            lease.append()
        self.assertTrue(lease.cleanup())
        self.assertEqual(state['writes'], [])

    def test_partial_failure_timeout_and_controlled_stop_cleanup(self):
        for failure in ('partial', 'timeout', 'signal'):
            with self.subTest(failure=failure):
                lease, state, original = self.fixture(failure)
                try:
                    with self.assertRaises((RuntimeError, subprocess.TimeoutExpired)):
                        lease.append()
                finally:
                    clean = lease.cleanup()
                self.assertTrue(clean)
                self.assertEqual(state['paths'], original)

    def test_foreign_concurrent_order_preserved_without_claiming_restore(self):
        lease, state, original = self.fixture()
        lease.append()
        state['paths'] = (original[1], '/synthetic/new.keychain-db', '/synthetic/own.keychain-db', original[0])
        self.assertFalse(lease.cleanup())
        self.assertEqual(state['paths'], (original[1], '/synthetic/new.keychain-db', original[0]))
        self.assertTrue(lease.facts['ownMembershipAbsent'])
        self.assertTrue(lease.facts['foreignSequencePreserved'])
        self.assertFalse(lease.facts['baselineRestored'])

    def test_own_already_removed_does_not_write_again(self):
        lease, state, original = self.fixture()
        lease.append()
        state['paths'] = original
        self.assertTrue(lease.cleanup())
        self.assertEqual(len(state['writes']), 1)

    def test_removal_failure_keeps_incomplete(self):
        lease, state, _ = self.fixture()
        lease.append()
        def fail(_paths):
            raise RuntimeError('synthetic remove failed')
        lease.write = fail
        self.assertFalse(lease.cleanup())
        self.assertFalse(lease.facts['ownMembershipAbsent'])
        self.assertTrue(lease.facts['removeWriteFailed'])


if __name__ == '__main__':
    unittest.main()
