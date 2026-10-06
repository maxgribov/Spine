# Mesh animations

Load Spine 4.1 mesh assets explicitly. Existing `Skeleton(json:folder:skin:)`
clients keep the legacy runtime and need no code changes. Both entry points use
the same 4.1 data model; the mesh entry point additionally validates every skin,
attachment and animation before constructing renderer resources.

```swift
let textures = try SpineAtlasTextureProvider(
    atlasText: atlasText,
    pageData: ["characters.png": pngData]
)
let asset = try SpineMeshAsset(json: jsonData, textures: textures)
let character = try Skeleton(meshAsset: asset, skin: "goblin")
addChild(character)
character.run(.repeatForever(try character.action(animation: "walk")), withKey: "walk")
```

Share an asset between characters. Their playback, selected skins and deformation
buffers remain independent. Mesh actions, including copies and actions nested in
sequences, groups or repeats, must run on the Skeleton that created them. Running
them on another node is unsupported. Each Skeleton permits one active mesh clip;
concurrent clips fault that owner and hide its managed visuals. Ordinary SpriteKit
actions still control the Skeleton's external transform.

Call `prepareMeshes(in:)` as the final operation in the scene's `didFinishUpdate`,
after actions, physics, camera movement and manual bone edits:

```swift
override func didFinishUpdate() {
    guard let view = view else { return }
    do {
        try character.prepareMeshes(in: view)
    } catch {
        // Report the typed SpineRuntimeError and fix its context/node contract.
    }
}
```

Preparation never advances animation or delivers events. Repeat it after late
edits, including while paused. For an external render target, supply
`SpineMeshFrameContext` with the complete Skeleton-local to actual fragment-pixel
transform, including the target's Y convention and viewport offset. Pixel size is
the full integral framebuffer size. A finite singular projection temporarily hides
visuals. Invalid contexts hide them until a successful preparation. Crop/effect
ancestors are unsupported.

Before removing or replacing an action container, explicitly stop mesh playback:

```swift
character.stopMeshAnimation(resetToSetupPose: true)
character.removeAction(forKey: "walk")
character.run(.repeatForever(try character.action(animation: "walk")), withKey: "walk")
```

Stopping invalidates every previously obtained mesh action, including unused
copies. Obtain a new action to restart. `resetToSetupPose: false` preserves the
current pose. Skin changes merge the selected skin with the default; deformation
survives only when the attachment's deformation-source identity remains compatible.

Bone nodes accept supported manual TRS/alpha/hidden edits before preparation.
Logical slots must retain their managed identity transform, hierarchy and depth.
Region attachments remain real `SKSpriteNode` instances; mesh attachment lookups
are for inspection. Keep character roots in separate scene depth bands at least
one unit apart when ordering them with environment objects. The library does not
change `ignoresSiblingOrder` or unrelated scene nodes.

The mesh runtime supports region, mesh, linked mesh, point and bounding-box
attachments; normal blend, bone TRS, slot RGB/RGBA/alpha, attachment, deformation,
draw-order and event timelines. Unsupported constraints, transform inheritance,
clipping and blend modes fail with a typed error and source path. The renderer is
available on macOS/iOS; the existing tvOS/watchOS library remains buildable and the
mesh entry point reports `unsupportedPlatform` there. Reverse playback, mixing,
seeking and automatic frame hooks are not provided.

The example's **Prototype / Library** selector retains both original prototype
scenes. **Tab** changes scene and **L** changes renderer. Library controls expose
pause, transparency, reflection and reset; the environment also exposes camera
motion and zoom.

Library-owned static bounding-box slots support bounded reconciliation in the
final preparation step. The body remains attached
to the same slot; legacy characters are unaffected. Position/rotation residuals
must satisfy both a fixed world-precision rule and local safety caps before being
restored to identity. Small edits within that precision cannot be distinguished
from solver residue. Unowned/dynamic bodies, hierarchy/scale/depth changes and
out-of-budget values are not silently corrected. No animation time, bone pose or
previously delivered contact is replayed. Invalid contexts and unsupported body
edits remain explicit errors; singular frames temporarily hide visuals.
