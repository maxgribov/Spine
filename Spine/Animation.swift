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
    
    init(_ animationModel: AnimationModel, _ model: SpineModel) {
        
        self.name = animationModel.name
        
        var actions = [SKAction]()
        
        for group in animationModel.groups {
            
            switch group {
            case .bones(let bonesAnimationModels):
                actions.append(contentsOf: bonesAnimationModels.map({ (boneAnimationModel) -> SKAction in
                    
                    let bone = model.bones?.filter({ $0.name == boneAnimationModel.bone }).first
                    return BoneAnimationBuilder.action(boneAnimationModel, bone)
                }))
            default:
                continue
                
            }
        }
        
        self.action = SKAction.group(actions)
    }
}

func setTiming(_ action: SKAction, _ curve: CurveModelType)  {
    
    switch curve {
    case .linear: action.timingMode = .linear
    case .stepped: action.timingFunction = { time in return time < 1.0 ? 0 : 1.0 }
    case .bezier(let bezierModel):
        let solver = BezierCurveSolver(bezierModel)
        action.timingFunction = solver.timingFunction()
    }
}

//MARK: - Bones Actions

class BoneAnimationBuilder {
    
    class func action(_ model: BoneAnimationModel, _ bone: BoneModel?) -> SKAction {
        
        guard let bone = bone else {
            
            return SKAction()
        }
        
        let boneName = Bone.generateName(model.bone)
        return SKAction.run(SKAction.group(model.timelines.map({ BoneAnimationBuilder.action(timeline: $0, bone)})), onChildWithName: "//\(boneName)")
    }
    
    class func action(timeline: BoneAnimationTimelineModelType, _ bone: BoneModel) -> SKAction {
        
        var lastTime: TimeInterval = 0
        
        switch timeline {
        case .rotate(let rotateKeyframes):
            return SKAction.sequence(rotateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return BoneAnimationBuilder.action(keyframe: keyframe, duration: duration, bone.rotation)
            }))
            
        case .translate(let translateKeyframes):
            return SKAction.sequence(translateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return BoneAnimationBuilder.action(keyframe: keyframe, duration: duration, bone.position)
            }))
            
        case .scale(let scaleKeyframes):
            return SKAction.sequence(scaleKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return BoneAnimationBuilder.action(keyframe: keyframe, duration: duration, bone.scale)
            }))
            
        case .shear(let shearKeyframes):
            return SKAction.sequence(shearKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return BoneAnimationBuilder.action(keyframe: keyframe, duration: duration, bone.shear)
            }))
        }
    }
    
    class func action(keyframe: BoneKeyframeRotateModel, duration: TimeInterval, _ defaultAngle: CGFloat) -> SKAction {
        
        let angle = (defaultAngle + keyframe.angle) * degreeToRadiansFactor
        let action = SKAction.rotate(toAngle: angle, duration: duration)
        setTiming(action, keyframe.curve)
        
        return action
    }
    
    class func action(keyframe: BoneKeyframeTranslateModel, duration: TimeInterval, _ defaultPosition: CGPoint) -> SKAction {
        
        let position = CGPoint(x: defaultPosition.x + keyframe.position.x, y: defaultPosition.y + keyframe.position.y)
        let action = SKAction.move(to: position, duration: duration)
        setTiming(action, keyframe.curve)

        return action
    }
    
    class func action(keyframe: BoneKeyframeScaleModel, duration: TimeInterval, _ defaultScale: CGVector) -> SKAction {
        
        let scaleX = defaultScale.dx + keyframe.scale.dx
        let scaleY = defaultScale.dy + keyframe.scale.dy
        let action = SKAction.group([SKAction.scaleX(to: scaleX, duration: duration),
                                     SKAction.scaleY(to: scaleY, duration: duration)])
        setTiming(action, keyframe.curve)
        
        return action
    }
    
    class func action(keyframe: BoneKeyframeShearModel, duration: TimeInterval, _ defaultShear: CGVector) -> SKAction {
        
        //TODO: Implement shear action here in future
        return SKAction()
    }
}
