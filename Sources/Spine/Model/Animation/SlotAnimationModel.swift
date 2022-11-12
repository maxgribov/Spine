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
    }
}

extension SlotAnimationModel: SpineDecodableDictionary {
    
    enum Keys: String, CodingKey {
        
        case attachment
        case color
    }
    
    typealias KeysType = Keys
    
    init(_ name: String, _ container: KeyedDecodingContainer<KeysType>) throws {
        
        var timelines = [Timeline]()
        
        for timelineKey in container.allKeys {
            
            switch timelineKey {
                
            case .attachment:
                let attachmentKeyframes = try container.decode([SlotKeyframeAttachmentModel].self, forKey: .attachment)
                timelines.append(.attachment(attachmentKeyframes))
                
            case .color:
                let colorKeyframes = try container.decode([SlotKeyframeColorModel].self, forKey: .color)
                let adjustedColorKeyframes = adjustedCurves(colorKeyframes)
                timelines.append(.color(adjustedColorKeyframes))
            }
        }
        
        self.slot = name
        self.timelines = timelines
    }
}


