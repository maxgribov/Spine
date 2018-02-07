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
                    
                    guard let bone = model.bones?.filter({ $0.name == boneAnimationModel.bone }).first else {
                        
                        //for some reason can't find bone for this animation model
                        return SKAction()
                    }
                    
                    return SKAction.bone(boneAnimationModel, bone)
                }))
            default:
                continue
                
            }
        }
        
        self.action = SKAction.group(actions)
    }
}

//MARK: - Bones Actions

extension SKAction {
    
    class func bone(_ model: BoneAnimationModel, _ bone: BoneModel) -> SKAction {
        
        return SKAction.run(SKAction.group(model.timelines.map({ SKAction.bone(timeline: $0, bone)})), onChildWithName: "//\(model.bone)")
    }
    
    class func bone(timeline: BoneAnimationTimelineModelType, _ bone: BoneModel) -> SKAction {
        
        var lastTime: CFTimeInterval = 0
        
        switch timeline {
        case .rotate(let rotateKeyframes):
            return SKAction.sequence(rotateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return SKAction.bone(keyframe: keyframe, duration: duration, bone.rotation)
            }))
            
        case .translate(let translateKeyframes):
            return SKAction.sequence(translateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return SKAction.bone(keyframe: keyframe, duration: duration, bone.position)
            }))

        case .scale(let scaleKeyframes):
            return SKAction.sequence(scaleKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return SKAction.bone(keyframe: keyframe, duration: duration, bone.scale)
            }))

        case .shear(let shearKeyframes):
            return SKAction.sequence(shearKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return SKAction.bone(keyframe: keyframe, duration: duration, bone.shear)
            }))
        }
    }
    
    class func bone(keyframe: BoneKeyframeRotateModel, duration: CFTimeInterval, _ defaultAngle: CGFloat) -> SKAction {

        let angle = (defaultAngle + keyframe.angle) * degreeToRadiansFactor
        return SKAction.rotate(toAngle: angle, duration: duration)
    }

    class func bone(keyframe: BoneKeyframeTranslateModel, duration: CFTimeInterval, _ defaultPosition: CGPoint) -> SKAction {

        let position = CGPoint(x: defaultPosition.x + keyframe.position.x, y: defaultPosition.y + keyframe.position.y)
        return SKAction.move(to: position, duration: duration)
    }
    
    class func bone(keyframe: BoneKeyframeScaleModel, duration: CFTimeInterval, _ defaultScale: CGVector) -> SKAction {

        let scaleX = defaultScale.dx + keyframe.scale.dx
        let scaleY = defaultScale.dy + keyframe.scale.dy
        return SKAction.group([SKAction.scaleX(to: scaleX, duration: duration),
                               SKAction.scaleY(to: scaleY, duration: duration)])
    }
    
    class func bone(keyframe: BoneKeyframeShearModel, duration: CFTimeInterval, _ defaultShear: CGVector) -> SKAction {
        
        //TODO: Implement shear action here in future
        return SKAction()
    }
}

