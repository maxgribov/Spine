// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Spine",
    platforms: [
        .iOS(.v8), .macOS(.v10_10), .tvOS(.v9), .watchOS(.v3)
    ],
    products: [
        .library(name: "Spine", targets: ["Spine"]),
    ],
    targets: [
        .target(name: "Spine"),
        .testTarget(name: "SpineTests",
                    dependencies: ["Spine"],
                    resources: [
                        .process("Resources/spineboy-ess.json"),
                        .process("Resources/skeleton.json"),
                        .process("Resources/bones.json"),
                        .process("Resources/slots.json"),
                        .process("Resources/skins.json"),
                        .process("Resources/events.json"),
                        .process("Resources/rotateBoneKeyframes.json"),
                        .process("Resources/translateBoneKeyframes.json"),
                        .process("Resources/slotAttachmentKeyframes.json"),
                        .process("Resources/slotColorKeyframes.json")
                    ])
    ]
)
