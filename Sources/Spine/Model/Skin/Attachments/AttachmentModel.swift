//
//  AttachmentModel.swift
//  
//
//  Created by Max Gribov on 06.11.2022.
//

import Foundation

protocol AttachmentModel {

    var name: String { get }
}

protocol AttachmentTexturedModel: AttachmentModel {

    var fileName: String? { get }
    var path: String? { get }
    var atlasName: String { get }
    var textureName: String { get }
}

extension AttachmentTexturedModel {
    
    var atlasName: String {
        
        guard let nameWithPath = path ?? fileName else {
            return "default"
        }
        
        var nameWithPathSplitted = nameWithPath.components(separatedBy: "/")
        if nameWithPathSplitted.count > 1 {
            
            nameWithPathSplitted.removeLast()
            return nameWithPathSplitted.joined(separator: "/")
            
        } else {
            
            return "default"
        }
    }
    
    var textureName: String {
        
        guard let resultName = path ?? fileName,
              let result = resultName.components(separatedBy: "/").last else {
            
            return name
        }
        
        return result
    }
}
