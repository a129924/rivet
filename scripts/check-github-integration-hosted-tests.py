#!/usr/bin/env python3
"""Native hosted tests. Offline by default; live requires an explicit private context."""
import argparse
import base64
import datetime as dt
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import secrets
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time

REPO = Path(__file__).resolve().parents[1]
FACILITY = REPO / 'Tests/GitHubIntegrationHostedTests'
PROJECT = FACILITY / 'GitHubIntegrationHostedTests.xcodeproj'
HOST = 'GitHubIntegrationTestHost'
BUNDLE = 'GitHubIntegrationHostedTests'
PHASES = ('first', 'fresh')
OFFLINE_BUNDLE = 'local.rivet.github-integration-hosted-tests.host'


class Failure(Exception):
    def __init__(self, code, exit_code=1):
        self.code, self.exit_code = code, exit_code


def require(condition, code='verification', exit_code=1):
    if not condition:
        raise Failure(code, exit_code)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def secure(path):
    path = Path(path)
    info = path.lstat()
    require(not stat.S_ISLNK(info.st_mode) and info.st_uid == os.getuid()
            and info.st_mode & 0o077 == 0, 'ownership', 2)
    return path


def read_json(path):
    path = secure(path)
    require(path.is_file() and path.stat().st_size <= 1024 * 1024, 'receipt')
    return json.loads(path.read_text())


def exclusive(path, value):
    data = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, 'wb') as output:
        output.write(data)
        output.flush()
        os.fsync(output.fileno())


def command(argv, log=None, timeout=600):
    try:
        result = subprocess.run(argv, cwd=REPO, capture_output=True, timeout=timeout)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        raise Failure('toolUnavailableOrTimeout', 2) from None
    if log:
        descriptor = os.open(log, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, 'wb') as output:
            output.write(result.stdout + result.stderr)
    require(result.returncode == 0, 'command')
    return result


def source_manifest():
    paths = [REPO/'Package.swift', REPO/'Package.resolved', REPO/'packages/RivetHTTPClient/Package.swift', Path(__file__)]
    for directory in [REPO/'Sources/BoundedContexts/GitHubIntegration', REPO/'packages/RivetHTTPClient/Sources', FACILITY]:
        paths.extend(p for p in directory.rglob('*') if p.is_file() and p.suffix in {
            '.swift', '.py', '.pbxproj', '.xcscheme', '.plist', '.entitlements', '.resolved'
        } and not any(part in {'__pycache__', '.build', 'xcuserdata'} for part in p.parts))
    entries = {str(p.relative_to(REPO)): digest(p) for p in sorted(set(paths))}
    return hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()


def artifact_manifest(root):
    products = root/'DerivedData/Build/Products'
    require(products.is_dir(), 'artifacts')
    entries = {str(p.relative_to(products)): digest(p) for p in sorted(products.rglob('*'))
               if p.is_file() and p.suffix != '.xctestrun'}
    entries['hosted.xctestrun'] = digest(root/'hosted.xctestrun')
    entries['control.json'] = digest(root/'control.json')
    entries['tests.json'] = digest(root/'tests.json')
    return hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()


def check_summary(summary):
    require(summary.get('result') == 'Passed' and summary.get('totalTestCount') == 1
            and summary.get('passedTests') == 1 and summary.get('failedTests') == 0
            and summary.get('skippedTests') == 0 and summary.get('expectedFailures') == 0,
            'nativeTestFailedOrEmpty')


def validate_context(path):
    require(path.is_file(), 'contextMissing', 2)
    value = read_json(path)
    keys = {'schemaVersion','runID','authorizationRef','bundleID','signingIdentitySHA1',
            'profilePath','profileSHA256','accessGroup','service','fixture','budget'}
    require(set(value) == keys and value['schemaVersion'] == 1 and value['fixture'] == 'existing'
            and value['budget'] == {'first':1,'fresh':1}, 'context', 2)
    for key in keys - {'schemaVersion','budget'}:
        require(isinstance(value[key], str) and 0 < len(value[key]) <= 1024, 'context', 2)
    require(re.fullmatch(r'[A-Za-z0-9-]{16,100}', value['runID']) is not None
            and re.fullmatch(r'[A-Za-z0-9.-]+', value['bundleID']) is not None
            and re.fullmatch(r'[0-9A-Fa-f]{40}', value['signingIdentitySHA1']) is not None
            and re.fullmatch(r'[0-9a-f]{64}', value['profileSHA256']) is not None
            and '*' not in value['accessGroup'], 'context', 2)
    return value


