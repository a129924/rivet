#!/usr/bin/env python3
"""E016 only. preflight reads signatures; first/fresh require separate explicit calls."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import time
import uuid

APP_ID = '4Q76YL5UQ5.local.rivet.dpkcontinuity.b90f5f16d3c8452faf9186b88d6dc64e'
BUNDLE_ID = APP_ID.split('.', 1)[1]
PROFILE_UUID = 'b6dca18c-18aa-438b-b2d9-0fcf6f577399'
PROFILE_HASH = '8b7cabcd79f3732a48c964eea5ee85576b8416b33b87d8144affcc0964dd3bd9'
CERT_HASH = '5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440'
EXPIRY = '2026-11-17T07:28:08Z'
ROOT = Path(__file__).resolve().parents[3]
BOOL_KEYS = {'seed_absent', 'seed_readback', 'write_attempted', 'signout_returned', 'same_process_absent',
             'configuration_intact', 'sentinel_intact', 'fresh_read_verified', 'previous_process_terminated',
             'launch_identity_verified', 'observation_complete'}
HASH_KEYS = {'run_hash', 'process_hash', 'provenance_hash', 'source_hash', 'binary_hash', 'profile_hash', 'attestation_hash'}
ENUMS = {'schema': {'e016.v1'}, 'phase': {'preflight', 'first', 'fresh'},
         'outcome': {'passed', 'failed', 'indeterminate'},
         'failureKind': {'none', 'prerequisite', 'existing_item', 'mismatch', 'operation_or_prerequisite'},
         'prompt_count_class': {'zero', 'nonzero', 'unknown'}}

class ProtocolError(Exception):
    pass

def sha(data):
    return hashlib.sha256(data).hexdigest()

def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':')).encode()

def require_equal(left, right):
    if left != right:
        raise ProtocolError('mismatch')

def public_receipt(value):
    for key, item in value.items():
        valid = ((key in BOOL_KEYS and type(item) is bool)
                 or (key in HASH_KEYS and type(item) is str and re.fullmatch('[0-9a-f]{64}', item))
                 or (key in ENUMS and item in ENUMS[key]))
        if not valid:
            raise ProtocolError('receipt_shape')
    return value

def write_once(path, value):
    with path.open('xb') as handle:
        os.chmod(path, 0o600)
        handle.write(canonical(value))

def read(path):
    return json.loads(path.read_bytes())

def consume(root, phase):
    try:
        write_once(root / (phase + '-consumed.json'), {'consumed': True})
    except FileExistsError as error:
        raise ProtocolError('budget_consumed') from error

def command(args):
    result = subprocess.run(args, capture_output=True, check=False)
    if result.returncode:
        raise ProtocolError('command_failed')
    return result.stdout

def source_manifest():
    files = [ROOT / 'Package.swift', ROOT / 'Package.resolved', ROOT / 'packages/RivetHTTPClient/Package.swift']
    for base in ['Sources', 'packages/RivetHTTPClient/Sources', 'experiments/E016/Sources',
                 'experiments/E016/Resources', 'experiments/E016/scripts', 'experiments/E016/E016LogoutProbe.xcodeproj']:
        files.extend(p for p in (ROOT / base).rglob('*') if p.is_file() and '__pycache__' not in p.parts and 'xcuserdata' not in p.parts)
    return {'commit': command(['git', '-C', str(ROOT), 'rev-parse', 'HEAD']).decode().strip(),
            'files': {str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in sorted(set(files))},
            'dirty': command(['git', '-C', str(ROOT), 'status', '--porcelain', '--untracked-files=all']).decode()}

def build_unsigned(derived_data):
    """Explicit preparation helper; never signs, launches, or touches DPK."""
    derived_data = Path(derived_data).resolve()
    before = source_manifest()
    derived_data.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (derived_data / 'unsigned-build.log').open('wb') as log:
        result = subprocess.run(['xcodebuild', '-project', str(ROOT / 'experiments/E016/E016LogoutProbe.xcodeproj'),
                                 '-scheme', 'E016LogoutProbe', '-configuration', 'Debug',
                                 '-derivedDataPath', str(derived_data), 'CODE_SIGNING_ALLOWED=NO', 'build'],
                                stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        raise ProtocolError('unsigned_build_failed')
    require_equal(source_manifest(), before)
    app = derived_data / 'Build/Products/Debug/E016LogoutProbe.app'
    record = {'source': before, 'unsigned_binary_hash': sha((app / 'Contents/MacOS/E016LogoutProbe').read_bytes()),
              'build_log_hash': sha((derived_data / 'unsigned-build.log').read_bytes())}
    write_once(app.with_suffix('.build-source.json'), record)
    return app


def bundle_hash(app):
    return sha(canonical({str(p.relative_to(app)): sha(p.read_bytes()) for p in sorted(app.rglob('*')) if p.is_file()}))

def signed_info(app):
    executable = app / 'Contents/MacOS/E016LogoutProbe'
    require_equal(plistlib.loads((app / 'Contents/Info.plist').read_bytes())['CFBundleIdentifier'], BUNDLE_ID)
    command(['codesign', '--verify', '--deep', '--strict', str(app)])
    require_equal(sha((app / 'Contents/embedded.provisionprofile').read_bytes()), PROFILE_HASH)
    profile_data = command(['security', 'cms', '-D', '-i', str(app / 'Contents/embedded.provisionprofile')])
    profile = plistlib.loads(profile_data)
    require_equal(profile['UUID'], PROFILE_UUID)
    require_equal(profile['ExpirationDate'].replace(tzinfo=dt.timezone.utc).isoformat().replace('+00:00', 'Z'), EXPIRY)
    if dt.datetime.now(dt.timezone.utc) >= profile['ExpirationDate'].replace(tzinfo=dt.timezone.utc):
        raise ProtocolError('profile_expired')
    entitlements = plistlib.loads(command(['codesign', '-d', '--entitlements', ':-', str(app)]))
    require_equal(entitlements['keychain-access-groups'], [APP_ID])
    require_equal(entitlements.get('com.apple.application-identifier', entitlements.get('application-identifier')), APP_ID)
    require_equal(entitlements.get('com.apple.security.app-sandbox', False), False)
    profile_entitlements = profile['Entitlements']
    require_equal(profile_entitlements.get('com.apple.application-identifier', profile_entitlements.get('application-identifier')), APP_ID)
    if not set(profile_entitlements['keychain-access-groups']).intersection({APP_ID, '4Q76YL5UQ5.*'}):
        raise ProtocolError('profile_group')
    # Extract the actual signing leaf certificate, not only the profile's advertised cert.
    import tempfile
    with tempfile.TemporaryDirectory(prefix='e016-cert-') as scratch:
        prefix = str(Path(scratch) / 'cert')
        command(['codesign', '-d', '--extract-certificates=' + prefix, str(app)])
        require_equal(sha(Path(prefix + '0').read_bytes()), CERT_HASH)
    if not any(sha(cert) == CERT_HASH for cert in profile['DeveloperCertificates']):
        raise ProtocolError('profile_certificate')
    return {'app': str(app), 'executable': str(executable), 'binary_hash': sha(executable.read_bytes()),
            'bundle_hash': bundle_hash(app), 'profile_hash': sha((app / 'Contents/embedded.provisionprofile').read_bytes()),
            'tools': {'xcode': command(['xcodebuild', '-version']).decode(), 'python': sys.version}}

def sign_prepared(app, profile):
    """Explicit post-review preparation. Not called by preflight/first/fresh."""
    app = Path(app).resolve(strict=True)
    profile = Path(profile).resolve(strict=True)
    require_equal(app.name, 'E016LogoutProbe.app')
    build_path = app.with_suffix('.build-source.json')
    build = read(build_path)
    source = source_manifest()
    require_equal(source, build['source'])
    executable = app / 'Contents/MacOS/E016LogoutProbe'
    unsigned_hash = sha(executable.read_bytes())
    require_equal(unsigned_hash, build['unsigned_binary_hash'])
    require_equal(sha(profile.read_bytes()), PROFILE_HASH)
    transition_path = app.with_suffix('.signing.json')
    if transition_path.exists():
        raise ProtocolError('already_signed')
    write_once(app.with_suffix('.signing-attempt.json'), {
        'build_hash': sha(build_path.read_bytes()), 'unsigned_binary_hash': unsigned_hash})
    # Only this E016 bundle is changed; no automatic/deep signing or asset creation.
    (app / 'Contents/embedded.provisionprofile').write_bytes(profile.read_bytes())
    entitlements = app.with_suffix('.signing.entitlements')
    with entitlements.open('xb') as handle:
        os.chmod(entitlements, 0o600)
        handle.write(plistlib.dumps({'keychain-access-groups': [APP_ID],
                                     'com.apple.application-identifier': APP_ID,
                                     'com.apple.developer.team-identifier': '4Q76YL5UQ5'}))
    command(['codesign', '--force', '--sign', '59E8ED4B0CCD45ED27129C7A3C6CC1EC510B87E9',
             '--entitlements', str(entitlements), str(app)])
    signed = signed_info(app)
    require_equal(source_manifest(), source)
    transition = {'schema': 'e016.signing.v1', 'source_hash': sha(canonical(source)),
                  'build_hash': sha(build_path.read_bytes()), 'unsigned_binary_hash': unsigned_hash,
                  **{key: signed[key] for key in ('binary_hash', 'bundle_hash', 'profile_hash')}}
    write_once(transition_path, transition)


def verify_transition(app, signed, source):
    build_path = app.with_suffix('.build-source.json')
    transition_path = app.with_suffix('.signing.json')
    build = read(build_path)
    transition = read(transition_path)
    require_equal(transition['schema'], 'e016.signing.v1')
    require_equal(build['source'], source)
    require_equal(transition['source_hash'], sha(canonical(source)))
    require_equal(transition['build_hash'], sha(build_path.read_bytes()))
    require_equal(transition['unsigned_binary_hash'], build['unsigned_binary_hash'])
    for key in ('binary_hash', 'bundle_hash', 'profile_hash'):
        require_equal(transition[key], signed[key])
    return sha(transition_path.read_bytes())


def process_info(pid):
    text = command(['ps', '-p', str(pid), '-o', 'lstart=', '-o', 'comm=']).decode().strip()
    parts = text.split(maxsplit=5)
    if len(parts) != 6:
        raise ProtocolError('process_identity')
    return {'start': ' '.join(parts[:5]), 'path': parts[5]}

def require_process(hello, pid, path, binary_hash):
    require_equal((hello['pid'], hello['path'], hello['binary_hash']), (pid, path, binary_hash))

def stopped(pid, start):
    try:
        return process_info(pid)['start'] != start
    except ProtocolError:
        # ps exit=1 is expected only when the exact pid is absent.
        result = subprocess.run(['ps', '-p', str(pid), '-o', 'pid='], capture_output=True)
        if result.returncode == 1 and not result.stdout.strip():
            return True
        raise

def related_processes_absent():
    for name in ['E016LogoutProbe', 'DPKContinuityProbe', 'CredentialStorageProbe', 'CredentialStorageProbeRebuilt']:
        result = subprocess.run(['pgrep', '-x', name], capture_output=True)
        if result.returncode != 1:
            raise ProtocolError('related_process_present_or_unknown')

def private_root(root, create=False):
    if create:
        root.mkdir(mode=0o700, parents=False, exist_ok=False)
    info = root.lstat()
    if root.is_symlink() or not root.is_dir() or info.st_uid != os.getuid() or info.st_mode & 0o777 != 0o700:
        raise ProtocolError('private_root')

def preflight(app, root):
    related_processes_absent()
    signed = signed_info(app)
    build = read(app.with_suffix('.build-source.json'))
    source = source_manifest()
    require_equal(source, build['source'])
    transition_hash = verify_transition(app, signed, source)
    private_root(root, create=True)
    frozen = {**signed, 'run_id': str(uuid.uuid4()), 'source': source, 'source_hash': sha(canonical(source)), 'source_root': str(ROOT), 'build': build, 'transition_hash': transition_hash}
    write_once(root / 'frozen.json', frozen)
    write_once(root / 'preflight-public.json', public_receipt({
        'schema': 'e016.v1', 'phase': 'preflight', 'outcome': 'passed', 'failureKind': 'none',
        'source_hash': frozen['source_hash'], 'binary_hash': frozen['binary_hash'], 'profile_hash': frozen['profile_hash']}))

def wait_file(path, launch, seconds=45):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if path.is_file():
            return read(path)
        if launch.poll() is not None:
            raise ProtocolError('launch_ended_without_receipt')
        time.sleep(0.1)
    raise ProtocolError('timeout')

def validate_machine(machine, phase):
    public_receipt(machine)
    require_equal(machine.get('schema'), 'e016.v1')
    require_equal(machine.get('phase'), phase)
    require_equal(machine.get('outcome'), 'passed')
    require_equal(machine.get('failureKind'), 'none')
    required = {'configuration_intact', 'sentinel_intact'}
    if phase == 'first':
        required |= {'seed_absent', 'seed_readback', 'write_attempted', 'signout_returned', 'same_process_absent'}
    else:
        required |= {'fresh_read_verified'}
        require_equal(machine.get('write_attempted'), False)
    for key in required:
        require_equal(machine.get(key), True)


def launch_phase(app, root, phase):
    private_root(root)
    frozen = read(root / 'frozen.json')
    require_equal(str(app), frozen['app'])
    require_equal(source_manifest(), frozen['source'])
    actual = signed_info(app)
    require_equal(verify_transition(app, actual, frozen['source']), frozen['transition_hash'])
    for key in ['binary_hash', 'bundle_hash', 'profile_hash', 'executable']:
        require_equal(actual[key], frozen[key])
    related_processes_absent()
    if phase == 'fresh':
        first = read(root / 'first-private.json')
        validate_machine(first['machine'], 'first')
        require_equal(first['frozen_hash'], sha(canonical(frozen)))
        require_equal(first['terminated'], True)
        if not stopped(first['pid'], first['start']):
            raise ProtocolError('previous_process_running')
    consume(root, phase)  # Persist budget before launch, including interrupted launches.
    launch = subprocess.Popen(['/usr/bin/open', '-W', str(app), '--args', phase, str(root)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    hello = wait_file(root / (phase + '-hello.json'), launch)
    require_equal((hello['phase'], hello['run_id']), (phase, frozen['run_id']))
    pid = hello['pid']
    process = process_info(pid)
    require_process(hello, pid, frozen['executable'], frozen['binary_hash'])
    require_equal(process['path'], frozen['executable'])
    require_equal(sha(Path(process['path']).read_bytes()), frozen['binary_hash'])
    require_equal(source_manifest(), frozen['source'])
    write_once(root / (phase + '-authorize.json'), {
        'pid': pid, 'phase': phase, 'run_id': frozen['run_id'], 'binary_hash': frozen['binary_hash'],
        'profile_hash': frozen['profile_hash'], 'source_hash': frozen['source_hash']})
    machine = public_receipt(wait_file(root / (phase + '-machine.json'), launch))
    require_equal(machine.get('phase'), phase)
    require_equal(machine.get('schema'), 'e016.v1')
    if machine.get('outcome') == 'passed':
        validate_machine(machine, phase)
    try:
        launch.wait(timeout=15)
    except subprocess.TimeoutExpired as error:
        raise ProtocolError('termination_unproven') from error
    if not stopped(pid, process['start']):
        raise ProtocolError('termination_unproven')
    private = {'pid': pid, **process, 'terminated': True, 'machine': machine,
               'machine_hash': sha((root / (phase + '-machine.json')).read_bytes()), 'frozen_hash': sha(canonical(frozen))}
    write_once(root / (phase + '-private.json'), private)
    projection = {**machine, 'run_hash': sha(frozen['run_id'].encode()), 'process_hash': sha(canonical({'pid': pid, **process})),
                  'provenance_hash': sha(canonical(private)), 'source_hash': frozen['source_hash'],
                  'binary_hash': frozen['binary_hash'], 'profile_hash': frozen['profile_hash'],
                  'previous_process_terminated': phase == 'fresh', 'launch_identity_verified': True,
                  'observation_complete': False, 'prompt_count_class': 'unknown'}
    write_once(root / (phase + '-public.json'), public_receipt(projection))
    require_equal(machine['outcome'], 'passed')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=['preflight', 'first', 'fresh'])
    parser.add_argument('--app', required=True, type=Path)
    parser.add_argument('--run-root', required=True, type=Path)
    args = parser.parse_args()
    try:
        app = args.app.resolve(strict=True)
        root = args.run_root.absolute()
        if args.phase == 'preflight': preflight(app, root)
        else: launch_phase(app, root, args.phase)
        print('E016 command completed; Human observation remains separately required.')
        return 0
    except Exception:
        # Paths, subprocess output, arbitrary exceptions, and payloads stay private.
        print('E016 stopped; do not retry or clean up. Preserve private run root.', file=sys.stderr)
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
