"""Focused synthetic regressions: selected macOS profile and real coordinator branches."""
import contextlib
import copy
import datetime as dt
import io
import json
import os
from pathlib import Path
import plistlib
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import preflight
import run_probe
import ux_stages as ux


class MacProfileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='E006-profile-fixture-')
        self.root = Path(self.tmp.name)
        self.app = self.root/'Fixture.app'
        (self.app/'Contents/MacOS').mkdir(parents=True)
        (self.app/'Contents/MacOS/DPKProbe').write_bytes(b'fake unsigned executable; never launched')
        (self.app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'DPKProbe'}))
        (self.app/'Contents/embedded.provisionprofile').write_bytes(b'fake CMS fixture; never decoded by Security')
        self.profile = {'Platform':['OSX'],'DeveloperCertificates':[b'fake-selected-leaf'],
                        'Entitlements':{'com.apple.application-identifier':'PREFIX.*','keychain-access-groups':['PREFIX.*']},
                        'ProvisionedDevices':['fixture-device'], 'ExpirationDate':dt.datetime(2031,1,1),
                        'CreationDate':dt.datetime(2029,1,1)}
        self.ent = {'com.apple.application-identifier':'PREFIX.app','keychain-access-groups':['PREFIX.app']}
        self.chain_valid = True
    def tearDown(self): self.tmp.cleanup()
    def command(self, args):
        if '--entitlements' in args: return plistlib.dumps(self.ent),b''
        if '-vvv' in args: return b'',b'Authority=Apple Development: synthetic\n'
        if '-r-' in args: return b'designated => identifier "fixture"',b''
        if 'cms' in args: return plistlib.dumps(self.profile),b''
        extraction = next((value for value in args if value.startswith('--extract-certificates=')), None)
        if extraction is not None:
            prefix = extraction.split('=', 1)[1]
            Path(prefix+'0').write_bytes(b'fake-selected-leaf')
        if 'verify-cert' in args and not self.chain_valid: raise ux.Rejected('selectedAssetValidationFailed')
        if '-enddate' in args: return b'notAfter=Jan  1 00:00:00 2031 GMT\n',b''
        return b'',b''
    def inspect(self):
        directory=self.root/('cert-'+str(len(list(self.root.glob('cert-*')))))
        directory.mkdir()
        with patch('preflight.command',side_effect=self.command): return preflight.inspect_app(self.app,directory)
    def test_valid_mac_profile_does_not_require_debugging_entitlement(self):
        item=self.inspect()
        self.assertNotIn('get-task-allow',item['profile']['Entitlements'])
        self.assertNotIn('com.apple.security.get-task-allow',item['profile']['Entitlements'])
        preflight.validate_profile(item['profile'],self.ent,'fixture-device',dt.datetime(2030,1,1,tzinfo=dt.timezone.utc))
    def test_selected_certificate_platform_device_group_expiry_still_reject(self):
        baseline=copy.deepcopy(self.profile)
        self.profile['DeveloperCertificates']=[b'other-cert']
        with self.assertRaises(ux.Rejected): self.inspect()
        self.profile=copy.deepcopy(baseline); self.chain_valid=False
        with self.assertRaises(ux.Rejected): self.inspect()
        self.chain_valid=True; self.profile=copy.deepcopy(baseline); self.profile['Platform']=['iOS']
        with self.assertRaises(ux.Rejected): self.inspect()
        self.profile=copy.deepcopy(baseline)
        for key,value in [('ProvisionedDevices',['other']),('ExpirationDate',dt.datetime(2030,1,1,0,34))]:
            bad=copy.deepcopy(baseline); bad[key]=value
            with self.assertRaises(ux.Rejected): preflight.validate_profile(bad,self.ent,'fixture-device',dt.datetime(2030,1,1,tzinfo=dt.timezone.utc))
        bad=copy.deepcopy(baseline); bad['Entitlements']['keychain-access-groups']=['OTHER.*']
        with self.assertRaises(ux.Rejected): preflight.validate_profile(bad,self.ent,'fixture-device',dt.datetime(2030,1,1,tzinfo=dt.timezone.utc))


