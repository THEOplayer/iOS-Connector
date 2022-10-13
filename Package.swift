// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayer-Connectors",
    platforms: [ .iOS(.v12) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConnectorConviva", targets: ["THEOplayerConnectorConviva"]),
        .library(name: "THEOplayerConnectorConvivaVerizonMedia", targets: ["THEOplayerConnectorConvivaVerizonMedia"])
    ],
    dependencies: [
        .package(url: "https://github.com/Conviva/conviva-ios-sdk-spm", from: "4.0.31"),
        .package(url: "https://github.com/THEOplayer/theoplayer-sdk-ios", exact: "4.3.3"),
    ],
    targets: [
        .target(
            name: "THEOplayerConnectorConviva",
            dependencies: [
                .product(name: "THEOplayerSDK", package: "theoplayer-sdk-ios"),
                .product(name: "ConvivaSDK", package: "conviva-ios-sdk-spm"),
            ],
            path: "Code/Conviva/Source"
        ),
        .target(
            name: "THEOplayerConnectorConvivaVerizonMedia",
            dependencies: [
                .product(name: "THEOplayerSDK", package: "theoplayer-sdk-ios"),
                .product(name: "ConvivaSDK", package: "conviva-ios-sdk-spm"),
                .target(name: "THEOplayerConnectorConviva")
            ],
            path: "Code/Conviva-VerizonMedia/Source"
        ),
    ]
)
