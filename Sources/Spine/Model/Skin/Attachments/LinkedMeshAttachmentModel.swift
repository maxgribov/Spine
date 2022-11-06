//
//  LinkedMeshAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct LinkedMeshAttachmentModel: AttachmentModel {
    
    let name: String
    let path: String?
    let skin: String
    let parent: String
    let deform: Bool
    let color: ColorModel
    let width: CGFloat?
    let height: CGFloat?
}

extension LinkedMeshAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, path, skin, parent, deform, color, width, height
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? name
        path = try container.decodeIfPresent(String.self, forKey: .path)
        skin = try container.decodeIfPresent(String.self, forKey: .skin) ?? "default"
        parent = try container.decode(String.self, forKey: .parent)
        deform = try container.decodeIfPresent(Bool.self, forKey: .deform) ?? true
        let colorValue = try container.decodeIfPresent(String.self, forKey: .color) ?? "FFFFFFFF"
        color = ColorModel(colorValue)
        width = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        height = try container.decodeIfPresent(CGFloat.self, forKey: .height)
    }
}