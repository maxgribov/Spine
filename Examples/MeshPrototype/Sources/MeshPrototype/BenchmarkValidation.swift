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