def bind_context(path, context, root, first):
    journal = Path(str(path) + '.journal')
    if first:
        journal.mkdir(mode=0o700, exist_ok=False)
        exclusive(journal/'binding.json', {'runID':context['runID'], 'contextSHA256':digest(path), 'runRoot':str(root)})
    secure(journal)
    require(read_json(journal/'binding.json') == {
        'runID':context['runID'], 'contextSHA256':digest(path), 'runRoot':str(root)}, 'contextBoundElsewhere', 2)
    return journal


def live_assets(context):
    path = Path(context['profilePath'])
    require(path.is_file() and digest(path) == context['profileSHA256'], 'profile', 2)
    value = plistlib.loads(command(['security','cms','-D','-i',str(path)]).stdout)
    require(value['ExpirationDate'].replace(tzinfo=dt.timezone.utc) > dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=120), 'profileExpired', 2)
    ent = value.get('Entitlements', {})
    app_id = ent.get('com.apple.application-identifier', ent.get('application-identifier', ''))
    team = value['TeamIdentifier'][0]
    require(app_id == team+'.'+context['bundleID']
            and any(fnmatch.fnmatchcase(context['accessGroup'], x) for x in ent.get('keychain-access-groups', [])), 'profilePermission', 2)
    require(any(hashlib.sha1(cert).hexdigest().lower() == context['signingIdentitySHA1'].lower()
                for cert in value.get('DeveloperCertificates', [])), 'profileSigner', 2)
    # Do not update assets, trust, identities or profiles.
    identities = command(['security','find-identity','-v','-p','codesigning']).stdout.decode()
    require(context['signingIdentitySHA1'].upper() in identities.upper(), 'signerUnavailable', 2)
    hardware = json.loads(command(['system_profiler','SPHardwareDataType','-json']).stdout)
    info = hardware['SPHardwareDataType'][0]
    udid = info.get('provisioning_UDID', info.get('provisioning_udid', ''))
    require(udid and udid.upper() in {x.upper() for x in value.get('ProvisionedDevices', [])}, 'profileDevice', 2)
    return value


def root_control(root, mode, context=None, negative=''):
    root.mkdir(mode=0o700, parents=False, exist_ok=False)
    exclusive(root/'control.json', {
        'runID': context['runID'] if context else secrets.token_hex(16),
        'group':context['accessGroup'] if context else 'offline-only',
        'service':context['service'] if context else 'offline-only',
        'bundleID':context['bundleID'] if context else OFFLINE_BUNDLE,
        'keyBase64':base64.b64encode(secrets.token_bytes(32)).decode(), 'mode':mode, 'negative':negative})
    if mode == 'offline':
        exclusive(root/'fake-credential.json', {'access':'offline-old','expires':0})
    exclusive(root/'source.json', {'sha256':source_manifest()})


def build(root, mode, context=None):
    scheme = 'GitHubIntegration-' + ('Live' if mode == 'live' else 'Offline')
    args = ['xcodebuild','-project',str(PROJECT),'-scheme',scheme,
            '-destination','platform=macOS,arch=arm64','-derivedDataPath',str(root/'DerivedData'),
            'ARCHS=arm64','ONLY_ACTIVE_ARCH=YES']
    if mode == 'live':
        args += ['CODE_SIGNING_ALLOWED=NO','HOSTED_BUNDLE_ID='+context['bundleID']]
    command(args+['build-for-testing'], root/'build.log')
    require(source_manifest() == read_json(root/'source.json')['sha256'], 'sourceChanged')
    if mode == 'live':
        sign_products(root, context)
    runs = list((root/'DerivedData/Build/Products').glob('*.xctestrun'))
    require(len(runs) == 1, 'testRun')
    value = plistlib.loads(runs[0].read_bytes())
    product_root = str(runs[0].parent)
    def configure(value):
        if isinstance(value, dict):
            for key, entry in list(value.items()): value[key] = configure(entry)
            if 'TestHostPath' in value:
                value.setdefault('EnvironmentVariables', {})['HOSTED_RUN_ROOT'] = str(root)
                value.setdefault('TestingEnvironmentVariables', {})['HOSTED_RUN_ROOT'] = str(root)
            return value
        if isinstance(value, list): return [configure(x) for x in value]
        if isinstance(value, str): return value.replace('__TESTROOT__', product_root)
        return value
    (root/'hosted.xctestrun').write_bytes(plistlib.dumps(configure(value)))
    (root/'hosted.xctestrun').chmod(0o600)
    enumeration = root/'enumeration.json'
    command(['xcodebuild','test-without-building','-xctestrun',str(root/'hosted.xctestrun'),
             '-destination','platform=macOS,arch=arm64','-enumerate-tests','-test-enumeration-style','flat',
             '-test-enumeration-format','json','-test-enumeration-output-path',str(enumeration)], root/'enumeration.log')
    data = json.loads(enumeration.read_text())
    ids = []
    def collect(value):
        if isinstance(value, dict):
            for key, entry in value.items():
                if key in {'identifier','testIdentifier'} and isinstance(entry,str): ids.append(entry)
                collect(entry)
        elif isinstance(value,list):
            for entry in value: collect(entry)
    collect(data)
    selected = {}
    for phase in PHASES:
        matches = [x for x in ids if 'OAuthStartupHostedTests' in x and re.search(r'/'+phase+r'\(\)$',x)]
        require(len(matches) == 1, 'testEnumeration')
        selected[phase] = matches[0]
    exclusive(root/'tests.json', selected)
    exclusive(root/'artifacts.json', {'sha256':artifact_manifest(root)})


