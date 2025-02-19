# THEOPlayer 🤝 Uplynk

THEOplayer-Connector-Uplynk for iOS provides an integration between the THEOplayerSDK and the Uplynk CMS. It allows the `THEOplayerSDK` to playback uplynk sources.

For example xcode projects with this connector see [Uplynk-Examples](../Uplynk-Examples/README.md).

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

1. In Xcode, install the THEOPlayer iOS-Connector package by navigating to **File > Add Packages**
2. In the prompt that appears, select the iOS-Connector GitHub repository: `https://github.com/THEOplayer/iOS-Connector`
3. Select the version you want to use. 
> the Uplynk connector is available for versions >= 8.12 only.

4. Choose the Connector libraries you want to include in your app.

To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package) of the `theoplayer-sdk-ios` package by selecting the folder `../../Helpers/TheoSPM/theoplayer-sdk-ios` in Finder and dragging it into the Project navigator of your Xcode project.
3. Place your custom THEOplayerSDK.xcframework at `../../Helpers/TheoSPM/theoplayer-sdk-ios/THEOplayerSDK.xcframework`. (It is also possible to place your xcframework somewhere else. In that case make sure to update the [Package.swift](../../Helpers/TheoSPM/theoplayer-sdk-ios/Package.swift) manifest inside the your local override so that it points to your custom THEOplayer build)
4. If Xcode complains about a missing xcframework
   1. Choose `File` > `Packages` > `Reset Package Caches` from the menu bar.
   2. If it is still not working, make sure to remove any `THEOplayerSDK.xcframework` inclusions that you manually installed before installing this THEOplayer-Connector-Uplynk package.

### [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started)

1. Create a Podfile if you don't already have one. From the root of your project directory, run the following command: `pod init`
2. To your Podfile, add the Uplynk connector pods that you want to use in your app: `pod 'THEOplayer-Connector-Uplynk'`
3. Install the pods using `pod install` , then open your `.xcworkspace` file to see the project in Xcode.

To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://guides.cocoapods.org/using/the-podfile.html#using-the-files-from-a-folder-local-to-the-machine) of the `THEOplayerSDK-basic` pod by adding the following line to your projects Podfile: `pod 'THEOplayerSDK-basic', :path => 'iOS-Connector/Helpers/TheoPod'` and make sure the path points to the [TheoPod folder](../../Helpers/TheoPod).

## Usage

Import the `THEOplayerConnectorUplynk` module

```swift
import THEOplayerConnectorUplynk
```

Create an `UplynkConfiguration` that contains information on how to handle ad skipping and seeking over ads scenarios: 

```swift
let uplynkConfiguration = UplynkConfiguration(defaultSkipOffset: ..., skippedAdStrategy: ...)

```

> `defaultSkipOffset` describes how many seconds the user has to wait before an ad is skippable. `skippedAdStrategy` controls how the connector behaves when seeking over ads. There are three values: `playAll`, `playLast` and `playNone`. The first option forces playback of all the unwatched ads before the seek point. `playLast` forces playback of the last ad before the seek point. 


After that, create the `UplynkConnector` using a `THEOPlayer` instance and the above configuration: 
```swift
let connector = UplynkConnector(player: yourTHEOplayer,
                                configuration: uplynkConfiguration
                                eventListener: nil)

```

If you would like to receive the Uplynk API responses, then you need to implement the `UplynkEventListener` protocol, and pass your event listener in the `eventListener` argument above.


Next, when creating a `TypedSource`, you can pass a `UplynkSSAIConfiguration` to describe the server side ad injection configuration for Uplynk, such as the asset IDs to play, whether 
the content to be played is DRM protected or not, etc: 

```swift
    let ssaiConfiguration = UplynkSSAIConfiguration(id: .asset(ids: [ your list of asset IDs]),
                                assetType: .asset or .channel,
                                prefix: "https://content.uplynk.com", 
                                contentProtected: true or false)
```
For more information about what each configuration option is, have a look at the API reference for this class. For the `id` argument, you can either pass a list of assetIDs, or a list of external IDs along with the user ID.

For each source, you can attach the uplynk configuration above to the `ssai` property: 

```swift
let myTypedSource = TypedSource(src: "",
                                type: "application/x-mpegurl",
                                ssai: ssaiConfiguration)

let mySource = SourceDescription(source: myTypedSource)
```

Finally you can set the source on your `THEOplayer` instance: 

```swift
yourTHEOplayer.source = mySource
```
