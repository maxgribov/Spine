# Skin composition validation

Release gate: **pending**. Phases 1–4 functional work does not approve release.
`measurements.json` records the Phase 3 source baseline; `runs` is empty because
Phase 5 target-specific measurements have not been accepted. Final runs must record
their own final implementation commit and source hashes.

## Reproduce functional checks

```sh
swift test
swift build
python3 Examples/SkinComposition/build.py --platform macos --output /tmp/skin-composition-mac
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition --validate-catalog
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition --smoke
python3 Examples/SkinComposition/build.py --platform simulator --output /tmp/skin-composition-sim
python3 Examples/SkinComposition/build.py --platform ios --output /tmp/skin-composition-ios
```

The iOS command above builds unsigned; it does not install on a physical device.
The macOS smoke command checks native frame preparation, not rendered pixel parity.
Each app embeds commit, dirty status, target/configuration and source/fixture hashes.

`CompositionLifetimeTests` asserts 100 warmup changes, 1,000 alternations and 1,000
identical descriptor applications. It checks old region weak references after drain,
node/proxy/body counts, active body identity, provider/compiler calls and independent
owners on one asset. The existing opt-in `RepeatTailDiagnosticTests` skip is not an
acceptance pass. Public client tests apply/prepare all 32 wardrobe combinations.

## Remaining release inputs and evidence

- Owner-approved devices, match workload, content-catalog size and change frequency.
- Numerical per-target time and memory budgets, followed by actual pass/fail.
- Isolated full-asset resident memory and peak staging/switch memory measurements.
- macOS and physical-iPhone controlled RGBA comparisons and playback videos.
- Existing mesh platform/image/physics release gates.

The example's `--measure` command is ready to export raw cold/alternating/repeat
CPU samples, median/p95/max, process resident diagnostics and source provenance.
Process resident snapshots are not isolated asset bytes or transient peak bytes;
those fields remain null until measured with appropriate allocation tools.
