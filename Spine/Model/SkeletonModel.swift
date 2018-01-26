//
//  SkeletonModel.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

struct SkeletonModel {

    let hash: String
    let spine: String
    let size: CGSize
    let fps: CGFloat
    let path: String?

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

struct BoneModel {
    
    let name: String
    let parent: String?
    let lenght: CGFloat
    let transform: BoneTransformModelType
    let position: CGPoint
    let rotation: CGFloat
    let scale: CGVector
    let shear: CGVector
    let inheritScale: Bool
    let inheritRotation: Bool
    
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

struct SlotModel {
    
    let name: String
    let bone: String
    let color: ColorModel
    let dark: ColorModel?
    let attachment: String?
    let blend: BlendModeModelType
    
    init(_ name: String, _ bone: String, _ color: String?, _ dark: String?, _ attachment: String?, _ blend: Int?) {
        
        self.name = name
        self.bone = bone
        if let color = color { self.color = ColorModel(color) } else { self.color = ColorModel("FFFFFFFF") }
        self.dark = ColorModel(dark)
        self.attachment = attachment
        if let blend = blend { self.blend = BlendModeModelType(blend) } else { self.blend = .normal }
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
