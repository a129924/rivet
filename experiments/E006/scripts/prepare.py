"""Preparation only: unsigned build recipe/config, no signing/assets/App launch."""
import argparse
import json
from pathlib import Path
import subprocess
import uuid

from ux_stages import Rejected, exclusive_json, now_utc, sha256


def commands(source, output, namespace):
    bundle='local.rivet.dpkprobe.'+namespace.replace('-','')
    return [['/usr/bin/xcodebuild','build','-project',str(source/'DPKProbe.xcodeproj'),
             '-scheme','DPKProbe','-configuration',config,'-derivedDataPath',str(output/config),
             'CODE_SIGNING_ALLOWED=NO','CODE_SIGNING_REQUIRED=NO',
             'E006_BUNDLE_IDENTIFIER='+bundle] for config in ('Debug','Rebuilt')]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--namespace',default=None)
    parser.add_argument('--unsigned-build',action='store_true')
    args=parser.parse_args()
    namespace=str(uuid.UUID(args.namespace)) if args.namespace else str(uuid.uuid4())
    output=args.out
    if output.exists() or output.is_symlink(): raise Rejected('preparationAlreadyExists')
    output.mkdir(mode=0o700,parents=True)
    source=Path(__file__).resolve().parents[1]
    builds=commands(source,output,namespace)
    receipt={'namespace':namespace,'synthetic':True,'live':False,'assetsInspected':False,
             'appLaunched':False,'SecurityOperations':0,'startedUTC':now_utc().isoformat(),
             'configurations':{},'sourceSHA256':{str(p.relative_to(source)):sha256(p)
                for p in sorted((source/'Sources/DPKProbe').glob('*.swift'))}}
    for config, command in zip(('Debug','Rebuilt'),builds):
        record={'unsigned':True,'performed':args.unsigned_build}
        if args.unsigned_build:
            result=subprocess.run(command,capture_output=True,text=True)
            (output/(config+'.build.log')).write_text(result.stdout+result.stderr)
            record.update(exitCode=result.returncode)
            if result.returncode:
                receipt['configurations'][config]=record
                exclusive_json(output/'preparation.json',receipt)
                print('Unsigned build failed; inspect private build log, no App launched.')
                return 2
        receipt['configurations'][config]=record
    receipt['endedUTC']=now_utc().isoformat()
    exclusive_json(output/'preparation.json',receipt)
    print('Unsigned preparation complete; no signed build or App launch.')
    return 0

if __name__=='__main__':
    try: raise SystemExit(main())
    except (Rejected,ValueError,OSError):
        print('Preparation rejected; no asset operation requested.')
        raise SystemExit(2)
