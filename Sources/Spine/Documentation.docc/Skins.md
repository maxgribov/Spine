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


