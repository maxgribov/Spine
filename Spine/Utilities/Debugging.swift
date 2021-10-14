//
//  Debugging.swift
//  Spine
//
//  Created by Vladimir on 15.10.21.
//  Copyright © 2021 Max Gribov. All rights reserved.
//

import Foundation

public struct UnwrapError<T>: Error, CustomStringConvertible {
    let optional: T?
    
    public var description: String {
        return "Found nil while unwrapping \(String(describing: optional))!"
    }
}

/// Returns the unwrapped value, or throws an error on `nil`.
public func unwrap<T>(_ optional: T?) throws -> T {
    if let real = optional {
        return real
    } else {
        throw UnwrapError(optional: optional)
    }
}
