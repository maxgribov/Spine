[![Build Status](https://api.travis-ci.org/maxgribov/Spine.svg?branch=master)](https://api.travis-ci.org/maxgribov/Spine.svg?branch=master)

# Spine
Unofficial Spine runtime.

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

**Swift 4.0**
* iOS 8.0+
* macOS 10.10+
* tvOS 9.0+
* watchOS 3.0+

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Spine user guide: http://esotericsoftware.com/spine-user-guide
* Spine JSON format documentation: http://esotericsoftware.com/spine-json-format
