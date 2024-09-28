// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Spine",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)
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
                        .process("Resources/slotColorKeyframes.json"),
                        .process("Resources/eventKeyframes.json"),
                        .process("Resources/drawOrderKeyframes.json")
                    ])
    ]
)
