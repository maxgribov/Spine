//
//  SpineNameKey.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SpineNameKey: CodingKey {
    
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}
