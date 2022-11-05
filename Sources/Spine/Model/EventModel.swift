//
//  EventModel.swift
//  Spine
//
//  Created by Max Gribov on 02/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public struct EventModel {
    
    let name: String
    let int: Int
    let float: CGFloat
    let string: String?
    
    init(_ name: String, _ int: Int?, _ float: CGFloat?, _ string: String?) {
        
        self.name = name
        self.int = int ?? 0
        self.float = float ?? 0
        self.string = string
    }
}

extension EventModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case event
        case int
        case float
        case string
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        let int: Int? = try container.decodeIfPresent(Int.self, forKey: .int)
        let float: CGFloat? = try container.decodeIfPresent(CGFloat.self, forKey: .float)
        let string: String? = try container.decodeIfPresent(String.self, forKey: .string)
        
        self.init(name, int, float, string)
    }
}
