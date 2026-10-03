import Foundation

public struct SpineRuntimeError: Error, LocalizedError {
    public enum Code: String {
        case unsupportedPlatform, unsupportedVersion, unsupportedFeature
        case invalidData, invalidGeometry, invalidTimeline, linkedMeshCycle, missingAttachment
        case missingTexture, invalidTextureRegion, missingSkin, missingAnimation
        case concurrentClip, wrongSkeleton, invalidRenderContext, mutatedNodeContract // wrongSkeleton is reserved
    }
    public let code: Code
    public let path: String
    public let message: String
    public var errorDescription: String? { message }

    init(_ code: Code, path: String, message: String) {
        self.code = code; self.path = path; self.message = message
    }

    static func pointerComponent(_ value: String) -> String {
        value.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
    }
}