class CoordinatorProcessTests(unittest.TestCase):
    def run_coordinator(self, survives, record_pid=True, foreign_pid=False, deadline_during_operation=False):
        with tempfile.TemporaryDirectory(prefix='E006-coordinator-fixture-') as temp:
            base=Path(temp)
            namespace='aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
            root=base/('rivet-E006-'+namespace); root.mkdir(mode=0o700)
            clock=[ux.now_utc()]
            start=clock[0]-dt.timedelta(minutes=2)
            ux.exclusive_json(root/'window.json',{'namespace':namespace,'kind':'setup-window','synthetic':False,
                'observationMode':'human-only','humanReadyStatement':'synthetic setup ready',
                'startUTC':start.isoformat(),'cutoffUTC':(start+dt.timedelta(minutes=25)).isoformat(),
                'deadlineUTC':(start+dt.timedelta(minutes=30)).isoformat()})
            first=base/'first.app'; second=base/'second.app'
            for app in (first,second):
                (app/'Contents/MacOS').mkdir(parents=True)
                (app/'Contents/MacOS/DPKProbe').write_bytes(b'fake; never launched')
                (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'DPKProbe'}))
            proof={'namespace':namespace,'firstApp':str(first),'secondApp':str(second),'firstHash':'1'*64,'secondHash':'2'*64,'windowSHA256':ux.sha256(root/'window.json')}
            selection=base/'selection.json'; ux.exclusive_json(selection,{'namespace':namespace})
            out=base/'safe-result.json'; events=[]; alive=[True]; ticks=iter([0,0,4]*10)
            binary=root/'current/DPKProbe.app/Contents/MacOS/DPKProbe'
            def ready(stage,phase):
                if phase>1: raise ux.Rejected('synthetic observation stop after phase 1')
            class OpenWrapper:
                def wait(self,timeout):
                    events.append('wrapper-wait')
                    if timeout!=3:
                        if deadline_during_operation: clock[0]=start+dt.timedelta(minutes=31)
                        raise subprocess.TimeoutExpired('mock open',timeout)
                    return 0
                def poll(self): return None
                def terminate(self): events.append('wrapper-term')
            def popen(args,**kwargs):
                phase=int(args[args.index('--phase')+1]); events.append('launch-'+str(phase))
                if phase==1:
                    if record_pid: ux.exclusive_json(root/'control/process-1.json',{'namespace':namespace,'phase':1,'pid':424242})
                    return OpenWrapper()
                # No real process/API exists: this receipt is a synthetic collaborator.
                ux.exclusive_json(root/f'receipts/phase-{phase}.machine.json',{'namespace':namespace,'phase':phase,
                    'completed':True,'synthetic':False,'absent':True,'proofSHA256':ux.sha256(root/'preflight.json'),
                    'executableSHA256':'1'*64})
                class Finished:
                    def wait(self,timeout): events.append('cleanup-wrapper-exited'); return 0
                    def poll(self): return 0
                return Finished()
            def process_query(args,**kwargs):
                events.append('owned-query')
                return subprocess.CompletedProcess(args,0 if alive[0] else 1,('/unrelated/other-app' if foreign_pid else str(binary)) if alive[0] else '', '')
            def kill(pid,sig):
                self.assertEqual(pid,424242)
                if foreign_pid: self.fail('must not signal unrelated reused PID')
                if sig==signal.SIGTERM:
                    events.append('owned-term')
                    if not survives: alive[0]=False
                elif sig==0:
                    if not alive[0]: events.append('owned-exited'); raise ProcessLookupError()
                else: self.fail('must not SIGKILL or signal other process')
            argv=['run_probe.py','--live','--human-asset-authorization','--selection',str(selection),'--scratch',str(root),'--out',str(out)]
            with contextlib.ExitStack() as stack:
                stack.enter_context(patch.object(sys,'argv',argv))
                stack.enter_context(patch('preflight.live_preflight',return_value=proof))
                stack.enter_context(patch('run_probe.now_utc',side_effect=lambda:clock[0]))
                stack.enter_context(patch('run_probe.verify_installed',return_value=root/'current/DPKProbe.app'))
                stack.enter_context(patch.object(run_probe.UXStages,'wait_ready',ready))
                stack.enter_context(patch('run_probe.subprocess.Popen',side_effect=popen))
                stack.enter_context(patch('run_probe.subprocess.run',side_effect=process_query))
                stack.enter_context(patch('run_probe.os.kill',side_effect=kill))
                stack.enter_context(patch('run_probe.time.monotonic',side_effect=lambda:next(ticks)))
                stack.enter_context(patch('run_probe.time.sleep',return_value=None))
                with contextlib.redirect_stdout(io.StringIO()): result=run_probe.main()
            return {'exitCode':result,'events':events,'rootPreserved':root.exists(),
                    'appPreserved':(root/'current/DPKProbe.app').exists(),
                    'recovery':(root/'recovery.json').exists(),'machine':json.loads(out.read_text())['machine'],
                    'manifest':json.loads(out.read_text())['manifest'],'expectedDeadline':(start+dt.timedelta(minutes=30)).isoformat()}
    def test_surviving_owned_process_blocks_cleanup_launch_and_retains_recovery(self):
        actual=self.run_coordinator(survives=True)
        self.assertEqual(actual['events'].count('launch-1'),1)
        self.assertNotIn('launch-4',actual['events'])
        self.assertTrue(actual['rootPreserved'] and actual['appPreserved'] and actual['recovery'])
        self.assertFalse(actual['machine']['cleanupComplete'])
        self.assertTrue(actual['machine']['recoveryRequired'])
    def test_missing_pid_after_open_timeout_is_unconfirmed_and_preserved(self):
        actual=self.run_coordinator(survives=True,record_pid=False)
        self.assertNotIn('launch-4',actual['events'])
        self.assertTrue(actual['rootPreserved'] and actual['appPreserved'] and actual['recovery'])
        self.assertFalse(actual['machine']['cleanupComplete'])
    def test_reused_foreign_pid_is_not_signalled(self):
        actual=self.run_coordinator(survives=True,foreign_pid=True)
        self.assertNotIn('owned-term',actual['events'])
        self.assertEqual(actual['events'].count('launch-4'),1)
        self.assertTrue(actual['machine']['cleanupComplete'])
    def test_cleanup_after_deadline_keeps_original_window(self):
        actual=self.run_coordinator(survives=False,deadline_during_operation=True)
        self.assertEqual(actual['events'].count('launch-4'),1)
        self.assertEqual(actual['manifest']['deadlineUTC'],actual['expectedDeadline'])
        self.assertTrue(actual['machine']['cleanupComplete'])
    def test_confirmed_owned_exit_precedes_cleanup_launch(self):
        actual=self.run_coordinator(survives=False)
        self.assertEqual(actual['events'].count('launch-4'),1)
        self.assertLess(actual['events'].index('owned-exited'),actual['events'].index('launch-4'))
        self.assertTrue(actual['machine']['cleanupComplete'])
        self.assertFalse(actual['rootPreserved'])

if __name__=='__main__': unittest.main()
