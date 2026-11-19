//
//  LiveDetectionTests.swift
//

import XCTest
import THEOplayerSDK
import ConvivaSDK
@testable import THEOplayerConnectorConviva

@MainActor
final class LiveDetectionTests: XCTestCase {
    // C5
    func testFiniteDurationReportsVodWithDuration() throws {
        let harness = makeHarness()

        let event = waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls()
            harness.player.play()
        }

        let duration = try XCTUnwrap(event?.duration)
        XCTAssertTrue(duration.isFinite)
        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).last as? NSNumber, false)
        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).last as? NSNumber, NSNumber(value: duration))
    }

    // C5
    func testInfiniteDurationReportsLive() throws {
        let endpoint = try fetchTHEOliveDemoEndpoint()
        let harness = makeHarness()

        let event = waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls(endpoint.hlsSrc)
            harness.player.play()
        }

        XCTAssertEqual(event?.duration, .infinity)
        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).last as? NSNumber, true)
        XCTAssertTrue(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).isEmpty)
        XCTAssertEqual(harness.video.contentInfoValues(ENCODING_TYPE).first as? String, "HLS")
    }

    // C5
    func testCustomerIsLiveIsNotOverwritten() {
        let harness = makeHarness()
        var contentInfoCountAtPlay = 0

        waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls()
            harness.connector.setContentInfo([CIS_SSDK_METADATA_IS_LIVE: true])
            harness.player.play()
            contentInfoCountAtPlay = harness.video.contentInfos.count
        }

        let reportedIsLive = harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).map { $0 as? Bool }
        XCTAssertGreaterThan(harness.video.contentInfos.count, contentInfoCountAtPlay, "The duration change must have pushed content info")
        XCTAssertFalse(reportedIsLive.isEmpty)
        XCTAssertTrue(reportedIsLive.allSatisfy { $0 == true })
        XCTAssertTrue(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).isEmpty)
    }
}
