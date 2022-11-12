//
//  File.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

protocol SpineDecodableArray {
    
    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws
}
