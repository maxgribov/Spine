//
//  SlotModel.swift
//  
//
//  Created by Max Gribov on 05.11.2022.
//

import SpriteKit

///The slots section describes the draw order and the available slots where attachments can be assigned.
struct SlotModel {
    
    ///The slot name. This is unique for the skeleton.
    let name: String
    ///The name of the bone that this slot is attached to.
    let bone: String
    ///The color of the slot for the setup pose. This is an 8 character string containing 4 two digit hex numbers in RGBA order. Assume "FF" for alpha if alpha is omitted. Assume "FFFFFFFF" if omitted.
    let color: ColorModel
    ///The dark color of the slot for the setup pose, used for two color tinting. This is a 6 character string containing 3 two digit hex numbers in RGB order. Omitted when two color tinting is not used.
    let dark: ColorModel?
    ///The name of the slot's attachment for the setup pose. Assume no attachment for the setup pose if omitted.
    let attachment: String?
    ///The type of blending to use when drawing the slot's visible attachment: normal, additive, multiply, or screen.
    let blend: BlendMode?
}

//MARK: - Types

extension SlotModel {
    
    enum BlendMode: String, Decodable {
        
        case normal
        case additive
        case multiply
        case screen
    }
}

//MARK: - Decodable

extension SlotModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case name, bone, color, dark, attachment, blend
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        name = try container.decode(String.self, forKey: .name)
        bone = try container.decode(String.self, forKey: .bone)
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "FFFFFFFF")
        dark = try container.decodeIfPresent(ColorModel.self, forKey: .dark)
        attachment = try container.decodeIfPresent(String.self, forKey: .attachment)
        blend = try container.decodeIfPresent(BlendMode.self, forKey: .blend)
    }
}
