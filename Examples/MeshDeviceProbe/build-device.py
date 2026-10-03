#!/usr/bin/env python3
"""Build the validation-only iOS host with the repository's production Swift sources.
Provisioning identities/profiles and private device identifiers stay outside the repository.
"""
import argparse, hashlib, json, pathlib, plistlib, shutil, subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True)
parser.add_argument('--profile', required=True)
parser.add_argument('--identity', required=True)
parser.add_argument('--bundle-id', default='dev.spine.meshvalidation')
parser.add_argument('--device', help='Install and launch on this physical device after building.')
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parents[2]
output = pathlib.Path(args.output).resolve()
app = output / 'MeshDeviceProbe.app'
app.mkdir(parents=True, exist_ok=True)
profile = pathlib.Path(args.profile).expanduser().resolve()
provision = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(profile)], stderr=subprocess.DEVNULL))
team = provision['TeamIdentifier'][0]
allowed = provision['Entitlements']['application-identifier']
identifier = team + '.' + args.bundle_id
if allowed != identifier and not (allowed.endswith('*') and identifier.startswith(allowed[:-1])):
    raise SystemExit('Provisioning profile does not authorize the requested bundle identifier.')
entitlements = dict(provision['Entitlements'])
entitlements['application-identifier'] = identifier
entitlements['keychain-access-groups'] = [identifier]
(output / 'entitlements.plist').write_bytes(plistlib.dumps(entitlements))
shutil.copy(profile, app / 'embedded.mobileprovision')
info = {'CFBundleIdentifier': args.bundle_id, 'CFBundleExecutable': 'MeshDeviceProbe',
        'CFBundleName': 'Spine mesh validation', 'CFBundlePackageType': 'APPL',
        'CFBundleVersion': '1', 'CFBundleShortVersionString': '1.0',
        'CFBundleSupportedPlatforms': ['iPhoneOS'], 'MinimumOSVersion': '13.0',
        'UIDeviceFamily': [1, 2], 'UILaunchScreen': {},
        'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait'], 'LSRequiresIPhoneOS': True}
(app / 'Info.plist').write_bytes(plistlib.dumps(info))
for filename in ['authored.atlas', 'authored-straight.png', 'authored-pma.png']:
    shutil.copy(repo / 'Tests/SpineTests/Resources/Mesh41' / filename, app / filename)
sources = sorted((repo / 'Sources/Spine').rglob('*.swift'))
host = pathlib.Path(__file__).resolve().with_name('App.swift')
manifest = {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in [host] + sources}
(output / 'source-sha256.json').write_text(json.dumps(manifest, indent=2) + '\n')
sdk = subprocess.check_output(['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'], text=True).strip()
commands = [
    ('build', ['xcrun', '--sdk', 'iphoneos', 'swiftc', '-target', 'arm64-apple-ios13.0', '-sdk', sdk,
               '-Onone', '-o', str(app / 'MeshDeviceProbe'), str(host)] + [str(p) for p in sources]),
    ('sign', ['codesign', '--force', '--sign', args.identity, '--entitlements', str(output / 'entitlements.plist'),
              '--timestamp=none', str(app)])]
if args.device:
    commands += [('install', ['xcrun', 'devicectl', 'device', 'install', 'app', '--device', args.device, str(app)]),
                 ('launch', ['xcrun', 'devicectl', 'device', 'process', 'launch', '--device', args.device, args.bundle_id])]
for name, command in commands:
    with (output / (name + '.log')).open('w') as log:
        subprocess.run(command, stdout=log, stderr=log, check=True)
    print(name + ': passed', flush=True)
