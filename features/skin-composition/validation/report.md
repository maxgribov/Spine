# Skin composition validation

**Release evidence passed for the stated owner workload and synthetic fixtures.**
No absolute memory ceiling is imposed: the owner explicitly requested no arbitrary
limits. Memory measurements and no-retention-growth checks are retained. This does
not predict costs for unseen production artwork or claim manual UI inspection.

## Approved workload and implementation assumptions

Owner inputs: Mac Studio and physical iPhone Air; four teams × three pirates,
up to six neutrals, ten animated buildings/traps/props: **28 simultaneous owners**.
No wardrobe changes during a match; changes before play or on **one fitting-room
pirate**. **20 separate cosmetic items per pirate**, not 20 complete outfits.

The reproducible synthetic catalog has eight hats, eight clothes, four earrings,
plus four separate team skins and base: 25 skins / 94 entries per pirate asset.
It uses explicitly synthetic, unique-per-item 256×256 RGBA textures shared between
that item's states/slots. This is a declared fixture, not inferred game art.
Both sharing bounds were tested: three pirate assets shared across teams, and twelve
distinct pirate assets. Six neutrals share one asset, ten props share another.
Totals: five/fourteen assets and 77/302 textures; exact decoded RGBA storage is
20,185,088/79,167,488 bytes. All catalogs stay loaded during the one-owner preview.
No outfit combination cache is created.

## Native workload and latency

Each scenario has 100 warmup and 120 measured native SKView frames. The match
keeps looks fixed. The preview changes once per frame, faster than manual fitting.
The operational latency criterion is warm preview **apply+prepare p95 ≤16.67 ms**
(one 60 Hz frame). The owner did not request an arbitrary absolute memory limit.

CPU apply+prepare p95 / p99 / max, milliseconds:

| Platform | 28 owners, 3 shared pirate assets | 28 owners, 12 distinct pirate assets | One preview owner |
|---|---|---|---|
| macos | 0.962 / 1.158 / 1.227 | 0.463 / 1.023 / 1.024 | 0.642 / 0.731 / 0.779 |
| iphone-air | 0.945 / 0.966 / 1.037 | 1.150 / 1.314 / 1.326 | 0.618 / 0.654 / 0.814 |

Both preview criteria passed. Native callback means are approximately 60 FPS on
both platforms; no measured interval exceeded two 60 Hz frames. Raw intervals,
including scheduling jitter, are retained and are not labeled GPU-presented times.
See `workload/<platform>/workload.json` and `assessment.json`. iPhone workload status
is passed and linked by fresh run ID, source manifest and output SHA-256; stale,
pending, failed and corrupted-result negative checks were rejected.

## Operational memory measurements

Fresh processes prewarm framework/render resources, then preload all catalog
textures before the retained-asset snapshot. Sample storage is allocated/touched
before baseline. Current allocator bytes and Mach physical footprint are sampled
at every detached region creation and immediately before commit while the complete
old and staged trees coexist: 1,300 checkpoints per run. Any failed Mach query fails
the probe, rather than publishing zero-valued deltas. All recorded queries succeeded.

Bytes:

| Platform / sharing | Full-catalog incremental physical footprint | Incremental live heap | Observed staged live-heap peak delta | Observed staged physical-footprint peak delta |
|---|---|---|---|---|
| macos / shared | 40,927,256 | 20,562,896 | 44,576 | 32,768 |
| macos / distinct | 160,809,104 | 80,425,120 | 38,240 | 98,304 |
| iphone-air / shared | 40,812,568 | 20,543,408 | 44,064 | 32,768 |
| iphone-air / distinct | 160,710,776 | 80,433,280 | 59,392 | 49,152 |

These are operational process deltas around the owned catalog lifetime, not exact
object-graph sums or global GPU allocation attribution. Held-staging maxima are
observed checkpoints, not a guarantee of every transient between checkpoints.
Before/after/drain samples preserve cache effects. All four owner weak references
released; 100/1000/1000 lifetime tests additionally confirm no retained region growth,
stable return-point node/body/proxy counts, no provider/compiler reentry, and owner
independence. There is no invented memory pass/fail ceiling.

Mac diagnostic: Release `-O -enable-testing`. Physical diagnostic: separate fresh
XCTest processes, Debug `-Onone`. These memory observations are not presented as a
matched optimization benchmark. Main app latency runs on both platforms use Release
`-O`. The public example remains ordinary `import Spine`; memory instrumentation is
a separate `@testable` diagnostic with an internal pre-commit checkpoint.

## Same-backend images and native playback

| Platform | Paired cases | Native frame PNGs | Frames compared after callback |
|---|---|---|---|
| macos | 6 / 6, zero differing bytes | 25 | 15 |
| iphone-air | 6 / 6, zero differing bytes | 24 | 13 |

Cases cover setup, current color/front, side/draw-order, animation nil, application
while already paused, and callback change. Paused owners must keep their poses after
a later renderer update. The control wears the target outfit from clip start; the
actual owner changes it at the same sampled pose. Pixel bytes match exactly on each
platform's own backend, without tolerance, alpha or sRGB adjustments.

