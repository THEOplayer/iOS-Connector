# OptiView Player iOS SDK Connectors

This repository is maintained by [Dolby OptiView](https://optiview.dolby.com/) and contains the different connectors available with the OptiView Player (formerly THEOplayer) iOS SDK.

The OptiView Player iOS SDK enables you to quickly deliver content playback on iOS and tvOS.

Using the available connectors allows you to augment the features delivered through the iOS SDK.

## Prerequisites

The OptiView Player iOS SDK Connectors requires the application to import the OptiView Player iOS SDK since the connectors rely on its public APIs.
For more details about importing OptiView Player iOS SDK check the [documentation](https://optiview.dolby.com/docs/theoplayer/getting-started/sdks/ios/getting-started/).

## Available Connectors

| Connector          | Dependency                                | Supported From |                    Documentation                     |
|:-------------------|:------------------------------------------|:--------------:|:----------------------------------------------------:|
| Uplynk             | `THEOplayer-Connector-Uplynk`             |     8.11.1     | [documentation](Code/Uplynk/README.md)               |
| Comscore           | `THEOplayer-Connector-Comscore`           |     4.5.0      | [documentation](Code/Comscore/README.md)             |
| Conviva            | `THEOplayer-Connector-Conviva`            |     4.1.1      | [documentation](Code/Conviva/README.md)              |
| Nielsen            | `THEOplayer-Connector-Nielsen`            |     4.3.0      | [documentation](Code/Nielsen/README.md)              |
| SideloadedSubtitle | `THEOplayer-Connector-SideloadedSubtitle` |     5.2.0      | [documentation](Code/Sideloaded-TextTracks/README.md)|
| Yospace            | `THEOplayer-Connector-Yospace`            |     7.8.0      | [documentation](Code/Yospace/README.md)              |

## Installation

### CocoaPods

In your `Podfile` add one or more of the OptiView Player iOS SDK Connectors, for example:

```ruby
pod 'THEOplayer-Connector-Conviva'
```

### Swift Package Manager

In Xcode, go to **File > Add Package Dependencies...** and add:

```
https://github.com/THEOplayer/iOS-Connector
```

Then select the library products you need (e.g. `THEOplayerConnectorConviva`).

## Documentation

-   [OptiView Docs](https://optiview.dolby.com/docs/)

## Other Platforms

If you are looking for connectors for other platforms see:

-   [Android SDK connectors](https://github.com/THEOplayer/android-connector)
-   [Web SDK connectors](https://github.com/THEOplayer/web-connectors)
-   [React Native SDK connectors](https://github.com/THEOplayer/react-native-connectors)

## License

The contents of this package are subject to the [Dolby OptiView Terms of Service](https://optiview.dolby.com/policies/terms-of-service/).
