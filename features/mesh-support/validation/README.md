# Mesh integration validation

The authorized [Swift / SpriteKit health scenario](swift-health-check.md) defines
reproducible phase-aware checks. [Phase 2 health evidence](phase2-health.json)
distinguishes executed checks, reused current test runs and deferred device gates.

Phase 1 characterized the existing library before mesh integration. At that capture,
the production `Sources/Spine` tree was identical to `d1cbd6e`; no source fixes or golden updates
for new behavior are included. `baseline.json` records the revision/tree identity,
fixture hashes, environment and commands. `platforms.json` separates SDK builds
and hardware discovery from on-device execution.

From the repository root:

```sh
swift test
swift test --package-path Examples/MeshPrototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-legacy /tmp/spine-legacy-check
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-library-legacy /tmp/spine-legacy-bench
```

The validation executable creates a temporary macOS app bundle to exercise the
unchanged `Bundle.main` constructors. The fixture is installed before process
launch (Foundation caches bundle contents); the app is deleted after it exits.
The runner locates repository fixtures/goldens relative to its compiled source
location, so build and run it in the same checkout. It does not require asset
files in `/tmp` from a previous session. Atlas-not-found messages from the
constructor-only checks are expected; rendered cases use a preloaded in-memory
`SKTextureAtlas` with authored image data.

`legacy-baseline/states.json` and 70 PNGs cover fixed SKRenderer timestamps for
once, sequence, repeat, group, reuse, root removal, pause, speed, reset and
skin/texture/manual-node scenarios. Each capture includes tree/type/TRS/z/color,
action flags, physics masks, point counts and delivered events. Comparisons use
1e-6 for numeric state and 1/255 for RGBA channels. The test fixture is authored
for this repository; the original Spineboy ESS 4.1.17 remains a decoder test.
Textures are generated before clock start; this is not a visual baseline of the
commercial Spineboy artwork.

`--record-library-legacy-baseline <output>` only writes to its explicit output
folder. `--record-library-legacy-benchmark <output>` is the explicit benchmark
bootstrap mode; it reports recording, not validation. Normal benchmarking requires
all six reference images and fails if any is missing/corrupt. All legacy output
modes reject the baseline directory and aliases through symlinks, including
existing candidate files that redirect into it. Candidates are compared before
saving, with atomic file replacement. Use a separate staging directory. Neither
recording mode changes checked-in goldens automatically. Do not replace the
baseline to hide a regression. Production source changes require comparison
against these files using the same SDK/OS/renderer.

Legacy behavior observed on the pinned build includes child bone actions
continuing after removal of their parent clip-action and repeated event callbacks
when `Skeleton.speed` is changed to 0.5 during a clip in the fixed SKRenderer
harness. Both reproduce in an independent process and are deliberately recorded,
not corrected during mesh integration. These observations are not newly failing
existing tests or a promise about the new mesh runtime.

`legacy-performance.json` is a separate small region-only CPU baseline, not the
Goblins mesh benchmark: 256×256 offscreen target, 1/10/50 skeletons, two rounds
with reversed population order, 30 warmup +120 measured frames. Update+encode CPU
excludes command submission/wait/readback; GPU command time is recorded
separately. It has no native callback/presentation FPS claim. Compare mean of the
two per-count medians in a matched environment; the accepted legacy CPU regression
limit is 10%. Later mesh performance still needs the spec's larger native/offscreen
benchmark and real-device runs.

The iPhone discovery report does not count as device parity/lifecycle/performance
validation. Those gates remain pending until a test app actually executes there.
