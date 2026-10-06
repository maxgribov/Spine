# Skin composition validation

**Release gate: pending.** Functional, same-backend image and native playback
checks below passed. Workload/budgets and isolated memory gates remain unapproved.
No manual UI screenshot inspection is claimed.

## Provenance

Runs were built in Release (`-O`) from the Phase 5 working tree based on
`4377855`. Each measurement/image/native report embeds the full source commit,
`dirty=true`, target, configuration, and SHA-256 of every production/runner Swift
source and bundled fixture. This is explicit working-tree evidence, not a claim
that a future clean commit was tested. The verifier checks those hashes against
the current tree. Pairwise comparisons never cross device backends.

## Recorded results

| Platform | Paired cases | Native playback | Alternating apply p95 | Prepare p95 |
|---|---|---|---|---|
| Mac Studio, Mac13,1 / M1 Max, macOS 26.6 (25G72) | 6/6, zero differing pixel bytes | 29 frames; 18 after change match control | 0.13367 ms | 0.00967 ms |
| Physical iPhone Air, iPhone18,4, iOS 26.6.2 (23G90) | 6/6, zero differing pixel bytes | 24 frames; 13 after change match control | 0.06304 ms | 0.00492 ms |

Each run uses one Skeleton, the entire authored 13-skin/54-state catalog, 100
warmups, 1,000 alternations and 1,000 equal-descriptor repeats. Raw samples and
cold/repeat/alternating median/p95/max are in each `measurements.json`. These are
fixture diagnostics, not the game's target workload or accepted budgets. Prepare
timings use an explicit context and do not measure GPU frame time.

Paired cases: setup, current color/front, side/draw order, animation nil, paused
application, and event callback. The control wears the target outfit from clip
start; the tested Skeleton changes it at the sampled pose. Both use the same
backend and action time. Raw image bytes must match exactly; no alpha/sRGB
corrections or relaxed pixel tolerance were applied.

Native recordings use actual `SKView.didFinishUpdate`, native prepare, and a
callback switch during `walk`. Root rotation agrees with the control on every
recorded frame; after the change, pixel bytes also agree. Frame PNGs and native
timestamps remain the source evidence. MP4s are encoded with those intervals;
lossy video is not used for exact pixel comparison.

Artifacts: [macOS](captures/macos/), [physical iPhone Air](captures/iphone-air/).

## Memory evidence and limits

Both runs record process resident bytes before/after loading the full fixture
asset and after each alternating switch. These include framework/cache activity;
they are not isolated asset residency. On iOS the app also loads its interactive
asset before entering the diagnostic runner, so process readings include that
retained asset and shared framework caches.

A superseded iteration-1 macOS Instruments Allocations trace was additionally recorded from a copy of the
same executable with an ad-hoc `get-task-allow` entitlement. Standard signing did
not permit attach; instrumentable signing did. The trace recorded heap and VM
allocations successfully. Exported [aggregate statistics](captures/macos/allocations-statistics.xml)
and [scope/provenance](captures/macos/allocations-summary.json) are retained. The
62 MB source trace remains at `/tmp/skin-phase5-allocations-authorized.trace`.
Aggregate lifetime/persistent allocation bytes cannot reliably identify either
isolated shared-asset residency or the transient peak of a particular staging
transaction. Therefore `assetResidentBytes` and `peakSwitchBytes` remain null.
No process snapshot or allocation-total value is mislabeled as those metrics.

## Commands and regression checks

```sh
swift test
swift build
python3 Examples/SkinComposition/build.py --platform macos --output /tmp/skin-phase5-mac
/tmp/skin-phase5-mac/SkinComposition.app/Contents/MacOS/SkinComposition --capture /tmp/skin-paired
/tmp/skin-phase5-mac/SkinComposition.app/Contents/MacOS/SkinComposition --native-evidence /tmp/skin-native
/tmp/skin-phase5-mac/SkinComposition.app/Contents/MacOS/SkinComposition --measure /tmp/skin-measurements.json
python3 Examples/SkinComposition/encode-video.py /tmp/skin-native /tmp/skin-native.mp4
python3 Examples/SkinComposition/verify-evidence.py features/skin-composition/validation/captures/macos
python3 Examples/SkinComposition/verify-evidence.py features/skin-composition/validation/captures/iphone-air
```

Physical build/sign/install/launch/export commands are in the
[example README](../../../Examples/SkinComposition/README.md). The installed bundle
is `dev.spine.skincomposition`; device identifiers, provisioning profiles and
signing credentials are not stored in evidence. The physical run wrote
`result.json` with `passed=true` and was exported from its app data container.

To repeat the allocation trace on an instrumentable local copy:

```sh
xcrun xctrace record --template Allocations --output /tmp/skin-allocations.trace \
  --time-limit 10s --no-prompt --launch -- /path/to/instrumentable/SkinComposition \
  --measure /tmp/skin-profiled-measurements.json
xcrun xctrace export --input /tmp/skin-allocations.trace \
  --xpath '/trace-toc/run[@number="1"]/tracks/track[@name="Allocations"]/details/detail[@name="Statistics"]' \
  --output /tmp/skin-allocation-statistics.xml
```

macOS full suite: **193 executed, 192 passed, 1 existing opt-in diagnostic skipped,
0 failures**. `swift build` passed. The existing skipped
`RepeatTailDiagnosticTests` is not counted as acceptance evidence. Current mesh
geometry/image/physics regression tests pass in that suite; this does not upgrade
older independent release gates in `features/mesh-support/validation/platforms.json`.
In particular the prior mesh platform release gate remains separately documented
as pending and was not replaced by this region-wardrobe proof.

## Remaining release gates

- Owner-approved target devices, match population, switch frequency and catalog size.
- Agreed numerical timing/memory budgets, then actual per-target workload pass/fail.
- Reliable isolated full-asset residency and transient staging-peak measurements.
- Any still-open inherited mesh platform/image/physics release gates.

`measurements.json` links actual runs while retaining `releaseGate=pending`, empty
approved targets and null unprovided workload/budget fields. Physical capture and
fast fixture measurements alone do not close these release gates.

## Iteration 2 correction and integrity

Both platform runs were freshly captured after correcting the paused scenario:
owner and control pause before applying the new outfit, a later renderer update
must preserve both root rotations, and exact paired pixels still match.
Paired/native PNG hashes are recorded by the capture runner. The MP4 encoder checks
source PNG hashes and seals the video together with its native-report hash.
The verifier validates these artifacts plus current source hashes. Negative checks
confirmed that corruption of paired PNG, native PNG and MP4 is rejected.
Old iteration-1 paired/native runs were superseded, not relabeled or resealed.
The earlier Allocations aggregate is retained only as explicitly scoped historical
diagnostic evidence; it does not close a current isolated-memory release gate.
