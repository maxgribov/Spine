//
//  SKNode+Extensions.swift
//  
//
//  Created by Max Gribov on 27.11.2022.
//

import SpriteKit

extension SKNode {
    
    static func childrenNamesTree(level: Int, node: SKNode) -> [(level: Int, name: String)] {
        
        var result =  [(Int, String)]()

        for child in node.children {
            
            result.append((level, child.name ?? ""))
           
            let childrenNames = Self.childrenNamesTree(level: level + 1, node: child)
            result.append(contentsOf: childrenNames)
        }
        
        return result
    }
}
