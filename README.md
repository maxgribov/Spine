[![Build Status](https://api.travis-ci.org/maxgribov/Spine.svg?branch=master)](https://api.travis-ci.org/maxgribov/Spine.svg?branch=master)
[![Pod Version](https://img.shields.io/cocoapods/v/Spine.svg?style=flat)](https://cocoapods.org/pods/Spine)

# Spine
This Swift library allows you to upload characters and their animations from the [Spine app](http://esotericsoftware.com) to SpriteKit for platforms:

`iOS` `macOS` `tvOS` `watchOS`

Implemented almost all the functionality of the essential version of Spine app:
Animation of bones, skins, animation of slots, creation of physical bodies on the basis of bounding boxes and some other. See [Implemented Features](#implemented-features) for more information.

Example of working with the library: [Sample project](https://github.com/maxgribov/SpineSampleProject)<BR>
Learn more about working with the library: [Spine Wiki](https://github.com/maxgribov/Spine/wiki)

![Hero](images/spine_readme_hero.png)

## Installing

### CocoaPods
Add the pod to your podfile
```
pod 'Spine'
```
run
```
pod install
```

## Basic Usage

### Assets

#### Files

1. In `assets` catalog create `folder`. *(`Goblins` folder in example below)*
2. Create `sprite atlases`. *(`default`, `goblin` and `goblingirl` sprite atlases in example below)*
3. Put images into sprite atlaces. 
>Note that the images that are in the `root` folder of the Spine app project must be in the sprite atlas named `default` in the Xcode project.

Final result should looks something like this:

![Assets](images/spine_readme_assets.png)

#### Namespace

Set `Provides Namespace` option enabled for the root folder and for all sprite atlases in the Xcode's attribute inspector:

![Namespace](images/spine_readme_assets_namespace.png)

>If you forget to set the namespace, later when you initialize your character images can be just not found.

#### JSON

Put the JSON exported from the Spine application somewhere in your project:

![json](images/spine_readme_assets_json.png)

For more information about assets see [Assets Wiki](https://github.com/maxgribov/Spine/wiki/Assets)

### Code

Somewhere at the beginning of your code, import the `Spine` library:

```swift
import Spine
```

The easiest way to load a character from a JSON file and apply skin to it is to use the appropriate `Skeleton` class constructor:

```swift
if let character = Skeleton(fromJSON: "goblins-ess", atlas: "Goblins", skin: "goblin") {

   //Do something with your character here
}
```
>[Skeleton](Spine/Skeleton.swift) is a subclass of `SKNode`, so you can do with it whatever you can do with `SKNode` itself

This way you can apply the animation created in Spine to the character:

```swift
if let walkAnimation = character.animation(named: "walk") {

    character.run(walkAnimation)
}
```
>The `animation(named:)` method returns an object of the `SKAction` class so that you can use this animation as any other object of the `SKAction` class

This is an example of the simplest scene in which we load our Goblin character, add it to the scene and start walk animation in an endless loop:
```swift
import SpriteKit
import Spine

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        
        if let character = Skeleton(fromJSON: "goblins-ess", atlas: "Goblins", skin: "goblin"){
            
            character.name = "goblin"
            character.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 2))
            
            self.addChild(character)

            if let walkAnimation = character.animation(named: "walk") {
                
                character.run(SKAction.repeatForever(walkAnimation))
            }
        }
    }
}
```

## Implemented Features

| Name | Model | Feature | Animation |
| --- | :---: | :---: | :---: |
| **Bones** |  |  |  |
| - Rotation | + | + | + |
| - Translation | + | + | + |
| - Scale | + | + | + |
| - Shear | + | - | - |
| *Bones extras:* |  |  |  |
| - Reflect | + | - | |
| - Rotation Inheritance | + | - | |
| - Scale Inheritance | + | - | |
| - Reflect Inheritance | + | - | |
| **Slots** |  |  |  |
| - Attachment | + | + | + |
| - Tint Color | + | + | +/- |
| - Dark Tint Color | + | - |  |
| **Skins** | + | + |  |
| **Attachments** |  |  |  |
| - Region | + | + |  |
| - Mesh | + | - | - |
| - Linked Mesh | + | - | - |
| - Bounding Box | + | + | - |
| - Path | + | - | - |
| - Point | + | + |  |
| - Clipping | + | - | - |
| **Constraints** |  |  |  |
| - IK Constraint | + | - | - |
| - Transform Constraint | + | - | - |
| - Path Constraint | + | - | - |
| **Events** | + | + | + |
| **Draw Order** | + | + | + |

## System Requirements

**Swift 5.0**
* iOS 8.0+
* macOS 10.10+
* tvOS 9.0+
* watchOS 3.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Useful links

* Spine user guide: http://esotericsoftware.com/spine-user-guide
* Spine JSON format documentation: http://esotericsoftware.com/spine-json-format
* Spine oficial runtimes: https://github.com/EsotericSoftware/spine-runtimes
