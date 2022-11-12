//
//  SpineModel+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 06/07/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension SpineModel {
    
    //TODO: - depricate, must return non optonal value
    func atlasesNames() -> [String]? {
        
        var names = Set<String>()
        for skin in skins {
            
            guard let atlasesNames = skin.atlasesNames() else {
                continue
            }
            
            names = names.union(Set(atlasesNames))
        }
        
        return Array(names)
    }
}
