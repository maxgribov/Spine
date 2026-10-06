#!/usr/bin/env python3
"""Verify the agreed MVP assessment, including the explicit owner memory-budget exception."""
import argparse,hashlib,json,math,pathlib,subprocess,sys
p=argparse.ArgumentParser();p.add_argument('--root',default=str(pathlib.Path(__file__).resolve().parents[2]));a=p.parse_args();repo=pathlib.Path(a.root);base=repo/'features/skin-composition/validation'
def read(p):return json.loads(p.read_text())
def require(value,message):
 if not value:raise SystemExit(message)
def hashes(manifest):
 for file,expected in manifest.items():require(hashlib.sha256((repo/file).read_bytes()).hexdigest()==expected,'Source hash mismatch: '+file)
r=read(base/'measurements.json');require(r['releaseGate']=='passed','Aggregate assessment is not passed')
require(r['workload']['maxSkeletons']==28 and r['workload']['catalogItems']==20 and r['workload']['switchesPerSecond']==0,'Unexpected owner workload')
require(len(r['targets'])==2 and all(t['approvedByOwner'] for t in r['targets']),'Targets lack owner approval')
budget=r['budgets']['combinedPreviewP95Ms'];require(math.isfinite(budget) and 0<budget<=1000/60,'Invalid 60Hz preview budget')
if any(r['budgets'][key] is None for key in ['assetResidentBytes','peakSwitchBytes']):
 exception=r.get('memoryBudgetPolicyOverride',{})
 require(exception.get('approvedByOwner') is True and exception.get('specRule')=='D.5' and set(exception.get('nullBudgetFields',[]))=={'assetResidentBytes','peakSwitchBytes'},'D.5 null budgets require the recorded owner exception')
for platform in ['macos','iphone-air']:
 subprocess.run([sys.executable,str(repo/'Examples/SkinComposition/verify-evidence.py'),str(base/'captures'/platform),'--repo',str(repo)],check=True)
 root=base/'workload'/platform;work=read(root/'workload.json');hashes(work['build']['hashes'])
 require(work['matchShared']['owners']==work['matchDistinct']['owners']==28 and work['preview']['owners']==1,'Owner count mismatch')
 require(work['catalog']['pirateItems']==20,'Cosmetic item count mismatch')
 samples=work['preview']['samples'];require(len(samples)==120,'Preview sample count mismatch')
 values=sorted(s['combinedMs'] for s in samples);require(all(math.isfinite(v) and v>=0 for v in values),'Invalid latency samples');require(values[math.ceil(len(values)*.95)-1]<=budget,'Preview frame budget exceeded')
 if platform=='iphone-air':
  status=read(root/'workload-status.json');require(status['state']=='passed' and status['runID']==work['runID'] and status['build']==work['build'],'Physical run status mismatch')
  require(hashlib.sha256((root/'workload.json').read_bytes()).hexdigest()==status['resultSHA256'],'Physical result hash mismatch')
 for mode in ['shared','distinct']:
  m=read(root/f'memory-{mode}.json');require(m['ownerReleased'],'Owner retained')
  require(len(m['stagingSamples'])==1300 and all(s['taskInfoValid'] for s in m['stagingSamples']),'Invalid staging memory samples')
  require(all(m[k]['taskInfoValid'] for k in ['beforeAssetLoad','afterAssetLoadAndDrain','beforeSwitch','afterSwitchAndDrain','afterOwnerAndAssetsRelease']),'Invalid memory baseline')
  require(m['assetIncrementalPhysicalFootprintBytes']>0 and m['peakObservedStagingHeapDeltaBytes']>=0,'Missing operational memory measurement')
hashes(read(base/'workload/macos/memory-build.json')['hashes'])
proof=read(base/'physical-tests/summary.json');require(proof['fullSuite']['passedTests']==proof['fullSuite']['totalTestCount']==173 and proof['fullSuite']['failedTests']==0,'Current physical suite failed')
require(all(v['passedTests']==1 and v['failedTests']==0 for v in proof['supplementalMemory'].values()),'Physical memory test failed')
for file,expected in proof['artifacts'].items():require(hashlib.sha256((base/'physical-tests'/file).read_bytes()).hexdigest()==expected,'Physical proof artifact mismatch')
hashes(read(base/'physical-tests/source-sha256.json'))
for name,count in [('setup',5),('animation',223)]:
 oracle=read(base/'physical-tests/oracle'/f'{name}-oracle.json');require(oracle['passed'] and oracle['snapshots']==count,'Current official-runtime oracle failed')
print('Agreed MVP release assessment verified. D.5 absolute memory ceilings are explicitly waived by owner; measured memory and no-retention checks remain required.')
