//
//  IKConstraintAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct IKConstraintAnimationModel {
    
    typealias Keyframe = IKConstraintKeyframeModel
    
    let constraint: String
    let keyframes: [Keyframe]
}

extension IKConstraintAnimationModel: SpineDecodableArray {
    
    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws {

        var keyframes = [Keyframe]()
        while container.isAtEnd == false {

            keyframes.append(try container.decode(Keyframe.self))
        }
        
        self.constraint = name
        self.keyframes = keyframes
    }
}
