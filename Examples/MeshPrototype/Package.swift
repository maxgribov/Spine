// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MeshPrototype",
    platforms: [.macOS(.v10_15)],
    products: [.executable(name: "MeshPrototype", targets: ["MeshPrototype"])],
    dependencies: [.package(name: "Spine", path: "../..")],
    targets: [
        .target(name: "TriangleRenderer"),
        .executableTarget(name: "MeshPrototype", dependencies: ["TriangleRenderer", .product(name: "Spine", package: "Spine")],
                          resources: [.copy("Resources")]),
        .testTarget(name: "TriangleRendererTests", dependencies: ["TriangleRenderer"])
    ]
)
