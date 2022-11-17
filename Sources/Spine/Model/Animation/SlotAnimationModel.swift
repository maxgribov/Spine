//
//  SlotAnimationModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotAnimationModel {
    
    let slot: String
    let timelines: [Timeline]
}

//MARK: - Types

extension SlotAnimationModel {
    
    enum Timeline {
        
        case attachment([SlotKeyframeAttachmentModel])
        case color([SlotKeyframeColorModel])
        case colorDark([SlotKeyframeColorDarkModel])
    }
}

extension SlotAnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case attachment, rgb, alpha, rgba, rgba2
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [Timeline]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
            case .attachment:
                var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .attachment)
                var keyframes = [SlotKeyframeAttachmentModel]()
                while keyframesContainer.isAtEnd == false {
                    
                    let keyframe = try keyframesContainer.decode(SlotKeyframeAttachmentModel.self)
                    keyframes.append(keyframe)
                }
                timelines.append(.attachment(keyframes))
                
            case .rgba:
                var keyframesContainer = try container.nestedUnkeyedContainer(forKey: .rgba)
                var keyframes = [SlotKeyframeColorModel]()
                while keyframesContainer.isAtEnd == false {
                    
                    let keyframe = try keyframesContainer.decode(SlotKeyframeColorModel.self)
                    keyframes.append(keyframe)
                }
                
//                let adjustedColorKeyframes = try adjustedCurves(keyframes)
                timelines.append(.color(keyframes))
                
            default:
                break
               //TODO: - Implementation required for rgb + alpha & rgba2
            }
        }
        
        self.slot = name
        self.timelines = timelines
    }
}


