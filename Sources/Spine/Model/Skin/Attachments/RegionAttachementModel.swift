//
//  RegionAttachmentModel.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import SpriteKit

struct RegionAttachmentModel: AttachmentTexturedModel {
    
    let name: String
    let fileName: String?
    let path: String?
    let position: CGPoint
    let scale: CGVector
    let rotation: CGFloat
    let size: CGSize
    let color: ColorModel
}

extension RegionAttachmentModel: SpineDecodableDictionary {

    enum Keys: String, CodingKey {
        
        case name, path, x, y, scaleX, scaleY
        case rotation, width, height , color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        self.name = name
        fileName = try container.decodeIfPresent(String.self, forKey: .name)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        let x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        let y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        position = .init(x: x, y: y)
        let scaleX = try container.decodeIfPresent(CGFloat.self, forKey: .scaleX) ?? 1
        let scaleY = try container.decodeIfPresent(CGFloat.self, forKey: .scaleY) ?? 1
        scale = .init(dx: scaleX, dy: scaleY)
        rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        size = .init(width: width, height: height)
        color = try container.decodeIfPresent(ColorModel.self, forKey: .color) ?? .init(value: "FFFFFFFF")
    }
}