def is_native_executable(path):
    # Apple Mach-O loader.h/fat.h: executable, dylib or loadable bundle, not MH_OBJECT resources.
    # https://github.com/apple-oss-distributions/xnu/tree/main/EXTERNAL_HEADERS/mach-o
    thin = {b'\xfe\xed\xfa\xce':'big', b'\xce\xfa\xed\xfe':'little',
            b'\xfe\xed\xfa\xcf':'big', b'\xcf\xfa\xed\xfe':'little'}
    fat = {b'\xca\xfe\xba\xbe':('big',4,20), b'\xbe\xba\xfe\xca':('little',4,20),
           b'\xca\xfe\xba\xbf':('big',8,32), b'\xbf\xba\xfe\xca':('little',8,32)}
    def runtime_header(header):
        order = thin.get(header[:4])
        minimum = 32 if header[:4] in {b'\xfe\xed\xfa\xcf',b'\xcf\xfa\xed\xfe'} else 28
        return bool(order and len(header) >= minimum and int.from_bytes(header[12:16],order) in {2,6,8})
    with path.open('rb') as binary:
        header = binary.read(32)
        if header[:4] in thin: return runtime_header(header)
        if header[:4] not in fat: return False
        order,width,stride = fat[header[:4]]
        count = int.from_bytes(header[4:8],order)
        length = path.stat().st_size
        if not 1 <= count <= 32: return False
        for index in range(count):
            binary.seek(8+index*stride)
            architecture = binary.read(stride)
            if len(architecture) != stride: return False
            offset = int.from_bytes(architecture[8:8+width],order)
            size = int.from_bytes(architecture[8+width:8+2*width],order)
            if offset < 8+count*stride or size < 28 or offset+size > length: return False
            binary.seek(offset)
            if not runtime_header(binary.read(32)): return False
        return True


def embedded_code_targets(app, test):
    # TN2206: sign copied nested code inside out; never follow an alias out to an SDK.
    # https://developer.apple.com/library/archive/technotes/tn2206/_index.html
    require(not app.is_symlink(), 'embeddedCodeOutsideApp', 2)
    boundary = app.resolve(strict=True)
    def bounded(path):
        resolved = path.resolve(strict=True)
        require(resolved.is_relative_to(boundary), 'embeddedCodeOutsideApp', 2)
        return resolved
    directories,files = {boundary},set()
    for folder,children,names in os.walk(app,followlinks=False):
        for name in children+names:
            resolved = bounded(Path(folder)/name)
            if resolved.is_dir(): directories.add(resolved)
            elif resolved.is_file(): files.add(resolved)
    native = {path for path in files if is_native_executable(path)}
    owners = {}
    # Framework roots precede their Current/Versions aliases; one physical binary gets one owner.
    for bundle in sorted(directories,key=lambda path:(len(path.parts),str(path))):
        version = bundle.parent.name == 'Versions' and bundle.parent.parent.suffix == '.framework'
        if bundle.suffix not in {'.app','.xctest','.framework','.bundle','.xpc','.appex','.plugin'} and not version:
            continue
        infos = [bundle/'Contents/Info.plist',bundle/'Resources/Info.plist',bundle/'Info.plist']
        info = next((path for path in infos if path.is_file()),None)
        if info is None: continue
        value = plistlib.loads(bounded(info).read_bytes())
        name = value.get('CFBundleExecutable')
        if not name: continue  # Resource-only bundles do not become signing targets.
        require(isinstance(name,str) and name not in {'.','..'} and Path(name).name == name,
                'embeddedExecutableName',2)
        candidates = [bundle/'Contents/MacOS'/name,bundle/name]
        executable = next((path for path in candidates if path.is_file()),None)
        require(executable is not None, 'embeddedExecutableMissing',2)
        resolved = bounded(executable)
        require(resolved in native, 'embeddedExecutableNotMachO',2)
        owners.setdefault(resolved,bundle)
    targets = set(owners.values()) | (native-set(owners))
    targets -= {boundary,bounded(test)}
    return sorted(targets,key=lambda path:(-len(path.parts),str(path)))


