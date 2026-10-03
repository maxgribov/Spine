import Foundation

/// Spine 4.1 attachment timelines; retained by the shared model and ignored by legacy playback.
struct AttachmentTimelineModel {
    let skin: String
    let slot: String
    let attachment: String
    let deform: [DeformKeyframeModel]
    let path: String

    static func decode(_ container: KeyedDecodingContainer<SpineNameKey>) throws -> [Self] {
        var timelines: [Self] = []
        for skin in container.allKeys {
            let slots = try container.nestedContainer(keyedBy:SpineNameKey.self,forKey:skin)
            for slot in slots.allKeys {
                let attachments = try slots.nestedContainer(keyedBy:SpineNameKey.self,forKey:slot)
                for attachment in attachments.allKeys {
                    let channels = try attachments.nestedContainer(keyedBy:SpineNameKey.self,forKey:attachment)
                    let key = SpineNameKey(stringValue:"deform")!
                    if channels.contains(key) {
                        timelines.append(.init(skin:skin.stringValue,slot:slot.stringValue,attachment:attachment.stringValue,
                            deform:try channels.decode([DeformKeyframeModel].self,forKey:key),
                            path:SpineFeatureIssue.pointer(channels.codingPath+[key])))
                    }
                }
            }
        }
        return timelines
    }
}

struct NumericTimelineModel {
    struct Key {
        let time: TimeInterval
        let values: [Float]
        let curves: [CurveModel]
    }
    let name: String
    let keys: [Key]

    init<T: CurvedKeyframeModel>(_ name: String, frames: [T]) {
        self.name = name
        keys = frames.map { .init(time:$0.time,values:$0.values,curves:[$0.curve]) }
    }
    init(name:String,keys:[Key]) { self.name=name; self.keys=keys }
}

/// Used only for previously ignored 4.1 single-axis bone channels.
struct ScalarBoneKeyframeModel: Decodable, CurvedKeyframeModel {
    let time: TimeInterval
    let value: Float?
    var curve: CurveModel
    var values: [Float] { [value ?? 0] }
    enum CodingKeys:String,CodingKey { case time,value,curve }
    init(from decoder:Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        time=try c.decodeIfPresent(TimeInterval.self,forKey:.time) ?? 0
        value=try c.decodeIfPresent(Float.self,forKey:.value)
        curve=try c.decodeIfPresent(CurveModel.self,forKey:.curve) ?? .linear
    }
}
