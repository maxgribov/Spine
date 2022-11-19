//
//  Animation.swift
//  Spine
//
//  Created by Max Gribov on 06/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

class Animation {
    
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
                    
                    return BoneAnimationBuilder.action(animaton, bone)
                }
                actions.append(contentsOf: bonesActions)
                
            case .slots(let slotsAnimationModels):
                let slotsAnimations = slotsAnimationModels.map({ (slotAnimationModel) -> SKAction in
                    
                    return SlotAnimationBuilder.action(slotAnimationModel)
                })
                actions.append(contentsOf: slotsAnimations)
                
            case .events(let eventsKeyframes):
                actions.append(EventAnimationBuilder.action(eventsKeyframes))
                
            case .drawOrder(let draworderKeyframes):
                actions.append(DrawOrderAnimationBuilder.action(draworderKeyframes, model.slots))

            default:
                break
            }
        }
        
        let longestDuration = actions.reduce(0, { (duration, action) -> TimeInterval in
            
            return action.duration > duration ? action.duration : duration
        })
        
        actions.append(SKAction.wait(forDuration: longestDuration))

        self.action = SKAction.group(actions)
    }
}

func setTiming(_ action: SKAction, _ curve: CurveModel)  {
    
    switch curve {
    case .linear: action.timingMode = .linear
    case .stepped: action.timingFunction = { time in return time < 1.0 ? 0 : 1.0 }
    case .bezier(let bezierModel): action.timingFunction = BezierCurveSolver(bezierModel).timingFunction()
        //FIXME: - real implementation required with two bezier curves for x and y
    case .bezier2(let bezierModel1, _): action.timingFunction = BezierCurveSolver(bezierModel1).timingFunction()
    }
}

//MARK: - Bones Actions

class BoneAnimationBuilder {
    
    class func action(_ model: BoneAnimationModel, _ bone: BoneModel) -> SKAction {
        
        let boneName = Bone.generateName(model.bone)
        return SKAction.run(SKAction.group(model.timelines.map({ BoneAnimationBuilder.action(timeline: $0, bone)})), onChildWithName: ".//\(boneName)", inheritDuration: true)
    }
    
    class func action(timeline: BoneAnimationModel.Timeline, _ bone: BoneModel) -> SKAction {
        
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
        let action = SKAction.rotate(toAngle: angle, duration: duration, shortestUnitArc: true)
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
        
        let action = SKAction.group([SKAction.scaleX(to: keyframe.scale.dx, duration: duration),
                                     SKAction.scaleY(to: keyframe.scale.dy, duration: duration)])
        setTiming(action, keyframe.curve)

        return action
    }
    
    class func action(keyframe: BoneKeyframeShearModel, duration: TimeInterval, _ defaultShear: CGVector) -> SKAction {
        
        //TODO: Implement shear action here in future
        return SKAction.wait(forDuration: 0.000001)
    }
}

//MARK: - Slot Actions

class SlotAnimationBuilder {
    
    class func action(_ model: SlotAnimationModel) -> SKAction {
        
        var actions = [SKAction]()
        
        for timeline in model.timelines {
            
            switch timeline {
            case .attachment(let attachmentKeyframes):
                actions.append(SlotAnimationBuilder.action(attachmentKeyframes, model.slot))
                
            case .color(let colorKeyframes):
                actions.append(SlotAnimationBuilder.action(colorKeyframes, model.slot))
                
            default:
                break
            }
        }

        return SKAction.group(actions)
    }
    
    class func action(_ keyframes: [SlotKeyframeAttachmentModel], _ slot: String) -> SKAction {
        
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
    
    class func action(_ keyframes: [SlotKeyframeColorModel], _ slot: String) -> SKAction {
        
        var actions = [SKAction]()
        let channels = keyframes.map({ $0.channels }).transposed()
        
        for (index, keyframes) in channels.enumerated() {
            
            let channelAction = Self.action(keyframes, index: index)
            actions.append(channelAction)
        }
        
        let colorAction = SKAction.group(actions)

        let longestDuration = actions.reduce(0, { (duration, action) -> TimeInterval in
            
            return action.duration > duration ? action.duration : duration
        })

        let result = SKAction.run(colorAction, onChildWithName: ".//\(Slot.generateName(slot))", inheritDuration: true)

        return SKAction.group([result, SKAction.wait(forDuration: longestDuration)])
    }
    
    class func action(_ keyframes: [SlotKeyframeColorModel.Channel], index: Int) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        var lastValue: CGFloat = 0
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let change = keyframe.value - lastValue
            let timingFunction = keyframe.curve.timingFunction
            
            //FIXME: bezier curve animation stops working after a little while for some reason
            let channelAction = SKAction.customAction(withDuration: duration) { [timingFunction, lastValue, change] node, time in

                if let spriteNode = node.children.compactMap({ $0 as? SKSpriteNode }).first {
                    
                    let delta = timingFunction(Float(time))
                    let value = min(lastValue + change * CGFloat(delta), 1)
                    
                    spriteNode.color = spriteNode.color.updated(channel: value, index: index)
                }
            }
  
