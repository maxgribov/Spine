# Phase 2: action-boundary investigation

Status: **historical investigation of the first construction under spec v4**.
The owner approved the receiver-precondition amendment in spec v5; the revised
runtime uses `.run` boundaries. Current validation is recorded in
[phase2-runtime.json](phase2-runtime.json). The failing observations below remain
evidence of the rejected zero-duration-custom boundary construction.
The phase-1 baseline remains at `c66cab0`. The spec/ADR and baseline goldens were not changed.

## Native observation

Run from the repository root:

```sh
swift Examples/MeshPrototype/Scripts/probe-action-lifecycle.swift
```

This independent script imports only AppKit/SpriteKit. It opens a small native
SKView, runs 90 actual scene updates, prints observations and exits. A 10-second
timeout exits with status 2. Exit 0 means the observation finished, not that the
phase-2 contract passed. No library implementation is involved.

The slow node starts at `speed = 0.5` and runs two repeats of:

```swift
SKAction.sequence([
    .customAction(withDuration: 0) { node, elapsed in /* begin */ },
    .customAction(withDuration: 0.2) { node, elapsed in /* sample */ },
    .customAction(withDuration: 0) { node, elapsed in /* end */ }
])
```

On Apple M1 Max / macOS 26.6 / Xcode 26.6 / SDK 26.5:

- Begin callbacks occurred on native scene updates **1, 2, 19**.
- End callbacks occurred on updates **19, 43**.
- Two activations produced **3 begin callbacks and 2 end callbacks**.
- Both callbacks of the first begin received the same node and elapsed time 0.

Exact update numbers depend on scheduling; the additional begin callback is the
relevant observation. Raw observations are stored in
`phase2-action-probe.json`. The same duplicate first begin reproduced with
SKRenderer using both fixed timestamps and real monotonic timestamps.

A second node in the native probe changes speed `1 → 0.5 → 1` while a single
positive-duration custom action runs. Its elapsed time advances correctly on the
native view. Therefore the separate offscreen speed-test failure below is **not**
evidence that dynamic speed is broken in native SpriteKit.

## Why the current construction fails

The partial runtime interprets each receiver-aware zero-duration callback as a
new execution. Its second callback at initial speed 0.5 encounters the existing
lease and falsely reports `concurrentClip`.

Blindly suppressing a second callback with the same owner/binding and elapsed 0
would also suppress a real second activation of a copied action. SKAction copies
share the captured binding; the callback exposes receiver and elapsed time, not
an activation identity. This prevents that simple deduplication fix from proving
the required conflict behavior.

The conflicting requirements **for this construction** are:

- A.1: immutable owner/epoch/clip binding, execution state on the owner.
- A.3: copy/repeat and nonnegative speed; concurrent copies must conflict; foreign
  receivers must not mutate the owner or receiver and receive one diagnostic per activation.
- A.6: one start event per execution and a once-only zero-duration clip.
- Phase 2: no independent clock or child actions outliving the returned clip.

This is **not a proof that every possible public SKAction construction is
impossible**. It establishes a failure of zero-duration custom begin/end callbacks
and an unresolved boundary/identity issue. No undocumented staging workaround was
adopted.

Apple's [custom action API](https://developer.apple.com/documentation/spritekit/skaction/customaction(withduration:actionblock:))
provides a receiver and elapsed time; [run](https://developer.apple.com/documentation/spritekit/skaction/run(_:))
provides a parameterless callback. [Sequence](https://developer.apple.com/documentation/spritekit/skaction/sequence(_:))
defines ordered actions and a duration equal to their summed durations.

## Explored alternatives

1. **Receiverless `.run` boundaries.** A separate headless probe with initial
   speed 0.5 produced the correct number of begins/ends. It cannot directly verify
   the actual receiver. Running a bound action on another node could reset or
   release its owner's execution before a later custom callback detects misuse.
   This is viable only with an explicit contract amendment making execution on
   the creating Skeleton a caller precondition, removing the strong foreign-node
   no-mutation/diagnostic guarantee. It keeps the existing public SKAction return
   type; native and complete lifecycle tests would still be required.
2. **An explicit owner-bound playback entry point/execution handle.** Start and
   cancellation would receive the Skeleton explicitly instead of requiring safe
   arbitrary SKAction transfer/composition. This is a larger API/architecture
   change, requiring a revised spec/ADR and a new composition contract.
3. **Further bounded research without changing the contract.** A documented
   receiver-aware once-per-activation boundary or another public construction
   could resolve this, but it must first pass real native tests for copied actions,
   foreign receivers, pause and initial/dynamic speed. Its feasibility is not yet
   established.

A per-binding "last receiver" staged by a custom callback and consumed by a later
`.run` was probed but not implemented: safety across paused/interleaved copies on
different receivers is unproven. A positive epsilon-duration boundary was only
considered, not implemented/tested: it adds duration/latency and cannot silently
replace the required exact zero-duration behavior.

## Current checks and preserved work

- Existing 41 tests passed after introducing the opt-in shell.
- Six new `ActionLifecycleTests` executed through actual SKRenderer action
  scheduling: four passed, two failed.
- Passing: setup/deform clock and prepare non-advancement; sequential action reuse,
  copies, sequence/repeat; zero-duration once at default speed; weak owner lifetime.
- Failing `testSharedImmutableAssetDoesNotSharePoseOrExecution`: second owner
  starting at speed 0.5 receives a false conflict from the duplicate begin.
- Failing `testRepeatForeverPauseAndNonnegativeSpeed`: fixed-clock SKRenderer
  elapsed time after speed changes does not match the test expectation. An
  independent direct-custom-action probe reproduces clock discontinuities;
  native SKView does not reproduce that dynamic-speed issue. This test needs a
  native host for dynamic speed, independently of the boundary fix.
- Tests 9–11 and the frame-context matrix are not complete. No claim that the
  phase-2 gate passed, and no production legacy image comparison was run for this
  incomplete phase.

The working tree retains the partial public/error/context/resource/asset shells,
compiled scalar timelines and one-bone/deform fixture, runtime/action routing and
six lifecycle tests. Load/resource/native-mapping shells explicitly throw for
functionality reserved for later phases. No phase-3 JSON decoder/atlas/renderer
implementation was added. No phase-2 commit or baseline update was made.
