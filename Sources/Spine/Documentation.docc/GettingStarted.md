# Getting Started

Basic information on working with the library.

## Overview

In this article, we will look at the main way to load character data exported from Spinne App in the form of json and a set of images, placing them in an Xcode project and creating a character in a SpriteKit scene.

### Assets

1. In `Assets` catalog create `folder`. *(`Goblins` folder in example below)*
2. Create `sprite atlases`. *(`default`, `goblin` and `goblingirl` sprite atlases in example below)*
3. Put images into sprite atlaces. 
>Note: Note that the images that are in the `root` folder of the Spine app project must be in the sprite atlas named `default` in the Xcode project.

Final result should looks something like this:

![Assets](spine_readme_assets.png)

### Namespace

Set `Provides Namespace` option enabled for the root folder and for all sprite atlases in the Xcode's attribute inspector:

![Namespace](spine_readme_assets_namespace.png)

>If you forget to set the namespace, later when you initialize your character images can be just not found.

### JSON

Put the JSON exported from the Spine application somewhere in your project:

![json](spine_readme_assets_json.png)

For more information about assets see <doc:AssetsBundle>

### Code

Somewhere at the beginning of your code, import the `Spine` library:

```swift
import Spine
```

The easiest way to load a character from a `JSON` file and apply skin to it is to use the appropriate `Skeleton` class init:

```swift
let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
```
>Tip: ``Skeleton`` is a subclass of `SKNode`, so you can do with it whatever you can do with `SKNode` itself

This way you can apply the animation created in Spine to the character:

```swift
let walkAnimation = try character.action(animation: "walk")
character.run(walkAnimation)
```
>The ``Skeleton/action(animation:)`` method returns an object of the `SKAction` class so that you can use this animation as any other object of the `SKAction` class

This is an example of the simplest scene in which we load our Goblin character, add it to the scene and start walk animation in an endless loop:
```swift
import SpriteKit
import Spine

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        
        do {
            
            let character = try Skeleton(json: "goblins-ess", folder: "goblins", skin: "goblin")
            character.name = "character"
            character.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 2) - 200)
            addChild(character)
            
            let walkAnimation = try character.action(animation: "walk")
            character.run(.repeatForever(walkAnimation))

        } catch {
            
            print(error)
        }
    }
}
```
