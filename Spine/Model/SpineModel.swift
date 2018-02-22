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
        
        //skins
        if container.contains(.skins) {
            
            let skinsContainer = try container.nestedContainer(keyedBy: SpineNameKey.self, forKey: .skins)
            var skins = [SkinModel]()
            
            for skinKey in skinsContainer.allKeys {
                
                let skinContainer = try skinsContainer.nestedContainer(keyedBy: SkinModel.KeysType.self, forKey: skinKey)
                let skin = try SkinModel(skinKey.stringValue, skinContainer)
                skins.append(skin)
            }
            
            self.skins = skins
            
        } else {
            
            self.skins = nil
        }

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

enum CurveModelType {
    
    case linear
    case stepped
    case bezier(BezierCurveModel)
    
    var name: String {
        get {
            switch self {
            case .linear: return "linear"
            case .stepped: return "stepped"
            case .bezier(_): return "bezier"
            }
        }
    }
    
    var bezierValue: [Float] {
        
        get {
            
            switch self {
            case .bezier(let value): return [value.p0, value.p1, value.p2, value.p3]
            default:
                return [Float]()
            }
        }
    }
    
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
    
    init(_ value: [Float]) {
        
        if let curve = BezierCurveModel(value) {
            
            self = .bezier(curve)
            
        } else {
            
            self = .linear
        }
    }
    
    struct BezierCurveModel {
        
        let p0: Float
        let p1: Float
        let p2: Float
        let p3: Float
        
        init?(_ values: [Float]) {
            
            guard values.count == 4 else {
                
                return nil
            }
            
            self.p0 = values[0]
            self.p1 = values[1]
            self.p2 = values[2]
            self.p3 = values[3]
        }
    }
}

struct ColorModel {

    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
    let value: String
    
    init(_ value: String) {

        var rgbaValue: UInt32 = 0
        Scanner(string: value).scanHexInt32(&rgbaValue)
        
        red = CGFloat((rgbaValue & 0xFF000000) >> 24) / 255.0
        green = CGFloat((rgbaValue & 0x00FF0000) >> 16) / 255.0
        blue = CGFloat((rgbaValue & 0x0000FF00) >> 8) / 255.0
        alpha = CGFloat(rgbaValue & 0x000000FF) / 255.0
        
        self.value = value
    }
    
    init?(_ value: String?) {

        if let value = value {

            self.init(value)

        } else {

            return nil
        }
    }
    
    func mix(with model: ColorModel) -> ColorModel {
        
        var rgbaValue: UInt32 = 0
        Scanner(string: value).scanHexInt32(&rgbaValue)
        
        var rgbaModelValue: UInt32 = 0
        Scanner(string: model.value).scanHexInt32(&rgbaModelValue)
        
        let rgbaResultValue: UInt32 = rgbaValue & rgbaModelValue
        
        let stringValue = String(format:"%2x", rgbaResultValue)
        
        return ColorModel(stringValue)
    }
}
