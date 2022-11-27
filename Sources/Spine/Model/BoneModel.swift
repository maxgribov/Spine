//
//  BoneModel.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import SpriteKit

///The bones section describes the bones in the setup pose.
struct BoneModel: Identifiable {
    
    /// The bone id.
    var id: String { name }
    ///The bone name. This is unique for the skeleton.
    let name: String
    ///Parent bone. Nil if omitted.
    let parent: String?
    ///The length of the bone. The bone length is not typically used at runtime except to draw debug lines for the bones. Assume 0 if omitted.
    let lenght: CGFloat
    ///Determines how parent bone transforms are inherited: normal, onlyTranslation, noRotationOrReflection, noScale, or noScaleOrReflection. Assume normal if omitted.
    let transform: Transform
    /**
     The position of the bone relative to the parent for the setup pose.
     
     - x: The X position of the bone relative to the parent for the setup pose. Assume 0 if omitted.
     - y: The Y position of the bone relative to the parent for the setup pose. Assume 0 if omitted.
     */
    let position: CGPoint
    ///The rotation in degrees of the bone relative to the parent for the setup pose. Assume 0 if omitted.
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
    ///False if scale from parent bones should not affect this bone. Assume true if omitted.
    let inheritScale: Bool
    ///False if rotation from parent bones should not affect this bone. Assume true if omitted.
    let inheritRotation: Bool
    ///The color of the bone, as it was in Spine. Assume 0x989898FF RGBA if omitted. Nonessential.
    let color: ColorModel
}

//MARK: - Types

extension BoneModel {
    
    enum Transform: String, Decodable {
        
        case normal
        case onlyTranslation
        case noRotationOrReflection
        case noScale
        case noScaleOrReflection
    }
}

//MARK: - Decodable

extension BoneModel: Decodable {

    enum Keys: String, CodingKey {
        case name, parent, length, transform, x, y, rotation
        case scaleX, scaleY, shearX, shearY, inheritScale, inheritRotation, color
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        parent = try container.decodeIfPresent(String.self, forKey: .parent)
        lenght = try container.decodeIfPresent(CGFloat.self, forKey: .length) ?? 0
        transform = try container.decodeIfPresent(Transform.self, forKey: .transform) ?? .normal
        let x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        position = .init(x: x, y: y)
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        let scaleX = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX) ?? 1
        let scaleY = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY) ?? 1
        scale = .init(dx: scaleX, dy: scaleY)
        let shearX = try container.decodeIfPresent(CGFloat.self, forKey: .shearX) ?? 0
        let shearY = try container.decodeIfPresent(CGFloat.self, forKey: .shearY) ?? 0
        shear = .init(dx: shearX, dy: shearY)
        inheritScale = try container.decodeIfPresent(Bool.self, forKey: .inheritScale) ?? true
        inheritRotation = try container.decodeIfPresent(Bool.self, forKey: .inheritRotation) ?? true
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "989898FF")
    }
}

