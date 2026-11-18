#!/usr/bin/env bash
set -euo pipefail

tool_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="$(cd -- "$tool_root/../../.." && pwd)"
# Validate canonical output paths before creating any run directory or receipt.
run_dir="$(python3 - "$source_root" "${ACCEPTANCE_RUN:-}" "${TMPDIR:-/tmp}" <<'PY'
from pathlib import Path
import sys,tempfile
root=Path(sys.argv[1]).resolve()
def external(path):
    resolved=Path(path).resolve()
    if resolved.is_relative_to(root):
        raise SystemExit('ACCEPTANCE_RUN and its temporary parent must be outside the source checkout')
    return resolved
if sys.argv[2]:
    run=external(sys.argv[2])
    app=run/'native/RivetLoginAcceptance.app'
    if app.exists() or app.is_symlink():
        raise SystemExit('Choose a new ACCEPTANCE_RUN; app output already exists')
else:
    parent=external(sys.argv[3])
    if not parent.is_dir(): raise SystemExit('Temporary parent must be an existing external directory')
    run=Path(tempfile.mkdtemp(prefix='rivet-login-acceptance-',dir=parent))
print(run)
PY
)"
mkdir -p "$run_dir/scratch" "$run_dir/cache/repositories" "$run_dir/modules" "$run_dir/logs"

python3 - "$source_root" "$run_dir" <<'PY'
from pathlib import Path
import hashlib,json,sys
root=Path(sys.argv[1]).resolve(); run=Path(sys.argv[2]).resolve()
files=['Package.swift','Package.resolved','.gitignore']
(run/'root-readonly-before.json').write_text(json.dumps({name:hashlib.sha256((root/name).read_bytes()).hexdigest() for name in files},indent=2)+'\n')
PY
verify_readonly() {
  python3 - "$source_root" "$run_dir" <<'PY'
from pathlib import Path
import hashlib,json,sys
root=Path(sys.argv[1]); run=Path(sys.argv[2]); before=json.loads((run/'root-readonly-before.json').read_text())
for name,value in before.items():
    if hashlib.sha256((root/name).read_bytes()).hexdigest()!=value:
        raise SystemExit('Root readonly file changed: '+name)
PY
}
on_exit() {
  build_status=$?
  verify_readonly || build_status=1
  exit "$build_status"
}
trap on_exit EXIT

apollo_revision="$(python3 - "$source_root/Package.resolved" <<'PY'
import json,sys
pins=json.load(open(sys.argv[1]))['pins']
print(next(pin['state']['revision'] for pin in pins if pin['identity']=='apollo-ios'))
PY
)"
cache_source="${APOLLO_CACHE_SOURCE:-$source_root/.build/repositories/apollo-ios-b9a1b528}"
test "$(git --git-dir="$cache_source" rev-parse --is-bare-repository)" = true
test "$(git --git-dir="$cache_source" rev-parse "$apollo_revision^{commit}")" = "$apollo_revision"
cache_copy="$run_dir/cache/repositories/apollo-ios-b9a1b528"
if test ! -e "$cache_copy"; then cp -R "$cache_source" "$cache_copy"; fi
test "$(git --git-dir="$cache_copy" rev-parse "$apollo_revision^{commit}")" = "$apollo_revision"

# No remote fallback: local root resolution still requires its transitive Apollo manifests/cache.
export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0=protocol.https.allow GIT_CONFIG_VALUE_0=never
export GIT_CONFIG_KEY_1=protocol.http.allow GIT_CONFIG_VALUE_1=never
if test ! -f "$tool_root/Package.resolved"; then
  swift package --package-path "$tool_root" --scratch-path "$run_dir/scratch" \
    --cache-path "$run_dir/cache" --manifest-cache local --skip-update \
    --disable-keychain --disable-netrc resolve > "$run_dir/logs/resolve.log" 2>&1
fi
python3 - "$source_root/Package.resolved" "$tool_root/Package.resolved" <<'PY'
import json,sys
def pins(path):
    return {pin['identity']:pin['state'] for pin in json.load(open(path))['pins']}
