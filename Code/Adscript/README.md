# THEOPlayer 🤝 Adscript

THEOplayer-Connector-Adscript provides an integration between the THEOplayerSDK and Adscript.

For example xcode projects with this connector see [Adscript-Examples](../Adscript-Examples/README.md).

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

1. In Xcode, install the Adscript connector by navigating to **File > Add Packages**
2. In the prompt that appears, select the iOS-Connector GitHub repository: `https://github.com/THEOplayer/iOS-Connector`
3. Select the version you want to use.
4. Choose the Connector libraries you want to include in your app.
5. The Adscript SDK is not available as a Swift Package. Download the .xcframework from the Adscript developer portal and drag it onto Project > General > Frameworks, Libraries and Embedded Content.

To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package) of the `theoplayer-sdk-ios` package by selecting the folder `../../Helpers/TheoSPM/theoplayer-sdk-ios` in Finder and dragging it into the Project navigator of your Xcode project.
3. Place your custom THEOplayerSDK.xcframework at `../../Helpers/TheoSPM/theoplayer-sdk-ios/THEOplayerSDK.xcframework`. (It is also possible to place your xcframework somewhere else. In that case make sure to update the [Package.swift](../../Helpers/TheoSPM/theoplayer-sdk-ios/Package.swift) manifest inside the your local override so that it points to your custom THEOplayer build)
4. If Xcode complains about a missing xcframework
   1. Choose `File` > `Packages` > `Reset Package Caches` from the menu bar.
   2. If it is still not working, make sure to remove any `THEOplayerSDK.xcframework` inclusions that you manually installed before installing this THEOplayer-Connector-Adscript package.

### [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started)

1. Create a Podfile if you don't already have one. From the root of your project directory, run the following command: `pod init`
2. To your Podfile, add the Adscript connector pods that you want to use in your app: `pod 'THEOplayer-Connector-Adscript'`
3. The Adscript SDK is not available as a pod.  Download the .xcframework from the Adscript developer portal. Place it in a folder next to a custom podspec. Refer to the ones in [Adscript-Example for Cocoapods for an example](./../Adscript-Examples//Cocoapod/Frameworks/). Include a line in you app's Podfile to point to that podspec for the `AscriptApiClient` dependency. 
```ruby
  pod 'AdscriptApiClient', :path => 'path/to/folder/with/custompodspec/'
```
4. Install the pods using `pod install` , then open your `.xcworkspace` file to see the project in Xcode.

**Important note**: You will need to set Project > Build Settings > User Script Sandboxing to `No`


To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://guides.cocoapods.org/using/the-podfile.html#using-the-files-from-a-folder-local-to-the-machine) of the `THEOplayerSDK-basic` pod by adding the following line to your projects Podfile: `pod 'THEOplayerSDK-basic', :path => 'iOS-Connector/Helpers/TheoPod'` and make sure the path points to the [TheoPod folder](../../Helpers/TheoPod).

## Usage

Import the `THEOplayerConnectorAdscript` module

```swift
import THEOplayerConnectorAdscript
```

Create a `AdscriptConfiguration` that contains your implementation id and a flag to enable/disable debug logging:

```swift
let configuration = AdscriptConfiguration(
    implementationId: "test123",
    debug: true
)
```

Create a `AdscriptConnector` that uses this `configuration`, your `THEOplayer` instance and the metadata for the first source you will set on the player:

```swift
let connector = AdscriptConnector(
    configuration: configuration,
    player: player,
    metadata: adscriptContentMetadata
)
```

During the connector's lifecycle, you can update the metadata of the currently set source using the `update` method, which you pass an `AdScriptDataObject`.

```swift
var adscriptContentMetadata = AdScriptDataObject()
    .set(key: .length, value: 596)
    .set(key: .assetId, value: "0123ABC")
    .set(key: .channelId, value: "Dolby Test Asset")
    .set(key: .program, value: "Big Buck Bunny")
    .set(key: .livestream, value: "0")
    .set(key: .type, value: .content)

connector.update(metadata: adscriptContentMetadata)
```

Change user info with the `updateUser` method, which you pass a `AdScriptI12n` object:
```swift
var adScriptI12n = AdScriptI12n()
    .set(key: 1, value: "28c7dacc-e68b-4fb7-9770-efeaaabe6688") // client-side user identifier (customerId)
    .set(key: 2, value: "29c7dacc-e68b-4fb7-9770-efeaaabe6688") // client-side user device identifier (deviceId)
    .set(key: 3, value: "30c7dacc-e68b-4fb7-9770-efeaaabe6688") // client-side profile identifier of the logged-in user (profileId)
    .set(key: 4, value: "31c7dacc-e68b-4fb7-9770-efeaaabe6688") // optional - SW device identifier for a situation where there are multiple device IDs in the client DB (typically a) HW ID - fill in i2, b) SW ID - fill in i4).
    .set(key: 5, value: "ef3c6dc72a26912f07f0e733d51b46c771d807bf") // fingerprint of user's email address
connector.updateUser(i12n: adScriptI12n)
```

On each DidBecomeActive, you need to call
```swift
connector.sessionStart()
```