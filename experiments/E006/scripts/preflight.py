"""Fixture/profile parser; --live inspects only two Human-selected Apps after authorization.
No account/certificate inventory, signing, provisioning, trust, SecItem, or App launch.
Private proof contains identifiers; never commit it or print subprocess output.
"""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile

from ux_stages import Rejected, exclusive_json, now_utc, sha256, timestamp, load_window


def covers(pattern, value):
    return isinstance(pattern, str) and (pattern == value or
        (pattern.endswith('*') and pattern.count('*') == 1 and value.startswith(pattern[:-1])))


def validate_profile(profile, entitlements, device, start, validated_at=None):
    app = entitlements.get('com.apple.application-identifier')
    groups = entitlements.get('keychain-access-groups')
    if not isinstance(app, str) or groups != [app] or '*' in app:
        raise Rejected('accessGroupRejected')
    allowed = profile.get('Entitlements', {})
    if (not covers(allowed.get('com.apple.application-identifier'), app) or
            not any(covers(pattern, app) for pattern in allowed.get('keychain-access-groups', []))):
        raise Rejected('profileEntitlementRejected')
    def date(value):
        if not isinstance(value, dt.datetime):
            raise Rejected('profileDateRejected')
        return value.replace(tzinfo=dt.timezone.utc) if value.tzinfo is None else value
    if (date(profile.get('ExpirationDate')) < start + dt.timedelta(minutes=35) or
            date(profile.get('CreationDate')) > (validated_at or start) or device not in profile.get('ProvisionedDevices', [])):
        raise Rejected('profileValidityOrDeviceRejected')



def provisioning_device_id(raw):
    """Bounded current-Mac JSON schema, not a Hardware UUID compatibility fallback."""
    try:
        document=json.loads(raw)
    except (ValueError,TypeError,UnicodeError):
        raise Rejected('provisioningDeviceIdentifierRejected') from None
    records=document.get('SPHardwareDataType') if isinstance(document,dict) else None
    if not isinstance(records,list) or len(records)!=1 or not isinstance(records[0],dict):
        raise Rejected('provisioningDeviceIdentifierRejected')
    value=records[0].get('provisioning_UDID')
    # Existing safe schema diagnosis observed hex 8-16 on this Apple silicon Mac.
    # Do not normalize values or claim this format covers all Mac generations.
    if not isinstance(value,str) or re.fullmatch(r'[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}',value) is None:
        raise Rejected('provisioningDeviceIdentifierRejected')
    return value

def command(args):
    result = subprocess.run(args, capture_output=True, timeout=30)
    if result.returncode:
        raise Rejected('selectedAssetValidationFailed')
    return result.stdout, result.stderr


def executable(app):
    app = Path(app)
    if app.is_symlink() or not app.name.endswith('.app'):
        raise Rejected('appPathRejected')
    info = plistlib.loads((app/'Contents/Info.plist').read_bytes())
    name = info.get('CFBundleExecutable')
    if not isinstance(name, str) or '/' in name or name in ('.', '..'):
        raise Rejected('executableRejected')
    binary = app/'Contents/MacOS'/name
    if binary.is_symlink() or not binary.is_file():
        raise Rejected('executableRejected')
    return binary, info


def inspect_app(app, scratch):
    app = Path(app).resolve()
    binary, info = executable(app)
    if any(path.is_symlink() for path in app.rglob('*')):
        raise Rejected('appSymlinkRejected')
    command(['/usr/bin/codesign', '--verify', '--strict', '--verbose=0', str(app)])
    out, err = command(['/usr/bin/codesign', '-d', '--entitlements', ':-', str(app)])
    start = out.find(b'<?xml')
    if start < 0:
        raise Rejected('entitlementsMissing')
    entitlements = plistlib.loads(out[start:])
    _, detail = command(['/usr/bin/codesign', '-d', '-vvv', str(app)])
    if b'Authority=Apple Development:' not in detail or b'Signature=adhoc' in detail:
        raise Rejected('developmentIdentityRequired')
    out, err = command(['/usr/bin/codesign', '-d', '-r-', str(app)])
    text = (out + err).decode('utf-8', errors='replace')
    match = re.search(r'designated => (.+)', text)
    if not match:
        raise Rejected('requirementMissing')
    requirement = match.group(1)
    profile_file = app/'Contents/embedded.provisionprofile'
    if profile_file.is_symlink() or not profile_file.is_file():
        raise Rejected('embeddedProfileMissing')
    out, _ = command(['/usr/bin/security', 'cms', '-D', '-i', str(profile_file)])
    profile = plistlib.loads(out)
    prefix = str(Path(scratch)/'selected-cert-')
    command(['/usr/bin/codesign', '-d', '--extract-certificates=' + prefix, str(app)])
    certificates = sorted(Path(scratch).glob('selected-cert-*'))
    if not certificates or certificates[0].name != 'selected-cert-0':
        raise Rejected('certificateMissing')
    leaf = certificates[0].read_bytes()
    if leaf not in profile.get('DeveloperCertificates', []):
        raise Rejected('certificateNotInProfile')
    # Exact selected code-signing chain only; no user keychain inventory or trust edits.
    verify = ['/usr/bin/security', 'verify-cert', '-p', 'codeSign']
    for cert in certificates:
        verify += ['-c', str(cert)]
    command(verify)
    expiry, _ = command(['/usr/bin/openssl', 'x509', '-inform', 'DER', '-in', str(certificates[0]), '-noout', '-enddate'])
    expiry = dt.datetime.strptime(expiry.decode().strip().removeprefix('notAfter='), '%b %d %H:%M:%S %Y %Z').replace(tzinfo=dt.timezone.utc)
    # TN3125: macOS com.apple.security.get-task-allow is unrestricted.
    # Neither its presence in the profile nor the iOS get-task-allow key identifies
    # this macOS development candidate. Apple Development chain, selected leaf
    # binding, platform/device, validity and restricted group authorization do.
    if profile.get('Platform') and 'OSX' not in profile['Platform']:
        raise Rejected('macOSProfileRequired')
    return {'app': str(app), 'binary': str(binary), 'hash': sha256(binary),
            'info': info, 'entitlements': entitlements, 'requirement': requirement,
            'profile': profile, 'profileHash': sha256(profile_file),
            'certificateHash': hashlib.sha256(leaf).hexdigest(), 'certificateExpiry': expiry}


