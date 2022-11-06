//
//  BoundingBoxAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct BoundingBoxAttachmentModel: AttachmentModel {
    
    //TODO: - remove
    let name = ""
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
}

extension BoundingBoxAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, vertexCount, vertices, color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        vertexCount = try container.decode(UInt.self, forKey: .vertexCount)
        vertices = try container.decode([CGFloat].self, forKey: .vertices)
        let colorValue = try container.decodeIfPresent(String.self, forKey: .color) ?? "60F000FF"
        color = ColorModel(colorValue)
    }
}
