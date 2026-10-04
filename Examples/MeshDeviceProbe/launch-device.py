#!/usr/bin/env python3
"""Every launch gets a fresh expected UUID before devicectl runs, including failed launches."""
import argparse,hashlib,json,pathlib,plistlib,subprocess,uuid
p=argparse.ArgumentParser();p.add_argument('--build-output',required=True);p.add_argument('--device',required=True);a=p.parse_args()
out=pathlib.Path(a.build_output).resolve();manifest=(out/'source-sha256.json').read_bytes()
run=str(uuid.uuid4());expected={'runID':run,'sourceManifestSHA256':hashlib.sha256(manifest).hexdigest()}
attempt=out/'attempts'/run;attempt.mkdir(parents=True)
(attempt/'expected-run.json').write_text(json.dumps(expected,indent=2)+'\n')
(out/'expected-run.json').write_text(json.dumps(expected,indent=2)+'\n')
bundle=plistlib.loads((out/'MeshDeviceProbe.app/Info.plist').read_bytes())['CFBundleIdentifier']
command=['xcrun','devicectl','device','process','launch','--device',a.device,'--environment-variables',json.dumps({'SPINE_VALIDATION_RUN_ID':run}),bundle]
with (attempt/'launch.log').open('w') as log:r=subprocess.run(command,stdout=log,stderr=log)
(attempt/'launch-status.json').write_text(json.dumps({'runID':run,'exitCode':r.returncode})+'\n')
print('Expected run:',run,'launch exit:',r.returncode,'expected file:',attempt/'expected-run.json')
raise SystemExit(r.returncode)
