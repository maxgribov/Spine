//
//  Animation.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

struct Animation {
    
    let name: String
    let action: SKAction
    
    init(_ animationModel: AnimationModel, _ model: SpineModel) {
        
        self.name = animationModel.name
        
        var actions = [SKAction]()
        
        for group in animationModel.groups {
            
            switch group {
            case .bones(let bonesAnimationModels):
                let bonesActions = bonesAnimationModels.compactMap({ (animationModel) -> (BoneModel, BoneAnimationModel)? in

                    guard let bone = model.bones.first(where: { $0.name == animationModel.bone } ) else {
                        return nil
                    }

                    return (bone, animationModel)
                    
                }).map { bone, animaton in
                    
                    return Self.action(animaton, bone)
                }
                actions.append(contentsOf: bonesActions)
                
            case .slots(let slotsAnimationModels):
                let slotsAnimations = slotsAnimationModels.map({ (slotAnimationModel) -> SKAction in
                    
                    return Self.action(slotAnimationModel)
                })
                actions.append(contentsOf: slotsAnimations)
                
            case .events(let eventsKeyframes):
                actions.append(Self.action(eventsKeyframes))
                
            case .drawOrder(let draworderKeyframes):
                actions.append(Self.action(draworderKeyframes, model.slots))

            default:
                break
            }
        }
        
        let duration = Self.longestDuration(actions)
        actions.append(SKAction.wait(forDuration: duration))

        self.action = SKAction.group(actions)
    }
}

//MARK: - Bones Actions

extension Animation {
    
    static func action(_ model: BoneAnimationModel, _ bone: BoneModel) -> SKAction {
        
        let boneName = Bone.generateName(model.bone)
        return SKAction.run(SKAction.group(model.timelines.map({ action(timeline: $0, bone)})), onChildWithName: ".//\(boneName)", inheritDuration: true)
    }
    
    static func action(timeline: BoneAnimationModel.Timeline, _ bone: BoneModel) -> SKAction {
        
        var lastTime: TimeInterval = 0
        
        switch timeline {
        case .rotate(let rotateKeyframes):
            return SKAction.sequence(rotateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return action(keyframe: keyframe, duration: duration, bone.rotation)
            }))
            
        case .translate(let translateKeyframes):
            return SKAction.sequence(translateKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return action(keyframe: keyframe, duration: duration, bone.position)
            }))
            
        case .scale(let scaleKeyframes):
            return SKAction.sequence(scaleKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return action(keyframe: keyframe, duration: duration, bone.scale)
            }))
            
        case .shear(let shearKeyframes):
            return SKAction.sequence(shearKeyframes.map({ (keyframe) -> SKAction in
                
                let duration = keyframe.time - lastTime
                lastTime = keyframe.time
                return action(keyframe: keyframe, duration: duration, bone.shear)
            }))
        }
    }
    
    static func action(keyframe: BoneKeyframeRotateModel, duration: TimeInterval, _ defaultAngle: CGFloat) -> SKAction {
        
        let angle = (defaultAngle + keyframe.angle) * degreeToRadiansFactor
        let action = SKAction.rotate(toAngle: angle, duration: duration, shortestUnitArc: true)
        action.timingFunction = keyframe.curve.timingFunction

        return action
    }
    
    static func action(keyframe: BoneKeyframeTranslateModel, duration: TimeInterval, _ defaultPosition: CGPoint) -> SKAction {
        
        let positionX = defaultPosition.x + keyframe.position.x
        let positionY = defaultPosition.y + keyframe.position.y
        let actionX = SKAction.moveTo(x: positionX, duration: duration)
        let actionY = SKAction.moveTo(y: positionY, duration: duration)
        actionX.timingFunction = keyframe.curve.timingFunction
        actionY.timingFunction = keyframe.curve.timingFunctionSecond
        
        return SKAction.group([actionX, actionY])
    }
    
    static func action(keyframe: BoneKeyframeScaleModel, duration: TimeInterval, _ defaultScale: CGVector) -> SKAction {
        
        let actionX = SKAction.scaleX(to: keyframe.scale.dx, duration: duration)
        let actionY = SKAction.scaleY(to: keyframe.scale.dy, duration: duration)
        actionX.timingFunction = keyframe.curve.timingFunction
        actionY.timingFunction = keyframe.curve.timingFunctionSecond
     
        return SKAction.group([actionX, actionY])
    }
    
    static func action(keyframe: BoneKeyframeShearModel, duration: TimeInterval, _ defaultShear: CGVector) -> SKAction {
        
        //TODO: Implement shear action here in future
        return SKAction.wait(forDuration: 0.000001)
    }
}

//MARK: - Slot Actions

extension Animation {
    
    static func action(_ model: SlotAnimationModel) -> SKAction {
        
        var actions = [SKAction]()
        
        for timeline in model.timelines {
            
            switch timeline {
            case .attachment(let attachmentKeyframes):
                actions.append(action(attachmentKeyframes, model.slot))
                
            case .color(let colorKeyframes):
                actions.append(action(colorKeyframes, model.slot))
                
            default:
                break
                
                //TODO: - [Spine Pro] color + darkColor animation
            }
        }

        return SKAction.group(actions)
    }
    
    static func action(_ keyframes: [SlotKeyframeAttachmentModel], _ slot: String) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0

