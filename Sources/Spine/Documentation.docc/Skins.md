# Skins

Working with character skins. Enabling the desired skin, switching between different skins on the fly, and more.

## Overview
In the Spine application project, it is possible to create multiple skins for a single character. Each skin can have its own image for one or more slots (for example, male and female skin of a character whose images of all body parts are replaced).

On the project side, skin images are grouped into folders:

![](spine_wiki_assets_spine_multiple.png)

>Tip: How to upload images to the project bundle correctly can be read here: <doc:AssetsBundle> 

### Installing skins during character initialization

When creating a character skeleton from a json file, you can immediately install the required skin by specifying its name in the initializer:

```swift
let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
```
- ``Skeleton/init(json:folder:skin:)``

>The default skin will be installed in any case, whether you specified the name of the skin during initialization or not.

If you use other initializers, then you are responsible for setting the skin (including the default one) after initializing the skeleton.
```swift
let character = try Skeleton(model, atlases)
try character.applyDefaultSkin()
try character.apply(skin: "goblin")
```
- ``Skeleton/init(_:atlas:)``
- ``Skeleton/init(_:_:)``

### Switching skins

At any time when required, you can switch the skin:

```swift
try character.apply(skin: "goblingirl")
...
try character.apply(skin: "goblin")
```
- ``Skeleton/apply(skin:)``

You can also create a SKAction that switches the skin and run it on the character along with other actions:

```swift
let switchSkinsAction = SKAction.sequence([.wait(forDuration: 3),
                                           try character.action(applySkin: "goblingirl"),
                                           .wait(forDuration: 3),
                                           try character.action(applySkin: "goblin")])

character.run(.repeatForever(switchSkinsAction))
```
- ``Skeleton/action(applySkin:)``

## Advanced Techniques

### Replacing region attachment texture

There are usually enough features that Pine provides in order to manipulate images of parts of your character using skins and attachments that you configure in the Spine App project.

However, in some cases, more subtle control over the images is required. For example, you have a character who wears armor and you want to replace images of different parts of the armor depending on what the user has chosen.

In this case, you will need to:
- prepare in advance all possible armor options for each slot (helmet, breastplate, etc.)
- download these images in a convenient way for you to the project (application bundle, download from a remote server, etc.)
- prepare textures (`SKTexture`) based on images and assemble them into atlases (`SKTextureAtlas`)  (Recommended but not required. atlases are very useful in optimizing the work with images in SpriteKit.)
- at the right moment, replace the textures in the corresponding region attachments with your own

>Note: How to upload images, create textures based on them and assemble them into texture atlases is beyond the scope of this discussion, you will have to study this issue yourself using the documentation on SpriteKit and other Apple frameworks.

First of all, we have to create a texture. The easiest way to create it to use image stored in the application bundle:

```swift 
let epicHelmetTexture = SKTexture(imageNamed: "Epic Helmet")
```

Next, we need to find the right attachment region. To do this, we can print information about the names of the child nodes of the character's skeleton:

```swift
print(warriorCharacter.childrenTreeInfo)
```

As a result, something like this will be printed in the console:

```console
Skeleton warrior children tree:
bone:root
-bone:hip
--bone:torso
---bone:neck
----bone:head
-----slot:head
------attachment:head
-----slot:helmet
------attachment:basic-helmet <<<< looking for
...
```

In this case, we are interested in an attachment called `basic-helmet`. The easiest way to replace its texture:

```swift 
try character.apply(texture: epicHelmetTexture, region: "basic-helmet")
```

Let's put all together:

```swift 
do {
    
    let character = try Skeleton(json: "warriors-ess", folder: "warriors", skin: "warrior-soldier")
    character.name = "warrior"
    
    let epicHelmetTexture = SKTexture(imageNamed: "Epic Helmet")
    try character.apply(texture: epicHelmetTexture, region: "basic-helmet")
    
    ...
    
} catch {
    
    print(error)
}
```
An alternative way is to get the `SKSpriteNode` for the desired region attachment and directly install the texture into it:

```swift
do {
    
    let character = try Skeleton(json: "warriors-ess", folder: "warriors", skin: "warrior-soldier")
    character.name = "warrior"
    
    let epicHelmetTexture = SKTexture(imageNamed: "Epic Helmet")
    character.regionAttachmentNode(named: "basic-helmet")?.texture = epicHelmetTexture
    
    
} catch {
    
    print(error)
}
```

>Warning: The dimensions and position of the image are determined by the `SKSpriteNode` itself. By applying a new texture, you may find that it does not display exactly as you expected.

>Warning: If you apply animations that switch the visibility of the character's skeleton attachments or apply skins, then what is displayed on the character may change.

## Composition on compiled assets

A composition describes the whole outfit over one fixed base skin. The base resolves
`default` first, then its own entries. Layers run in order:

- `overlay` adds the skin's own placeholders and overrides matching keys.
- `replace` removes all earlier entries in selected slots and installs the skin's own entries.
- `hide` removes entire slots. A later overlay restores only its own keys.

Only regions can be introduced. A slot containing any non-region state in the resolved
base is protected, including currently invisible states. Keep points, hitboxes and
mesh attachments in separate slots from interchangeable clothing.

### Validate a catalog

Create a `SpineMeshAsset` once with its JSON and texture provider, then validate each
item without constructing a Skeleton:

