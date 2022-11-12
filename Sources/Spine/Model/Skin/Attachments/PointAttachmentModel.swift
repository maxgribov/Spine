//
//  PointAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct PointAttachmentModel: AttachmentModel {

    //TODO: - remove
    let name = ""

    let position: CGPoint
    let rotation: CGFloat
    let color: ColorModel
}

extension PointAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, x, y, rotation, color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        position = .init(x: x, y: y)
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "F1F100FF")
    }
}
