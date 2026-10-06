import Foundation
@main struct MemoryMain {
    static func main() throws {
        let report = try runMemoryProbe(distinct: CommandLine.arguments.contains("--distinct"))
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: CommandLine.arguments.last!))
    }
}
