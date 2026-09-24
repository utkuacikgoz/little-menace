// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MenaceCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "MenaceCore", targets: ["MenaceCore"])],
    targets: [
        .target(name: "MenaceCore"),
        .testTarget(name: "MenaceCoreTests", dependencies: ["MenaceCore"]),
    ]
)
