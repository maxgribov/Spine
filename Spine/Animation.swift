//
//  Animation.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public class Animation {
    
    let name: String
    let action: SKAction
    
    init(_ model: AnimationModel) {
        
        self.name = model.name
        
        var actions = [SKAction]()
        
        for group in model.groups {
            
            switch group {
            case .bones(let bonesAnimationModels):
                let bonesActions = bonesAnimationModels.map({ SKAction.bone(animation: $0)})
                actions.append(contentsOf: bonesActions)
            default:
                continue
                
            }
        }
        
        self.action = SKAction.group(actions)
    }
}

extension SKAction {
    
    class func bone(animation: BoneAnimationModel) -> SKAction {
        
        return SKAction.run(SKAction.group(animation.timelines.map({ SKAction.bone(timeline: $0)})), onChildWithName: "//\(animation.bone)")
    }
    
    class func bone(timeline: BoneAnimationTimelineModelType) -> SKAction {
        
        switch timeline {
        case .rotate(let rotateKeyframes):
            return SKAction.sequence(rotateKeyframes.map({ SKAction.bone(keyframe: $0)}))
        case .scale(let scaleKeyframes):
            return SKAction.sequence(scaleKeyframes.map({ SKAction.bone(keyframe: $0)}))
        case .translate(let translateKeyframes):
            return SKAction.sequence(translateKeyframes.map({ SKAction.bone(keyframe: $0)}))
        case .shear(let shearKeyframes):
            return SKAction.sequence(shearKeyframes.map({ SKAction.bone(keyframe: $0)}))
        }
    }
    
    class func bone(keyframe: BoneKeyframeRotateModel) -> SKAction {
        
        let angle = keyframe.angle * degreeToRadiansFactor
        
        return SKAction.rotate(byAngle: angle, duration: keyframe.time)
    }
    
    class func bone(keyframe: BoneKeyframeTranslateModel) -> SKAction {
        
        let vector = CGVector(dx: keyframe.position.x, dy: keyframe.position.y)
        return SKAction.move(by: vector, duration: keyframe.time)
    }
    
    class func bone(keyframe: BoneKeyframeScaleModel) -> SKAction {
        
        return SKAction.scaleX(by: keyframe.scale.dx, y: keyframe.scale.dy, duration: keyframe.time)
        
//        return SKAction.group([SKAction.scaleX(to: keyframe.scale.dx, duration: keyframe.time),
//                               SKAction.scaleY(to: keyframe.scale.dy, duration: keyframe.time)])
    }
    
    class func bone(keyframe: BoneKeyframeShearModel) -> SKAction {
        
        return SKAction.customAction(withDuration: keyframe.time, actionBlock: { (node, time) in
            
            //TODO: Implement shear action here in future
        })
    }
}

