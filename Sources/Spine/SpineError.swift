//
//  File.swift
//  
//
//  Created by Max Gribov on 19.11.2022.
//

import Foundation

enum SpineError: LocalizedError {
    
    case jsonFileLoadingFromBundleFailed(String)
    case missingAnimatonNamed(String)
    case missingSkinNamed(String)
    case unableApplyTextureToRegionAttachmentNode(String)
    
    var errorDescription: String? {
        
        switch self {
        case let .jsonFileLoadingFromBundleFailed(fileName):
            return "JSON file \(fileName) loading from bundle failed. "
            
        case let .missingAnimatonNamed(animationName):
            return "Missing animation named: \(animationName)"
            
        case let .missingSkinNamed(skinName):
            return "Missing skin named: \(skinName)"
            
        case let .unableApplyTextureToRegionAttachmentNode(attachmentName):
            return "Applying texture failed. Region attachment node named: \(attachmentName) not found in skeleton nodes tree."
        }
    }
}
