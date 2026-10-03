import SpriteKit

/// Validated immutable scalar keys, independent of JSON and SpriteKit scheduling.
struct MeshScalarTimeline {
    enum Curve {
        case linear, stepped
        /// Absolute (time,value) control points for this channel.
        case bezier(SIMD2<Float>, SIMD2<Float>)
    }
    struct Key {
        let time: Float
        let value: Float
        let curve: Curve
        init(_ time: Float, _ value: Float, curve: Curve = .linear) {
            self.time = time; self.value = value; self.curve = curve
        }
    }
    private struct Frame {
        let time: Float
        let value: Float
        let points: [SIMD2<Float>]
        let stepped: Bool
    }
    private let frames: [Frame]
    let duration: TimeInterval

    init(keys: [Key], path: String = "/runtime/timeline") throws {
        var previous: Float = -1
        for key in keys {
            guard key.time.isFinite, key.value.isFinite, key.time >= 0, key.time > previous else {
                throw SpineRuntimeError(.invalidTimeline, path: path, message: "Timeline keys must be finite and strictly increasing.")
            }
            if case let .bezier(a, b) = key.curve {
                guard a.x.isFinite, a.y.isFinite, b.x.isFinite, b.y.isFinite else {
                    throw SpineRuntimeError(.invalidTimeline, path: path, message: "Bezier control points must be finite.")
                }
            }
            previous = key.time
        }
        duration = TimeInterval(keys.last?.time ?? 0)
        frames = keys.enumerated().map { index, key in
            var points: [SIMD2<Float>] = []
            var stepped = false
            if case .stepped = key.curve { stepped = true }
            if index + 1 < keys.count {
                let next = keys[index + 1]
                if case let .bezier(a, b) = key.curve {
                    let from = SIMD2(key.time, key.value), to = SIMD2(next.time, next.value)
                    // Spine 4.1 approximates a cubic with ten linear segments.
                    points = (1...10).map { step in
                        let t = Float(step) / 10, u = 1 - t
                        return u*u*u*from + 3*u*u*t*a + 3*u*t*t*b + t*t*t*to
                    }
                } else { points = [SIMD2(next.time, next.value)] }
            }
            return Frame(time: key.time, value: key.value, points: points, stepped: stepped)
        }
    }

    func sample(_ time: Float, default defaultValue: Float, cursor: inout Int) -> Float {
        guard !frames.isEmpty, time >= frames[0].time else { return defaultValue }
        // Execution cursors are owned by a Skeleton, never by an SKAction closure.
        while cursor + 1 < frames.count && frames[cursor + 1].time <= time { cursor += 1 }
        while cursor > 0 && frames[cursor].time > time { cursor -= 1 }
        let frame = frames[cursor]
        if frame.stepped { return frame.value }
        var previous = SIMD2(frame.time, frame.value)
        for point in frame.points {
            if time <= point.x {
                return point.x > previous.x
                    ? previous.y + (point.y - previous.y) * (time - previous.x) / (point.x - previous.x)
                    : point.y
            }
            previous = point
        }
        return previous.y
    }
}

struct MeshClip {
    enum Target {
        case boneX(Int), boneY(Int), boneRotation(Int), boneScaleX(Int), boneScaleY(Int)
        case deform(slot: Int, component: Int)
    }
    struct Channel {
        let target: Target
        let timeline: MeshScalarTimeline
    }
    struct Event {
        let time: TimeInterval
        let value: EventModel
    }
    let name: String
    let channels: [Channel]
    let events: [Event]
    let duration: TimeInterval

    init(name: String, channels: [Channel], events: [Event] = []) throws {
        var previous: TimeInterval = -1
        for event in events {
            guard event.time.isFinite, event.time >= 0, event.time > previous else {
                throw SpineRuntimeError(.invalidTimeline, path: "/animations/" + SpineRuntimeError.pointerComponent(name) + "/events",
                                        message: "Event keys must be finite and strictly increasing.")
            }
            previous = event.time
        }
        self.name = name; self.channels = channels; self.events = events
        duration = max(channels.map { $0.timeline.duration }.max() ?? 0, events.last?.time ?? 0)
    }
}

/// Internal compiled input. Only tests construct this before the phase-3 compiler exists.
struct CompiledMeshSkeleton {
    let bones: [BoneModel]
    let slots: [SlotModel]
    let deformComponentCounts: [Int]
    let clips: [MeshClip]
    let skinNames: [String]
}
