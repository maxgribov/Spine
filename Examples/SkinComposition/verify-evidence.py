#!/usr/bin/env python3
"""Verify a recorded platform run and its current source provenance, not release budgets."""
import argparse, hashlib, json, math, pathlib
p=argparse.ArgumentParser(); p.add_argument('directory'); p.add_argument('--repo', default=str(pathlib.Path(__file__).resolve().parents[2])); a=p.parse_args()
root=pathlib.Path(a.directory); repo=pathlib.Path(a.repo)
def require(condition,message):
    if not condition: raise SystemExit(message)
def read(path): return json.loads(path.read_text())
paired=read(root/'paired/comparisons.json'); native=read(root/'native/native.json'); metrics=read(root/'measurements.json')
for report in [paired,native,metrics]:
    for name,expected in report['build']['hashes'].items():
        require(hashlib.sha256((repo/name).read_bytes()).hexdigest()==expected, 'Source changed: '+name)
require(paired['build']==native['build']==metrics['build'],'Run build provenance differs')
require({c['case'] for c in paired['cases']}=={'setup','color-front','side-draw-order','nil','paused','callback'},'Missing paired cases')
for case in paired['cases']:
    require(case['passed'] and case['differentBytes']==0,'Paired mismatch: '+case['case'])
    for file,expected in case['artifacts'].items():
        require(hashlib.sha256((root/'paired'/file).read_bytes()).hexdigest()==expected,'Paired PNG integrity mismatch: '+file)
    if case['case']=='paused':require(case['appliedWhilePaused'] and case['pausePosePreserved'],'Pause apply not proven')
    for suffix in ['actual','control']:
        require((root/'paired'/f"{case['case']}-{suffix}.png").read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),'Invalid PNG')
frames=native['frames']; require(native['passed'] and len(frames)>2,'Native frames missing')
require(any(f['compareRequired'] for f in frames),'No native frames after change')
last=-1
for frame in frames:
    require(frame['time']>last,'Native timestamps do not increase'); last=frame['time']
    require(frame['actualRootRotation']==frame['controlRootRotation'],'Native phase diverged')
    require(not frame['compareRequired'] or frame['differentBytes']==0,'Native pixel mismatch')
    require(hashlib.sha256((root/'native'/frame['file']).read_bytes()).hexdigest()==frame['sha256'],'Native PNG integrity mismatch')
require(metrics['releaseGate']=='pending','Diagnostic metrics cannot approve release')
for key,count in [('cold',1),('alternating',1000),('repeat',1000)]:
    samples=metrics[key]['samples'];require(len(samples)==count,'Incorrect sample count')
    require(all(math.isfinite(s[k]) and s[k]>=0 for s in samples for k in ['applyMs','prepareMs']),'Invalid timing samples')
seal=read(root/'native-playback.mp4.sha256.json')
require(hashlib.sha256((root/'native-playback.mp4').read_bytes()).hexdigest()==seal['videoSHA256'],'Video integrity mismatch')
require(hashlib.sha256((root/'native/native.json').read_bytes()).hexdigest()==seal['nativeReportSHA256'],'Video native-source integrity mismatch')
if (root/'result.json').exists():require(read(root/'result.json')['passed'],'Device runner reported failure')
print(f"Verified {root}: 6 paired cases, {len(frames)} native frames, timing samples and source hashes. Release assessment remains pending.")
