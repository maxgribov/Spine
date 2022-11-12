//
//  SpineModel.swift
//  Spine
//
//  Created by Max Gribov on 27/01/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

let degreeToRadiansFactor: CGFloat = CGFloat.pi / 180.0

public struct SpineModel {
    
    let skeleton: SkeletonModel
    let bones: [BoneModel]?
    let slots: [SlotModel]?
    let skins: [SkinModel]?
    let ik: [IKConstraintModel]?
    let transform: [TransformConstraintModel]?
    let path: [PathConstraintModel]?
    let events: [EventModel]?
    let animations: [AnimationModel]?
}

extension SpineModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case skeleton
        case bones
        case slots
        case skins
        case ik
        case transform
        case path
        case events
        case animations
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        self.skeleton = try container.decode(SkeletonModel.self, forKey: .skeleton)
        self.bones = try container.decodeIfPresent([BoneModel].self, forKey: .bones)
        self.slots = try container.decodeIfPresent([SlotModel].self, forKey: .slots)
        self.skins = try container.decodeIfPresent([SkinModel].self, forKey: .skins)
        self.ik = try container.decodeIfPresent([IKConstraintModel].self, forKey: .ik)
        self.transform = try container.decodeIfPresent([TransformConstraintModel].self, forKey: .transform)
        self.path = try container.decodeIfPresent([PathConstraintModel].self, forKey: .path)
        
        //events
        if container.contains(.events) {

            let eventsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .events)
            var events = [EventModel]()

            for eventKey in eventsContainer.allKeys {

                let eventContainer = try eventsContainer.nestedContainer(keyedBy: EventModel.Keys.self, forKey: eventKey)
                let event = try EventModel(eventKey.stringValue, eventContainer)
                events.append(event)
            }

            self.events = events

        } else {

            self.events = nil
        }

        //animations
        if container.contains(.animations) {
            
            let animationsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .animations)
            
            var animations = [AnimationModel]()
            
            for animationKey in animationsContainer.allKeys {
                
                let animationContainer = try animationsContainer.nestedContainer(keyedBy: AnimationModel.Keys.self, forKey: animationKey)
                let animation = try AnimationModel(animationKey.stringValue, animationContainer)
                animations.append(animation)
            }
            
            self.animations = animations
            
        } else {
            
            self.animations = nil
        }
    }
}

//MARK: - Decodable helpers

protocol SpineDecodableDictionary {
    
    associatedtype KeysType: CodingKey
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws
}

protocol SpineDecodableArray {
    
    init(_ name: String, _ container: inout UnkeyedDecodingContainer) throws
}

struct SpineNameKey: CodingKey {
    
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
}

//MARK: - Helpers models

enum CurveModelType: Decodable, Equatable {
    
    case linear
    case stepped
    case bezier(BezierCurveModel)
    case bezier2(BezierCurveModel, BezierCurveModel)
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        do {
            
            let stringValue = try container.decode(String.self)
            
            guard stringValue == "stepped" else {
                throw DecodingError.typeMismatch(CurveModelType.self, .init(codingPath: decoder.codingPath, debugDescription: "Unexpected string value: \(stringValue)"))
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
    
//TODO: - REMOVE
    init(_ value: String?) {
        
        if let value = value {
            
            if value == "stepped" {
                
                self = .stepped
                
            } else {
                
                self = .linear
            }
            
        } else {
            
            self = .linear
        }
    }
    //TODO: - REMOVE
    init(_ value: [Float]) {
        
        if let curve = BezierCurveModel(value) {
            
            self = .bezier(curve)
            
        } else {
            
            self = .linear
        }
    }

    struct BezierCurveModel: Equatable {
        
        let p0: Float
        let p1: Float
        let p2: Float
        let p3: Float
        
        init(p0: Float, p1: Float, p2: Float, p3: Float) {
            
            self.p0 = p0
            self.p1 = p1
            self.p2 = p2
            self.p3 = p3
        }
        
        //TODO: - REMOVE
        init?(_ values: [Float]) {
            
            guard values.count == 4 else {
                return nil
            }
            
            self.p0 = values[0]
            self.p1 = values[1]
            self.p2 = values[2]
            self.p3 = values[3]
        }
        //TODO: - REMOVE
        init(_ c1: Float, _ c2: Float?, _ c3: Float?, _ c4: Float?) {
            
            p0 = c1
            p1 = c2 ?? 0
            p2 = c3 ?? 1
            p3 = c4 ?? 1
        }
    }
}

struct ColorModel: Equatable {
    
    let value: String
    
    var rgbaValue: UInt32 {
        
        var result: UInt32 = 0
        Scanner(string: value).scanHexInt32(&result)
        
        return result
    }
    
    var red: CGFloat { CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0 }
    var green: CGFloat { CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0 }
    var blue: CGFloat { CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0 }
    var alpha: CGFloat { CGFloat(rgbaValue & 0x000000FF) / 255.0 }

    init(value: String) {
        
        self.value = value
    }
    
    func mix(with color: ColorModel) -> ColorModel {
        
        let rgbaResultValue: UInt32 = rgbaValue & color.rgbaValue
        let stringValue = String(format:"%2x", rgbaResultValue)
        
        return ColorModel(value: stringValue)
    }
}

extension ColorModel: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        value = try container.decode(String.self)
    }
}
