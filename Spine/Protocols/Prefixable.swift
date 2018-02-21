//
//  Prefixable.swift
//  Spine
//
//  Created by Max Gribov on 08/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import Foundation

protocol Prefixable {
    
    static var prefix: String { get }
    static func generateName(_ name: String) -> String
}

extension Prefixable {
    
    static func generateName(_ name: String) -> String {
        
        return "\(prefix)\(name)"
    }
}
