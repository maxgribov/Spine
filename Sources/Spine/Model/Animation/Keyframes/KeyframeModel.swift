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
    
    var values: [Float] { get }
    var curve: CurveModel { get set }
}

/**
 Most keyframe properties affect how animation behaves *prior* to the keyframe,
 but curve property affects now animation behaves *after* the keyframe.
 This function moves curve property of keyframes to consequent keyframes
 in order to make curve logic consistent with other properties, like position and angle.
 */
func adjustedCurves<T:CurvedKeyframeModel>(_ input: [T]) throws -> [T]
{
    var output = [T]()
    
    var previousTime: Float = 0
    var previousValues: [Float] = [0, 0]
    var previousCurve = CurveModel.linear
    
    for frame in input {
        
        var adjustedFrame = frame
        
        switch previousCurve {
        case let .bezier(bezier):
            guard let prevValue = previousValues.first,
                  let currValue = frame.values.first else {
                throw KeyframeModelError.noFirstValue
            }
            previousCurve = .bezier(bezier.normalazed(timeStart: previousTime, timeEnd: Float(frame.time), valueStart: prevValue, valueEnd: currValue))
            
        case let .bezier2(bezier1, bezier2):
            guard let prevValue1 = previousValues.first,
                  let currValue1 = frame.values.first else {
                throw KeyframeModelError.noFirstValue
            }
            
            guard let prevValue2 = previousValues.last,
                  let currValue2 = frame.values.last else {
                throw KeyframeModelError.noLastValue
            }
            
            let bezier1normal = bezier1.normalazed(timeStart: previousTime, timeEnd: Float(frame.time), valueStart: prevValue1, valueEnd: currValue1)
            let bezier2normal = bezier2.normalazed(timeStart: previousTime, timeEnd: Float(frame.time), valueStart: prevValue2, valueEnd: currValue2)
            
            previousCurve = .bezier2(bezier1normal, bezier2normal)
            
        default:
            break
        }
        
        adjustedFrame.curve = previousCurve
        output.append(adjustedFrame)

        previousTime = Float(frame.time)
        previousValues = frame.values
        previousCurve = frame.curve
    }

    return output
}

enum KeyframeModelError: LocalizedError {
    
    case noFirstValue
    case noLastValue
}
