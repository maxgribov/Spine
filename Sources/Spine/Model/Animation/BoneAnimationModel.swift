//
//  BoneAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct BoneAnimationModel {
    
    let bone: String
    let timelines: [Timeline]
    let numericTimelines: [NumericTimelineModel]
    let meshDecodeErrors: [Error]
}

//MARK: - Types

extension BoneAnimationModel {

    enum Timeline {
        
        case rotate([BoneKeyframeRotateModel])
        case translate([BoneKeyframeTranslateModel])
        case scale([BoneKeyframeScaleModel])
        case shear([BoneKeyframeShearModel])
    }
}

//MARK: - Decoding

extension BoneAnimationModel: SpineDecodableDictionary {

    enum Keys: String, CodingKey {
        
        case rotate, translate, scale, shear
        case translatex, translatey, scalex, scaley
    }
    
    typealias KeysType = Keys

    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [Timeline]()
        var numericTimelines: [NumericTimelineModel] = []
        var meshDecodeErrors: [Error] = []
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
            case .translatex, .translatey, .scalex, .scaley:
                do {
                    let frames = try container.decode([ScalarBoneKeyframeModel].self,forKey:timelineKey)
                    let fallback:Float = timelineKey == .scalex || timelineKey == .scaley ? 1 : 0
                    numericTimelines.append(.init(name:timelineKey.rawValue,keys:frames.map {
                        .init(time:$0.time,values:[$0.value ?? fallback],curves:[$0.curve])
                    }))
                } catch { meshDecodeErrors.append(error) }
            case .rotate:
                let rotateKeyframes = try container.decode([BoneKeyframeRotateModel].self, forKey: .rotate)
                numericTimelines.append(.init("rotate",frames:rotateKeyframes))
                let adjustedRotateKeyframes = try adjustedCurves(rotateKeyframes)
                timelines.append(.rotate(adjustedRotateKeyframes))

            case .translate:
                let translateKeyframes = try container.decode([BoneKeyframeTranslateModel].self, forKey: .translate)
                numericTimelines.append(.init("translate",frames:translateKeyframes))
                let adjustedTranslateKeyframes = try adjustedCurves(translateKeyframes)
                timelines.append(.translate(adjustedTranslateKeyframes))

            case .scale:
                let scaleKeyframes = try container.decode([BoneKeyframeScaleModel].self, forKey: .scale)
                numericTimelines.append(.init("scale",frames:scaleKeyframes))
                let adjustedScaleKeyframes = try adjustedCurves(scaleKeyframes)
                timelines.append(.scale(adjustedScaleKeyframes))

            case .shear:
                let shearKeyframes = try container.decode([BoneKeyframeShearModel].self, forKey: .shear)
                numericTimelines.append(.init("shear",frames:shearKeyframes))
                let adjustedShearKeyframes = try adjustedCurves(shearKeyframes)
                timelines.append(.shear(adjustedShearKeyframes))
            }
        }
        
        self.bone = name
        self.timelines = timelines
        self.numericTimelines = numericTimelines
        self.meshDecodeErrors = meshDecodeErrors
    }
}
