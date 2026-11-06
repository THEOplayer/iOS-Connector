# THEOplayer Connector for OptiView Lens

THEOplayer-Connector-Lens reports a THEOplayer to the [OptiView Lens SDK](https://github.com/Dolby-OptiView/optiview-lens-sdk-swift). It implements the Lens SDK's `LensPlayerAdapter` on top of the THEOplayer public API, so that Lens can run the viewing sessions of the player and report its playback on its own: playback states, errors, mute and rate changes, presentation mode changes, and the player keys Lens derives from the playhead, the buffer, the tracks, the throughput and the dropped frames.

## Installation

The Lens SDK is distributed with Swift Package Manager only, and so is this connector.

In Xcode, go to **File > Add Package Dependencies...** and add:

```
https://github.com/THEOplayer/iOS-Connector
```

Then select the `THEOplayerConnectorLens` product. To call the Lens SDK from your app, for example to configure it or to report events of your own, also add `https://github.com/Dolby-OptiView/optiview-lens-sdk-swift` and select its `LensSDK` product.

## Usage

Create one connector per player, on the main queue:

```swift
import THEOplayerConnectorLens

let lensConnector = try LensConnector(player: player)
```

Lens starts a session at the first play request on each source, and ends it when the source is replaced or removed. The connector does not retain the player.

Lens reports to the OptiView ingest by default. The configuration takes the options of `Lens.join`, except the namespace and the player, for example to add destinations of your own:

```swift
import LensSDK

let lensConnector = try LensConnector(
    player: player,
    configuration: LensConfiguration(destinations: [LensDestination(url: "https://collector.example.com/lens", format: .json)])
)
```

To report only to your own destinations, call `Lens.configure(LensConfigureOptions(backend: .disabled))` before creating the connector.

The playback reports are sent in Lens's `lens` namespace, and the connector's heartbeats in the `theoplayer` namespace. A destination that filters on namespaces must list them to receive them.

### Content ID

Lens derives the content ID (`cid`) from the source URL. A Google DAI source is reported by its asset key, or by its content source ID and video ID, instead of by the stream URL it resolves to. To report your own content ID, return it from `contentId`:

```swift
let lensConnector = try LensConnector(
    player: player,
    configuration: LensConfiguration(contentId: { source in source.metadata?.title })
)
```

### Your own events

To report events of your own, join Lens in your own registered namespace with `lensConnector.adapter`. Lens reports one session per player adapter, so your events and the player's playback share that session. Another SDK that reports this player to Lens joins with the adapter the same way.

```swift
import LensSDK

let lens = try Lens.join(LensJoinOptions(namespace: "my_namespace", player: lensConnector.adapter))
lens.emitCustom("chapterStart", payload: LensPayload(custom: ["chapter": 3]))
```

`lensConnector.handle` is the Lens handle the connector joined with. Use it to set consent or to flush.

### Destroying

The connector ends the session and stops reporting when the player is released, or when you destroy it:

```swift
lensConnector.destroy()
```

Do not enable THEOplayer's own CMCD reporting on a player that Lens observes.

## Limitations

- THEOplayer exposes the quality being played, not the one being loaded. Lens therefore reports the top and lowest bitrates (`tb`/`lb`, or `tab`/`lab` for HLS), and the playhead bitrate (`pb`) outside HLS, but not the encoded bitrate (`br`) or bitrate changes (`bc`).
- A THEOplayer quality only exposes its bandwidth, and its size for video. A rendition is identified by its bandwidth, and Lens receives no codecs or frame rate.
- The visibility of the player's own view is not reported: Lens follows the app moving to the background and back.
- Only fatal errors are reported.
- Ads are not reported as such: Lens sees what the content player does during an ad break.

## Example

See the [example app](../Lens-Examples).
