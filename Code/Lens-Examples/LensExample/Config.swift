//
//  Config.swift
//  LensExample
//

/// Your THEOplayer license, from the OptiView portal. The example streams play without one.
let theoplayerLicense: String? = nil

/// An endpoint that also receives the Lens reports as JSON, such as a request inspector you can watch.
let lensDestinationUrl: String? = nil

let exampleSources: [(title: String, src: String)] = [
    ("Big Buck Bunny (HLS VOD)", "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"),
    ("Elephants Dream (HLS VOD)", "https://cdn.theoplayer.com/video/elephants-dream/playlist-no-subtitles.m3u8"),
    ("Broken URL (fatal error)", "https://cdn.theoplayer.com/video/lens-example/missing.m3u8"),
]
