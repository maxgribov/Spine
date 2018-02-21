//
//  Skeleton+Skins.swift
//  Spine
//
//  Created by Max Gribov on 20/02/2018.
//  Copyright © 2018 Max Gribov. All rights reserved.
//

import SpriteKit

extension Skeleton {
    
    /**
     Applies a skin with a specific name if possible. Attachments that belong to the 'default' skin will be added to the slots anyway.
     
     See more information about skins:
     http://esotericsoftware.com/spine-skins
     
     - parameter named: The name of the skin you want to apply.
     If a skin with that name is not found or skipped it will be added only attachments for the 'default' skin.
     */
    public func applySkin(named: String? = nil) {
        
        var skinsNames: Set = ["default"]
        
        if let named = named {
            
            skinsNames.insert(named)
        }
        
        guard let skins = skins?.filter({ skinsNames.contains($0.model.name) }) else {
            
            return
        }
        
        for skin in skins {
            
            guard let slotsModels = skin.model.slots else {
                
                continue
            }
            
            for slotModel in slotsModels {
                
                guard let slot = slots?.first(where: { $0.model.name == slotModel.name }),
                    let attachmentsModels = slotModel.attachments else {
                        
                        continue
                }
                
                var boundingBoxes = [BoundingBoxAttachment]()
                
                for attachmentModel in attachmentsModels {
                    
                    if let attachment = skin.attachment(attachmentModel) {
                        
                        if let region = attachment as? RegionAttachment {
                            
                            slot.addChild(region)
                            
                        } else if let boundingBox = attachment as? BoundingBoxAttachment {
                            
                            boundingBoxes.append(boundingBox)
                            
                        } else if let point = attachment as? PointAttachment {
                            
                            slot.addChild(point)
                        }
                    }
                }

                if boundingBoxes.count > 1 {
                    
                    let physicBodies = boundingBoxes.flatMap({ $0.physicsBody })
                    let compositePhysicBody = SKPhysicsBody(bodies: physicBodies)
                    compositePhysicBody.isDynamic = false
                    slot.physicsBody = compositePhysicBody
                    
                } else {
                    
                    if let boundingBox = boundingBoxes.first {
                        
                        slot.physicsBody = boundingBox.physicsBody
                    }
                }
                
                slot.dropToDefaults()
            }
        }
    }
}
