//
//  NamePrefix.swift
//  Spine
//
//  Created by Max Gribov on 08/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

protocol NamePrefix {
    
    static var namePrefix: String { get }
    static func generateName(_ name: String) -> String
}

extension NamePrefix {
    
    static func generateName(_ name: String) -> String {
        
        return "\(namePrefix)\(name)"
    }
}
