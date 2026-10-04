# Swift / SpriteKit health scenario

This repository-specific scenario was authorized by the user on 2026-10-03.
It supplies the Swift recipe missing from the generic `code:health-check` skill;
the shared skill and the feature specification are not changed. Run from the
repository root on macOS with Xcode selected, Metal available and a logged-in
graphical session. The native lifecycle XCTest cases create a window and an
actual `SKView`; a headless environment or fixed-clock `SKRenderer` is not a
substitute for those tests.

## Common checks

Record the branch, source revision, dirty-tree scope, OS, Swift and Xcode versions.
Do not clear caches, change toolchains, overwrite goldens or repair baseline
behavior as part of a health run. Use new output directories; retain command
exit codes and logs. A skipped required check is not a pass. Tests supplied by
another pipeline agent may be reused only from the same current source/test
state, with the command, completion time, agent and log recorded as provenance.

```sh
git branch --show-current
git rev-parse HEAD
git status --short
sw_vers
xcodebuild -version
swift --version
swift test
swift test --package-path Examples/MeshPrototype
swift build -c release --package-path Examples/MeshPrototype
git diff --check
git diff --cached --check
```

`git diff --check` covers tracked changes, not untracked files. Inspect newly
added files as well. There is no configured standalone Swift lint recipe;
compiler diagnostics, tests and whitespace checks are reported separately.
For this inspection, preserve verbatim imported fixtures/license files and their
hashes. A missing final newline in imported data or generated JSON is formatting
information, not a build failure; validate generated JSON by parsing it. Trailing
whitespace in authored source/docs remains a reported defect.

Compile the library for all existing deployment minima, using separate scratch
directories. These are compile checks, not simulator or physical-device tests.
Do not raise minimum versions to get a green result.

```sh
health_output=$(mktemp -d "${TMPDIR:-/tmp}/spine-health.XXXXXX")
swift build --target Spine --triple x86_64-apple-macosx10.15 --sdk "$(xcrun --sdk macosx --show-sdk-path)" --scratch-path "$health_output/macos"
swift build --target Spine --triple arm64-apple-ios13.0 --sdk "$(xcrun --sdk iphoneos --show-sdk-path)" --scratch-path "$health_output/ios"
swift build --target Spine --triple arm64-apple-tvos13.0 --sdk "$(xcrun --sdk appletvos --show-sdk-path)" --scratch-path "$health_output/tvos"
swift build --target Spine --triple arm64_32-apple-watchos6.0 --sdk "$(xcrun --sdk watchos --show-sdk-path)" --scratch-path "$health_output/watchos"
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-legacy "$health_output/legacy"
```

The final command must validate all 70 legacy images and state/events against
the checked-in baseline: numeric error at most 1e-6 and RGBA channel error at
most 1/255. A missing baseline is an error, not a reason to use a recording
mode. Use the same SDK/renderer as the recorded baseline. Expected missing-atlas
messages from constructor-only tests are documented in [README](README.md).

## Phase gates

| Phase | Additional required evidence |
|---|---|
| 1 | Baseline characterization for Tests 1–3 and 21–23, unchanged production revision, fixture hashes, CPU baseline, SDK/device discovery. |
| 2 | Tests 8–11 and 19 state cases, baseline 1–3, full implemented suite. Native SKView pause/resume and initial/dynamic nonnegative node/container speed must pass; record begin/end counts, events and lease release. |
| 3 | Decoder/compiler/resources, setup skinning/renderer and lifetime tests; full compatibility. Real iOS triangle-pair, PMA/tint, trim/rotation and native frame mapping subset is mandatory before phase completion. |
| 4 | Full timeline/slot/node/render/integration checks, all three fixtures against the pinned oracle, both production-backed demo scenes, and existing GPU regressions. |
| 5 | All spec Tests 1–23; matched legacy/mesh performance, lifetime and platform checks; real-device iOS parity/lifecycle/render and 1/10/50 measurements. |

Later-phase gates remain `pending` until executed. Do not invent a successful
`--verify-library-mesh` or `--benchmark-library-mesh` result while those commands
are still unimplemented. Once implemented, run their spec-defined fixtures and
timestamp grids, not only a sample pose. Apply the spec's numeric/image limits
and record exceptions individually. Performance runs are sequential with no
other builds/tests running; use the specified warmup, measured frame counts and
reversed rounds. GPU encode timings and callback FPS are not presented FPS.

Discover device availability with `xcrun devicectl list devices`; discovery and
successful iOS compilation do not prove execution. A future device report must
identify model/OS and the app/test command actually run, without checking private
device identifiers into the repository. Missing device execution blocks the
applicable phase/release gate, not earlier state-only phases.

An automated health pass does not claim interactive visual review. The
`macos-use` tool required by the separate visual-check workflow is unavailable
in this session; native XCTest windows and offscreen image comparisons are
reported for what they test, not as a replacement for that UI workflow.

## Result

