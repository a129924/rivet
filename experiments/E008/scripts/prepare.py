"""Unsigned preparation only. Does not build an App launch/provisioning/live-run recipe."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import uuid
from continuity import Rejected, canonical, file_hash, utc


def commands(source, output, namespace):
    bundle = 'local.rivet.dpkcontinuity.' + namespace.replace('-', '')
    return [['/usr/bin/xcodebuild', 'build', '-project', str(source/'DPKContinuityProbe.xcodeproj'),
             '-scheme', 'DPKContinuityProbe', '-configuration', config, '-derivedDataPath', str(output/config),
             'CODE_SIGNING_ALLOWED=NO', 'CODE_SIGNING_REQUIRED=NO', 'E008_BUNDLE_IDENTIFIER='+bundle]
            for config in ('Debug', 'Rebuilt')]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--unsigned-build', action='store_true')
    args = parser.parse_args(); output = args.out
    if output.exists() or output.is_symlink(): raise Rejected('freshPreparationOutputRequired')
    parent = output.parent.resolve()
    if not (parent.is_relative_to(Path('/private/tmp')) or parent.is_relative_to(Path(tempfile.gettempdir()).resolve())):
        raise Rejected('temporaryUnsignedOutputRequired')
    output.mkdir(mode=0o700, parents=True)
    source = Path(__file__).resolve().parents[1]; namespace = str(uuid.uuid4())
    inputs = [p for folder in ('Sources', 'Resources', 'DPKContinuityProbe.xcodeproj') for p in (source/folder).rglob('*') if p.is_file()]
    receipt = {'kind':'unsigned-preparation', 'synthetic':True, 'liveExecuted':False, 'namespace':namespace,
               'appLaunched':False, 'assetsInspected':False, 'SecurityCalls':0, 'clockArmed':False,
               'startedUTC':utc().isoformat(), 'buildInputsSHA256':{str(p.relative_to(source)):file_hash(p) for p in sorted(inputs)}, 'configurations':{}}
    for name, cmd in zip(('Debug','Rebuilt'), commands(source, output, namespace)):
        item = {'performed':args.unsigned_build, 'signingAllowed':False, 'signingRequired':False}
        if args.unsigned_build:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
            (output/(name+'.build.log')).write_text(result.stdout+result.stderr)
            item['exitCode'] = result.returncode
            if result.returncode:
                receipt['configurations'][name] = item; (output/'preparation.json').write_bytes(canonical(receipt))
                print('Unsigned compile failed; no App launched. See external build log.'); return 2
            executable = output/name/'Build/Products'/name/'DPKContinuityProbe.app/Contents/MacOS/DPKContinuityProbe'
            item['mainSHA256'] = file_hash(executable)
            item['debugDylibAbsent'] = not list(executable.parent.glob('*.debug.dylib'))
        receipt['configurations'][name] = item
    receipt['endedUTC'] = utc().isoformat(); (output/'preparation.json').write_bytes(canonical(receipt))
    print('Unsigned preparation complete; no signed build, App launch or live clock.'); return 0

if __name__ == '__main__':
    try: raise SystemExit(main())
    except (Rejected, OSError, ValueError, subprocess.SubprocessError):
        print('Preparation stopped; no live run.'); raise SystemExit(2)
