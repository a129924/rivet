"""Synthetic setup-window bookkeeping; never starts Human setup or a real App."""
import contextlib
import datetime as dt
import io
import json
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import run_probe
import preflight
import ux_stages as ux


class WindowTests(unittest.TestCase):
    namespace='aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
    now=dt.datetime(2030,1,1,12,10,tzinfo=dt.timezone.utc)
    def window(self,start=None,namespace=None):
        start=start or self.now-dt.timedelta(minutes=10)
        return {'namespace':namespace or self.namespace,'kind':'setup-window','synthetic':False,
                'observationMode':'human-only','humanReadyStatement':'Human ready before account/assets settings',
                'startUTC':start.isoformat(),'cutoffUTC':(start+dt.timedelta(minutes=25)).isoformat(),
                'deadlineUTC':(start+dt.timedelta(minutes=30)).isoformat()}
    def exercise(self,window,selection_start=None):
        with tempfile.TemporaryDirectory(prefix='E006-window-fixture-') as temp:
            base=Path(temp); root=base/('rivet-E006-'+self.namespace);root.mkdir(mode=0o700)
            if window is not None: ux.exclusive_json(root/'window.json',window)
            selection={'namespace':self.namespace}
            if selection_start is not None: selection['startUTC']=selection_start
            selection_file=base/'selection.json';ux.exclusive_json(selection_file,selection)
            app=base/'fixture.app';(app/'Contents/MacOS').mkdir(parents=True)
            (app/'Contents/MacOS/DPKProbe').write_bytes(b'fake; never launched')
            (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'DPKProbe'}))
            out=base/'safe.json';called=[]
            def inspect(value,authorized,**kwargs):
                called.append(value)
                return {'namespace':self.namespace,'firstHash':'1'*64,'secondHash':'2'*64,
                        'firstApp':str(app),'secondApp':str(app),
                        'windowSHA256':ux.sha256(root/'window.json'),'measurementStartUTC':value['startUTC']}
            def stop_before_write(stage,phase): raise ux.Rejected('synthetic stop before OAuth')
            argv=['run_probe.py','--live','--human-asset-authorization','--selection',str(selection_file),'--scratch',str(root),'--out',str(out)]
            with contextlib.ExitStack() as stack:
                stack.enter_context(patch.object(sys,'argv',argv))
                stack.enter_context(patch('run_probe.now_utc',return_value=self.now))
                stack.enter_context(patch('run_probe.preflight.live_preflight',side_effect=inspect))
                stack.enter_context(patch('run_probe.verify_installed',return_value=root/'current/DPKProbe.app'))
                stack.enter_context(patch.object(run_probe.UXStages,'wait_ready',stop_before_write))
                launches=stack.enter_context(patch('run_probe.subprocess.Popen',side_effect=AssertionError('no real launch')))
                error=None
                try:
                    with contextlib.redirect_stdout(io.StringIO()): run_probe.main()
                except ux.Rejected as caught: error=str(caught)
            return {'error':error,'inspectCalls':called,'launches':launches.call_count,
                    'receipt':json.loads(out.read_text()) if out.exists() else None}
    def test_elapsed_setup_window_is_not_reset_at_coordinator_start(self):
        window=self.window();actual=self.exercise(window)
        self.assertIsNone(actual['error'])
        self.assertEqual(actual['inspectCalls'][0]['startUTC'],window['startUTC'])
        manifest=actual['receipt']['manifest']
        for key in ('startUTC','cutoffUTC','deadlineUTC'): self.assertEqual(manifest[key],window[key])
        self.assertIn('windowSHA256',manifest)
        self.assertEqual(actual['launches'],0)
    def test_missing_mismatched_future_cutoff_expired_window_zero_inspect_launch(self):
        for window in (None,self.window(namespace='wrong'),self.window(start=self.now+dt.timedelta(seconds=1)),
                       self.window(start=self.now-dt.timedelta(minutes=25)),self.window(start=self.now-dt.timedelta(minutes=31))):
            with self.subTest(window=window):
                actual=self.exercise(window)
                self.assertIsNotNone(actual['error'])
                self.assertEqual(actual['inspectCalls'],[])
                self.assertEqual(actual['launches'],0)
    def test_selection_cannot_supply_a_new_start(self):
        actual=self.exercise(self.window(),selection_start=self.now.isoformat())
        self.assertIsNotNone(actual['error']);self.assertEqual(actual['inspectCalls'],[])
    def test_profile_created_during_setup_uses_now_but_expiry_uses_original_t0(self):
        start=self.now-dt.timedelta(minutes=10)
        ent={'com.apple.application-identifier':'PREFIX.app','keychain-access-groups':['PREFIX.app']}
        profile={'Entitlements':{'com.apple.application-identifier':'PREFIX.*','keychain-access-groups':['PREFIX.*']},
                 'ProvisionedDevices':['fixture-device'],'CreationDate':self.now-dt.timedelta(minutes=1),
                 'ExpirationDate':start+dt.timedelta(minutes=35)}
        preflight.validate_profile(profile,ent,'fixture-device',start,validated_at=self.now)
        with self.assertRaises(ux.Rejected): preflight.validate_profile({**profile,'ExpirationDate':start+dt.timedelta(minutes=34)},ent,'fixture-device',start,validated_at=self.now)
    def test_window_tamper_rejected_without_extending_cleanup_clock(self):
        with tempfile.TemporaryDirectory(prefix='E006-window-binding-') as temp:
            root=Path(temp);window=self.window(start=self.now-dt.timedelta(minutes=31))
            ux.exclusive_json(root/'window.json',window)
            manifest={**window,'windowSHA256':ux.sha256(root/'window.json')}
            proof={'windowSHA256':manifest['windowSHA256']}
            run_probe.bound_window(root,manifest,proof)
            self.assertEqual(manifest['deadlineUTC'],window['deadlineUTC'])
            (root/'window.json').write_text(json.dumps(self.window()))
            with self.assertRaises(ux.Rejected):run_probe.bound_window(root,manifest,proof)
    def test_begin_window_only_bookkeeping_exclusive_and_namespace_bound(self):
        with tempfile.TemporaryDirectory(prefix='E006-arm-fixture-') as temp:
            root=Path(temp)/('rivet-E006-'+self.namespace);root.mkdir(mode=0o700)
            argv=['run_probe.py','--begin-window','--namespace',self.namespace,'--scratch',str(root),'--human-ready-statement','Human ready before setup']
            with patch.object(sys,'argv',argv),patch('run_probe.now_utc',return_value=self.now),patch('run_probe.preflight.live_preflight',side_effect=AssertionError('no inspect')),patch('run_probe.subprocess.Popen',side_effect=AssertionError('no launch')):
                with contextlib.redirect_stdout(io.StringIO()): self.assertEqual(run_probe.main(),0)
                first=(root/'window.json').read_bytes()
                self.assertEqual(json.loads(first)['namespace'],self.namespace)
                with self.assertRaises(ux.Rejected): run_probe.main()
                self.assertEqual(first,(root/'window.json').read_bytes())

if __name__=='__main__':unittest.main()
