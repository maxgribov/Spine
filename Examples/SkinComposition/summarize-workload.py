#!/usr/bin/env python3
"""Derive transparent fixture latency/memory assessments without invented memory ceilings."""
import argparse,hashlib,json,pathlib,math,statistics
p=argparse.ArgumentParser();p.add_argument('directory');a=p.parse_args();root=pathlib.Path(a.directory)
r=json.loads((root/'workload.json').read_text())
status=root/'workload-status.json'
if r['build']['platform']=='ios':
 if not status.exists():raise SystemExit('Physical workload status is required')
 state=json.loads(status.read_text())
 if state.get('state')!='passed' or state.get('runID')!=r.get('runID') or not state.get('runID'):raise SystemExit('No completed physical workload run')
 if state.get('resultSHA256')!=hashlib.sha256((root/'workload.json').read_bytes()).hexdigest():raise SystemExit('Physical workload result integrity mismatch')
 if state['build']!=r['build']:raise SystemExit('Physical workload provenance differs')
def summary(values):
 values=sorted(values)
 return {'median':statistics.median(values),'p95':values[math.ceil(len(values)*.95)-1],'p99':values[math.ceil(len(values)*.99)-1],'max':max(values)}
result={'criterion':'Warm preview apply+prepare p95 <= one 60Hz frame; memory has no owner-requested absolute ceiling','warmPreviewBudgetMs':1000/60,'scenarios':{}}
for name in ['matchShared','matchDistinct','preview']:
 samples=r[name]['samples']
 if len(samples)!=120:raise SystemExit('Expected120post-warmup samples')
 if any(not math.isfinite(v) or v<0 for s in samples for v in s.values()):raise SystemExit('Invalid sample')
 row={k:summary([s[k] for s in samples]) for k in ['applyMs','prepareMs','combinedMs','nativeFrameMs']}
 row['nativeMeanCallbackFPS']=1000/statistics.mean(s['nativeFrameMs'] for s in samples)
 row['intervalsLongerThanTwo60HzFrames']=sum(s['nativeFrameMs']>2000/60 for s in samples)
 result['scenarios'][name]=row
result['warmPreviewPassed']=result['scenarios']['preview']['combinedMs']['p95']<=1000/60
result['memory']={}
for name in ['shared','distinct']:
 path=root/f'memory-{name}.json'
 if path.exists():
  memory=json.loads(path.read_text())
  result['memory'][name]={key:memory[key] for key in ['assetIncrementalPhysicalFootprintBytes','assetIncrementalLiveHeapBytes','peakObservedStagingHeapDeltaBytes','peakObservedStagingPhysicalFootprintDeltaBytes','ownerReleased']}
  result['memory'][name]['method']='Prewarmed, fully texture-preloaded process footprint delta; held-staging checkpoints; not exact global GPU attribution or between-checkpoint transient maximum'
(root/'assessment.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
