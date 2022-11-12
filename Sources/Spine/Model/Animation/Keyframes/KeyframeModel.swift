//
//  KeyframeModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

protocol KeyframeModel {
    
    var time: TimeInterval { get }
}

protocol CurvedKeyframeModel: KeyframeModel {

    var curve: CurveModel { get set }
}

/**
 Most keyframe properties affect how animation behaves *prior* to the keyframe,
 but curve property affects now animation behaves *after* the keyframe.
 This function moves curve property of keyframes to consequent keyframes
 in order to make curve logic consistent with other properties, like position and angle.
 */
func adjustedCurves<T:CurvedKeyframeModel>(_ input: [T]) -> [T]
{
    var output = [T]()
    var previousCurve = CurveModel.linear
    for frame in input {
        var adjustedFrame = frame
        adjustedFrame.curve = previousCurve
        output.append(adjustedFrame)
        previousCurve = frame.curve
    }

    return output
}
