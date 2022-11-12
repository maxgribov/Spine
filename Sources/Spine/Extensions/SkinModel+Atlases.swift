//
//  SkinModel+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 06/07/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

extension SkinModel {
    
    func atlasesNames() -> [String] {

        var names = Set<String>()
        
        for slot in slots {
            
            names = names.union(Set(slot.atlasesNames()))
        }
        
        return Array(names)
    }
}
