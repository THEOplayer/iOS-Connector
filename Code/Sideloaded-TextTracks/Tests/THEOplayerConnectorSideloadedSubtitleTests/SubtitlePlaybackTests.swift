import XCTest
import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class SubtitlePlaybackTests: XCTestCase {
    func testSideloadedWebVTTAddsTrackAndEntersCueDuringPlayback() async {
        let base = "https://cdn.theoplayer.com/video/elephants-dream"
        let video = TypedSource(src: "\(base)/playlist-no-subtitles.m3u8", type: "application/x-mpegurl")
        let subtitle = SSTextTrackDescription(
            src: "\(base)/captions.en.vtt", srclang: "en", isDefault: false,
            kind: .subtitles, label: "English", format: .WebVTT
        )
        let player = THEOplayer(with: nil)
        let added = expectation(description: "English sideloaded subtitle track added")
        let entered = expectation(description: "First English subtitle cue entered")
        var foundTrack = false
        let addListener = player.textTracks.addEventListener(type: TextTrackListEventTypes.ADD_TRACK) { event in
            guard !foundTrack, let track = event.track as? TextTrack, track.language == "en" else { return }
            foundTrack = true
            var observedCue = false
            _ = track.addEventListener(type: TextTrackEventTypes.ADD_CUE) { event in
                guard !observedCue else { return }
                observedCue = true
                XCTAssertTrue(event.cue.contentString?.contains("At the left we can see") == true)
                _ = event.cue.addEventListener(type: TextTrackCueEventTypes.ENTER) { _ in
                    entered.fulfill()
                }
            }
            added.fulfill()
            track.mode = .showing
        }
        let errorListener = player.addEventListener(type: PlayerEventTypes.ERROR) { event in
            XCTFail("Playback error: \(event.errorObject?.message ?? "unknown")")
        }
        defer {
            player.textTracks.removeEventListener(type: TextTrackListEventTypes.ADD_TRACK, listener: addListener)
            player.removeEventListener(type: PlayerEventTypes.ERROR, listener: errorListener)
            player.setSourceWithSubtitles(source: nil)
        }

        player.setSourceWithSubtitles(source: SourceDescription(source: video, textTracks: [subtitle]))
        player.play()

        await fulfillment(of: [added, entered], timeout: 45, enforceOrder: true)
    }
}
