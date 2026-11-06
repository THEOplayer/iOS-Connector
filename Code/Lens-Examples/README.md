# THEOplayer Connector for OptiView Lens: example

`LensExample.xcodeproj` is an iOS app that plays streams with THEOplayer and reports them to OptiView Lens with a `LensConnector` from the [Lens connector](../Lens). It uses the connector from this repository checkout.

Open the project, pick an iPhone simulator or device, and run. The app:

- loads one of a few example streams, or a URL of your own (`Load a source`),
- plays, pauses, stops, seeks, mutes, changes the rate and goes fullscreen, which Lens reports as state changes, `m`/`um`, `pr` and `pe`/`pc`,
- shows the current Lens session, which starts at the first play request on a source,
- lists every report Lens sends, newest first, with its namespace, event, playback state and main keys. Tap a report for all its keys.

The reports are captured inside the app: the example disables the OptiView backend and adds a destination that the app answers itself. Heartbeats are sent every 10 seconds.

In `LensExample/Config.swift`, you can set:

- `theoplayerLicense`: your THEOplayer license, needed for streams of your own. The example streams play without one.
- `lensDestinationUrl`: an endpoint that also receives the reports as JSON, such as a request inspector.
