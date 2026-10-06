#!/usr/bin/env python3
"""Build the public API client and Spine as separate modules; no third-party tools."""
import argparse, hashlib, json, pathlib, plistlib, shutil, subprocess
p = argparse.ArgumentParser()
p.add_argument('--platform', choices=['macos', 'simulator', 'ios'], default='macos')
p.add_argument('--output', required=True)
p.add_argument('--identity')
p.add_argument('--profile')
p.add_argument('--bundle-id', default='dev.spine.skincomposition')
a = p.parse_args()
if bool(a.identity) != bool(a.profile):
    p.error('--identity and --profile must be supplied together')
repo = pathlib.Path(__file__).resolve().parents[2]
here = pathlib.Path(__file__).resolve().parent
out = pathlib.Path(a.output).resolve(); out.mkdir(parents=True, exist_ok=True)
sdk, target = {'macos': ('macosx', 'arm64-apple-macosx10.15'), 'simulator': ('iphonesimulator', 'arm64-apple-ios13.0-simulator'), 'ios': ('iphoneos', 'arm64-apple-ios13.0')}[a.platform]
sdkpath = subprocess.check_output(['xcrun', '--sdk', sdk, '--show-sdk-path'], text=True).strip()
app = out / 'SkinComposition.app'
resources = app / 'Contents/Resources' if a.platform == 'macos' else app
binary = app / 'Contents/MacOS/SkinComposition' if a.platform == 'macos' else app / 'SkinComposition'
resources.mkdir(parents=True, exist_ok=True); binary.parent.mkdir(parents=True, exist_ok=True)
sources = sorted((repo / 'Sources/Spine').rglob('*.swift'))
base = ['xcrun', '--sdk', sdk, 'swiftc', '-target', target, '-sdk', sdkpath, '-O']
commands = [base + ['-whole-module-optimization', '-parse-as-library', '-emit-object', '-emit-module', '-module-name', 'Spine', '-emit-module-path', str(out / 'Spine.swiftmodule'), '-o', str(out / 'Spine.o')] + list(map(str, sources)),
            base + ['-parse-as-library', '-I', str(out), str(out / 'Spine.o'), '-o', str(binary)] + list(map(str, sorted(here.glob('*.swift'))))]
for i, command in enumerate(commands):
    with (out / f'build-{i}.log').open('w') as log: subprocess.run(command, stdout=log, stderr=log, check=True)
fixture = repo / 'Tests/SpineTests/Resources/Mesh41/skin-composition'
for name in ['wardrobe.json', 'swatch.atlas', 'swatch.png']: shutil.copy(fixture / name, resources / name)
info = dict(CFBundleIdentifier=a.bundle_id, CFBundleExecutable='SkinComposition', CFBundleName='Skin composition', CFBundlePackageType='APPL', CFBundleVersion='1', CFBundleShortVersionString='1.0')
if a.platform != 'macos': info.update(MinimumOSVersion='13.0', UIDeviceFamily=[1, 2], UILaunchScreen={}, UISupportedInterfaceOrientations=['UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'])
(app / ('Contents/Info.plist' if a.platform == 'macos' else 'Info.plist')).write_bytes(plistlib.dumps(info))
tracked = sources + sorted(here.glob('*.swift')) + [fixture / name for name in ['wardrobe.json', 'swatch.atlas', 'swatch.png']]
build = dict(sourceCommit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(), dirty=bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo)), platform=a.platform, target=target, configuration='Release -O', hashes={str(f.relative_to(repo)): hashlib.sha256(f.read_bytes()).hexdigest() for f in tracked})
(resources / 'build.json').write_text(json.dumps(build, indent=2) + '\n')
if a.profile:
    provision = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', a.profile]))
    identifier = provision['TeamIdentifier'][0] + '.' + a.bundle_id
    allowed = provision['Entitlements']['application-identifier']
    if allowed != identifier and not (allowed.endswith('*') and identifier.startswith(allowed[:-1])): raise SystemExit('Profile does not permit bundle identifier')
    entitlements = dict(provision['Entitlements']); entitlements['application-identifier'] = identifier
    entitlements['keychain-access-groups'] = [identifier]
    ent = out / 'entitlements.plist'; ent.write_bytes(plistlib.dumps(entitlements))
    shutil.copy(a.profile, app / 'embedded.mobileprovision')
    if not a.identity: raise SystemExit('--profile requires --identity')
    subprocess.run(['codesign', '--force', '--sign', a.identity, '--entitlements', str(ent), '--timestamp=none', str(app)], check=True)
elif a.platform != 'ios': subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
print(app)
