//
//  SpineModel+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 06/07/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension SpineModel {
    
    //TODO: tests
    var uniqueAtlasesNames: Set<String> {
        
        skins.reduce(Set<String>()) { partialResult, skin in
            
            partialResult.union(skin.atlasesNames)
        }
    }
    
    @available(*, deprecated, message: "Use uniqueAtlasesNames instead")
    func atlasesNames() -> [String]? {
        
        Array(uniqueAtlasesNames)
    }
}
