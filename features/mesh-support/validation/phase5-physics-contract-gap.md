# Phase 5 blocker: SpriteKit physics writes managed slot transforms

Implementation is stopped pending an approved spec/ADR amendment. Spec v5 and
the strict callback≥30FPS comparator remain unchanged. The current partial
numerical guard is **not accepted**, and its moving-parent regression is red.

## Physical proof

The physical iPhone run completed all21 setup/animated GPU comparisons and
100-owner lifetime cycles. Its223 exported animation snapshots independently
passed `spine-core@4.1.56`. Native lifecycle preparation then failed with
`mutatedNodeContract` at `/runtime/nodes/box`; performance was not reached.

The targeted physical trace proves the writer and preserves ownership:

- Immediately after construction, after placing Skeleton at(80,80)/scale2, and
  in `didEvaluateActions`, the box slot position is exactly(0,0).
- `didSimulatePhysics` changes it to(3.814697265625e-6,3.814697265625e-6) at clip time0.
- The expected parent and the expected library-owned static body remain attached.
  Rotation0, scale1/1 and z0 remain unchanged. No application code writes the slot.

See [physical diagnostic](phase5-physics-device-diagnostic.json). This matches
Apple's documented behavior: physics updates a body's node position and rotation.
[SKNode.physicsBody](https://developer.apple.com/documentation/spritekit/sknode/physicsbody).

## Long trace: macOS, not physical iOS

The read-only [reproduction source](phase5-physics-stress.swift) advances real
SKRenderer physics3000 times per case. It changes only the Skeleton's position
and rotation, calls no mesh prepare and never writes slot transforms. The two
centered/off-center fixtures and the large-parent fixture preserve parent, scale
and z. [Recorded checkpoints](phase5-physics-feedback.json):

| Case | Maximum local translation residue | Maximum one-frame local change |
|---|---:|---:|
|Origin80, scale2, centered box|0.001708984375|0.0000457763671875|
|Origin0, scale2, box offset40|0.002197265625|0.000030517578125|
|Origin10000, scale0.65, box offset20|0.22705078125|0.005859375|

Rotation also reaches−12.5663700104 (approximately−4π): an equivalent identity
orientation expressed with a different winding. An absolute epsilon cannot
preserve identity indefinitely. Increasing it until these traces pass, or
accepting unlimited incremental drift, would conceal meaningful mutations.

To reproduce, temporarily copy the diagnostic into `Tests/SpineTests/Mesh`, run
`swift test --filter PhysicsFeedbackInvestigation`, then remove that temporary
copy. It writes `/tmp/spine-phase5-physics-feedback.json`. This is an observation,
not a passing implementation acceptance test.

## Contract conflict and recommendation

G.4 requires managed slot identity and mutation diagnostics; G.5 keeps physical
bounding-box placement under those slots. R.4 requires preparation after physics,
while R.5 prohibits preparation from changing physics. Native SpriteKit makes
those requirements incompatible for a moving owned static body.

Recommended amendment: permit narrowly bounded reconciliation of **library-owned
static-body slots only** in the final prepare. Validate the numerical residue
first, then restore canonical position0/rotation0 to break feedback. Recognize
full-turn-equivalent angles modulo2π. This changes R.5's no-physics-write promise
and clarifies G.4/G.5; it is not implemented or silently inferred from v5.

The approved rule must keep these limits concrete:

- No bone, Skeleton, ancestor, camera, clock or event writes; repeated preparation
  is idempotent. All unrelated physics and unowned slots stay untouched.
- Ownership/parent/body identity, scale and z remain strict. A meaningful manual
  mutation such as0.001 at the normal fixture scale must still fail before any
  correction. Nonfinite/out-of-budget values remain typed errors.
- Derive a finite world-space precision budget from relevant body coordinates;
  do not use a blanket local epsilon or enlarge a cumulative allowance. Account
  for physics representation only with evidence. Apple documents a150² area
  conversion, but an unverified positional conversion constant is not a policy.
- Use forward transforms; a singular matrix must not make arbitrary local
  mutations acceptable. Prior-owned-body residue after removal needs explicit,
  equally bounded treatment. No inverse-singular-bone dependency.
- Verify hundreds/thousands of moving-parent frames, origin/off-center/large
  coordinates, mutation rejection, correction idempotence and a fresh physical
  lifecycle/performance run before accepting the change.

Alternative: give bounding boxes dedicated physical proxy nodes so solver writes
cannot modify logical slots. That changes `physicsBody.node`, hierarchy/lookup and
possibly `slot.physicsBody` semantics, requiring a larger G.4/G.5/API/ADR decision.
It does not preserve all current physical-node assumptions automatically.

## Current tree

The accepted performance optimizations and iteration2 reporting fixes remain.
The additional uncommitted partial patch is confined to `MeshSetupRenderer.swift`,
`MeshSlotState.swift` and `StaticPhysicsPrecisionTests.swift`: an absolute owned
world-ULP guard plus unchanged-residue history. It fails accumulation and must
not be committed as a finished fix. No corrective position/rotation writes have
been implemented. Diagnostic host files contain before/after-physics capture.

The callback gate is a **separate** pending decision: raw mean29.9968014564FPS
fails unchanged v5≥30. The proposed0.1% cadence allowance has not been approved.

The temporary physical probe was uninstalled successfully after collecting the
evidence (exit0). It restored its own idle timer on failure. No probe/test
process remains active; no spec/ADR edit or commit was made.
