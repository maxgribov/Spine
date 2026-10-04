# Phase 5 — v6 release evidence

Current implementation is based on `c685a59` and the approved v6 contract.
Implementation reviews are clean. M1 performance, matched legacy performance and
the fresh physical iOS gate passed. Final automated health and testing reviews pass; human phase review and commit
remain pending. See [final health](phase5-health.json).

## Current performance

The accepted M1 Max run uses two reversed rounds, 1/10/50 actors, 30+120 native
and 30+60 offscreen frames. Every one of the 12×120 native samples was active,
visible and thermal nominal. No samples were filtered. For 50 actors, the mean
of two p50 values is pose 8.026145806 ms, encode 20.385895856 ms and GPU
0.517916691 ms. Raw callback rounds are 29.99994343710319 and
30.000060937432952; their mean 30.000002187268073 passes the approved ≥29.97
criterion. Callback rate is not presented FPS. Six strict pair/single image
comparisons have maximum channel difference zero.

See [raw measurements](phase5-v6-mesh-performance.json),
[image guards](phase5-v6-mesh-performance-images.json) and
[exact source hashes](phase5-v6-performance-source-sha256.json).
The prior foreground run at 29.447891533 failed and remains historical evidence.

Profiling found repeated attribute uploads, unnecessary region proxy chains and
repeated ancestry checks before unchanged physics-body transitions. The runtime
now reuses validated geometry for atomic commit, uploads each preallocated
attribute map once, retains all logical-node validation, and skips setters only
when actual SpriteKit values already match. The diagnostic repeat-boundary CPU
median fell from 35.359 to 31.973 ms; that offscreen trace alone was never treated
as native FPS proof. See [tail diagnosis](phase5-v6-repeat-tail.json).

The independent prototype benchmark now advances by elapsed native time, matching
SKAction. Its historical tick/60 clock made walking slower at 30 callbacks. Both
current variants start at phase zero. Strict renderer references use an independent
single-triangle shader with the same compiled pose; the external 4.1.56 oracle
separately validates pose math. The old prototype raster diagnostic still differs
by at most 10/255 for ten pixels at 50 actors and is not a passing image reference.

The fresh matched legacy comparison uses archived `d1cbd6e`, the identical harness
and immutable PNG guards. Combined update+encode ratios for 1/10/50 actors are
0.989122462, 1.026879636 and 0.983651682, all below 1.10. Update-only figures remain
diagnostic. See [raw matched legacy](phase5-v6-legacy-performance.json).

## Physical iOS gate

Run `5654dfca-d739-4b67-a8e0-b7c69c19be94` completed on the physical iPhone
(A19 Pro GPU, iOS 26.6.2). All 95 bundled production/host hashes match current
sources. The fresh-run collector verified the exact run ID, manifest and artifact
hashes; the independent pinned 4.1.56 oracle passed all 223 exported snapshots.

The run passed 21 setup/animated render comparisons (maximum channel difference
2; all 15 animated cases zero), three 3000-frame corrected physics traces,
100 owner-release cycles, native pause/speed/repeat/copy/skin checks and reentrant
restart/conflict recovery. It measured 1/10/50 actors in both reversed rounds with
strict independent image guards. Native 50-actor callback rates were
59.978029294 and 59.979007348 at the host's 768×768 native viewport; offscreen
1920×1080 GPU p50 values were 2.713874914 and 2.718375064 ms. These device figures
are recorded without applying M1-specific budgets or claiming presented FPS.
The probe was uninstalled after collection and no longer keeps the phone awake.

All raw reports, snapshots and PNGs are in
[physical proof](phase5-v6-device-proof/run-manifest.json), including the separate
[external oracle](phase5-v6-device-proof/animation-oracle.json).
Historical phase3/v5 device evidence is not substituted for this run.

## Verification status

The current root suite passed 145 required tests; the additional opt-in tail
diagnostic is skipped in the ordinary suite and passed separately in Release.
The current mesh CLI passed nine setup GPU cases, eight integration comparisons,
five setup snapshots and 223 animation snapshots against the external oracle.
The approved bounded static-body reconciliation preserves body.node and logical
bone/clock/event semantics, cleans valid slots independently of rendering errors,
and is covered by long-run, ownership, expiry, singularity, mixed-error, contact
and lifetime regressions. Legacy behavior remains mode-separated.

The final health runner verified the complete current-source platform/test/API
matrix: all four deployment minima, 70 exact immutable legacy images and the
retained prototype regressions pass. The testing stage added one test-only
next-representable-Float local-cap boundary regression; 146 tests were discovered,
145 passed and one optional diagnostic was intentionally skipped. Production/host
and resource evidence remains unchanged. See [checkpoint](phase5-v6-checkpoint.json) and
[reproduction recipe](swift-health-check.md). No final Done claim is made until
the remaining human review and commit gates are complete.

## Spec test mapping for final health review

| Test | Evidence | Current status |
|---|---|---|
|1|LegacyConstructionTests; unchanged client fixtures|Current root suite passed.|
|2|UnifiedDecoderTests|Current root suite passed.|
|3|70-image legacy characterization|Fresh final-health 70-image comparison passed exactly.|
|4|Decoder41Tests|Current root suite passed.|
|5|GeometryValidationTests|Current root suite passed.|
|6|LinkedMeshTests|Current root suite passed.|
|7|TextureProviderTests + physical trim/PMA cases|Passed.|
|8|ActionLifecycleTests + physical native node/action-speed cases|Passed.|
|9|ActionConflictTests + physical copied-action conflict|Passed.|
|10|ActionCancellationTests + physical reentrant restart/stale action|Passed.|
|11|TimelineTests + external timestamp oracle|Passed.|
|12|SlotStateTests + physical animated skin-transition cases|Passed.|
|13|SkinningTests + external numeric oracle|Passed.|
|14|223 animation snapshots + five setup snapshots; physical223 oracle|Passed.|
|15|NodeBridge/StaticPhysicsPrecision/LongRun/PhysicsReconciliationContract tests; physical9000 steps|Passed.|
|16|AttachmentInteropTests + body ownership/removal-token tests|Passed.|
|17|Nine setup GPU cases + physical21 render cases|Passed.|
|18|Eight production world comparisons; retained prototype demo scenes|Current mesh CLI and fresh retained prototype smoke passed.|
|19|FrameContext/NativeFrameProjection + reconciliation/error/contact tests|Current root suite passed; physical native prepare passed.|
|20|ResourceLifetime/RendererProxyLifetime/ValidatedGeometry; physical100 releases|Passed.|
|21|Current accepted M1 and matched legacy reports; strict images; benchmark policy checks|Passed.|
|22|Physical current-source release gate; four deployment-minimum builds|Physical and four fresh current-source minimum builds passed.|
|23|Meshes documentation, prototype/device READMEs, unchanged legacy smoke|Documentation and final example/API smoke passed.|

Interactive visual automation remains unavailable because the required macos-use
connector is absent. Automated GPU comparisons and recorded application captures
are identified as such; they are not claimed as that interactive tool workflow.
