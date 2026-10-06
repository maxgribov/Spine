#!/usr/bin/env python3
"""macOS fresh-process @testable memory probe using the existing detached staging seam."""
import pathlib,subprocess,shutil,plistlib,argparse
p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
here=pathlib.Path(__file__).resolve().parent;repo=here.parents[2];out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
app=out/'MemoryProbe.app';resources=app/'Contents/Resources';binary=app/'Contents/MacOS/MemoryProbe';resources.mkdir(parents=True,exist_ok=True);binary.parent.mkdir(parents=True,exist_ok=True)
sdk=subprocess.check_output(['xcrun','--sdk','macosx','--show-sdk-path'],text=True).strip();base=['xcrun','swiftc','-sdk',sdk,'-target','arm64-apple-macosx10.15','-O']
subprocess.run(base+['-whole-module-optimization','-enable-testing','-parse-as-library','-emit-object','-emit-module','-module-name','Spine','-emit-module-path',str(out/'Spine.swiftmodule'),'-o',str(out/'Spine.o')]+[str(p) for p in sorted((repo/'Sources/Spine').rglob('*.swift'))],check=True)
subprocess.run(base+['-parse-as-library','-I',str(out),str(out/'Spine.o'),str(here/'MemoryProbe.swift'),str(here/'MemoryMain.swift'),str(here.parent/'ScaledCatalog.swift'),'-o',str(binary)],check=True)
shutil.copy(repo/'Tests/SpineTests/Resources/Mesh41/skin-composition/wardrobe.json',resources/'wardrobe.json')
(app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'dev.spine.memoryprobe','CFBundleExecutable':'MemoryProbe','CFBundlePackageType':'APPL'}))
subprocess.run(['codesign','--force','--sign','-',str(app)],check=True);print(binary)