def live_preflight(selection, asset_authorized=False, window_root=None):
    if not asset_authorized:
        raise Rejected('humanAssetAuthorizationRequired')
    # Human declarations are facts not derivable from an entitlement/profile alone.
    if selection.get('humanFreePersonalTeamStatement', '').strip() == '' or selection.get('humanOnlyMarkerChangeStatement', '').strip() == '':
        raise Rejected('humanSourceStatementsRequired')
    namespace = selection['namespace']
    if window_root is None: raise Rejected('setupWindowRequired')
    window,window_hash=load_window(window_root,namespace,now_utc())
    if (('startUTC' in selection and timestamp(selection['startUTC'])!=timestamp(window['startUTC'])) or
            ('windowSHA256' in selection and selection['windowSHA256']!=window_hash)):
        raise Rejected('selectionCannotResetWindow')
    expected_id = 'local.rivet.dpkprobe.' + namespace.replace('-', '')
    start = timestamp(window['startUTC'])
    if os.getuid() == 0 or os.stat('/dev/console').st_uid != os.getuid():
        raise Rejected('guiUserSessionRequired')
    hardware_json, _ = command(['/usr/sbin/system_profiler', 'SPHardwareDataType', '-json'])
    device = provisioning_device_id(hardware_json)
    with tempfile.TemporaryDirectory(prefix='E006-selected-validation-') as temp:
        first_dir = Path(temp)/'first'; second_dir = Path(temp)/'second'
        first_dir.mkdir(); second_dir.mkdir()
        first = inspect_app(selection['firstApp'], first_dir)
        second = inspect_app(selection['secondApp'], second_dir)
    for item, marker in ((first, 'initial'), (second, 'rebuilt')):
        if item['info'].get('CFBundleIdentifier') != expected_id or item['info'].get('E006BuildMarker') != marker:
            raise Rejected('bundleOrMarkerRejected')
        validate_profile(item['profile'], item['entitlements'], device, start, validated_at=now_utc())
        identifier = item['entitlements']['com.apple.application-identifier']
        if not identifier.endswith('.' + expected_id):
            raise Rejected('appIdentifierPrefixRejected')
        prefix = identifier[:-(len(expected_id) + 1)]
        if prefix not in item['profile'].get('ApplicationIdentifierPrefix', []):
            raise Rejected('appIdentifierPrefixRejected')
        if item['certificateExpiry'] < start + dt.timedelta(minutes=35):
            raise Rejected('certificateExpiryRejected')
    if first['hash'] == second['hash'] or any(first[key] != second[key] for key in ('entitlements','requirement','profileHash','certificateHash')):
        raise Rejected('rebuildIdentityRejected')
    # codesign itself evaluates both cross requirements; equality is insufficient.
    command(['/usr/bin/codesign','--verify','--strict','-R='+second['requirement'],first['app']])
    command(['/usr/bin/codesign','--verify','--strict','-R='+first['requirement'],second['app']])
    expires = min(first['certificateExpiry'], first['profile']['ExpirationDate'].replace(tzinfo=dt.timezone.utc))
    source_root = Path(__file__).resolve().parents[1]
    sources = sorted(source_root.glob('Sources/DPKProbe/*.swift')) + [source_root/'DPKProbe.xcodeproj/project.pbxproj']
    return {'namespace': namespace, 'kind': 'live', 'synthetic': False,
            'validatedUTC': now_utc().isoformat(), 'expiresUTC': expires.isoformat(),
            'measurementStartUTC': window['startUTC'], 'windowSHA256':window_hash, 'observationMode':'human-only', 'backend':'dpk',
            'firstHash':first['hash'], 'secondHash':second['hash'],
            'bundleIdentifier':expected_id, 'accessGroup':first['entitlements']['keychain-access-groups'][0],
            'entitlements':first['entitlements'], 'entitlementsSHA256':hashlib.sha256(plistlib.dumps(first['entitlements'],sort_keys=True)).hexdigest(),
            'profileSHA256':first['profileHash'], 'certificateSHA256':first['certificateHash'],
            'requirement':first['requirement'], 'firstApp':first['app'], 'secondApp':second['app'],
            'sourceSHA256':{str(p.relative_to(source_root)):sha256(p) for p in sources},
            'humanFreePersonalTeamStatement':selection['humanFreePersonalTeamStatement'],
            'humanOnlyMarkerChangeStatement':selection['humanOnlyMarkerChangeStatement']}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--human-asset-authorization', action='store_true')
    parser.add_argument('--selection',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--scratch',type=Path,required=True)
    args=parser.parse_args()
    if not args.live:
        raise Rejected('usePureFixtureTestsNoProofIssued')
    result=live_preflight(json.loads(args.selection.read_text()),args.human_asset_authorization,window_root=args.scratch)
    exclusive_json(args.out,result)
    print('Private live proof saved; identifiers intentionally not printed.')

if __name__ == '__main__':
    try: main()
    except (Rejected, KeyError, ValueError, OSError, subprocess.SubprocessError):
        print('preflight rejected; no OAuth operation performed')
        raise SystemExit(2)