Native SKView recordings preserve equal root rotation against the control on every
frame; post-callback pixels also match. PNGs and native timestamps are source proof.
MP4 uses recorded intervals and is presentation only. Capture-time PNG hashes and
video/native-report hash sidecars are verified; corruption of paired PNG, native
PNG and video was rejected. macOS-only native UI test wrappers are not counted as
iOS tests. Device runtime scheduling additionally executes through real SKRenderer
in the full physical suite.

## Current-source regression and inherited contracts

- macOS: **193 executed, 192 passed, 1 existing opt-in diagnostic skipped**, zero
  failures; `swift build` passed. The diagnostic skip is not an acceptance pass.
- Physical iPhone Air: **173 / 173 applicable XCTest cases passed**, zero skipped;
  two additional memory tests each passed in a separate fresh host process.
- Current physical setup exports: **5 / 5** official-runtime comparisons passed.
- Current physical animation exports: **223 / 223** comparisons against pinned
  `@esotericsoftware/spine-core@4.1.56` passed. Max position error
  0.0000576304, max UV error 0.0000000596046, within the existing tolerances.

Full physical suite logs/source hashes are in `physical-tests/`; actual device
exports, comparator results and pinned tarball hash are in `physical-tests/oracle/`.
The first physical attempt had two infrastructure failures because existing oracle
exporters defaulted to forbidden `/tmp`. The generated host points their existing
environment override at its sandbox; no library/test behavior was changed. The
full corrected suite was rerun, not reduced to failed cases.

Inherited mapping: current geometry/oracle tests protect mesh/deform/linked-source
semantics; current image/frame suites protect existing raster/prepare behavior;
AttachmentInterop and PhysicsReconciliation/StaticPhysics suites protect G.5 and
P.1–P.7 ownership, correction, tokens, error priority and long-run stability.
Composition mixed-base tests additionally retain point/body/mesh identities.
Historical v6 device render/performance/external-oracle baselines remain available
in `features/mesh-support/validation/phase5-v6-device-proof/`; they are explicitly
historical. A legacy CPU ratio or old 50-mesh benchmark was not newly measured or
silently promoted from history. The current owner workload was measured separately.

## Specification coverage

Tests 1–8: public contract, resolver, validation, metadata; 9–12: transitions,
logical requests, rollback and mixed identities; 13–15: playback/events/frame
behavior; 16: exact-repeat/1000-cycle resource checks and shared owners; 17: existing
mesh/legacy suites; 18: DocC/public app/catalog checks; 19: per-platform paired images,
native videos, raw timing and operational memory measurements. The public fixture
executes all 32 outfits; scaled generators exercise 20 separate items per pirate,
4 team layers, both asset-sharing bounds and 28 fixed-look owners.

## Provenance and reproduction

Evidence is from the final Phase 5 working tree based on `7a61ac8`, with `dirty=true`
and exact source/fixture SHA-256 manifests. This is not a claim that a later clean
commit was tested. Platform app manifests, physical XCTest manifests and separate
memory-build metadata identify their exact builds. Device identifiers, signing
credentials and profiles are not stored in the repository.

Build/run/capture/video/XCTest commands are documented in
[the example README](../../../Examples/SkinComposition/README.md). Key checks:

```sh
swift test
swift build
python3 Examples/SkinComposition/verify-evidence.py features/skin-composition/validation/captures/macos
python3 Examples/SkinComposition/verify-evidence.py features/skin-composition/validation/captures/iphone-air
python3 Examples/SkinComposition/summarize-workload.py features/skin-composition/validation/workload/macos
python3 Examples/SkinComposition/summarize-workload.py features/skin-composition/validation/workload/iphone-air
```

The superseded iteration-1 macOS Allocations aggregate remains explicitly scoped
historical diagnostic evidence. Its 62 MB `.trace` stays outside the repository;
current operational asset/staging measurements are the fresh-process probes above.
The manual visual-check tool was unavailable; no manual screenshot inspection is
claimed or substituted. Automated same-backend image and native playback evidence
satisfies the recorded image checks.


## Explicit deviation from the original numeric budget rule

Original spec D.5 permits null budget fields only while the release gate is pending.
The owner's later instruction (no arbitrary limits; one fitting-room character must
not lag) overrides an invented absolute memory ceiling. Accordingly aggregate
`budgets.assetResidentBytes` and `budgets.peakSwitchBytes` are **null by approved
policy**, not because their operational observations are absent. Numeric observations
are in all four memory runs. The 60 Hz combined latency budget remains numeric.
`memoryBudgetPolicyOverride` names D.5, owner approval and the two exempt budget
fields. Thus `releaseGate=passed` means the **agreed MVP assessment**, not literal
unchanged conformance to the original v1 D.5. Spec v2 and the ADR now record this
owner policy, measured workload and the limits of the operational memory method.
The composition architecture and behavior are unchanged.

`verify-release.py` checks the aggregate approval, workload, numeric latency result,
explicit D.5 exception, operational memory validity/release, current physical suite,
current external oracle and image/source integrity. Raw standalone collector reports
retain `releaseGate=pending` because an individual diagnostic run does not itself
approve the aggregate workload.
