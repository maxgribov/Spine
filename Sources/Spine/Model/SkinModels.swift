//
//  SkinModels.swift
//  Spine
//
//  Created by Max Gribov on 26/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit





//MARK: - Mesh



//MARK: - Linked Mesh



//MARK: - Path



//MARK: - Point



//MARK: - Clipping

struct ClippingAttachmentModel: AttachmentModel {
    
    let name: String
    let actualName: String?
    let end: String
    let vertexCount: UInt
    let vertices: [CGFloat]
    let color: ColorModel
    
    init(_ name: String, _ actualName: String?, _ end: String, _ vertexCount: UInt, _ vertices: [CGFloat], _ color: String?) {
        
        self.name = name
        self.actualName = actualName
        self.end = end
        self.vertexCount = vertexCount
        self.vertices = vertices
        self.color = ColorModel(color ?? "CE3A3AFF")
    }
}

extension ClippingAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name
        case end
        case vertexCount
        case vertices
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let actualName: String? = try container.decodeIfPresent(String.self, forKey: .name)
        let end: String = try container.decode(String.self, forKey: .end)
        let vertexCount: UInt = try container.decode(UInt.self, forKey: .vertexCount)
        let vertices: [CGFloat] = try container.decode([CGFloat].self, forKey: .vertices)
        let color: String? = try container.decodeIfPresent(String.self, forKey: .color)
        
        self.init(name, actualName, end, vertexCount, vertices, color)
    }
}
