//
//  ClippingAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct ClippingAttachmentModel: AttachmentModel {
    
    //TODO: - remove
    let name = ""
    
    let end: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
}

extension ClippingAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, end, vertexCount, vertices, color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        end = try container.decode(String.self, forKey: .end)
        vertexCount = try container.decode(UInt.self, forKey: .vertexCount)
        vertices = try container.decode([CGFloat].self, forKey: .vertices)
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? ColorModel(value: "CE3A3AFF")
    }
}
