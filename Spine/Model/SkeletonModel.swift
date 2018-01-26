//
//  SkeletonModel.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

/// The skeleton section stores metadata about the skeleton.
struct SkeletonModel {

    /// A hash of all the skeleton data. This can be used by tools to detect if the data has changed since the last time it was loaded.
    let hash: String
    /// The version of Spine that exported the data. This can be used by tools to enforce a particular Spine version to be used.
    let spine: String
    /**
     The AABB size for the skeleton's attachments as it was in the setup pose in Spine
     
     - width: The AABB width for the skeleton's attachments as it was in the setup pose in Spine. This can be used as a general size of the skeleton, though the skeleton's AABB depends on how it is posed.
     - height: The AABB height for the skeleton's attachments as it was in the setup pose in Spine.
     */
    let size: CGSize
    /// The dopesheet framerate in frames per second, as it was in Spine. Assume 30 if omitted. Nonessential.
    let fps: CGFloat
    
    ///The images path, as it was in Spine. Nonessential.
    let path: String?

    /**
     Initializes a new skeleton.
     
     - Parameters:
        - hash: Required
        - spine: Required
        - width: Required
        - height: Required
        - fps: Optional, default: 30.0
        - path: Optional
     
     - Returns: new skeleton.
     */
    init(_ hash: String, _ spine: String, _ width: CGFloat, _ height: CGFloat, _ fps: CGFloat?, _ path: String?) {
        
        self.hash = hash
        self.spine = spine
        self.size = CGSize(width: width, height: height)
        if let fps = fps { self.fps = fps } else { self.fps = 30 }
        self.path = path
    }
}

extension SkeletonModel: Decodable {
    
    enum SkeletonKeys: String, CodingKey {
        
        case hash
        case spine
        case width
        case height
        case fps
        case path = "images"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: SkeletonKeys.self)
        let hash: String = try container.decode(String.self, forKey: .hash)
        let spine: String = try container.decode(String.self, forKey: .spine)
        let width: CGFloat = try container.decode(CGFloat.self, forKey: .width)
        let height: CGFloat = try container.decode(CGFloat.self, forKey: .height)
        let fps: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .fps)
        let path: String? = try container.decodeIfPresent(String.self, forKey: .path)
        
        self.init(hash, spine, width, height, fps, path)
    }
}

//MARK: - Bone

/// The bones section describes the bones in the setup pose.
struct BoneModel {
    
    /// The bone name. This is unique for the skeleton.
    let name: String
    /// Parent bone. Nil if omitted.
    let parent: String?
    /// The length of the bone. The bone length is not typically used at runtime except to draw debug lines for the bones. Assume 0 if omitted.
    let lenght: CGFloat
    /// Determines how parent bone transforms are inherited: normal, onlyTranslation, noRotationOrReflection, noScale, or noScaleOrReflection. Assume normal if omitted.
    let transform: BoneTransformModelType
    /**
     The position of the bone relative to the parent for the setup pose.
     
     - x: The X position of the bone relative to the parent for the setup pose. Assume 0 if omitted.
     - y: The Y position of the bone relative to the parent for the setup pose. Assume 0 if omitted.
     */
    let position: CGPoint
    /// The rotation in degrees of the bone relative to the parent for the setup pose. Assume 0 if omitted.
    let rotation: CGFloat
    /**
     The scale of the bone for the setup pose.
     
     - dx: The X scale of the bone for the setup pose. Assume 1 if omitted.
     - dy: The Y scale of the bone for the setup pose. Assume 1 if omitted.
     */
    let scale: CGVector
    /**
     The shear of the bone for the setup pose.
     
     - dx: The X shear of the bone for the setup pose. Assume 0 if omitted.
     - dy: The Y shear of the bone for the setup pose. Assume 0 if omitted.
     */
    let shear: CGVector
    /// False if scale from parent bones should not affect this bone. Assume true if omitted.
    let inheritScale: Bool
    /// False if rotation from parent bones should not affect this bone. Assume true if omitted.
    let inheritRotation: Bool
    
    /**
     Initializes a new bone.
     
     - Parameters:
         - name: Required
         - parent: Optional
         - lenght: Optional, default: 0
         - transform: Optional, default: .normal
         - x: Optional, default: 0
         - y: Optional, default: 0
         - rotation: Optional, default: 0
         - scaleX: Optional, default: 1.0
         - scaleY: Optional, default: 1.0
         - shearX: Optional, default: 0
         - shearY: Optional, default: 0
         - inheritScale: Optional, default: true
         - inheritRotation: Optional, default: true

     - Returns: new bone.
     */
    init(_ name: String, _ parent: String?, _ lenght: CGFloat?, _ transform: Int?, _ x: CGFloat?, _ y: CGFloat?, _ rotation: CGFloat?, _ scaleX: CGFloat?, _ scaleY: CGFloat?, _ shearX: CGFloat?, _ shearY: CGFloat?, _ inheritScale: Bool?, _ inheritRotation: Bool?) {
        
        self.name = name
        self.parent = parent
        if let lenght = lenght { self.lenght = lenght } else { self.lenght = 0 }
        if let transform = transform { self.transform = BoneTransformModelType(transform) } else { self.transform = .normal }
        if let x = x, let y = y { self.position = CGPoint(x: x, y: y) } else { self.position = CGPoint.zero }
        if let rotation = rotation { self.rotation = rotation } else { self.rotation = 0 }
        if let scaleX = scaleX, let scaleY = scaleY { self.scale = CGVector(dx: scaleX, dy: scaleY) } else { self.scale = CGVector(dx: 1.0, dy: 1.0)}
        if let shearX = shearX, let shearY = shearY { self.shear = CGVector(dx: shearX, dy: shearY) } else { self.shear = CGVector.zero }
        if let inheritScale = inheritScale { self.inheritScale = inheritScale } else { self.inheritScale = true }
        if let inheritRotation = inheritRotation { self.inheritRotation = inheritRotation } else { self.inheritRotation = true }
    }
    
