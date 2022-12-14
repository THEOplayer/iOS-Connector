// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayer-Connector",
    platforms: [ .iOS(.v12) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConnectorConviva", targets: ["THEOplayerConnectorConviva"]),
        .library(name: "THEOplayerConnectorConvivaVerizonMedia", targets: ["THEOplayerConnectorConvivaVerizonMedia"])
    ],
    dependencies: [
        .package(name: "ConvivaSDK", url: "https://github.com/Conviva/conviva-ios-sdk-spm", from: "4.0.30"),
        .package(name: "THEOplayerSDK", url: "https://github.com/THEOplayer/theoplayer-sdk-ios", .exact("4.1.1")),
    ],
    targets: [
        .target(
            name: "THEOplayerConnectorConviva",
            dependencies: ["THEOplayerSDK", "ConvivaSDK"],
            path: "Code/Conviva/Source"
        ),
        .target(
            name: "THEOplayerConnectorConvivaVerizonMedia",
            dependencies: [
                "THEOplayerSDK",
                "ConvivaSDK",
                .target(name: "THEOplayerConnectorConviva")
            ],
            path: "Code/Conviva-VerizonMedia/Source"
        ),
    ]
)
