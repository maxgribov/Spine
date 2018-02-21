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
                actions.append(contentsOf: bonesAnimationModels.map({ (boneAnimationModel) -> SKAction in
                    
                    let bone = model.bones?.filter({ $0.name == boneAnimationModel.bone }).first
                    return BoneAnimationBuilder.action(boneAnimationModel, bone)
                }))
            case .slots(let slotsAnimationModels):
                actions.append(contentsOf: slotsAnimationModels.map({ (slotAnimationModel) -> SKAction in
                    
                    return SlotAnimationBuilder.action(slotAnimationModel)
                }))
            case .events(let eventsKeyframes):
                actions.append(EventAnimationBuilder.action(eventsKeyframes))
            case .draworder(let draworderKeyframes):
                actions.append(DrawOrderAnimationBuilder.action(draworderKeyframes, model.slots))

            default:
                continue
            }
        }
        
        let longestDuration = actions.reduce(0, { (duration, action) -> TimeInterval in
            
            return action.duration > duration ? action.duration : duration
        })
        
        let actionsCorrected = actions.map({ (action) -> SKAction in
            
            let delayDuration = longestDuration - action.duration
            return delayDuration > 0 ? SKAction.sequence([action, SKAction.wait(forDuration: delayDuration)]) : action
        })
        
        self.action = SKAction.group(actionsCorrected)
    }
}

func setTiming(_ action: SKAction, _ curve: CurveModelType)  {
    
    switch curve {
    case .linear: action.timingMode = .linear
    case .stepped: action.timingFunction = { time in return time < 1.0 ? 0 : 1.0 }
    case .bezier(let bezierModel): action.timingFunction = BezierCurveSolver(bezierModel).timingFunction()
    }
}

//MARK: - Bones Actions

class BoneAnimationBuilder {
    
    class func action(_ model: BoneAnimationModel, _ bone: BoneModel?) -> SKAction {
        
        guard let bone = bone else {
            
            return SKAction()
        }
        
        let boneName = Bone.generateName(model.bone)
        return SKAction.run(SKAction.group(model.timelines.map({ BoneAnimationBuilder.action(timeline: $0, bone)})), onChildWithName: "//\(boneName)", inheritDuration: true)
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
            }
        }
        
        return SKAction.group(actions)
    }
    
    class func action(_ keyframes: [SlotKeyframeAttachmentModel], _ slot: String) -> SKAction {
        
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        var prevAttachmentName: String?
        
        for keyframe in keyframes {
            
            var keyframeActions = [SKAction]()
            
            let duration = keyframe.time - lastTime
            keyframeActions.append(SKAction.wait(forDuration: duration))
            
            if let prevAttachmentName = prevAttachmentName {
                
                keyframeActions.append(SKAction.run(SKAction.hide(), onChildWithName: prevAttachmentName, inheritDuration: true))
            }
            
            if let attachmentName = keyframe.name {
                
                let childName = "//\(Slot.generateName(slot))/\(RegionAttachment.generateName(attachmentName))"
                keyframeActions.append(SKAction.run(SKAction.unhide(), onChildWithName: childName, inheritDuration: true))
                
                prevAttachmentName = childName
            }
            
            let keyframeAction = SKAction.sequence(keyframeActions)
            actions.append(keyframeAction)
            
            lastTime = keyframe.time
        }
        
        return SKAction.sequence(actions)
    }
    
    class func action(_ keyframes: [SlotKeyframeColorModel], _ slot: String) -> SKAction {
        
        //color action
        var actions = [SKAction]()
        var lastTime: TimeInterval = 0
        
        for keyframe in keyframes {
            
            let duration = keyframe.time - lastTime
            let action = SKAction.colorize(with: createColor(with: keyframe.color), colorBlendFactor: 1.0, duration: duration)
            setTiming(action, keyframe.curve)
            
            actions.append(action)
            
            lastTime = keyframe.time
        }
        
        let colorAction = SKAction.sequence(actions)
        
        let slotColorAction = SKAction.customAction(withDuration: 0) { (node, time) in
            
            let sprites = node.children.filter { $0 is SKSpriteNode }
            
            for sprite in sprites {
                
                sprite.run(colorAction)
            }
        }
        
        return SKAction.run(slotColorAction, onChildWithName: "//\(Slot.generateName(slot))", inheritDuration: true)
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
        
        return EventModel(keyframe.event, keyframe.int, keyframe.float, keyframe.string)
    }
}

//MARK: - Draw Order Actions

class DrawOrderAnimationBuilder {
    
    class func action(_ keyframes: [DrawOrderKeyframeModel], _ slots: [SlotModel]?) -> SKAction {
        
        guard let slots = slots else {
            
            return SKAction()
        }
        
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
    
    fileprivate class func action(_ slotsData: inout [SlotData], _ offsets: [DrawOrderOffsetModel]?) -> SKAction? {
        
        let slotsNewOrders = calculateSlotsNewOrders(slotsData, offsets)
        
        var actions = [SKAction]()
        
        for slotNewOrder in slotsNewOrders {
            
            let action = SKAction.customAction(withDuration: 0, actionBlock: { (node, time) in
                
                if let slot = node as? Slot {
                    
                    slot.setOrder(to: slotNewOrder.order)
                }
            })
            
            actions.append(SKAction.run(action, onChildWithName: "//\(Slot.generateName(slotNewOrder.name))", inheritDuration: true))
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

fileprivate func calculateSlotsNewOrders(_ slots: [SlotData], _ offsets: [DrawOrderOffsetModel]?) -> [SlotNewOrder] {
    
    var orders = [SlotNewOrder]()
    
    if let offsets = offsets {
        
        var slotsOrdered = slots.sorted(by: { $0.order < $1.order })
        
        for slot in slotsOrdered {
            
            guard let shift = offsets.first(where: { $0.slot == slot.name }),
                let index = slotsOrdered.index(where: { $0.name == slot.name }) else {
                    
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
            if let index = slotsData.index(where: { $0.name == slotData.name }){
                
                slotsData[index] = slotData
            }
        }
    }
}
