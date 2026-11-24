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

        guard playAdBreak(timeOffset: 0, maxDuration: 15, on: harness.player, using: controller),
              playAdBreak(timeOffset: 60, maxDuration: 10, on: harness.player, using: controller) else { return }

        let started = harness.video.adBreaksStarted
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_INDEX] as? String }, ["1", "2"])
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_POSITION] as? String }, ["Pre-roll", "Mid-roll"])
        XCTAssertEqual(started.map { $0.info[CIS_SSDK_AD_BREAK_POD_DURATION] as? String }, ["15", "10"])
        XCTAssertEqual(started.map { $0.info["podTechnology"] as? String }, ["Server Side", "Server Side"])
        XCTAssertEqual(started.map(\.adType), [.SERVER_SIDE, .SERVER_SIDE])
        XCTAssertEqual(harness.video.adBreakEndedCount, 2)
    }

    // C9 — needs real playback for PLAYING and PAUSE.
    func testAdPlaybackEventsAreOnlyForwardedDuringAdBreak() {
        let harness = makeHarness()
        let player = harness.player
        let controller = harness.registerCustomAdIntegration()
        player.source = TestSources.hls()

        guard playThenPause(player) else { return }
        XCTAssertTrue(harness.ad.playerStates.isEmpty)

        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: 0, maxDuration: 30))
        let ad = controller.createAd(params: AdInit(type: "linear", duration: 30), adBreak: adBreak)
        guard waitForEvent(AdsEventTypes.AD_BREAK_BEGIN, on: player.ads, afterAdForwarding: true, after: {
            controller.beginAd(ad: ad)
        }) != nil else { return }

        guard playThenPause(player) else { return }
        XCTAssertEqual(harness.ad.playerStates.last, .CONVIVA_PAUSED)

        guard waitForEvent(AdsEventTypes.AD_BREAK_END, on: player.ads, afterAdForwarding: true, after: {
            controller.endAd(ad: ad)
        }) != nil else { return }
        let adStatesAfterBreak = harness.ad.playerStates.count

        guard playThenPause(player) else { return }
        XCTAssertEqual(harness.ad.playerStates.count, adStatesAfterBreak)
    }

    private func playThenPause(_ player: THEOplayer) -> Bool {
        guard waitForEvent(PlayerEventTypes.PLAYING, on: player, after: { player.play() }) != nil else { return false }
        return waitForEvent(PlayerEventTypes.PAUSE, on: player, afterAdForwarding: true, after: { player.pause() }) != nil
    }

    private func playAdBreak(timeOffset: Int, maxDuration: Int, on player: THEOplayer, using controller: ServerSideAdIntegrationController) -> Bool {
        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: timeOffset, maxDuration: maxDuration))
        let ad = controller.createAd(params: AdInit(type: "linear", duration: maxDuration), adBreak: adBreak)
        guard waitForEvent(AdsEventTypes.AD_BREAK_BEGIN, on: player.ads, afterAdForwarding: true, after: {
            controller.beginAd(ad: ad)
        }) != nil else { return false }
        return waitForEvent(AdsEventTypes.AD_BREAK_END, on: player.ads, afterAdForwarding: true, after: {
            controller.endAd(ad: ad)
        }) != nil
    }
}
