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
    /// Names of atlases with textures that are stored in the model. The names correspond to folders in the Spine App project
    var atlasesNames: Set<String> {
        
        skins.reduce(Set<String>()) { partialResult, skin in
            
            partialResult.union(skin.atlasesNames)
        }
    }
}
