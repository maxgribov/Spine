//
//  File.swift
//  
//
//  Created by Max Gribov on 17.11.2022.
//

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        
        guard let firstRow = self.first else {
            return []
        }
        
        return firstRow.indices.map { index in
            
            self.map { $0[index] }
        }
    }
}
