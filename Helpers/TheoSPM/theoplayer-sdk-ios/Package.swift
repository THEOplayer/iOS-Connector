// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "THEOplayerSDK",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "THEOplayerSDK", targets: ["TheoSdkWithDependencies"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "THEOplayerSDK",
            path: "THEOplayerSDK.xcframework"
        ),
        .binaryTarget(
            name: "GoogleInteractiveMediaAds",
            url: "https://imasdk.googleapis.com/native/downloads/ima-ios-v3.16.3.zip",
            checksum: "049bac92551b50247ea14dcbfde9aeb99ac2bea578a74f67c6f3e781d9aca101"
        ),
        .binaryTarget(
            name: "GoogleCast",
            url: "https://dl.google.com/dl/chromecast/sdk/ios/GoogleCastSDK-ios-4.7.1_dynamic_beta.xcframework.zip",
            checksum: "e2b832f1f7b63ea25edf91fefc244b76f26975bc22ef878fbf1f79cfba441c7c"
        ),
        .target( // Workaround from https://forums.swift.org/t/swiftpm-binary-target-with-sub-dependencies/40197/7
            name: "TheoSdkWithDependencies",
            dependencies: [
                .target(name: "GoogleInteractiveMediaAds"),
                .target(name: "GoogleCast"),
                .target(name: "THEOplayerSDK")
            ]
        )
    ]
)
