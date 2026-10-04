#!/usr/bin/env python3
import hashlib,importlib.util,json,pathlib,tempfile,unittest,uuid
spec=importlib.util.spec_from_file_location('collector',pathlib.Path(__file__).resolve().parents[1]/'validate-results.py');collector=importlib.util.module_from_spec(spec);spec.loader.exec_module(collector)
class CollectorChecks(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.root=pathlib.Path(self.temp.name)
  self.expected={'runID':str(uuid.uuid4()),'sourceManifestSHA256':hashlib.sha256(b'{}\n').hexdigest()}
  self.run=self.root/'runs'/self.expected['runID'];self.run.mkdir(parents=True);(self.run/'source-sha256.json').write_bytes(b'{}\n')
  payloads={'production-gate.json':{'status':'passed','cases':[{}]*21,'nativePrepareFailures':0},'animation-vertices.json':[{}]*223,'animation-grid.json':[{}]*4,'device-performance.json':[{}]*6,'release-gate.json':{'physicsStressFrames':9000,'releasedOwnersAfter100SkinCycles':100,'lifecycle':[{}, {}, {'harnessReleasedBeforePerformance':True}]}}
  payloads['physics-stress.json']=[{}]*3
  for name,payload in payloads.items(): (self.run/name).write_text(json.dumps({**self.expected,'status':'completed','payload':payload}))
  self.manifest={**self.expected,'status':'completed','completedStages':sorted(collector.STAGES),'artifacts':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in self.run.iterdir()}}
  self.save()
 def save(self): (self.run/'run-manifest.json').write_text(json.dumps(self.manifest))
 def test_valid_current_run_and_missing_external_oracle(self):
  self.assertEqual(collector.validate(self.root,self.expected),self.run)
  with self.assertRaises(FileNotFoundError):collector.validate(self.root,self.expected,True)
 def test_new_failed_launch_cannot_reuse_old_success(self):
  expected={**self.expected,'runID':str(uuid.uuid4())}
  with self.assertRaises(FileNotFoundError):collector.validate(self.root,expected)
 def test_source_mismatch_rejected(self):
  with self.assertRaises(ValueError):collector.validate(self.root,{**self.expected,'sourceManifestSHA256':'0'*64})
 def test_running_failed_or_incomplete_stage_rejected(self):
  for state in ['running','failed']:
   self.manifest['status']=state;self.save()
   with self.assertRaises(ValueError):collector.validate(self.root,self.expected)
  self.manifest['status']='completed';self.manifest['completedStages'].pop();self.save()
  with self.assertRaises(ValueError):collector.validate(self.root,self.expected)
 def test_changed_or_missing_report_rejected(self):
  path=self.run/'release-gate.json';path.write_text('{}')
  with self.assertRaises(ValueError):collector.validate(self.root,self.expected)
  path.unlink()
  with self.assertRaises(FileNotFoundError):collector.validate(self.root,self.expected)
if __name__=='__main__':unittest.main()
