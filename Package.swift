// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayerConvivaConnector",
    platforms: [ .iOS(.v12) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConvivaConnector", targets: ["THEOplayerConvivaConnector"])
    ],
    dependencies: [
        .package(url: "https://github.com/Conviva/conviva-ios-sdk-spm", from: "4.0.31"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.4"),
        .package(url: "https://github.com/Dev1an/theoplayer-sdk-ios", branch: "master"), //TODO: replace with official URL
    ],
    targets: [
        .target(
            name: "THEOplayerConvivaConnector",
            dependencies: [
                .product(name: "THEOplayerSDK", package: "theoplayer-sdk-ios"),
                .product(name: "ConvivaSDK", package: "conviva-ios-sdk-spm"),
            ],
            path: "Sources/ConvivaConnector",
            swiftSettings: [
                .define("VERIZONMEDIA")
            ],
            plugins: [.plugin(name: "TheoFeatureDetectorPlugin")]
        ),
        .executableTarget(
            name: "FeatureMocker",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")],
            resources: [.copy("VerizonMock.txt")]
        ),
        .plugin(
            name: "TheoFeatureDetectorPlugin",
            capability: .buildTool(),
            dependencies: ["FeatureMocker"]
        ),
    ]
)
