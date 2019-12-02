// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TelloSwift",
    platforms: [
        .macOS(.v10_15), .iOS(.v12)
    ],
    products: [
        .library(name: "TelloSwift", targets: ["TelloSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.10.0"),
    ],
    targets: [
        .target(name: "TelloSwift", dependencies: ["NIO"], path:"TelloSwift"),
        .testTarget(name: "TelloSwiftTests", dependencies: ["TelloSwift"], path:"TelloSwiftTests"),
    ]
)
