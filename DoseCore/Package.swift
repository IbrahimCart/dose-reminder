// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DoseCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "DoseCore", targets: ["DoseCore"])],
    targets: [
        .target(name: "DoseCore"),
        .testTarget(name: "DoseCoreTests", dependencies: ["DoseCore"]),
    ]
)
