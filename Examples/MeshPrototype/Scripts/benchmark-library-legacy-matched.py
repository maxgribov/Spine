#!/usr/bin/env python3
"""Run the identical current legacy-only harness against an archived baseline and current sources.
No branch/worktree is created; library sources and checked-in goldens are never modified.
"""
import argparse, hashlib, io, json, pathlib, shutil, subprocess, tarfile
p=argparse.ArgumentParser()
p.add_argument('--output',required=True)
a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[3]
out=pathlib.Path(a.output).resolve()
if out.exists(): raise SystemExit('Choose a new output directory to preserve previous evidence.')
out.mkdir(parents=True)
baseline=out/'baseline-source';baseline.mkdir()
revision=subprocess.check_output(['git','rev-parse','d1cbd6e'],cwd=root,text=True).strip()
archive=subprocess.check_output(['git','archive',revision],cwd=root)
with tarfile.open(fileobj=io.BytesIO(archive)) as tar: tar.extractall(baseline,filter='data')
# Only validation tooling is grafted onto the archive. Sources/Spine remains exact.
for path in ['Examples/MeshPrototype/Package.swift','Examples/MeshPrototype/Sources/MeshPrototype/LegacyValidation.swift','Tests/SpineTests/Resources/Compatibility/legacy-4.1.json']:
 dest=baseline/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy(root/path,dest)
shutil.copytree(root/'features/mesh-support/validation/legacy-baseline',baseline/'features/mesh-support/validation/legacy-baseline')
main=baseline/'Examples/MeshPrototype/Sources/MeshPrototype/main.swift'
text=main.read_text()
marker='var selectedGroupSize'
entry='''if let index=CommandLine.arguments.firstIndex(of:"--benchmark-library-legacy") {
    _ = NSApplication.shared
    do {try benchmarkLibraryLegacy(output:URL(fileURLWithPath:CommandLine.arguments[index+1]));exit(0)}
    catch {fputs("Legacy benchmark failed: \\(error)\\n",stderr);exit(1)}
}
'''
if marker not in text: raise SystemExit('Pinned baseline main entry changed unexpectedly.')
main.write_text(text.replace(marker,entry+marker,1))

def run(command,cwd,log):
 with log.open('w') as handle:
  result=subprocess.run(command,cwd=cwd,stdout=handle,stderr=handle)
 if result.returncode: raise SystemExit(f'{log.name} failed with exit {result.returncode}; inspect log')
 return {'command':command,'exitCode':result.returncode,'log':str(log)}

commands=[]
for name,source in [('baseline',baseline),('current',root)]:
 commands.append(run(['swift','build','-c','release','--package-path','Examples/MeshPrototype'],source,out/f'build-{name}.log'))
records=[]
for round_index,order in enumerate([['baseline','current'],['current','baseline']]):
 for name in order:
  source=baseline if name=='baseline' else root
  output=out/f'round{round_index+1}-{name}'
  command=[str(source/'Examples/MeshPrototype/.build/release/MeshPrototype'),'--benchmark-library-legacy',str(output)]
  commands.append(run(command,source,out/f'round{round_index+1}-{name}.log'))
  result=json.loads((output/'legacy-performance.json').read_text())
  if result['mode']!='verify' or not all(x['imageVerified'] for x in result['records']): raise SystemExit('Missing benchmark image verification')
  records.append({'outerRound':round_index+1,'source':name,'records':result['records']})
comparisons=[]
for count in [1,10,50]:
 means={name:sum(r['updateEncodeMedianMS'] for batch in records if batch['source']==name for r in batch['records'] if r['characters']==count)/4 for name in ['baseline','current']}
 ratio=means['current']/means['baseline']
 update_only={name:sum(r['updateMedianMS'] for batch in records if batch['source']==name for r in batch['records'] if r['characters']==count)/4 for name in ['baseline','current']}
 comparisons.append({'actors':count,'metric':'updateEncodeMedianMS','baselineMeanOfP50ms':means['baseline'],'currentMeanOfP50ms':means['current'],'ratio':ratio,'passed':ratio<=1.1,'updateOnlyDiagnosticMS':update_only})
report={'baselineRevision':revision,'currentRevision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'harnessSHA256':hashlib.sha256((root/'Examples/MeshPrototype/Sources/MeshPrototype/LegacyValidation.swift').read_bytes()).hexdigest(),'baselineSourceSHA256':{str(f.relative_to(baseline)):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted((baseline/'Sources/Spine').rglob('*.swift'))},'commands':commands,'comparisons':comparisons,'records':records,'passed':all(x['passed'] for x in comparisons),'protocol':'Two reversed process rounds; each identical legacy harness has two reversed 1/10/50 rounds,30 warmup+120 measured fixed-clock updates; no timed readback; six immutable PNGs required each run.'}
(out/'legacy-matched-performance.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(comparisons,indent=2))
raise SystemExit(0 if report['passed'] else 1)