def sign_products(root, context):
    products = root/'DerivedData/Build/Products/Live'
    app = products/(HOST+'.app')
    test = app/'Contents/PlugIns'/(BUNDLE+'.xctest')
    require(app.is_dir() and test.is_dir(), 'signingProductsMissing', 2)
    embedded = embedded_code_targets(app, test)
    profile = live_assets(context)
    shutil.copyfile(context['profilePath'], app/'Contents/embedded.provisionprofile')
    team = profile['TeamIdentifier'][0]
    ent = {'com.apple.application-identifier':team+'.'+context['bundleID'],
           'com.apple.developer.team-identifier':team,'keychain-access-groups':[context['accessGroup']]}
    if profile.get('Entitlements',{}).get('get-task-allow'): ent['get-task-allow'] = True
    path=root/'signing.entitlements'; path.write_bytes(plistlib.dumps(ent)); path.chmod(0o600)
    for index, code in enumerate(embedded):
        command(['codesign','--force','--sign',context['signingIdentitySHA1'],'--timestamp=none',str(code)],
                root/('sign-embedded-'+str(index)+'.log'))
    command(['codesign','--force','--sign',context['signingIdentitySHA1'],'--timestamp=none',str(test)], root/'sign-test.log')
    command(['codesign','--force','--sign',context['signingIdentitySHA1'],'--timestamp=none','--entitlements',str(path),str(app)], root/'sign-host.log')
    verify_signing(root, context)


def verify_signing(root, context):
    live_assets(context)
    app=root/'DerivedData/Build/Products/Live'/(HOST+'.app')
    command(['codesign','--verify','--deep','--strict',str(app)])
    require(digest(app/'Contents/embedded.provisionprofile') == context['profileSHA256'], 'profileChanged', 2)
    ent=plistlib.loads(command(['codesign','-d','--entitlements',':-',str(app)]).stdout)
    require(ent.get('keychain-access-groups') == [context['accessGroup']], 'group', 2)
    info=plistlib.loads((app/'Contents/Info.plist').read_bytes())
    require(info['CFBundleIdentifier'] == context['bundleID'], 'bundle', 2)
    certdir=Path(tempfile.mkdtemp(prefix='certificate-',dir=root))
    command(['codesign','-d','--extract-certificates='+str(certdir/'leaf-'),str(app)])
    require(hashlib.sha1((certdir/'leaf-0').read_bytes()).hexdigest().lower() == context['signingIdentitySHA1'].lower(), 'certificate', 2)


def process_info(pid):
    result = subprocess.run(['ps','-p',str(pid),'-o','comm=','-o','lstart='], capture_output=True, text=True)
    if result.returncode != 0 or not result.stdout.strip(): return None
    # comm is a path without whitespace for our fixed test host name; use separate fields to support spaces in repository paths.
    executable = subprocess.run(['ps','-p',str(pid),'-o','comm='],capture_output=True,text=True).stdout.strip()
    started = subprocess.run(['ps','-p',str(pid),'-o','lstart='],capture_output=True,text=True).stdout.strip()
    return {'pid':pid,'executable':executable,'start':started}


def verify_provenance(root):
    require(source_manifest() == read_json(root/'source.json')['sha256'], 'sourceChanged')
    require(artifact_manifest(root) == read_json(root/'artifacts.json')['sha256'], 'artifactsChanged')