            actions.append(channelAction)
            
            lastTime = keyframe.time
            lastValue = keyframe.value
        }

        actions.removeFirst()
        return SKAction.sequence(actions)
    }
}

//MARK: - Event Actions

class EventAnimationBuilder {
    
    class func action(_ keyframes: [EventKeyfarameModel]) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let delayAction = SKAction.wait(forDuration: duration)
            let keyframeAction = EventAnimationBuilder.action(keyframe)
            actions.append(SKAction.sequence([delayAction, keyframeAction]))
            
            lastTime = keyframe.time
        }
        
        //empty action in order to eliminate double-triggering of the last event
        actions.append(SKAction.sequence([SKAction.wait(forDuration: 0.01), SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in })]))
        
        return SKAction.sequence(actions)
    }
    
    class func action(_ keyframe: EventKeyfarameModel) -> SKAction {
        
        let event = EventAnimationBuilder.event(with: keyframe)
        return SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in

            if let character = node as? Skeleton, let eventTrigger = character.eventTriggered {

                eventTrigger(event)
            }
        })
    }
    
    class func event(with keyframe: EventKeyfarameModel) -> EventModel {
        
        return EventModel(with: keyframe)
    }
}

//MARK: - Draw Order Actions

class DrawOrderAnimationBuilder {
    
    class func action(_ keyframes: [DrawOrderKeyframeModel], _ slots: [SlotModel]) -> SKAction {
        
        var slotsData = [SlotData]()
        
        for (index, slot) in slots.enumerated() {
            
            slotsData.append(SlotData(slot.name, order: index))
        }
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let delayAction = SKAction.wait(forDuration: duration)
            if let keyframeAction = DrawOrderAnimationBuilder.action(&slotsData, keyframe.offsets) {
                
                actions.append(SKAction.sequence([delayAction, keyframeAction]))
                
            } else {
                
                actions.append(delayAction)
            }

            lastTime = keyframe.time
        }
        
        return SKAction.sequence(actions)
    }
    
    fileprivate class func action(_ slotsData: inout [SlotData], _ offsets: [DrawOrderKeyframeModel.Offset]?) -> SKAction? {
        
        let slotsNewOrders = calculateSlotsNewOrders(slotsData, offsets)
        
        var actions = [SKAction]()
        
        for slotNewOrder in slotsNewOrders {
            
            let action = SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in
                
                if let slot = node as? Slot {
                    
                    slot.setOrder(to: slotNewOrder.order)
                }
            })
            
            actions.append(SKAction.run(action, onChildWithName: ".//\(Slot.generateName(slotNewOrder.name))", inheritDuration: true))
        }
        
        applyNewOrders(&slotsData, slotsNewOrders)
        
        if actions.count > 0 {
            
            return SKAction.group(actions)
            
        } else {
            
            return nil
        }
    }
}

fileprivate struct SlotData {
    
    let initialOrder: Int
    let name: String
    var order: Int
    
    init(_ name: String, order: Int) {
        
        self.initialOrder = order
        self.name = name
        self.order = self.initialOrder
    }
}

fileprivate struct SlotNewOrder {
    
    let name: String
    let order: Int
    
    init(_ name: String, newOrder: Int ) {
        
        self.name = name
        self.order = newOrder
    }
}

fileprivate func calculateSlotsNewOrders(_ slots: [SlotData], _ offsets: [DrawOrderKeyframeModel.Offset]?) -> [SlotNewOrder] {
    
    var orders = [SlotNewOrder]()
    
    if let offsets = offsets {
        
        var slotsOrdered = slots.sorted(by: { $0.order < $1.order })
        
        for slot in slotsOrdered {
            
            guard let shift = offsets.first(where: { $0.slot == slot.name }),
                let index = slotsOrdered.firstIndex(where: { $0.name == slot.name }) else {
                    
                    continue
            }
            
            let newIndex = slot.initialOrder + shift.offset
            
            slotsOrdered.remove(at: index)
            slotsOrdered.insert(slot, at: newIndex)
        }
        
        for (index, slot) in slotsOrdered.enumerated() {
            
            if slot.order != index {
                
                orders.append(SlotNewOrder(slot.name, newOrder: index ))
            }
        }
        
    } else {

        for slot in slots {
            
            if slot.initialOrder != slot.order {
                
                orders.append(SlotNewOrder(slot.name, newOrder: slot.initialOrder))
            }
        }
    }
    
    return orders
}

fileprivate func applyNewOrders(_ slotsData: inout [SlotData], _ orders: [SlotNewOrder]) {
    
    for order in orders {
        
        if var slotData = slotsData.first(where: { $0.name == order.name }) {
            
            slotData.order = order.order
            if let index = slotsData.firstIndex(where: { $0.name == slotData.name }){
                
                slotsData[index] = slotData
            }
        }
    }
}