```swift
import Spine

func validateHat(asset: SpineMeshAsset) throws {
    let item = SpineSkinComposition(baseSkin: "base", layers: [
        .replace(skin: "hat/a", slots: ["hat-front", "hat-back"]),
        .hide(slots: ["bandana"])
    ])
    try asset.validate(skinComposition: item)
    let description = try asset.skinDescription(named: "hat/a")
    let actualSlots = Set(description.entries.map { $0.slot })
    precondition(actualSlots == Set(["hat-front", "hat-back"]))
    precondition(description.entries.allSatisfy { $0.kind == .region })
}
```

Every replacement must cover all non-nil setup and attachment-timeline names in all
compiled clips. Revalidate the catalog against each newly exported asset: adding a
rare clip can invalidate an older item. Validation throws the first `SpineRuntimeError`
with a stable code and JSON Pointer path. Later layers cannot repair an incomplete
replacement. Nil states never require an image.

`skinDescription(named:)` reports only own entries, in setup-slot and placeholder-name
order, without `default` fallback. `linkedMesh` remains distinct from `mesh`. Names are
logical placeholders, not texture paths. Neither inspection nor validation creates
scene nodes or requests textures again. Serialize access to the asset; validation does
not preflight a live scene or its render context.

The game must additionally compare these slots with its catalog, include explicit
hide areas, and reject forbidden overlaps. Intentional overlaps are legal for the
library. Per-item completeness does not establish combination compatibility. The
public-client test in `Tests/SpineTests/Skins/CompositionPublicAPITests.swift` demonstrates
area checks, conflict rejection and all 32 fixture outfits using only `import Spine`.

### Apply and restore an outfit

Create the Skeleton with the descriptor's fixed base. Pass the entire next outfit
on every change; removing a hide restores the current animation request, not setup.
A nil animation request remains invisible.

```swift
let character = try Skeleton(meshAsset: asset, skin: "base")
let clothes = SpineSkinLayer.replace(skin: "clothes/a", slots: ["torso", "sleeves"])
let hat = SpineSkinLayer.replace(skin: "hat/a", slots: ["hat-front", "hat-back"])
let team = SpineSkinLayer.overlay(skin: "team/blue")
let look = SpineSkinComposition(baseSkin: "base", layers: [
    clothes, hat, .hide(slots: ["bandana", "earring"]), team
])
try character.apply(skinComposition: look)
let saved = character.skinComposition
try character.apply(skinComposition: .init(baseSkin: "base", layers: [
    clothes, .replace(skin: "hat/b", slots: ["hat-front", "hat-back"]),
    .hide(slots: ["bandana"]), team
])) // restore the earring without resetting animation
if let saved = saved { try character.apply(skinComposition: saved) }
try character.apply(skinComposition: .init(baseSkin: "base", layers: []))
try character.apply(skin: "base") // leave composition, including when the base is unchanged
```

An empty layer list keeps composition active and resolves the base at current
requests. A successful single-skin API or skin action exits composition, using its
existing current-attachment/setup fallback. `skinComposition` is then nil.
A different descriptor base fails with `skinCompositionBaseMismatch`; explicitly
switch the single skin before entering composition on a new base. Legacy Skeletons
reject composition with `unsupportedFeature`.

### Playback, callbacks and frame preparation

Applying an outfit preserves the current pose, clock, event cursors, action ownership,
color, draw order, speed and pause. Begin, repeats and setup reset retain the outfit
while resetting animation state. `stopMeshAnimation(resetToSetupPose: false)` freezes
the current request and appearance; `true` retains the outfit and resolves setup
through it. As before, stopping invalidates previously created animation actions;
request a new action for a restart. Removing an action early still requires stop.

Calls must be serialized with SpriteKit updates. You may change outfits outside
updates during a serialized pause, or directly inside a Spine event callback.
Several changes within a callback are allowed: the last successful change is visible
to following callbacks. Content errors throw synchronously and keep the previous
outfit; catch them inside the callback. Events with equal timestamps retain their
source order and are delivered once per execution. Composition itself does not restart
playback or clear frame/playback errors. Stop/restart from a callback retains the
existing epoch guards against stale work.

Do not call composition concurrently, during renderer preparation or from physics
callbacks. Asset inspection/validation also requires serialized access; these APIs
do not add background work or thread-safety guarantees.

Finish each frame with the existing `prepareMeshes` call after actions, physics and
manual changes (normally in `didFinishUpdate`). This is required on pause too. A late
outfit change after prepare requires another prepare before drawing. Logical application
is atomic; the new rendered image is guaranteed after successful prepare. Render-context
errors are separate frame failures and do not roll back an accepted outfit.

Affected region nodes may be replaced. Reacquire their references after applying an
outfit; an externally retained old node is detached and no longer managed. Untouched
records, including mixed mesh/point/body slots, keep identity and physics ownership.
An exactly equal descriptor is a no-op. The asset and textures can be shared across
Skeletons; appearance and playback state belong to each instance.

### Run the standalone public client

The repository's `Examples/SkinComposition/README.md` provides native macOS and iOS
build/run commands. The example imports only public API, displays two independent
Skeletons sharing one asset, and exposes clothing, team, pause, speed, repeat, reset
and event-driven changes. Its catalog check runs all 32 fixture outfits and rejects
forbidden catalog overlaps independently of the library's ordered layer policy.
The optional diagnostic collector exports raw apply/prepare samples with source
hashes. Release budgets and physical-device image/memory validation remain separate
requirements; successful builds or diagnostic samples do not satisfy them.
