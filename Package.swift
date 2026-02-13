// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "THEOplayer-Connector",
    platforms: [ .iOS(.v13), .tvOS(.v13) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "THEOplayerConnectorConviva", targets: ["THEOplayerConnectorConviva"]),
        
        .library(name: "THEOplayerConnectorNielsen", targets: ["THEOplayerConnectorNielsen"]),

        .library(name: "THEOplayerConnectorGemius", targets: ["THEOplayerConnectorGemius"]),
        
        .library(name: "THEOplayerConnectorUtilities", targets: ["THEOplayerConnectorUtilities"]),

        .library(name: "THEOplayerConnectorSideloadedSubtitle", targets: ["THEOplayerConnectorSideloadedSubtitle"]),

        .library(name: "THEOplayerConnectorYospace", targets: ["THEOplayerConnectorYospace"]),

        .library(name: "THEOplayerConnectorUplynk", targets: ["THEOplayerConnectorUplynk"]),
    ],
    dependencies: [
        .package(name: "ConvivaSDK", url: "https://github.com/Conviva/conviva-ios-sdk-spm", .exactItem( "4.0.51")),
        .package(name: "THEOplayerSDK", url: "https://github.com/THEOplayer/theoplayer-sdk-apple", from: "10.0.0"),
        .package(name: "NielsenAppApi", url: "https://github.com/NielsenDigitalSDK/nielsenappsdk-ios-dynamic-spm-global", from: "9.0.0"),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter.git", .exactItem("1.5.0")),
        .package(name: "SwiftSubtitles", url: "https://github.com/dagronf/SwiftSubtitles.git", .exactItem("0.9.1")),
    ],
    targets: [
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
            name: "THEOplayerConnectorNielsen",
            dependencies: [
                "THEOplayerSDK",
                "NielsenAppApi",
                .target(name: "THEOplayerConnectorUtilities")
            ],
            path: "Code/Nielsen/Source"
        ),

        // GEMIUS \\
        .target(
            name: "THEOplayerConnectorGemius",
            dependencies: [
                "THEOplayerSDK",
            ],
            path: "Code/Gemius/Source"
        ),
        
        .target(
            name: "THEOplayerConnectorUtilities",
            dependencies: ["THEOplayerSDK"],
            path: "Code/Utilities/Source"
        ),

        .target(
            name: "THEOplayerConnectorSideloadedSubtitle",
            dependencies: [
                "THEOplayerSDK",
                "Swifter",
                "SwiftSubtitles",
            ],
            path: "Code/Sideloaded-TextTracks/Sources/THEOplayerConnectorSideloadedSubtitle" 
        ),

        .target(
            name: "THEOplayerConnectorYospace",
            dependencies: [
                "THEOplayerSDK",
            ],
            path: "Code/Yospace/Source"
        ),
        
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
