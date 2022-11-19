//
//  File.swift
//  
//
//  Created by Max Gribov on 19.11.2022.
//

import Foundation

extension Float {
    
    func rounded(places: Int) -> Float {
        
        if places > 0 {
            
            let multiplier = pow(Float(10), Float(places))
            return roundf(self * multiplier) / multiplier
            
        } else {
            
            return roundf(self)
        }
    }
}
