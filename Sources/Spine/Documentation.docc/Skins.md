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
