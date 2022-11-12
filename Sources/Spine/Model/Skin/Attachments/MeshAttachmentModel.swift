//
//  MeshAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct MeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let uvs: [CGFloat]
    let triangles: [UInt]
    let vertices: [CGFloat]
    let hull: UInt
    let edges: [UInt]?
    let color: ColorModel
    let width: CGFloat?
    let height: CGFloat?
}

extension MeshAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, path, uvs, triangles, vertices, hull, edges
        case color, width, height
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? name
        path = try container.decodeIfPresent(String.self, forKey: .path)
        uvs = try container.decode([CGFloat].self, forKey: .uvs)
        triangles = try container.decode([UInt].self, forKey: .triangles)
        vertices = try container.decode([CGFloat].self, forKey: .vertices)
        hull = try container.decode(UInt.self, forKey: .hull)
        edges = try container.decodeIfPresent([UInt].self, forKey: .edges)
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "FFFFFFFF")
        width = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        height = try container.decodeIfPresent(CGFloat.self, forKey: .height)
    }
}
