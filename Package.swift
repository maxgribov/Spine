// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Spine",
    products: [
        .library(name: "Spine", targets: ["Spine"]),
    ],
    targets: [
        .target(name: "Spine", path: "Spine"),
    ]
)