    enum BoneTransformModelType: Int {
        
        case normal = 0
        case onlyTranslation
        case noRotationOrReflection
        case noScale
        case noScaleOrReflection
        
        init(_ transform: Int ) {
            
            if let transform = BoneTransformModelType(rawValue: transform) {
                
                self = transform
                
            } else {
                
                self = .normal
            }
        }
    }
}

extension BoneModel: Decodable {

    enum BoneKeys: String, CodingKey {
        case name
        case parent
        case length
        case transform
        case x
        case y
        case rotation
        case scaleX
        case scaleY
        case shearX
        case shearY
        case inheritScale
        case inheritRotation
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: BoneKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let parent: String? = try container.decodeIfPresent(String.self, forKey: .parent)
        let lenght: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .length)
        let transform: Int? = try container.decodeIfPresent(Int.self, forKey: .transform)
        let x: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .x)
        let y: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .y)
        let rotation: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .rotation)
        let scaleX: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX)
        let scaleY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY)
        let shearX: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearX)
        let shearY: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .shearY)
        let inheritScale: Bool? = try container.decodeIfPresent(Bool.self, forKey: .inheritScale)
        let inheritRotation: Bool? = try container.decodeIfPresent(Bool.self, forKey: .inheritRotation)
        
        self.init(name, parent, lenght, transform, x, y, rotation, scaleX, scaleY, shearX, shearY, inheritScale, inheritRotation)
    }
}

//MARK: - Slot

/// The slots section describes the draw order and the available slots where attachments can be assigned.
struct SlotModel {
    
    /// The slot name. This is unique for the skeleton.
    let name: String
    /// The name of the bone that this slot is attached to.
    let bone: String
    /// The color of the slot for the setup pose. This is an 8 character string containing 4 two digit hex numbers in RGBA order. Assume "FF" for alpha if alpha is omitted. Assume "FFFFFFFF" if omitted.
    let color: ColorModel
    /// The dark color of the slot for the setup pose, used for two color tinting. This is a 6 character string containing 3 two digit hex numbers in RGB order. Omitted when two color tinting is not used.
    let dark: ColorModel?
    /// The name of the slot's attachment for the setup pose. Assume no attachment for the setup pose if omitted.
    let attachment: String?
    /// The type of blending to use when drawing the slot's visible attachment: normal, additive, multiply, or screen.
    let blend: BlendModeModelType
    
    /**
     Initializes a new slot.
     
     - Parameters:
         - name: Required
         - bone: Required
         - color: Optional, default: FFFFFFFF
         - dark: Optional
         - attachment: Optional
         - blend: Optional, default: .normal
     
     - Returns: new slot.
     */
    init(_ name: String, _ bone: String, _ color: String?, _ dark: String?, _ attachment: String?, _ blend: Int?) {
        
        self.name = name
        self.bone = bone
        if let color = color { self.color = ColorModel(color) } else { self.color = ColorModel("FFFFFFFF") }
        self.dark = ColorModel(dark)
        self.attachment = attachment
        if let blend = blend { self.blend = BlendModeModelType(blend) } else { self.blend = .normal }
    }
    
    enum BlendModeModelType: Int {
        
        case normal = 0
        case additive
        case multiply
        case screen
        
        init(_ blend: Int) {
            
            if let blend = BlendModeModelType(rawValue: blend) {
                
                self = blend
                
            } else {
                
                self = .normal
            }
        }
    }
}

extension SlotModel: Decodable {
    
    enum SlotKeys: String, CodingKey {
        
        case name
        case bone
        case color
        case dark
        case attachment
        case blend
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: SlotKeys.self)
        let name: String = try container.decode(String.self, forKey: .name)
        let bone: String = try container.decode(String.self, forKey: .bone)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        let dark: String? = try container.decodeIfPresent(String.self, forKey: .dark)
        let attachment: String? = try container.decodeIfPresent(String.self, forKey: .attachment)
        let blend: Int? = try container.decodeIfPresent(Int.self, forKey: .blend)
        
        self.init(name, bone, color, dark, attachment, blend)
    }
}
