# Conviva 

The THEOplayer-Connector-Conviva for iOS provides an integration between the THEOplayerSDK and ConvivaSDK. It connects to the Conviva backend and reports events fired from THEOplayer instances.

## Installation

### [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started)

1. Create a Podfile if you don't already have one. From the root of your project directory, run the following command: `pod init`
2. To your Podfile, add the Conviva connector pods that you want to use in your app: `pod 'THEOplayer-Connector-Conviva'`
3. Install the pods using `pod install` , then open your `.xcworkspace` file to see the project in Xcode.

### [Swift Package Manager](https://swift.org/package-manager/)

1. In Xcode, install the Conviva libraries by navigating to **File > Add Packages**
2. In the prompt that appears, select the ios-connectors GitHub repository: `https://github.com/THEOplayer/ios-connectors`
3. Select the version you want to use.
4. Choose the Connector libraries you want to include in your app.

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

Set report the viewer's ID:

```swift
connector.report(viewerID: "John Doe")
```

For each asset that you play, set it's name using:

```swift
connector.report(assetName: "Star Wars episode II")
```

Hold a reference to your connector. Once the connector is released from memory it will clean up itself and stop reporting to Conviva.
