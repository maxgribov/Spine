//
//  SkinModel+Atlases.swift
//  Spine
//
//  Created by Max Gribov on 06/07/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

extension SkinModel {
    
    func atlasesNames() -> [String]? {
        
        guard let slots = slots else {
            
            return nil
        }
        
        var names = Set<String>()
        
        for slot in slots {
            
            guard let atlasesNames = slot.atlasesNames() else {
                continue
            }
            
            names = names.union(Set(atlasesNames))
        }
        
        return Array(names)
    }
}
