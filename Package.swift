// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayer-Connector",
    platforms: [ .iOS(.v12) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConnectorConviva", targets: ["THEOplayerConnectorConviva"]),
        .library(name: "THEOplayerConnectorConvivaVerizonMedia", targets: ["THEOplayerConnectorConvivaVerizonMedia"]),
        
        .library(name: "THEOplayerConnectorNielsen", targets: ["THEOplayerConnectorNielsen"]),
        
        .library(name: "THEOplayerConnectorUtilities", targets: ["THEOplayerConnectorUtilities"]),
    ],
    dependencies: [
        .package(name: "ConvivaSDK", url: "https://github.com/Conviva/conviva-ios-sdk-spm", from: "4.0.30"),
        .package(name: "THEOplayerSDK", url: "https://github.com/THEOplayer/theoplayer-sdk-ios", .exact("4.2.0")),
        .package(name: "NielsenAppApi", url: "https://github.com/NielsenDigitalSDK/nielsenappsdk-ios-dynamic-spm-global", from: "9.0.0")
    ],
    targets: [
        // CONVIVA \\
        .target(
            name: "THEOplayerConnectorConviva",
            dependencies: [
                "THEOplayerSDK",
                "ConvivaSDK",
                .target(name: "THEOplayerConnectorUtilities")
            ],
            path: "Code/Conviva/Source"
        ),
        .target(
            name: "THEOplayerConnectorConvivaVerizonMedia",
            dependencies: [
                "THEOplayerSDK",
                "ConvivaSDK",
                .target(name: "THEOplayerConnectorConviva"),
                .target(name: "THEOplayerConnectorUtilities")
            ],
            path: "Code/Conviva-VerizonMedia/Source"
        ),

        // NIELSEN \\
        .target(
            name: "THEOplayerConnectorNielsen",
            dependencies: [
                "THEOplayerSDK",
                "NielsenAppApi",
                .target(name: "THEOplayerConnectorUtilities")
            ],
            path: "Code/Nielsen/Source"
        ),
        
        
        .target(
            name: "THEOplayerConnectorUtilities",
            dependencies: ["THEOplayerSDK"],
            path: "Code/Utilities/Source"
        )
    ]
)
