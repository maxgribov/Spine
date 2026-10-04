# Phase 3 setup integration evidence

The single `SpineModel` decoder now retains 4.1 attachment/deform and numeric
channel data. Previously ignored unsupported features are recorded for the opt-in
compiler; malformed newly decoded fields are deferred for mesh loading so legacy
unknown-field behavior is preserved. No second/versioned loader was added.

The compiler validates all skins, geometry, references, supported timelines and
capabilities before resolving textures. Geometry is shared across linked chains;
timeline identity follows the direct parent in pinned Spine 4.1.56. The resource
provider handles multi-page PNG, trim, rotations 0/90 and straight/PMA metadata.
Meshes use pairs of triangles by default; regions remain native SKSpriteNodes with
the primary texture sampler. Shared shaders contain no mutable pose state.

`Skeleton(meshAsset:)` renders setup poses through native/custom preparation.
Bone transforms are multiplied forward in Skeleton-local space. Regions use proxy
bone transforms in the render branch, preserving nonuniform parent transforms;
mesh vertices do not receive a second bone transform. Logical bone/slot lookup,
points and physics stay separate from the render branch. Runtime invalid geometry
and node-contract errors hide managed visuals until successful preparation.

Actual source-animation playback and skin replacement remain phase 4. Declared
animations are listed, but requesting playback of one currently throws
`unsupportedFeature`; the implementation does not return an inert action as if it
supported playback. Minimal compiled lifecycle fixtures from phase 2 still run.
No production-backed demo scene replaces either existing prototype scene.

## Reproduction

```sh
swift test
swift test --package-path Examples/MeshPrototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-legacy /tmp/spine-legacy-phase3
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-mesh /tmp/spine-library-mesh-phase3
node Examples/MeshPrototype/Scripts/compare-library-setup.mjs "$SPINE_CORE_4156_ENTRY" /tmp/spine-library-mesh-phase3
```

The mesh CLI invokes the internal XCTest GPU/geometry-export host from the same
checkout, avoiding a new public debug API. It emits GPU comparison metrics,
Goblins captures and five setup snapshots for three fixtures. The external oracle
must be `@esotericsoftware/spine-core@4.1.56`; it is not vendored or a production
dependency. The full animation timestamp grid belongs to phase 4.

See [the iOS host instructions](../../../Examples/MeshDeviceProbe/README.md) for
physical-device reproduction. [phase3-device.json](phase3-device.json) records the
six image comparisons and the exact captured-source provenance. Its source-delta
field explicitly identifies any production change made after capture; do not
silently treat a different source snapshot as a fresh physical-device run.

## Findings encoded as regressions

- Native shaders do not honor the texture's nearest setting automatically for
  these sampler paths: both mesh and region shaders explicitly snap to texel
  centers. Region filtering attributes follow its current primary texture.
- `SKSpriteNode.size` includes the sprite's own scale. Oracle export uses the
  unscaled region size before applying node transforms, avoiding double scaling.
- Headless `resizeFill` and an opaque default Metal clear can produce matching
  blank images. The physical host uses `aspectFit`, transparent clear and colored
  occupancy checks; PNGs were inspected before accepting the result.
- Spine exports can round a Bezier handle slightly beyond the following key time.
  The validator checks finite controls/arity, not an extra unrequired range clamp.

The phase-1 goldens remain unchanged. No tolerances were relaxed. Metadata records
scope-specific checks; phase-4/5 animation, integration and performance gates are
not implied by setup validation.
