//
//  SourceChangeTests.swift
//

import XCTest
import THEOplayerSDK
@testable import THEOplayerConnectorConviva

@MainActor
final class SourceChangeTests: XCTestCase {
    // C2
    func testNewSourceEndsPreviousSession() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        waitForEvent(PlayerEventTypes.SOURCE_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls(TestSources.elephantsDream)
        }

        XCTAssertEqual(harness.video.playbackEndedCount, 1)
        XCTAssertEqual(harness.video.cleanupCount, 1)
    }

    // C2
    func testNewSourceClearsMetadataOfPreviousSession() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        harness.connector.setContentInfo(["previousSourceOnly": "yes"])
        XCTAssertEqual(harness.video.contentInfoValues("previousSourceOnly").count, 1)

        harness.player.source = TestSources.hls(TestSources.elephantsDream)
        let contentInfosBefore = harness.video.contentInfos.count
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        let newSessionInfos = harness.video.contentInfos.dropFirst(contentInfosBefore)
        XCTAssertFalse(newSessionInfos.isEmpty)
        XCTAssertTrue(newSessionInfos.allSatisfy { $0["previousSourceOnly"] == nil })
        XCTAssertEqual(newSessionInfos.last?[CIS_SSDK_METADATA_STREAM_URL] as? String, TestSources.elephantsDream)
    }

    // C2
    func testSettingSameSourceKeepsSession() {
        let harness = makeHarness()
        let source = TestSources.hls()
        harness.player.source = source
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        waitForEvent(PlayerEventTypes.SOURCE_CHANGE, on: harness.player) { harness.player.source = source }

        XCTAssertEqual(harness.video.playbackEndedCount, 0)
    }
}
