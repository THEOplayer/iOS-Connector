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
    func testFiniteDurationReportsVodWithDuration() {
        let harness = makeHarness()

        let event = waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls()
        }

        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).last as? NSNumber, false)
        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).last as? NSNumber, event?.duration.map { NSNumber(value: $0) })
    }

    // C5
    func testInfiniteDurationReportsLive() throws {
        let endpoint = try fetchTHEOliveDemoEndpoint()
        let harness = makeHarness()

        let event = waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.player.source = TestSources.hls(endpoint.hlsSrc)
        }

        XCTAssertEqual(event?.duration, .infinity)
        XCTAssertEqual(harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).last as? NSNumber, true)
        XCTAssertTrue(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).isEmpty)
    }

    // C5
    func testCustomerIsLiveIsNotOverwritten() {
        let harness = makeHarness()

        waitForEvent(PlayerEventTypes.SOURCE_CHANGE, on: harness.player) { harness.player.source = TestSources.hls() }
        waitForEvent(PlayerEventTypes.DURATION_CHANGE, on: harness.player) {
            harness.connector.setContentInfo([CIS_SSDK_METADATA_IS_LIVE: true])
        }

        let reportedIsLive = harness.video.contentInfoValues(CIS_SSDK_METADATA_IS_LIVE).map { $0 as? Bool }
        XCTAssertGreaterThan(reportedIsLive.count, 1, "The duration change must have pushed content info")
        XCTAssertTrue(reportedIsLive.allSatisfy { $0 == true })
        XCTAssertTrue(harness.video.contentInfoValues(CIS_SSDK_METADATA_DURATION).isEmpty)
    }
}
