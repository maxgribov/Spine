#!/usr/bin/env python3
import pathlib,subprocess,tempfile,shutil,plistlib
root=pathlib.Path(__file__).resolve().parents[3]
with tempfile.TemporaryDirectory(prefix='spine-device-host-checks-') as tmp:
 base=pathlib.Path(tmp);app=base/'HostChecks.app';binary=app/'Contents/MacOS/HostChecks';binary.parent.mkdir(parents=True)
 (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'HostChecks','CFBundleIdentifier':'dev.spine.hostchecks','CFBundlePackageType':'APPL'}))
 for resource in (root/'Tests/SpineTests/Resources/Mesh41').iterdir():
  if resource.is_file():shutil.copy(resource,app/resource.name)
 host=root/'Examples/MeshDeviceProbe'
 sources=[host/'RunReporting.swift',host/'AnimationOracle.swift',host/'Lifecycle.swift',host/'Tests/main.swift']+sorted((root/'Sources/Spine').rglob('*.swift'))
 subprocess.run(['xcrun','swiftc','-O','-whole-module-optimization','-o',str(binary)]+[str(x) for x in sources],check=True)
 subprocess.run([str(binary),str(base/'reports')],check=True)
