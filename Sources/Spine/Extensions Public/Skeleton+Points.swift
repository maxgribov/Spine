//
//  Skeleton+Points.swift
//  Spine
//
//  Created by Max Gribov on 21/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

public extension Skeleton {
    
    /**
     Representation of Spine's *Point Attachments*

     Not all point attachments in the slot can be active.
     This property returns **all points** attached to all slots regardless of whether they are currently active or not.
     
     Each point attachment represented with 'SKNode` class.
     
     See more information about point attachments:
     http://esotericsoftware.com/spine-point-attachments
     */
    var points: [SKNode]? {
        
        slots.compactMap { slot in

            slot.children.compactMap { node in

                guard let point = node as? PointAttachment else {
                    return nil
                }
                
                return point
            }
            
        }.reduce([SKNode]()) { result, nodes in

            var resultMutable = result
            resultMutable.append(contentsOf: nodes)

            return resultMutable
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
    var activePoints: [SKNode]? {
        
       slots.compactMap { slot in
            
            slot.children.first(where: { node in
                
                guard let name = node.name, let attachment = slot.model.attachment else {
                    return false
                }
                
                return name.range(of: attachment) != nil
            })
            
        }.compactMap { node in
            
            guard let point = node as? PointAttachment else {
                return nil
            }
            
            return point
        }
    }
}
