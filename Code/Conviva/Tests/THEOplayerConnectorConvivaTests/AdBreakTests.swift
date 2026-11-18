//
//  AdBreakTests.swift
//

import XCTest
import THEOplayerSDK
import ConvivaSDK
@testable import THEOplayerConnectorConviva

@MainActor
final class AdBreakTests: XCTestCase {
    // C9
    func testPodPositionFollowsTimeOffset() {
        XCTAssertEqual(MockAdBreak(timeOffset: 0).calculateCurrentAdBreakPosition(), "Pre-roll")
        XCTAssertEqual(MockAdBreak(timeOffset: 30).calculateCurrentAdBreakPosition(), "Mid-roll")
        XCTAssertEqual(MockAdBreak(timeOffset: -1).calculateCurrentAdBreakPosition(), "Post-roll")
    }

    // C9 — pod values must not depend on the device locale (e.g. "," as decimal separator).
    func testSerializationUsesDotWithoutGrouping() {
        let formatter = AdHandler.createSerializationFormatter()
        XCTAssertEqual(formatter.decimalSeparator, ".")
        XCTAssertFalse(formatter.usesGroupingSeparator)
        XCTAssertEqual(AdHandler.serialize(number: 12.5), "12.5")
        XCTAssertEqual(AdHandler.serialize(number: 1234567.25), "1234567.25")
        XCTAssertEqual(AdHandler.serialize(number: 30), "30")
    }

    // C9
    func testAdBreaksReportIncrementingPodIndexAndPosition() {
        let harness = makeHarness()
        let controller = harness.registerCustomAdIntegration()
        harness.player.source = TestSources.hls()

        playAdBreak(timeOffset: 0, maxDuration: 15, using: controller)
        playAdBreak(timeOffset: 60, maxDuration: 10, using: controller)
        drainMainQueue()

        let started = harness.video.adBreaksStarted
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_INDEX] as? String }, ["1", "2"])
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_POSITION] as? String }, ["Pre-roll", "Mid-roll"])
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_DURATION] as? String }, ["15", "10"])
        XCTAssertEqual(started.map { $0.info["podTechnology"] as? String }, ["Server Side", "Server Side"])
        XCTAssertEqual(started.map(\.adType), [.SERVER_SIDE, .SERVER_SIDE])
        XCTAssertEqual(harness.video.adBreakEndedCount, 2)
    }

    // C9
    func testAdPlaybackEventsAreOnlyForwardedDuringAdBreak() {
        let harness = makeHarness()
        let controller = harness.registerCustomAdIntegration()
        harness.player.source = TestSources.hls()

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        waitForEvent(PlayerEventTypes.PAUSE, on: harness.player) { harness.player.pause() }
        XCTAssertTrue(harness.ad.playerStates.isEmpty)

        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: 0, maxDuration: 30))
        controller.beginAd(ad: controller.createAd(params: AdInit(type: "linear", duration: 30), adBreak: adBreak))
        drainMainQueue()
        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        waitForEvent(PlayerEventTypes.PAUSE, on: harness.player) { harness.player.pause() }

        XCTAssertEqual(harness.ad.playerStates.last, .CONVIVA_PAUSED)
    }

    private func playAdBreak(timeOffset: Int, maxDuration: Int, using controller: ServerSideAdIntegrationController) {
        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: timeOffset, maxDuration: maxDuration))
        let ad = controller.createAd(params: AdInit(type: "linear", duration: maxDuration), adBreak: adBreak)
        controller.beginAd(ad: ad)
        controller.endAd(ad: ad)
    }
}
