# THEOplayer Connector for OptiView Lens: example

`LensExample.xcodeproj` is an iOS app that plays a few streams with THEOplayer and reports them to the OptiView Lens SDK through the [Lens connector](../Lens), with `LensConnector`. It uses the connector from this repository checkout.

Before running it, fill in `LensExample/Config.swift`:

- `theoplayerLicense`: your THEOplayer license.
- `lensDestinationUrl`: an endpoint that receives the Lens reports as JSON, such as a request inspector you can watch. The example disables the OptiView backend, so without a destination Lens reports nothing.

The app shows the current Lens session, which starts at the first play request on a source.