For phase 3, the setup-only mesh CLI and external oracle are now available.
After the common checks, run the following from the repository root (using the
`health_output` directory created above). Install the pinned oracle outside the
repository; it is validation tooling, not a package dependency.

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-mesh "$health_output/mesh"
npm install --prefix "$health_output/oracle" --no-save @esotericsoftware/spine-core@4.1.56
SPINE_CORE_4156_ENTRY="$health_output/oracle/node_modules/@esotericsoftware/spine-core/dist/index.js"
node Examples/MeshPrototype/Scripts/compare-library-setup.mjs "$SPINE_CORE_4156_ENTRY" "$health_output/mesh"
```

Expect nine setup GPU comparisons and five snapshots across three fixtures.
This is not the phase 4 animation timestamp grid. Follow the separate
[physical iOS host instructions](../../../Examples/MeshDeviceProbe/README.md)
for the mandatory phase 3 device subset. Compare every recorded production/host
source hash with the current tree before accepting a reused device capture;
old captures with source deltas are historical evidence only.

Write a JSON report alongside this document containing phase/spec version,
source revision and dirty scope, environment, command/exit code/result for each
check, reused-run provenance, warnings, deferred gates and a phase-scoped status.
Do not label the whole mesh feature complete from a phase 2 health pass.
The first execution is recorded in [phase2-health.json](phase2-health.json).
Setup integration checks are recorded in [phase3-health.json](phase3-health.json).

## Phase 4 animation and integration

The same mesh CLI now also exports the complete animation timestamp grid and
runs both production scenes against the retained prototype environment reference:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-mesh "$health_output/mesh"
node Examples/MeshPrototype/Scripts/compare-library-setup.mjs "$SPINE_CORE_4156_ENTRY" "$health_output/mesh"
node Examples/MeshPrototype/Scripts/compare-library-animation.mjs "$SPINE_CORE_4156_ENTRY" "$health_output/mesh"
```

Expect 223 animation snapshots across the required three fixtures plus the authored
slot-transition fixture, nine existing setup GPU comparisons and eight strict
world comparisons (max channel error 3/255, count over 2 recorded separately).
`NativeFrameProjectionTests` additionally verifies live-view corner/pixel-center
mapping after late edits and a strict bottom-left custom crop-origin comparison.
Its hard-edged opaque silhouette readbacks are **supplementary diagnostics**, not
passing image acceptance evidence: two calibration cases differ by one pixel
(max 39/255). The strict textured camera gate is the eight world comparisons.
The custom capture crops an ordinary subtree; cropping an `SKScene` resizes its
projection and is not a faithful viewport-offset fixture.

Phase 3 physical-device hashes and captures remain historical after phase 4
production changes. Final iOS parity/lifecycle/performance runs belong to phase 5.

## Phase 5 performance and physical release gate

Run the production benchmark and matched legacy script sequentially after builds:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-library-mesh "$health_output/mesh-performance"
python3 Examples/MeshPrototype/Scripts/benchmark-library-legacy-matched.py --output "$health_output/legacy-matched"
```

The mesh harness uses the canonical30+120 native and30+60 offscreen counts,
separate CPU/action/preparation and encode intervals, completed GPU timestamps,
and post-timing image guards. Internal `.one` reference images receive exactly
the same compiled input as production `.two`; independent numeric validation
remains the pinned4.1.56 oracle. The prototype image diagnostic does not replace
the strict group comparison and is not promoted to a pass when it differs.
The legacy archive comparison requires its immutable image guards every round.
Record failed runs, clock/protocol differences, thermal/visibility metadata and
raw unrounded callback FPS. Do not relax a threshold without an approved spec
amendment. Current v5 strict callback failure is recorded in `phase5-checks.json`.

Follow the updated physical-host instructions for the full current-source gate.
Build/sign/install before requesting unlock, verify hashes, collect both device
reports and PNGs, run the external oracle on its223 exported snapshots, and remove
the host after evidence collection. Build success and a historical phase3 setup
capture do not prove phase5 iOS release readiness.

## Approved v6 acceptance and measurement conditions

The nominal30 callback gate is now specified as the unrounded mean of the two
round FPS values ≥30×(1−0.001)=29.97. Each round uses1000/mean(all120 intervals).
CPU pose≤10ms, update/encode≤21.3ms, GPU≤0.52ms and all image thresholds are
unchanged. Existing v5 failures remain historical raw evidence; the current acceptance script uses29.97 and rejects any inactive/occluded or
non-nominal measured sample while preserving every sample.

Owned-static reconciliation must pass spec P.1–P.7: fixed32-ULP world-coordinate
budgets intersected with local position≤0.01 and modulo-angle≤1e-5 caps, no
accumulated allowance, strict ownership/scale/depth, valid correction even when
render context is invalid, and canonical state after each prepared physics step.
Add3000-frame corrected traces, removal-token/near-singular/fault/contact cases
and a fresh physical iOS run; the old uncorrected diagnostic traces are not passes.
