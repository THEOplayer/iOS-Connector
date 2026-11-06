# THEOplayer Connector for OptiView Lens: example

`LensExample.xcodeproj` is an iOS app that plays streams with THEOplayer and reports them to OptiView Lens with a `LensConnector` from the [Lens connector](../Lens). It uses the connector from this repository checkout.

Open the project, pick an iPhone simulator or device, and run. The app:

- loads one of a few example streams, or a URL of your own (`Load a source`),
- plays, pauses, stops, seeks, mutes, changes the rate and goes fullscreen or picture-in-picture, which Lens reports as state changes, `m`/`um`, `pr` and `pe`/`pc`,
- runs a fixed scenario (`Run scenario`, below),
- shows the current Lens session, which starts at the first play request on a source,
- lists every report Lens sends, newest first, with its namespace, event, playback state and main keys. Tap a report for all its keys.

## Where the reports go

The reports are captured inside the app, without a server: Lens sends them to a JSON destination that the app answers itself, and shows them in the list. Heartbeats are sent every 10 seconds.

The example also enables the Lens development backend (the `LensSDKDev` product), which sends the reports to the staging ingest. The app sends them on only while **Send to staging** is on, and answers them itself otherwise. Next to the switch, the app counts the reports it sent, with the last HTTP status, and the ones it kept. The switch is remembered between launches.

To send the reports to an endpoint of your own as well, such as a test CMCD endpoint, press **Destination…**, enter its URL, and save it as CMCD or JSON. Next to the button, the app counts the reports it sent there, with the last HTTP status. The destination is remembered between launches; changing or removing it joins Lens again, which ends the current session. The example allows plain `http` endpoints.

In `LensExample/Config.swift`, you can set `theoplayerLicense`, your THEOplayer license, needed for streams of your own. The example streams play without one.

## The scenario

The scenario is the same on every platform's Lens demo, so that their reports can be compared in the backend. It takes about a minute, and its source is reported with the content ID `lens-connector-demo-scenario`:

1. Load Big Buck Bunny (`https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8`), as a new source.
2. Play for 10 s.
3. Pause for 3 s.
4. Play for 5 s.
5. Seek to 120 s, play for 5 s.
6. Mute for 3 s, then unmute for 2 s.
7. Play at rate 2 for 5 s, then at rate 1 for 2 s.
8. Go picture-in-picture for 5 s, then inline for 2 s.
9. Seek to 5 s before the end, play to the end, wait 2 s, and unload the source.

Every platform makes the same choices behind these timings:

- A play step counts from when playback starts (`playing`), not from the play request, so a slow startup does not shorten it.
- A seek step waits for the seek to complete (`seeked`) before counting.
- Picture-in-picture is the player's own: the in-page one on web, and here THEOplayer's in-app one (`nativePictureInPicture` off), not the system's. A presentation step counts from when the player has changed mode.

Lens reports `sta=e` at the end, and no quit report after it: the session is over once the content has ended.

Press **Run scenario** to run it, with **Send to staging** on or off; press it again to stop. To run it unattended, launch the app with arguments, for example on a booted simulator:

```sh
xcrun simctl launch booted com.theoplayer.connector.LensExample -runScenario YES -sendToStaging YES
```

`-destinationUrl <url>` and `-destinationFormat cmcd|json` set a destination of your own for that launch.
