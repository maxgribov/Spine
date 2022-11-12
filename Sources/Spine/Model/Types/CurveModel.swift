//
//  CurveModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import SpriteKit

enum CurveModel: Equatable {
    
    case linear
    case stepped
    case bezier(BezierCurveModel)
    case bezier2(BezierCurveModel, BezierCurveModel)
}

//MARK: - Decoding

extension CurveModel: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        do {
            
            let stringValue = try container.decode(String.self)
            
            guard stringValue == "stepped" else {
                throw DecodingError.typeMismatch(CurveModel.self, .init(codingPath: decoder.codingPath, debugDescription: "Unexpected string value: \(stringValue)"))
            }
            
            self = .stepped
            
        } catch {
            
            let floatsValue = try container.decode([Float].self)
            switch floatsValue.count {
            case 4:
                let bezierCurve = BezierCurveModel(p0: floatsValue[0], p1: floatsValue[1], p2: floatsValue[2], p3: floatsValue[3])
                self = .bezier(bezierCurve)
                
            case 8:
                let bezierCurve1 = BezierCurveModel(p0: floatsValue[0], p1: floatsValue[1], p2: floatsValue[2], p3: floatsValue[3])
                let bezierCurve2 = BezierCurveModel(p0: floatsValue[4], p1: floatsValue[5], p2: floatsValue[6], p3: floatsValue[7])
                self = .bezier2(bezierCurve1, bezierCurve2)
                
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unable recognize bezier curve data in floats value: \(floatsValue)"))
            }
        }
    }
}
