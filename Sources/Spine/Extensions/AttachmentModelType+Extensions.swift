//
//  File.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

extension AttachmentModelType {
    
    var isTextureRequired: Bool {
        
        switch self {
        case .region, .mesh, .linkedMesh:
            return true
            
        default:
            return false
        }
    }
}
