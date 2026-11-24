//
//  SessionLifecycleTests.swift
//

import XCTest
import THEOplayerSDK
import ConvivaSDK
@testable import THEOplayerConnectorConviva

@MainActor
final class SessionLifecycleTests: XCTestCase {
    // C1
    func testOnlyFirstPlayRequestsPlayback() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        waitForEvent(PlayerEventTypes.PAUSE, on: harness.player) { harness.player.pause() }
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        XCTAssertEqual(harness.video.playbackRequested.count, 1)
        XCTAssertEqual(harness.video.playbackEndedCount, 0)
    }

    // C1 — needs real playback to reach the end of the stream.
    func testEndedReportsStoppedAndEndsSession() {
        let harness = makeHarness()
        let player = harness.player
        guard waitForEvent(PlayerEventTypes.PLAYING, on: player, after: {
            player.source = TestSources.hls(TestSources.elephantsDream)
            player.play()
        }) != nil else { return }
        guard let duration = player.duration, duration.isFinite, duration > 2 else {
            return XCTFail("VOD source without usable duration")
        }

        waitForEvent(PlayerEventTypes.ENDED, on: player, timeout: 60) { player.currentTime = duration - 2 }

        XCTAssertEqual(harness.video.playbackRequested.count, 1)
        XCTAssertEqual(harness.video.playerStates.last, .CONVIVA_STOPPED)
        XCTAssertEqual(harness.video.playbackEndedCount, 1)
    }

    // C3
    func testInitialMetadataIsSentWithEverySession() {
        let initialMetadata = ["testTag": "test-value", CIS_SSDK_METADATA_VIEWER_ID: "viewer-1"]
        let harness = makeHarness(convivaMetadata: initialMetadata)
        harness.player.source = TestSources.hls()

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        harness.connector.stopAndStartNewSession(contentInfo: [:])
        harness.connector.stopAndStartNewSession(contentInfo: [:])

        XCTAssertEqual(harness.video.playbackEndedCount, 2)
        XCTAssertEqual(harness.video.playbackRequested.count, 3)
        for requested in harness.video.playbackRequested {
            XCTAssertEqual(requested as? [String: String], initialMetadata)
        }
    }

    // C7
    func testPauseReportsPausedState() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        waitForEvent(PlayerEventTypes.PAUSE, on: harness.player) { harness.player.pause() }

        XCTAssertEqual(harness.video.playerStates.last, .CONVIVA_PAUSED)
    }

    // C7 — needs real playback.
    func testPlayingReportsPlayingState() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()

        waitForEvent(PlayerEventTypes.PLAYING, on: harness.player) { harness.player.play() }

        XCTAssertEqual(harness.video.playerStates.last, .CONVIVA_PLAYING)
    }

    // C7 — needs real playback; seeking to an unbuffered position makes the player wait.
    func testWaitingReportsBufferingState() {
        let harness = makeHarness()
        let player = harness.player
        player.source = TestSources.hls()
        waitForEvent(PlayerEventTypes.PLAYING, on: player) { player.play() }

        let statesBeforeSeek = harness.video.playerStates.count

        waitForEvent(PlayerEventTypes.WAITING, on: player) { player.currentTime = 300 }

        XCTAssertTrue(harness.video.playerStates.dropFirst(statesBeforeSeek).contains(.CONVIVA_BUFFERING))
    }

    // C7
    func testNewSessionWhilePausedStartsOnPlay() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        waitForEvent(PlayerEventTypes.PAUSE, on: harness.player) { harness.player.pause() }

        harness.connector.stopAndStartNewSession(contentInfo: [:])

        XCTAssertEqual(harness.video.playbackEndedCount, 1)
        XCTAssertEqual(harness.video.playbackRequested.count, 1, "A new session must not start while paused")

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        XCTAssertEqual(harness.video.playbackRequested.count, 2)
    }
}
