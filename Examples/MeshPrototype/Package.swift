// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MeshPrototype",
    platforms: [.macOS(.v10_15)],
    products: [.executable(name: "MeshPrototype", targets: ["MeshPrototype"])],
    targets: [
        .target(name: "TriangleRenderer"),
        .executableTarget(name: "MeshPrototype", dependencies: ["TriangleRenderer"],
                          resources: [.copy("Resources")]),
        .testTarget(name: "TriangleRendererTests", dependencies: ["TriangleRenderer"])
    ]
)
