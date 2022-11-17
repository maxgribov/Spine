//
//  SlotKeyframeColorModel.swift
//  
//
//  Created by Max Gribov on 12.11.2022.
//

import Foundation

struct SlotKeyframeColorModel {

    var keyframes: [SlotKeyframeColorChannelModel]

    init(keyframes: [SlotKeyframeColorChannelModel]) {
        
        self.keyframes = keyframes
    }
}

extension SlotKeyframeColorModel: Decodable {
    
    enum Keys: String, CodingKey {
        
        case time, color, curve
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: Keys.self)
        let time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        let color = try container.decode(ColorModel.self, forKey: .color)
        do {
            
            let curve = try container.decode(CurveModel.self, forKey: .curve)
            let keyframes = color.channels.map{ SlotKeyframeColorChannelModel(time: time, channel: $0, curve: curve) }
            self.init(keyframes: keyframes)
            
        } catch {
            
            if let curveValues = try? container.decode([Float].self, forKey: .curve), curveValues.count == 4 * 4 {
                
                var keyframes = [SlotKeyframeColorChannelModel]()
                for (index, channel) in color.channels.enumerated() {
                    
                    let p0 = curveValues[index]
                    let p1 = curveValues[index + 1]
                    let p2 = curveValues[index + 2]
                    let p3 = curveValues[index + 3]
                    let curve = BezierCurveModel(p0: p0, p1: p1, p2: p2, p3: p3)
                    let keyframe = SlotKeyframeColorChannelModel(time: time, channel: channel, curve: .bezier(curve))
                    keyframes.append(keyframe)
                }
                
                self.init(keyframes: keyframes)
                
            } else {
                
                let keyframes = color.channels.map{ SlotKeyframeColorChannelModel(time: time, channel: $0, curve: .linear) }
                self.init(keyframes: keyframes)
            }
        }
    }
}