        for keyframe in keyframes {
            
            var keyframeActions = [SKAction]()
            
            let duration = keyframe.time - lastTime
            keyframeActions.append(SKAction.wait(forDuration: duration))
            
            let hideAction = SKAction.customAction(withDuration: 0) { (node, time) in
                
                for children in node.children {
                    
                    children.isHidden = true
                }
            }
            
            keyframeActions.append(SKAction.run(hideAction, onChildWithName: ".//\(Slot.generateName(slot))", inheritDuration: true))
            
            if let attachmentName = keyframe.name {
                
                let childName = ".//\(Slot.generateName(slot))/\(RegionAttachment.generateName(attachmentName))"
                keyframeActions.append(SKAction.run(SKAction.unhide(), onChildWithName: childName, inheritDuration: true))
            }
            
            let keyframeAction = SKAction.sequence(keyframeActions)
            actions.append(keyframeAction)
            
            lastTime = keyframe.time
        }
        
        return SKAction.sequence(actions)
    }
    
    static func action(_ keyframes: [SlotKeyframeColorModel], _ slot: String) -> SKAction {
        
        var actions = [SKAction]()
        let channels = keyframes.map({ $0.channels }).transposed()
        
        for (index, keyframes) in channels.enumerated() {
            
            let channelAction = action(keyframes, index: index)
            actions.append(channelAction)
        }
        
        let channelsAction = SKAction.group(actions)
        let colorAction = SKAction.run(channelsAction, onChildWithName: ".//\(Slot.generateName(slot))", inheritDuration: true)
        let duration = longestDuration(actions)

        return SKAction.group([colorAction, SKAction.wait(forDuration: duration)])
    }
    
    static func action(_ keyframes: [SlotKeyframeColorModel.Channel], index: Int) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        var lastValue: CGFloat = 1
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let change = keyframe.value - lastValue
            let timingFunction = keyframe.curve.timingFunction
            
            let channelAction = SKAction.customAction(withDuration: duration) { [lastValue, change, duration] node, time in

                guard let spriteNode = node.children.compactMap({ $0 as? SKSpriteNode }).first else {
                    return
                }
                
                let deltaTime = duration > 0 ? Float(time) / Float(duration) : 1
                let delta = timingFunction(deltaTime)
                let value = min(lastValue + change * CGFloat(delta), 1)
                
                spriteNode.color = spriteNode.color.updated(channel: value, index: index)
            }
  
            actions.append(channelAction)
            
            lastTime = keyframe.time
            lastValue = keyframe.value
        }

        return SKAction.sequence(actions)
    }
}

//MARK: - Event Actions

extension Animation {
    
    static func action(_ keyframes: [EventKeyfarameModel]) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let delayAction = SKAction.wait(forDuration: duration)
            let keyframeAction = action(keyframe)
            actions.append(SKAction.sequence([delayAction, keyframeAction]))
            
            lastTime = keyframe.time
        }
        
        //empty action in order to eliminate double-triggering of the last event
        actions.append(SKAction.sequence([SKAction.wait(forDuration: 0.01), SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in })]))
        
        return SKAction.sequence(actions)
    }
    
    static func action(_ keyframe: EventKeyfarameModel) -> SKAction {
        
        let event = event(keyframe)
        return SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in

            if let character = node as? Skeleton, let eventTrigger = character.eventTriggered {

                eventTrigger(event)
            }
        })
    }
    
    static func event(_ keyframe: EventKeyfarameModel) -> EventModel {
        
        return EventModel(with: keyframe)
    }
}

//MARK: - Draw Order Actions

extension Animation {
    
    static func action(_ keyframes: [DrawOrderKeyframeModel], _ slots: [SlotModel]) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        
        for keyframe in keyframes {
  
            let sotsReordered = reordered(slots: slots, offsets: keyframe.offsets)
            let duration = keyframe.time - lastTime
            let delayAction = SKAction.wait(forDuration: duration)
            
            var keyframeActions = [SKAction]()
            
            for (index, slot) in sotsReordered.enumerated() {
                
                let action = SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in
                    
                    guard let slot = node as? Slot else {
                        return
                    }
                    
                    slot.setOrder(to: index)
                })
                
                keyframeActions.append(SKAction.run(action, onChildWithName: ".//\(Slot.generateName(slot.name))", inheritDuration: true))
            }
            
            let keyframeAciton = SKAction.group(keyframeActions)
            actions.append(SKAction.sequence([delayAction, keyframeAciton]))

            lastTime = keyframe.time
        }
        
        return SKAction.sequence(actions)
    }
    
    static func reordered(slots: [SlotModel], offsets: [DrawOrderKeyframeModel.Offset]?) -> [SlotModel] {
        
        guard let offsets = offsets else {
            return slots
        }
        
        var result = slots
        
        for offset in offsets {
            
            guard let fromIndex = slots.firstIndex(where: { $0.name == offset.slot }) else {
                continue
            }
            
            let toIndex = fromIndex + offset.offset
            guard toIndex >= 0, toIndex < slots.count else {
                continue
            }
            
            result.rearrange(from: fromIndex, to: toIndex)
        }
        
        return result
    }
}

//MARK: - Helpers

extension Animation {
    
    static func longestDuration(_ actions: [SKAction]) -> TimeInterval {
        
        actions.reduce(0, { (duration, action) -> TimeInterval in
            
            return action.duration > duration ? action.duration : duration
        })
    }
}

