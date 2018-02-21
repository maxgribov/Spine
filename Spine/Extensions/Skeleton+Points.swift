//
//  Skeleton+Points.swift
//  Spine
//
//  Created by Max Gribov on 21/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {
    
    /**
     Representation of Spine's *Point Attachments*

     Not all point attachments in the slot can be active.
     This property returns **all points** attached to all slots regardless of whether they are currently active or not.
     
     Each point attachment represented with 'SKNode` class.
     
     See more information about point attachments:
     http://esotericsoftware.com/spine-point-attachments
     */
    public var points: [SKNode]? {
        get {
            return slots?.flatMap({ (slot) -> [SKNode]? in

                return slot.children.flatMap({ (node) -> SKNode? in

                    guard let point = node as? PointAttachment else {

                        return nil
                    }

                    return point
                })
            }).reduce([SKNode](), { (result, nodes) -> [SKNode] in

                var resultMutable = result
                resultMutable.append(contentsOf: nodes)

                return resultMutable
            })
        }
    }
    
    /**
     Representation of Spine's *Point Attachments*

     Not all point attachments in the slot can be active.
     This property returns **only active** points attached to all slots.
     
     Each point attachment represented with 'SKNode` class.
     
     See more information about point attachments:
     http://esotericsoftware.com/spine-point-attachments
     */
    public var activePoints: [SKNode]? {
        get {
            
            return slots?.flatMap({ (slot) -> SKNode? in
                
                return slot.children.first(where: { (node) -> Bool in
                    
                    guard let name = node.name, let attachment = slot.model.attachment else {
                        
                        return false
                    }
                    
                    return name.range(of: attachment) != nil
                    
                })
                
            }).flatMap({ (node) -> SKNode? in
                
                guard let point = node as? PointAttachment else {
                    
                    return nil
                }
                
                return point
            })
        }
    }
}
