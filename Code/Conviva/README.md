# THEOPlayer 🤝 Conviva

THEOplayer-Connector-Conviva for iOS provides an integration between the THEOplayerSDK and ConvivaSDK. It connects to the Conviva backend and reports events fired from THEOplayer instances.

For example xcode projects with this connector see [Conviva-Examples](../Conviva-Examples).

**Verizon Media**

For custom THEOplayerSDK builds with the VerizonMedia feature, use the [Conviva-VerizonMedia](../Conviva-VerizonMedia) connector.

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

1. In Xcode, install the Conviva libraries by navigating to **File > Add Packages**
2. In the prompt that appears, select the iOS-Connector GitHub repository: `https://github.com/THEOplayer/iOS-Connector`
3. Select the version you want to use.
4. Choose the Connector libraries you want to include in your app.

To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package) of the `theoplayer-sdk-ios` package by selecting the folder `../../Helpers/TheoSPM/theoplayer-sdk-ios` in Finder and dragging it into the Project navigator of your Xcode project.
3. Place your custom THEOplayerSDK.xcframework at `../../Helpers/TheoSPM/theoplayer-sdk-ios/THEOplayerSDK.xcframework`. (It is also possible to place your xcframework somewhere else. In that case make sure to update the [Package.swift](../../Helpers/TheoSPM/theoplayer-sdk-ios/Package.swift) manifest inside the your local override so that it points to your custom THEOplayer build)
4. If Xcode complains about a missing xcframework
   1. Choose `File` > `Packages` > `Reset Package Caches` from the menu bar.
   2. If it is still not working, make sure to remove any `THEOplayerSDK.xcframework` inclusions that you manually installed before installing this THEOplayer-Connector-Conviva package.

### [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started)

1. Create a Podfile if you don't already have one. From the root of your project directory, run the following command: `pod init`
2. To your Podfile, add the Conviva connector pods that you want to use in your app: `pod 'THEOplayer-Connector-Conviva'`
3. Install the pods using `pod install` , then open your `.xcworkspace` file to see the project in Xcode.

To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://guides.cocoapods.org/using/the-podfile.html#using-the-files-from-a-folder-local-to-the-machine) of the `THEOplayerSDK-basic` pod by adding the following line to your projects Podfile: `pod 'THEOplayerSDK-basic', :path => 'iOS-Connector/Helpers/TheoPod'` and make sure the path points to the [TheoPod folder](../../Helpers/TheoPod).

## Usage

Import the `THEOplayerConnectorConviva` module

```swift
import THEOplayerConnectorConviva
```

Create a `ConvivaConfiguration` that contains the info on how to connect to your conviva endpoint:

```swift
let configuration = ConvivaConfiguration(
    customerKey: "put your customer key here",
    gatewayURL: " put your  gateway URL here ",
    logLevel: .LOGLEVEL_FUNC
)
```

Create a `ConvivaConnector` that uses this `configuration` and your `THEOplayer` instance:

```swift
let connector = ConvivaConnector(
    configuration: configuration,
    player: yourTHEOplayer
)
```

Report the viewer's ID:

```swift
connector.report(viewerID: "John Doe")
```

For each asset you play, the asset name needs to be reported to Conviva. If you provide the asset name as `title` inside your `SourceDescription`'s `.metadata` property the connector will report that title automatically to Conviva as `CIS_SSDK_METADATA_ASSET_NAME`. If you do not provide the title in your `SourceDescription` you will need to manually report your asset name to conviva each time you change the source of your THEOPlayer. You can do this manual reporting using the following convenience method:

```swift
connector.report(assetName: "Star Wars episode II")
```

Hold a reference to your connector. Once the connector is released from memory it will clean up itself and stop reporting to Conviva.

In case you need to report additional information to conviva you can get access to the underlying Conviva types using:

- `connector.analytics` which gives you access to Conviva's `CISAnalytics` type
- `connector.videoAnalytics` which gives you access to Conviva's `CISVideoAnalytics` type
- `connector.adAnalytics` which gives you access to Conviva's `CISAdAnalytics` type

## What events does this connector report?

### Basic playback events

