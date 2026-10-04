#!/usr/bin/env python3
"""Validate only the caller's expected current run; never fall back to old Documents reports."""
import argparse,hashlib,json,pathlib
STAGES={'render','physics-stress','parity-export','lifetime','lifecycle','performance'}
REPORTS=['production-gate.json','animation-vertices.json','animation-grid.json','device-performance.json','release-gate.json','physics-stress.json']
def validate(documents,expected,require_oracle=False):
 run=documents/'runs'/expected['runID']
 def read(name): return json.loads((run/name).read_text())
 def identity(record):
  if any(record.get(k)!=expected[k] for k in ['runID','sourceManifestSHA256']): raise ValueError('Run/source identity mismatch')
 manifest=read('run-manifest.json');identity(manifest)
 if manifest.get('status')!='completed' or set(manifest.get('completedStages',[]))!=STAGES: raise ValueError('Device run is incomplete or failed')
 if hashlib.sha256((run/'source-sha256.json').read_bytes()).hexdigest()!=expected['sourceManifestSHA256']: raise ValueError('Bundled source manifest differs')
 for name,digest in manifest['artifacts'].items():
  if pathlib.Path(name).name!=name: raise ValueError('Invalid artifact path')
  if hashlib.sha256((run/name).read_bytes()).hexdigest()!=digest: raise ValueError('Artifact missing/changed: '+name)
 for name in REPORTS:
  if name not in manifest['artifacts']: raise ValueError('Required report was not finalized: '+name)
  record=read(name);identity(record)
  if record.get('status')!='completed': raise ValueError('Report is incomplete: '+name)
 setup=read('production-gate.json')['payload'];release=read('release-gate.json')['payload'];perf=read('device-performance.json')['payload']
 if setup.get('status')!='passed' or len(setup.get('cases',[]))!=21 or setup.get('nativePrepareFailures')!=0: raise ValueError('Incomplete render gate')
 if len(read('animation-vertices.json')['payload'])!=223 or len(perf)!=6: raise ValueError('Incomplete parity/performance data')
 if len(read('physics-stress.json')['payload'])!=3 or release.get('physicsStressFrames')!=9000: raise ValueError('Incomplete corrected physics stress')
 if release.get('releasedOwnersAfter100SkinCycles')!=100 or len(release.get('lifecycle',[]))!=3: raise ValueError('Incomplete lifetime/lifecycle data')
 if not release['lifecycle'][-1].get('harnessReleasedBeforePerformance'): raise ValueError('Reentrant harness was not released')
 if require_oracle:
  oracle=read('animation-oracle.json');identity(oracle)
  if not oracle.get('passed') or oracle.get('snapshots')!=223 or oracle.get('runtime')!='@esotericsoftware/spine-core@4.1.56': raise ValueError('Pinned external oracle has not passed')
 return run
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--documents',required=True);p.add_argument('--expected',required=True);p.add_argument('--require-oracle',action='store_true');a=p.parse_args()
 run=validate(pathlib.Path(a.documents),json.loads(pathlib.Path(a.expected).read_text()),a.require_oracle)
 print('Validated exact run:',run)
 print('External oracle verified.' if a.require_oracle else 'Device reports verified; external oracle still required.')