def execute_phase(root, phase, mode):
    verify_provenance(root)
    exclusive(root/(phase+'.attempt.json'), {'phase':phase})
    selected=read_json(root/'tests.json')[phase]
    result_path=root/(phase+'.xcresult')
    args=['xcodebuild','test-without-building','-xctestrun',str(root/'hosted.xctestrun'),
          '-destination','platform=macOS,arch=arm64','-only-testing:'+selected,
          '-parallel-testing-enabled','NO',
          '-test-timeouts-enabled','YES','-default-test-execution-time-allowance','120',
          '-resultBundlePath',str(result_path)]
    config='Live' if mode=='live' else 'Offline'
    binary=root/'DerivedData/Build/Products'/config/(HOST+'.app')/'Contents/MacOS'/HOST
    host=None; authorized=False
    descriptor=os.open(root/(phase+'.test.log'),os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(descriptor,'wb') as log:
        proc=subprocess.Popen(args,cwd=REPO,stdout=log,stderr=log,start_new_session=True)
        start=time.monotonic()
        try:
            hello_path=root/(phase+'.hello.json')
            while not hello_path.exists():
                require(proc.poll() is None and time.monotonic()-start<70,'hostHandshake')
                time.sleep(.1)
            hello=read_json(hello_path); control=read_json(root/'control.json')
            require(set(hello)=={'runID','phase','pid','executable'} and hello['phase']==phase and hello['runID']==control['runID'], 'hostHandshake')
            host=process_info(int(hello['pid']))
            require(host and host['start'] and os.path.samefile(host['executable'],binary)
                    and os.path.samefile(hello['executable'],binary),'hostProcess')
            verify_provenance(root)
            exclusive(root/(phase+'.process.json'),host)
            exclusive(root/(phase+'.authorize.json'),{'runID':control['runID'],'phase':phase})
            authorized=True
            proc.wait(timeout=max(1,120-(time.monotonic()-start)))
        except subprocess.TimeoutExpired:
            raise Failure('testTimeout') from None
        finally:
            if proc.poll() is None:
                os.killpg(proc.pid,signal.SIGTERM)
                try: proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid,signal.SIGKILL); proc.wait(timeout=5)
            if host:
                deadline=time.monotonic()+5
                while process_info(host['pid']) and time.monotonic()<deadline: time.sleep(.1)
            terminated=bool(host and process_info(host['pid']) is None)
            exclusive(root/(phase+'.exit.json'),{'terminated':terminated,'authorized':authorized,'exitCode':proc.returncode})
    require(authorized and terminated and proc.returncode==0,'nativeExecution')
    verify_provenance(root)
    summary=json.loads(command(['xcrun','xcresulttool','get','test-results','summary','--path',str(result_path)]).stdout)
    check_summary(summary)
    receipt=read_json(root/(phase+'.machine.json'))
    require(receipt.get('schema')=='github-integration.hosted.v1' and receipt.get('phase')==phase,'receipt')
    exclusive(root/(phase+'.result.json'),{'passed':True,'machineSHA256':digest(root/(phase+'.machine.json')),
              'artifactSHA256':read_json(root/'artifacts.json')['sha256'],'sourceSHA256':read_json(root/'source.json')['sha256'],
              'tests':summary['totalTestCount'],'processTerminated':True})
    return 3 if mode=='live' else 0


def first_ready(root):
    require(all((root/name).is_file() for name in ['first.result.json','first.human.json','first.exit.json']), 'firstIncomplete', 2)
    result=read_json(root/'first.result.json'); human=read_json(root/'first.human.json')
    ended=read_json(root/'first.exit.json')
    require(result['passed'] and ended['terminated'] and ended['exitCode']==0,'firstIncomplete',2)
    require(human['fullyObserved'] is True and human['promptCount']==0
            and human['machineSHA256']==digest(root/'first.machine.json'),'humanObservation',2)


def attest(root, phase, fully_observed, prompts):
    require(type(prompts) is int and 0<=prompts<=20,'prompts',2)
    result=read_json(root/(phase+'.result.json'))
    ended=read_json(root/(phase+'.exit.json'))
    require(result.get('passed') is True and ended.get('terminated') is True and ended.get('exitCode') == 0, 'phaseIncomplete')
    machine_hash=digest(root/(phase+'.machine.json'))
    require(result['machineSHA256']==machine_hash,'receiptChanged')
    exclusive(root/(phase+'.human.json'),{'fullyObserved':fully_observed,'promptCount':prompts,'machineSHA256':machine_hash})
    return 0 if fully_observed and prompts==0 else 1


