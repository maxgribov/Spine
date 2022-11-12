//
//  File.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

protocol SpineDecodableDictionary {
    
    associatedtype KeysType: CodingKey
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws
}
