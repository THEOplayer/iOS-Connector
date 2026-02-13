# THEOPlayer 🤝 Gemius

THEOplayer-Connector-Gemius for iOS provides an integration between the THEOplayerSDK and Gemius.

For example xcode projects with this connector see [Gemius-Examples](../Gemius-Examples/README.md).


## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

1. In Xcode, install the Gemius libraries by navigating to **File > Add Packages**
2. In the prompt that appears, select the iOS-Connector GitHub repository: `https://github.com/THEOplayer/iOS-Connector`
3. Select the version you want to use.
4. Choose the Connector libraries you want to include in your app.
5. The Gemius SDK is not available as a Swift Package. Download the .xcframework from the Gemius developer portal and drag it onto Project > General > Frameworks, Libraries and Embedded Content.


To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://developer.apple.com/documentation/xcode/editing-a-package-dependency-as-a-local-package) of the `theoplayer-sdk-ios` package by selecting the folder `../../Helpers/TheoSPM/theoplayer-sdk-ios` in Finder and dragging it into the Project navigator of your Xcode project.
3. Place your custom THEOplayerSDK.xcframework at `../../Helpers/TheoSPM/theoplayer-sdk-ios/THEOplayerSDK.xcframework`. (It is also possible to place your xcframework somewhere else. In that case make sure to update the [Package.swift](../../Helpers/TheoSPM/theoplayer-sdk-ios/Package.swift) manifest inside the your local override so that it points to your custom THEOplayer build)
4. If Xcode complains about a missing xcframework
   1. Choose `File` > `Packages` > `Reset Package Caches` from the menu bar.
   2. If it is still not working, make sure to remove any `THEOplayerSDK.xcframework` inclusions that you manually installed before installing this THEOplayer-Connector-Gemius package.

### [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#getting-started)

1. Create a Podfile if you don't already have one. From the root of your project directory, run the following command: `pod init`
2. To your Podfile, add the Gemius connector pods that you want to use in your app: `pod 'THEOplayer-Connector-Gemius'`
3. The Gemius SDK is not available as a pod.  Download the .xcframework from the Gemius developer portal. Place it in a folder next to a custom podspec. Refer to the ones in [Gemius-Example for Cocoapods for an example](./../Gemius-Examples//Cocoapod/Frameworks/). Include a line in you app's Podfile to point to that podspec for the `GemiusSDK` dependency. 
```ruby
  pod 'GemiusSDK', :path => 'path/to/folder/with/custompodspec/'
```
4. Install the pods using `pod install` , then open your `.xcworkspace` file to see the project in Xcode.

**Important note**: You will need to set Project > Build Settings > User Script Sandboxing to `No`


To support custom feature builds of THEOplayerSDK perform the following steps:

1. Clone this repository to your computer.
2. Use a [local override](https://guides.cocoapods.org/using/the-podfile.html#using-the-files-from-a-folder-local-to-the-machine) of the `THEOplayerSDK-basic` pod by adding the following line to your projects Podfile: `pod 'THEOplayerSDK-basic', :path => 'iOS-Connector/Helpers/TheoPod'` and make sure the path points to the [TheoPod folder](../../Helpers/TheoPod).

## Usage

Import the `THEOplayerConnectorGemius` module

```swift
import THEOplayerConnectorGemius
```

Create a `GemiusConfiguration`

```swift
let configuration = GemiusConfiguration(
    applicationName: "GemiusReporter",
    applicationVersion: "0.0.1",
    hitCollectorHost: "<your hitcollectorhost>",
    gemiusId: "<your gemiusId>",
    debug: true
)
```

Create a `GemiusConnector` that uses this `configuration` and your `THEOplayer` instance:

```swift
let connector = GemiusConnector(
    configuration: configuration,
    player: yourTHEOplayer
)
```

Update metadata using the `update` method

```swift
let programId = "<your program id>"
let programData: GemiusSDK.GSMProgramData = <your program data>
connector.update(programId,programData)
```


