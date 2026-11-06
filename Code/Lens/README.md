# THEOplayer Connector for OptiView Lens

THEOplayer-Connector-Lens reports a THEOplayer to the [OptiView Lens SDK](https://github.com/Dolby-OptiView/optiview-lens-sdk-swift). It implements the Lens SDK's `LensPlayerAdapter` on top of the THEOplayer public API, so that Lens can run the viewing sessions of the player and report its playback on its own: playback states, errors, bitrate switches, mute and rate changes, presentation mode changes, and the player keys Lens derives from the playhead, the buffer, the tracks, the throughput and the dropped frames.

## Installation

The Lens SDK is distributed with Swift Package Manager only, and so is this connector.

In Xcode, go to **File > Add Package Dependencies...** and add:

```
https://github.com/THEOplayer/iOS-Connector
```

Then select the `THEOplayerConnectorLens` product. Also add `https://github.com/Dolby-OptiView/optiview-lens-sdk-swift` and select its `LensSDK` product, to call the Lens SDK from your app.

## Usage

Import the modules:

```swift
import LensSDK
import THEOplayerConnectorLens
```

Create a `THEOplayerLensAdapter` for your `THEOplayer` instance and join Lens with it:

```swift
let adapter = THEOplayerLensAdapter(player: player)
let lens = try Lens.join(LensJoinOptions(namespace: "my-app", player: adapter))
```

Lens then starts a session at the first play request on each source, and ends it when the source is replaced or removed, or the player is released. Call `lens.dispose()` when you no longer want to report the player.

Notes:

- Create one adapter per player, and hand the same adapter to every SDK that joins Lens for that player: Lens tells players apart by adapter identity, so they share one session.
- Use the adapter on the main queue, as the player. The adapter does not retain the player.
- Do not enable THEOplayer's own CMCD reporting on a player that Lens observes.
- A Google DAI source is reported by its asset key, or by its content source ID and video ID, instead of by the stream URL it resolves to.

## Example

See the [example app](../Lens-Examples).