def negative_smoke(base, kind):
    # Reuse immutable build products, but isolate fake data and execution settings.
    root = base.parent / ('negative-' + kind)
    root_control(root, 'offline', negative=kind)
    (root/'DerivedData').symlink_to(base/'DerivedData', target_is_directory=True)
    value = plistlib.loads((base/'hosted.xctestrun').read_bytes())
    def configure(value):
        if isinstance(value, dict):
            for key, entry in list(value.items()):
                if key == 'HOSTED_RUN_ROOT': value[key] = str(root)
                else: value[key] = configure(entry)
        elif isinstance(value, list):
            value = [configure(x) for x in value]
        return value
    (root/'hosted.xctestrun').write_bytes(plistlib.dumps(configure(value)))
    (root/'hosted.xctestrun').chmod(0o600)
    exclusive(root/'tests.json', read_json(base/'tests.json'))
    exclusive(root/'artifacts.json', {'sha256':artifact_manifest(root)})
    try:
        execute_phase(root, 'first', 'offline')
    except Failure as error:
        require(error.code == 'nativeExecution', 'negativeDidNotReachNativeTest')
    else:
        raise Failure('negativeUnexpectedPass')
    summary = json.loads(command(['xcrun','xcresulttool','get','test-results','summary',
                                  '--path',str(root/'first.xcresult')]).stdout)
    require(summary.get('result') == 'Failed' and summary.get('totalTestCount') == 1
            and summary.get('failedTests') == 1 and summary.get('skippedTests') == 0,
            'negativeNativeResult')
    require(read_json(root/'first.exit.json')['terminated'], 'negativeProcessStillRunning')
    return {'case':kind,'nativeFailureObserved':True,'tests':1}


def offline():
    command([sys.executable,'-B','-m','unittest','discover','-s',str(FACILITY),'-p','test_driver.py'])
    parent=Path(tempfile.mkdtemp(prefix='rivet-hosted-offline-'))
    root=parent/'run'
    root_control(root,'offline')
    build(root,'offline')
    execute_phase(root,'first','offline'); execute_phase(root,'fresh','offline')
    first=read_json(root/'first.process.json'); fresh=read_json(root/'fresh.process.json')
    require((first['pid'],first['start'])!=(fresh['pid'],fresh['start']),'sameProcess')
    negatives = [negative_smoke(root, kind) for kind in ['assert','throw']]
    exclusive(root/'offline-result.json',{'passed':True,'phases':2,'distinctProcesses':True,'liveOperations':0,'negativeCases':negatives})
    # The caller gets an explicit evidence location; no personal identity or credentials.
    print(json.dumps({'status':'passed','mode':'offline','phases':2,'distinctProcesses':True,'liveOperations':0,'nativeNegativeCases':len(negatives),'evidence':str(root)}))
    return 0


def main(argv=None):
    parser=argparse.ArgumentParser()
    group=parser.add_mutually_exclusive_group()
    group.add_argument('--offline',action='store_true');group.add_argument('--live',action='store_true');group.add_argument('--attest',action='store_true')
    parser.add_argument('--context',type=Path);parser.add_argument('--run-root',type=Path)
    parser.add_argument('--phase',choices=PHASES);parser.add_argument('--fully-observed',action='store_true')
    parser.add_argument('--prompt-count',type=int)
    args=parser.parse_args(argv)
    os.umask(0o077)
    try:
        if not(args.live or args.attest): return offline()
        require(args.context and args.run_root and args.phase,'arguments',2)
        path=Path(os.path.abspath(args.context));root=args.run_root.resolve()
        context=validate_context(path)
        journal=bind_context(path,context,root,args.live and args.phase=='first')
        if args.attest:
            code=attest(root,args.phase,args.fully_observed,args.prompt_count)
        else:
            if args.phase=='first':
                exclusive(journal/'first.attempt.json',{'phase':'first'})
                live_assets(context)
                root_control(root,'live',context)
                build(root,'live',context)
            else:
                first_ready(root)
                exclusive(journal/'fresh.attempt.json',{'phase':'fresh'})
                verify_signing(root,context)
            code=execute_phase(root,args.phase,'live')
        print(json.dumps({'status':{0:'passed',1:'failed',2:'blocked',3:'pending-human'}[code],'phase':args.phase}))
        return code
    except Failure as error:
        print(json.dumps({'status':'blocked' if error.exit_code==2 else 'failed','failureKind':error.code,'noAutomaticRetry':True}))
        return error.exit_code
    except Exception:
        print(json.dumps({'status':'failed','failureKind':'internal','noAutomaticRetry':True}))
        return 1


if __name__=='__main__':
    sys.exit(main())
