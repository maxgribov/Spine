//
//  PathAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct PathAttachmentModel: AttachmentModel {
    
    //TODO: - remove
    let name = ""
    
    let closed: Bool
    let constantSpeed: Bool
    let lengths: [CGFloat]
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
}

extension PathAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, closed, constantSpeed, lengths, vertexCount, vertices, color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        closed = try container.decodeIfPresent(Bool.self, forKey: .closed) ?? false
        constantSpeed = try container.decodeIfPresent(Bool.self, forKey: .constantSpeed) ?? true
        lengths = try container.decode([CGFloat].self, forKey: .lengths)
        vertexCount = try container.decode(UInt.self, forKey: .vertexCount)
        vertices = try container.decode([CGFloat].self, forKey: .vertices)
        let colorValue = try container.decodeIfPresent(String.self, forKey: .color) ?? "FF7F00FF"
        color = ColorModel(colorValue)
    }
}
