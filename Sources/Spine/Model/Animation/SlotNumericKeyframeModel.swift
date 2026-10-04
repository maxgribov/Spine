import Foundation

struct SlotNumericKeyframeModel: Decodable {
    let time:TimeInterval
    let color:ColorModel?
    let value:Float?
    let curves:[CurveModel]
    enum Keys:String,CodingKey {case time,color,value,curve}
    init(from decoder:Decoder)throws {
        let c=try decoder.container(keyedBy:Keys.self)
        time=try c.decodeIfPresent(TimeInterval.self,forKey:.time) ?? 0
        color=try c.decodeIfPresent(String.self,forKey:.color).map {ColorModel(value:$0.count==6 ? $0+"ff":$0)}
        value=try c.decodeIfPresent(Float.self,forKey:.value)
        if !c.contains(.curve) {curves=[.linear]}
        else if (try? c.decode(String.self,forKey:.curve)) == "stepped" {curves=[.stepped]}
        else {
            let values=try c.decode([Float].self,forKey:.curve)
            guard !values.isEmpty,values.count.isMultiple(of:4) else {
                throw DecodingError.dataCorrupted(.init(codingPath:c.codingPath+[Keys.curve],debugDescription:"Invalid curve component count."))
            }
            curves=stride(from:0,to:values.count,by:4).map {.bezier(.init(p0:values[$0],p1:values[$0+1],p2:values[$0+2],p3:values[$0+3]))}
        }
    }
}
