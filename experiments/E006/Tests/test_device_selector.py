"""Existing observed system_profiler JSON shape, with synthetic device values only."""
import datetime as dt
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import preflight
import ux_stages as ux


class ProvisioningDeviceTests(unittest.TestCase):
    provisioning='11111111-2222222222222222'
    hardware='AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
    def document(self):
        return {'SPHardwareDataType':[{'provisioning_UDID':self.provisioning,'platform_UUID':self.hardware}]}
    def parse(self, value):
        with patch('preflight.command',side_effect=AssertionError('pure parser must not execute host/assets')):
            return preflight.provisioning_device_id(json.dumps(value).encode())
    def profile(self, device):
        start=dt.datetime(2030,1,1,tzinfo=dt.timezone.utc)
        return {'ProvisionedDevices':[device],'CreationDate':start-dt.timedelta(days=1),
                'ExpirationDate':start+dt.timedelta(minutes=35),'Entitlements':{
                    'com.apple.application-identifier':'PREFIX.*','keychain-access-groups':['PREFIX.*']}},start
    def test_profile_with_only_provisioning_udid_succeeds_despite_different_hardware_uuid(self):
        device=self.parse(self.document())
        self.assertEqual(device,self.provisioning)
        self.assertNotEqual(device,self.hardware)
        profile,start=self.profile(self.provisioning)
        ent={'com.apple.application-identifier':'PREFIX.app','keychain-access-groups':['PREFIX.app']}
        with patch('preflight.command',side_effect=AssertionError('zero live calls')):
            preflight.validate_profile(profile,ent,device,start)
    def test_wrong_device_profile_membership_is_not_repaired_by_hardware_fallback(self):
        device=self.parse(self.document())
        profile,start=self.profile(self.hardware)
        ent={'com.apple.application-identifier':'PREFIX.app','keychain-access-groups':['PREFIX.app']}
        with patch('preflight.command',side_effect=AssertionError('zero live calls')):
            with self.assertRaises(ux.Rejected):preflight.validate_profile(profile,ent,device,start)
    def test_missing_ambiguous_invalid_values_reject_without_host_or_asset_calls(self):
        invalid=[{}, {'SPHardwareDataType':[]},{'SPHardwareDataType':{}},
                 {'SPHardwareDataType':[{'platform_UUID':self.hardware}]},
                 {'SPHardwareDataType':[self.document()['SPHardwareDataType'][0]]*2},
                 {'SPHardwareDataType':[False]},
                 *[{'SPHardwareDataType':[{'provisioning_UDID':v,'platform_UUID':self.hardware}]}
                   for v in ('',None,False,3,' '+self.provisioning,self.provisioning+'\n','not-a-device','x/y')]]
        for value in invalid:
            with self.subTest(value=value):
                with self.assertRaises(ux.Rejected):self.parse(value)

if __name__=='__main__':unittest.main()
