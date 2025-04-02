// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayer-Connector",
    platforms: [ .iOS(.v13), .tvOS(.v13) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConnectorConviva", targets: ["THEOplayerConnectorConviva"]),
        .library(name: "THEOplayerConnectorConvivaVerizonMedia", targets: ["THEOplayerConnectorConvivaVerizonMedia"]),
        
        .library(name: "THEOplayerConnectorNielsen", targets: ["THEOplayerConnectorNielsen"]),
        
        .library(name: "THEOplayerConnectorUtilities", targets: ["THEOplayerConnectorUtilities"]),

        .library(name: "THEOplayerConnectorSideloadedSubtitle", targets: ["THEOplayerConnectorSideloadedSubtitle"]),

        .library(name: "THEOplayerConnectorYospace", targets: ["THEOplayerConnectorYospace"]),

        .library(name: "THEOplayerConnectorUplynk", targets: ["THEOplayerConnectorUplynk"]),
    ],
    dependencies: [
        .package(name: "ConvivaSDK", url: "https://github.com/Conviva/conviva-ios-sdk-spm", .exactItem( "4.0.51")),
        .package(name: "THEOplayerSDK", url: "https://github.com/THEOplayer/theoplayer-sdk-apple", from: "9.0.0"),
        .package(name: "NielsenAppApi", url: "https://github.com/NielsenDigitalSDK/nielsenappsdk-ios-dynamic-spm-global", from: "9.0.0"),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter.git", .exactItem("1.5.0")),
        .package(name: "SwiftSubtitles", url: "https://github.com/dagronf/SwiftSubtitles.git", .exactItem("0.9.1")),
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
        
        // UTILITY \\
        .target(
            name: "THEOplayerConnectorUtilities",
            dependencies: ["THEOplayerSDK"],
            path: "Code/Utilities/Source"
        ),

        // Sideloaded subtitles \\
        .target(
            name: "THEOplayerConnectorSideloadedSubtitle",
            dependencies: [
                "THEOplayerSDK",
                "Swifter",
                "SwiftSubtitles",
            ],
            path: "Code/Sideloaded-TextTracks/Sources/THEOplayerConnectorSideloadedSubtitle" 
        ),

        // Yospace \\
        .target(
            name: "THEOplayerConnectorYospace",
            dependencies: [
                "THEOplayerSDK",
            ],
            path: "Code/Yospace/Source"
        ),
        
        // Uplynk \\
        .target(
            name: "THEOplayerConnectorUplynk",
            dependencies: [
                "THEOplayerSDK"
            ],
            path: "Code/Uplynk/Source"
        ),
        .testTarget(
            name: "THEOplayerConnectorUplynkTests",
            dependencies: [
                "THEOplayerConnectorUplynk"
            ],
            path: "Code/Uplynk/Tests"
        )
    ]
)