if pins(sys.argv[1])!=pins(sys.argv[2]): raise SystemExit('Tool pins must match the existing root lock; do not update root settings')
PY
swift_options=(
  --package-path "$tool_root" --scratch-path "$run_dir/scratch" --cache-path "$run_dir/cache"
  --manifest-cache local --skip-update --disable-automatic-resolution --disable-keychain --disable-netrc
  -Xbuild-tools-swiftc -module-cache-path -Xbuild-tools-swiftc "$run_dir/modules"
  -Xswiftc -module-cache-path -Xswiftc "$run_dir/modules" -Xcc "-fmodules-cache-path=$run_dir/modules"
)
swift build "${swift_options[@]}" --product RivetLoginAcceptance > "$run_dir/logs/build.log" 2>&1
bin_dir="$(swift build "${swift_options[@]}" --show-bin-path)"
python3 - "$source_root" "$tool_root" "$run_dir" "$bin_dir" <<'PY'
from pathlib import Path
import hashlib,json,os,plistlib,shutil,stat,sys
root,tool,run,bin_dir=map(Path,sys.argv[1:])
binary=bin_dir/'RivetLoginAcceptance'
bundles=[p for p in bin_dir.glob('*_RivetPresentation.bundle') if p.is_dir()]
if not binary.is_file() or len(bundles)!=1: raise SystemExit('Expected the actual executable and exactly one formal Presentation resource bundle')
bundle=bundles[0]; app=run/'native/RivetLoginAcceptance.app'
mac=app/'Contents/MacOS'; packaged_bundle=app/bundle.name;mac.mkdir(parents=True)
# SwiftPM's generated accessor first searches Bundle.main.bundleURL / bundle.name.
shutil.copy2(binary,mac/binary.name);shutil.copytree(bundle,packaged_bundle)
info={'CFBundleExecutable':'RivetLoginAcceptance','CFBundleIdentifier':'local.rivet.login-ui-acceptance','CFBundleName':'Rivet Login Acceptance','CFBundleDisplayName':'Rivet Login Acceptance','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','LSMinimumSystemVersion':'15.0','NSHighResolutionCapable':True,'NSPrincipalClass':'NSApplication'}
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(binary)==sha(mac/binary.name)
resource_files=[]
for path in sorted(bundle.rglob('*')):
    if path.is_file():
        target=packaged_bundle/path.relative_to(bundle);assert sha(path)==sha(target)
        resource_files.append({'path':str(target.relative_to(app)),'sha256':sha(target),'bytes':target.stat().st_size})
source_paths=[root/'Package.swift',root/'Package.resolved',tool/'Package.swift',tool/'Package.resolved',tool/'scripts/build-app.sh']
source_paths+=sorted((root/'Sources/Presentation').rglob('*.swift'))
source_paths+=sorted(p for p in (root/'Sources/Presentation/Resources').rglob('*') if p.is_file())
source_paths+=sorted((tool/'Sources').rglob('*.swift'))
source_files=[{'path':str(p.relative_to(root)),'sha256':sha(p)} for p in source_paths]
def digest(value): return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
app_entries=[]
for path in sorted(app.rglob('*')):
    entry={'path':str(path.relative_to(app)),'mode':stat.S_IMODE(path.lstat().st_mode)}
    if path.is_symlink():entry.update(type='symlink',target=os.readlink(path))
    elif path.is_file():entry.update(type='file',sha256=sha(path),bytes=path.stat().st_size)
    else:entry.update(type='directory')
    app_entries.append(entry)
readonly_before=json.loads((run/'root-readonly-before.json').read_text())
readonly_after={name:sha(root/name) for name in readonly_before}
if readonly_before!=readonly_after:raise SystemExit('Root readonly hashes changed; do not launch the app')
receipt={'sourceState':'checkout bytes at build; native launch not performed','sourceFiles':source_files,'sourceManifestSha256':digest(source_files),'binary':{'path':'native/RivetLoginAcceptance.app/Contents/MacOS/RivetLoginAcceptance','sha256':sha(binary),'bytes':binary.stat().st_size},'artifact':{'path':'native/RivetLoginAcceptance.app','bundleIdentifier':info['CFBundleIdentifier'],'treeSha256':digest(app_entries),'treeHashDefinition':'SHA-256 of canonical JSON sorted relative entries with type, mode, file bytes/SHA-256 or symlink target; timestamps excluded','entries':app_entries},'resourceBundle':bundle.name,'resources':resource_files,'rootReadonlyBefore':readonly_before,'rootReadonlyAfter':readonly_after,'nativeLaunch':'not-run'}
(run/'acceptance-build.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
print('artifact=native/RivetLoginAcceptance.app')
print('binary_sha256='+receipt['binary']['sha256'])
print('app_tree_sha256='+receipt['artifact']['treeSha256'])
print('source_manifest_sha256='+receipt['sourceManifestSha256'])
print('native_launch=not-run; receipt=acceptance-build.json')
PY
plutil -lint "$run_dir/native/RivetLoginAcceptance.app/Contents/Info.plist"
