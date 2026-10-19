import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import preflight
import ux_stages as ux
import run_probe

class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="E006-test-")
        self.root = Path(self.tmp.name)
        self.namespace = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
        self.now = dt.datetime(2030,1,1,tzinfo=dt.timezone.utc)
    def tearDown(self): self.tmp.cleanup()
    def test_group_exact_or_terminal_wildcard(self):
        self.assertTrue(preflight.covers("TEAM.local.rivet.*", "TEAM.local.rivet.app"))
        self.assertTrue(preflight.covers("TEAM.app", "TEAM.app"))
        self.assertFalse(preflight.covers("TEAM.other.*", "TEAM.app"))
        self.assertFalse(preflight.covers("TEAM.*.app", "TEAM.foo.app"))
    def test_profile_rejects_missing_group_expiry_device(self):
        profile = {"ExpirationDate": self.now + dt.timedelta(hours=1), "CreationDate": self.now - dt.timedelta(days=1),
                   "ProvisionedDevices": ["device"], "Entitlements": {"com.apple.application-identifier":"TEAM.*", "keychain-access-groups":["TEAM.*"]}}
        ent = {"com.apple.application-identifier":"TEAM.app", "keychain-access-groups":["TEAM.app"]}
        preflight.validate_profile(profile, ent, "device", self.now)
        for field, value in [("ExpirationDate", self.now+dt.timedelta(minutes=34)), ("ProvisionedDevices", ["other"])]:
            bad = dict(profile); bad[field] = value
            with self.assertRaises(ux.Rejected): preflight.validate_profile(bad,ent,"device",self.now)
        with self.assertRaises(ux.Rejected): preflight.validate_profile(profile,{**ent,"keychain-access-groups":["TEAM.app","TEAM.other"]},"device",self.now)
    def test_exclusive_receipt_and_symlink_rejected(self):
        f=self.root/"receipt.json"; ux.exclusive_json(f,{"safe":True})
        with self.assertRaises(ux.Rejected): ux.exclusive_json(f,{})
        link=self.root/"link"; link.symlink_to(f)
        with self.assertRaises(ux.Rejected): ux.safe_path(self.root,"link")
        with self.assertRaises(ux.Rejected): ux.safe_path(self.root,"../escape")
    def gate(self, sha):
        return {"namespace":self.namespace,"phase":1,"observationMode":"human-only","previousReceiptSHA256":sha,"humanReady":True,"humanReadyStatement":"ready","recordedUTC":self.now.isoformat()}
    def human(self, sha):
        return {"namespace":self.namespace,"phase":0,"observationMode":"human-only","machineReceiptSHA256":sha,"wholeStageObserved":True,"phaseIdentified":True,"promptCount":0,"actions":[],"purposes":[]}
    def test_sha_and_full_observation_gate(self):
        machine=self.root/"phase-0.machine.json"; ux.exclusive_json(machine,{"namespace":self.namespace,"phase":0})
        sha=ux.sha256(machine); gate=self.gate(sha); human=self.human(sha)
        ux.validate_gate(gate,human,machine,self.namespace,1,self.now-dt.timedelta(seconds=1),self.now+dt.timedelta(seconds=1))
        for key,value in [("synthetic",True),("phase",2),("phase",True),("namespace","wrong"),("previousReceiptSHA256","0"*64),("desktopConnected",True),("humanReady",False)]:
            with self.assertRaises(ux.Rejected): ux.validate_gate({**gate,key:value},human,machine,self.namespace,1,self.now-dt.timedelta(seconds=1),self.now+dt.timedelta(seconds=1))
        for key,value in [("wholeStageObserved",False),("phase",False),("promptCount",True),("actions",["allow"]),("synthetic",True)]:
            with self.assertRaises(ux.Rejected): ux.validate_gate(gate,{**human,key:value},machine,self.namespace,1,self.now-dt.timedelta(seconds=1),self.now+dt.timedelta(seconds=1))
        machine.write_text("changed")
        with self.assertRaises(ux.Rejected): ux.validate_gate(gate,human,machine,self.namespace,1,self.now,self.now+dt.timedelta(seconds=1))
    def test_deadline_and_abort_cleanup_once_no_ready(self):
        for trigger in ("abort","deadline","operation","observation"):
            log=[]
            def body(state):
                state["mayHaveWritten"]=True; log.append("save")
                raise ux.Rejected(trigger)
            result=run_probe.controlled_run(body,lambda:log.append("delete-read-absent") or True)
            self.assertEqual(log,["save","delete-read-absent"])
            self.assertTrue(result["cleanupComplete"])
            self.assertFalse(result["completed"])
        log=[]
        result=run_probe.controlled_run(lambda state: (_ for _ in ()).throw(ux.Rejected("preflight")),lambda:log.append("cleanup"))
        self.assertEqual(log,[]); self.assertEqual(result["cleanup"],"not-attempted")
    def test_incomplete_cleanup_keeps_recovery(self):
        def body(state): state["mayHaveWritten"]=True
        result=run_probe.controlled_run(body,lambda:False)
        self.assertFalse(result["cleanupComplete"]); self.assertTrue(result["recoveryRequired"])
    def test_redaction_only_allowlisted_public_fields(self):
        result=ux.public_receipt({"namespace":self.namespace,"phase":1,"error":"profileRejected","teamID":"secret","profilePath":"/private/personal","accessToken":"fake-secret","fields":{"accessToken":True}})
        self.assertNotIn("secret",json.dumps(result)); self.assertNotIn("/private",json.dumps(result))
        self.assertEqual(result["fields"],{"accessToken":True})
    def test_cutoff_abort_and_future_ready(self):
        machine=self.root/"phase-0.machine.json"; ux.exclusive_json(machine,{"phase":0})
        sha=ux.sha256(machine)
        gate=self.gate(sha); human=self.human(sha)
        with self.assertRaises(ux.Rejected): ux.validate_gate(gate,human,machine,self.namespace,1,self.now+dt.timedelta(seconds=1),self.now+dt.timedelta(seconds=2))
        with self.assertRaises(ux.Rejected): ux.validate_gate(gate,human,machine,self.namespace,1,self.now-dt.timedelta(seconds=2),self.now-dt.timedelta(seconds=1))
        owned=self.root/("rivet-E006-"+self.namespace); owned.mkdir(mode=0o700); (owned/"control").mkdir()
        manifest={"namespace":self.namespace,"cutoffUTC":self.now.isoformat(),"deadlineUTC":(self.now+dt.timedelta(minutes=5)).isoformat()}
        stages=ux.UXStages(owned,manifest,clock=lambda:self.now)
        with self.assertRaises(ux.Rejected): stages.guard_time(3)
        stages.guard_time(4)
        ux.exclusive_json(owned/"control/abort.json",{})
        with self.assertRaises(ux.Rejected): stages.guard_time(4)
    def test_keyboard_interrupt_and_cleanup_exception(self):
        def body(state): state["mayHaveWritten"]=True; raise KeyboardInterrupt()
        def fail(): raise RuntimeError("private diagnostic must not escape")
        result=run_probe.controlled_run(body,fail)
        self.assertTrue(result["recoveryRequired"])
        self.assertNotIn("private",json.dumps(result))
    def test_coordinator_cli_without_authorization_does_not_inspect(self):
        with patch.object(sys,"argv",["run_probe.py","--selection","missing","--scratch","missing","--out","missing"]), patch("preflight.live_preflight",side_effect=AssertionError("must not inspect")):
            with self.assertRaises(ux.Rejected): run_probe.main()
    def test_live_cli_requires_explicit_asset_authorization(self):
        with patch("preflight.inspect_app", side_effect=AssertionError("must not inspect")):
            with self.assertRaises(ux.Rejected): preflight.live_preflight({},asset_authorized=False)

if __name__ == "__main__": unittest.main()
