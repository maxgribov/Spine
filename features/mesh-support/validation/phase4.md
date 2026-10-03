# Phase 4 — animation and scene integration

Implementation iteration 1 against unchanged spec v5, based on `ce517e9`.
Independent code/architecture reviews are recorded by the orchestrator; this
report records implementation evidence, not their approval.

The asset compiler now produces immutable bone/color/attachment/deform/draw-order
and event clips from the shared 4.1 model. Existing owner-bound SKActions remain
the only animation clock. Slot state owns active attachment, tint and deformation;
skin changes stage their next state and visuals before replacing live nodes.
Direct linked-mesh deformation identity remains distinct from shared geometry.
Points, bounding boxes and bounded slot depth follow the active state. No decoder
fork, new public clock, automatic scene hook or phase 5 redesign was introduced.

Both original prototype scenes remain cached and selectable. The additional
Library scenes use the public production asset/Skeleton/actions/preparation API.
The second selector and L change renderer; the original selector and Tab change
scene. Programmatic keyboard smoke preserved all four scene instances and their
paused state. Saved Library images were directly inspected: both complete
characters, readable controls, tree/fence/foreground composition and intended
occlusion. These are native action/Metal readback checks, not an interactive
`macos-use` session.

Evidence is summarized in [phase4-checks.json](phase4-checks.json), with exact
[source hashes](phase4-source-sha256.json), the complete
[timestamp grid](phase4-animation-grid.json), [oracle summary](phase4-oracle.json),
[setup GPU checks](phase4-gpu.json) and [scene comparisons](phase4-scenes.json).
The grid contains 223 real-SKAction snapshots across Goblins, weighted-link,
deform-resources and the additional authored slot-transition fixture. It covers
all keys/midpoints and discrete/stepped boundaries ±1e-5. Pinned external
`spine-core@4.1.56` matches positions within 0.0000577 and UVs within 5.97e-8;
active attachments, draw order and direct deformation-source identities match.
No official runtime code was copied into the library.

The root suite passes 128 tests; prototype suite passes 10. Legacy characterization
retains all 70 images exactly (RGBA maximum 0), state/events within 1e-6. Existing
prototype GPU and environment regressions pass with only their already-documented
allowances. The nine production setup comparisons remain strict ≤2/255; eight
production environment comparisons have maxima [1,3,1,1,1,2,3,1], two channels
above 2 and none above 3. Tests cover 12/16-number per-channel RGB/RGBA Beziers,
atomic skins, active point/physics transitions, 100 skin changes, mixed legacy/new
characters without legacy preparation, and unchanged foreign nodes/order settings.
All four minimum-platform builds and the Release example pass.

Native context validation warms an actual SKView, then checks corners and pixel
centers after paused bone/root/ancestor/camera edits across aspectFit, aspectFill
and resizeFill. Strict custom offset/Y pixel validation crops a normal SKNode
subtree. Two exploratory hard-edged silhouette captures differed by one pixel
(maximum 39/255), so they are explicitly **not passing image acceptance evidence**.
The strict camera gate is the independent retained-prototype textured world
comparison. SKScene capture rescales the scene to its render target, so using it
as a cropped-subtree viewport test produced misleading projection differences;
production projection code was not changed to fit that harness.

A real static SpriteKit physics body can leave approximately 1.19e-7 radians of
slot rotation under a rotating bone. Validation accepts only a small Float-ULP
residue on the library-owned static body's slot (including residue after removal),
never writes the physics transform, and still rejects deliberate 0.001 rotation.
A watchOS build exposed unavailable `SKScene.filter`; that access is conditionally
compiled while the mesh entry point keeps its unsupported-platform error.

Phase 3 physical-device captures and hashes remain historical. No phase 4 physical
iOS execution or phase 5 performance result is claimed. Reproduction commands are
in [swift-health-check.md](swift-health-check.md) and the example README. Local
readback PNGs/logs are under `/tmp/spine-phase4-mesh-final`; the CLI regenerates them
from a clean checkout with the pinned external oracle installed separately.

The final testing stage added a public-JSON regression for an event callback that
resets playback and changes skin. The fresh 128-test run passes; only that test
file changed, and production/resource hashes still match the GPU/oracle runs.
See [phase4-health.json](phase4-health.json) for final run provenance.
