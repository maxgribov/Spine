import AppKit

/// Post-timing guard against benchmarking blank/misprojected geometry. Detailed
/// shared-edge correctness remains the responsibility of --verify.
@discardableResult
func validateBenchmarkImages(output: URL) throws -> [[String: Any]] {
    var results: [[String: Any]] = []
    func load(_ name: String) throws -> CGImage {
        let data = try Data(contentsOf: output.appendingPathComponent(name))
        guard let image = NSBitmapImageRep(data: data)?.cgImage else { throw PrototypeError("Invalid benchmark PNG: \(name)") }
        return image
    }
    for round in 1...2 {
        for count in [1,10,50] {
            let prefix = "gpu-r\(round)-\(count)"
            let reference = try load("\(prefix)-mesh.png"), candidate = try load("\(prefix)-triangle.png")
            guard reference.width == candidate.width, reference.height == candidate.height else { throw PrototypeError("Benchmark image sizes differ") }
            let a = try bitmap(reference), b = try bitmap(candidate)
            var foreground = 0, different = 0, maximum = 0
            for pixel in 0..<(a.count/4) {
                let offset = pixel*4
                let foregroundDifference = max(abs(Int(a[offset])-Int(a[0])), max(abs(Int(a[offset+1])-Int(a[1])), abs(Int(a[offset+2])-Int(a[2]))))
                if foregroundDifference > 8 { foreground += 1 }
                var delta = 0
                for channel in 0..<4 { delta = max(delta, abs(Int(a[offset+channel])-Int(b[offset+channel]))) }
                maximum = max(maximum, delta)
                if delta > 4 { different += 1 }
            }
            let fraction = Double(different)/Double(max(foreground,1))
            let passed = foreground > 1000 && fraction < 0.01
            results.append(["round": round, "actors": count, "foregroundPixels": foreground,
                            "pixelsDifferingOver4": different, "fractionOfForeground": fraction,
                            "rawMaximumChannelDifference": maximum, "passed": passed])
            guard passed else {
                throw PrototypeError("Benchmark render validation failed: \(prefix), \(different) differing pixels / \(foreground) foreground pixels")
            }
        }
    }
    try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        .write(to: output.appendingPathComponent("image-validation.json"))
    print("Benchmark render validation: all 6 mesh/triangle image pairs passed (<1% of foreground differing by >4/255).")
    return results
}

/// Compare the same deterministic frame across two renderer revisions/settings.
/// Unlike the bounds comparison, this allows no displaced silhouette pixels.
func validateBenchmarkRevision(reference: URL, output: URL) throws {
    var results: [[String: Any]] = []
    for round in 1...2 {
        for count in [1,10,50] {
            for mode in ["mesh", "triangle"] {
                let name = "gpu-r\(round)-\(count)-\(mode).png"
                func load(_ directory: URL) throws -> CGImage {
                    let data = try Data(contentsOf: directory.appendingPathComponent(name))
                    guard let image = NSBitmapImageRep(data: data)?.cgImage else { throw PrototypeError("Invalid PNG: \(name)") }
                    return image
                }
                let old = try load(reference), new = try load(output)
                guard old.width == new.width, old.height == new.height else { throw PrototypeError("Revision image sizes differ") }
                let a = try bitmap(old), b = try bitmap(new)
                var maximum = 0, different = 0
                for index in a.indices {
                    let delta = abs(Int(a[index])-Int(b[index]))
                    maximum = max(maximum, delta)
                    if delta > 2 { different += 1 }
                }
                results.append(["image": name, "maximumChannelDifference": maximum, "channelsDifferingOver2": different])
                guard different == 0 else { throw PrototypeError("Revision render differs: \(name), \(different) channels >2/255") }
            }
        }
    }
    try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
        .write(to: output.appendingPathComponent("revision-validation.json"))
    print("Revision validation: 12 image pairs passed, no channels differing by >2/255.")
}

/// Strict revision comparison on opaque-background SKRenderer captures.
func validateGroupedBenchmarkImages(output: URL) throws {
    var results: [[String: Any]] = []
    for round in 1...2 {
        for count in [1,10,50] {
            func load(_ size: Int) throws -> CGImage {
                let name = "gpu-r\(round)-\(count)-g\(size).png"
                let data = try Data(contentsOf: output.appendingPathComponent(name))
                guard let image = NSBitmapImageRep(data: data)?.cgImage else { throw PrototypeError("Invalid PNG: \(name)") }
                return image
            }
            let reference = try load(1), a = try bitmap(reference)
            let foreground = stride(from: 0,to: a.count,by: 4).filter { offset in
                (0..<3).contains { abs(Int(a[offset+$0])-Int(a[$0])) > 8 }
            }.count
            guard foreground > 1000 else { throw PrototypeError("Grouped benchmark reference is blank") }
            for size in [2,4] {
                let candidate = try load(size)
                guard reference.width == candidate.width, reference.height == candidate.height else { throw PrototypeError("Grouped capture sizes differ") }
                let b = try bitmap(candidate)
                var maximum = 0, different = 0
                for index in a.indices {
                    let delta = abs(Int(a[index])-Int(b[index]))
                    maximum = max(maximum,delta)
                    if delta > 2 { different += 1 }
                }
                results.append(["round": round,"actors": count,"groupSize": size,"foregroundPixels": foreground,
                                "maximumChannelDifference": maximum,"channelsDifferingOver2": different])
                guard different == 0 else { throw PrototypeError("Grouped benchmark r\(round)/\(count)/g\(size): \(different) channels >2/255, max \(maximum)") }
            }
        }
    }
    try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted,.sortedKeys])
        .write(to: output.appendingPathComponent("group-image-validation.json"))
    print("Grouped benchmark: 12 image pairs passed, no channels differing by >2/255.")
}
