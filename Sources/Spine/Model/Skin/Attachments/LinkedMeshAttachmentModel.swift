//
//  LinkedMeshAttachmentModel.swift
//  
//
//  Created by Max Gribov on 07.11.2022.
//

import SpriteKit

struct LinkedMeshAttachmentModel: AttachmentTexturedModel {
    
    let name: String
    let fileName: String?
    let path: String?
    let skin: String
    let parent: String
    let deform: Bool
    let timelines: Bool
    let meshDecodeError: Error?
    let color: ColorModel
    let width: CGFloat?
    let height: CGFloat?
}

extension LinkedMeshAttachmentModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case name, path, skin, parent, deform, timelines, color, width, height
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        self.name = name
        fileName = try container.decodeIfPresent(String.self, forKey: .name)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        skin = try container.decodeIfPresent(String.self, forKey: .skin) ?? "default"
        parent = try container.decode(String.self, forKey: .parent)
        deform = try container.decodeIfPresent(Bool.self, forKey: .deform) ?? true
        do {
            timelines = try container.decodeIfPresent(Bool.self, forKey: .timelines) ?? true
            meshDecodeError = nil
        } catch {
            timelines = true; meshDecodeError = error
        }
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "FFFFFFFF")
        width = try container.decodeIfPresent(CGFloat.self, forKey: .width)
        height = try container.decodeIfPresent(CGFloat.self, forKey: .height)
    }
}
