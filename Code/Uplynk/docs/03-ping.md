# Ping

This article explains how to use the Uplynk Ping API.

The Ping API for Uplynk allows users of their CMS to receive updates about SSAI on running live-streams or provide better playback position beaconing for Video on demand. The Ping API is used together with the Preplay API because the latter provides a session to be used with the Ping API.

This connector allows the user to specify a source for Preplay, and enable or disable certain features of the Ping API. The player will then perform these Ping calls internally, without the user having to write their own Ping client. The response of Ping calls will be exposed for external handling if necessary.

**Feature Assumptions**
We assume the SSAI information returned through the Ping API to be of a certain format, which we compile from examples and our own testing. The documentation does not define the structure of this payload very well and only states that it is "like the object returned in Preplay requests", though the formats are not a one-on-one match.

This feature currently excludes client-side ad tracking and VPAID support.

**Assumptions**

- THEOplayer assumes the availability of the Ping API and Uplynk content servers to be 100%, since these identify and provide the necessary streams for playback with this feature.
- THEOplayer assumes application developers have a notion of the Ping API, namely any extra parameters to be appended to the requests to Uplynk (e.g. for correct ad insertion). As documented in https://api-docs.uplynk.com/#Develop/Preplayv2.htm
- THEOplayer assumes application developers provide proper ID's of the Assets they want to play back, as well as the proper content protection level.

## Configuring Ping

The player allows specification of the desired features of the Ping API as listed [in the official Ping API documentation](https://api-docs.uplynk.com/#Develop/Preplayv2.htm#Features).

By default, the ping API is disabled for all sessions. To enable it, the `ad.cping=1` parameter must be added to your preplay request. If you attempt to call the API without passing in the `ad.cping` parameter, you can throw off the server's ability to make ad event calls correctly.

In addition to enabling the API, you must also notify the server of the features you want to support for this viewing session. To specify which features you'd like to enable, you add the`ad.pingf={some value} `parameter to the playback token. The value of the parameter is detailed in the official Ping Documentation.

Sample playback URL with `cping`:

`https://content.uplynk.com/preplay/cc829785506f46dda4c605abdf65392b.json?ad=adserver&ad.cping=1&ad.pingf=3`

In the THEOplayer-Connector-Uplynk, these features can be activated through the `uplynkPingConfiguration` property in the SSAI configuration:

```swift
let ssaiConfiguration = UplynkSSAIConfiguration(
                                id: .asset(ids: [ your list of asset IDs]),
                                assetType: .asset or .channel,
                                prefix: "https://content.uplynk.com",
                                preplayParameters: [ Dictionary of parameters ]
                                contentProtected: true or false,
                                uplynkPingConfiguration: UplynkPingConfiguration(adImpressions: true or false, // Defaults to false
                                                                                 freeWheelVideoViews: true or false, // Defaults to false
                                                                                 linearAdData: true or false)) // Defaults to false
```

Another important note is that the official documentation does not permit certain options for certain content types (e.g.`adImpressions`must not be used with Live content). The player will respect this documentation and will not enable a feature that is not allowed for the current content type, even if explicitly enabled in the`ping`configuration.

If the `uplynkPingConfiguration` uses the default value, or all of `adImpressions`, `freeWheelVideoViews` and `linearAdData` are set to false, Ping API will not be used.

## Ping requests

When the Ping API is enabled, THEOplayer will call the Ping URL located at:

```
{prefix}/session/ping/{sessionID}.json?v=3&pt={currentTime}&ev={event}&ft={freeWheelTime}
```

Where:

- `{prefix}`: Is the prefix URL from the Preplay response.
- `{sessionID}`: Is the session ID from the Preplay response.
- `{currentTime}`: Mandatory parameter. This is the current player time in seconds.

- `{event}`: Is the current Ping event. An event should only be passed when playback starts or when a viewer seeks to a new position.
  Valid values are:

  - **start**: Pass this event, along `withpt=0`, when the player starts playback. This lets the server know where playback starts and allows the server to fire start events as needed.
  - **seek**: Pass this event when a viewer seeks. This resets the timeline to prevent inadvertently firing events for skipped ads.

- `{freeWheelTime}`: Indicates the playback position, in seconds, right before a viewer seeks to a different position in the timeline. This property is mandatory when the freeWheelVideoViews is used.

## Ping Response

When performed correctly, a Ping request will return a JSON response. THEOplayer will interpret this response according to the following principles:

- next_time: A new beacon will be scheduled when the player's currentTime passes this value. In case the value is -1, no further beacons will be scheduled.
- ads: Will be interpreted in order to display markers in the timeline as well as expose ad information through the `player.ads.scheduledAds` property.

  - ads.breaks.timeOffset will be used in order to determine the start time of the ad break (in seconds).
  - ads.breaks.ads will be looped in order to extract the ad information to be exposed in UplynkAdBreak:
    - duration will serve as duration in UplynkAd (in seconds)
    - mimeType will serve as mimeType in UplynkAd
    - apiFramework will serve as apiFramework in UplynkAd
    - companions will serve as companions UplynkAd
    - creative will serve as creative in UplynkAd
    - width will serve as width in UplynkAd
    - height will serve as height in UplynkAd
    - events will serve as events in UplynkAd
    - fwParameters will serve as freeWheelParameters in UplynkAd
    - extensions will serve as the custom set of VAST extensions in UplynkAd
  - ads.breaks.breakEnd will be used in order to determine the end of the ad break. Note that this property is optional, and the duration of an ad break can be unknown and updated at a later point.
  - ads.breaks.duration will be ignored by the player.

  For all ads and adBreaks added, AD_BREAK_BEGIN, AD_BREAK_END, AD_BEGIN, AD_END events will be dispatched.

The ping response can be retrieved from the `onPingResponse(:)` delegate method of UplynkConnector's `eventListener`.

| Delegate method |               Description               |                    Arguments                    |
| :-------------: | :-------------------------------------: | :---------------------------------------------: |
| onPingResponse  | Fired when a Ping response is received. | `response` argument contains the `PingResponse` |

## Related articles

- [Uplynk - Preplay](../docs/01-preplay.md)
- [Uplynk - Ads](../docs/02-ads.md)
