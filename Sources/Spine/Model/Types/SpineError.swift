//
//  File.swift
//  
//
//  Created by Max Gribov on 19.11.2022.
//

import Foundation

enum SpineError: LocalizedError {
    
    case jsonFileLoadingFromBundleFailed(String)
    
    var errorDescription: String? {
        
        switch self {
        case let .jsonFileLoadingFromBundleFailed(fileName):
            return "JSON file \(fileName) loading from bundle failed. "
        }
    }
}
