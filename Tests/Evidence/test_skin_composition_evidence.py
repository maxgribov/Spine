"""Black-box integrity regressions for recorded evidence (no device or recapture).

Run: python3 -m unittest discover -s Tests/Evidence -v

Execution trace: CLI parses paths, reads three reports, checks source hashes and
build equality, validates paired cases/hashes/pause, validates native frames/hashes,
checks timing samples, then checks video/report seals and optional device result.
Each negative test changes one input in a disposable copy and must fail at its
corresponding stage. The positive test proves both unchanged captures reach exit 0.
No collaborator spies: this exercises the real public CLI and filesystem boundary.
"""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from contextlib import contextmanager
from dataclasses import dataclass


REPO = Path(__file__).resolve().parents[2]
CAPTURES = REPO / "features/skin-composition/validation/captures"
VERIFIER = REPO / "Examples/SkinComposition/verify-evidence.py"


@dataclass
class VerificationHarness:
    evidence: Path

    def run(self):
        return subprocess.run(
            [sys.executable, str(VERIFIER), str(self.evidence), "--repo", str(REPO)],
            text=True, capture_output=True, check=False,
        )

    def change_report(self, relative_path, change):
        path = self.evidence / relative_path
        report = json.loads(path.read_text())
        change(report)
        path.write_text(json.dumps(report))


@contextmanager
def make_sut(platform="macos"):
    with tempfile.TemporaryDirectory(prefix="skin-evidence-test-") as directory:
        evidence = Path(directory) / platform
        shutil.copytree(CAPTURES / platform, evidence)
        yield VerificationHarness(evidence=evidence)


class SkinCompositionEvidenceTests(unittest.TestCase):
    def test_verify_accepts_recorded_platforms(self):
        for platform in ["macos", "iphone-air"]:
            with self.subTest(platform=platform), make_sut(platform) as sut:
                result = sut.run()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, "")

    def test_verify_rejects_changed_paired_png(self):
        self.assert_artifact_rejected(
            "paired/setup-actual.png", "Paired PNG integrity mismatch: setup-actual.png"
        )

    def test_verify_rejects_changed_native_png(self):
        self.assert_artifact_rejected(
            "native/frame-0000.png", "Native PNG integrity mismatch"
        )

    def test_verify_rejects_changed_video(self):
        self.assert_artifact_rejected("native-playback.mp4", "Video integrity mismatch")

    def test_verify_rejects_source_mismatch(self):
        source = "Examples/SkinComposition/ImageEvidence.swift"
        with make_sut() as sut:
            sut.change_report("paired/comparisons.json", lambda report:
                              report["build"]["hashes"].__setitem__(source, "0" * 64))
            self.assert_rejected(sut.run(), "Source changed: " + source)

    def test_verify_rejects_pause_not_applied(self):
        with make_sut() as sut:
            def remove_pause_proof(report):
                for case in report["cases"]:
                    if case["case"] == "paused":
                        case["appliedWhilePaused"] = False
            sut.change_report("paired/comparisons.json", remove_pause_proof)
            self.assert_rejected(sut.run(), "Pause apply not proven")

    def test_verify_rejects_native_phase_divergence(self):
        with make_sut() as sut:
            def change_phase(report):
                report["frames"][0]["actualRootRotation"] += 1
            sut.change_report("native/native.json", change_phase)
            self.assert_rejected(sut.run(), "Native phase diverged")

    def test_verify_rejects_unearned_release_approval(self):
        with make_sut() as sut:
            sut.change_report("measurements.json", lambda report:
                              report.__setitem__("releaseGate", "passed"))
            self.assert_rejected(sut.run(), "Diagnostic metrics cannot approve release")

    def assert_artifact_rejected(self, relative_path, message):
        with make_sut() as sut:
            path = sut.evidence / relative_path
            # Preserve format headers; a signature-only existence check must not pass.
            with path.open("ab") as artifact:
                artifact.write(b"corrupted-evidence")
            self.assert_rejected(sut.run(), message)

    def assert_rejected(self, result, message):
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, message + "\n")


if __name__ == "__main__":
    unittest.main()
