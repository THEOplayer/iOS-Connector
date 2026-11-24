//
//  FailedAdBreakTests.swift
//

import XCTest
import THEOplayerSDK
import ConvivaSDK
@testable import THEOplayerConnectorConviva
#if canImport(THEOplayerTHEOadsIntegration)
import THEOplayerTHEOadsIntegration
#endif

@MainActor
final class FailedAdBreakTests: XCTestCase {
    // C10
    func testFailedAdBreakIsReportedAsServerGuidedPod() {
        let analytics = RecordingAnalytics()
        let endpoints = ConvivaEndpoints(analytics: analytics)
        let storage = ConvivaStorage()
        let handler = AdHandler(endpoints: endpoints, storage: storage)

        handler.reportFailedAdBreak(message: "No ad available", podDuration: 12.5, podPosition: "Mid-roll")

        let started = analytics.video.adBreaksStarted
        XCTAssertEqual(started.count, 1)
        XCTAssertEqual(started.first?.adType, .SERVER_SIDE)
        XCTAssertEqual(started.first?.info[CIS_SSDK_AD_BREAK_POD_INDEX] as? String, "1")
        XCTAssertEqual(started.first?.info[CIS_SSDK_AD_BREAK_POD_POSITION] as? String, "Mid-roll")
        XCTAssertEqual(started.first?.info[CIS_SSDK_AD_BREAK_POD_DURATION] as? String, "12.5")
        XCTAssertEqual(started.first?.info["podTechnology"] as? String, "Server Guided")
        XCTAssertEqual(analytics.ad.adFailed.map(\.message), ["No ad available"])
        XCTAssertEqual(analytics.ad.adFailed.first?.adInfo?["c3.ad.technology"] as? String, "Server Guided")
        XCTAssertEqual(analytics.ad.adFailed.first?.adInfo?["c3.csid"] as? Int32, 42)
        XCTAssertEqual(analytics.video.adBreakEndedCount, 1)
        withExtendedLifetime((endpoints, storage)) {}
    }

    // C10
    func testFailedAdBreakIsIgnoredWhileAdBreakIsActive() {
        let harness = makeHarness()
        let controller = harness.registerCustomAdIntegration()
        let analytics = RecordingAnalytics()
        let endpoints = ConvivaEndpoints(analytics: analytics)
        let storage = ConvivaStorage()
        let handler = AdHandler(endpoints: endpoints, storage: storage)
        let forwarder = AdEventForwarder(player: harness.player, handler: handler)
        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: 0, maxDuration: 30))
        let ad = controller.createAd(params: AdInit(type: "linear", duration: 30), adBreak: adBreak)
        guard waitForEvent(AdsEventTypes.AD_BREAK_BEGIN, on: harness.player.ads, afterAdForwarding: true, after: {
            controller.beginAd(ad: ad)
        }) != nil else { return }

        handler.reportFailedAdBreak(message: "No ad available", podDuration: 30, podPosition: "Mid-roll")
        XCTAssertEqual(analytics.video.adBreaksStarted.count, 1, "Only the active ad break must be reported")
        XCTAssertTrue(analytics.ad.adFailed.isEmpty)

        guard waitForEvent(AdsEventTypes.AD_BREAK_END, on: harness.player.ads, afterAdForwarding: true, after: {
            controller.endAd(ad: ad)
        }) != nil else { return }
        handler.reportFailedAdBreak(message: "No ad available", podDuration: 30, podPosition: "Mid-roll")

        XCTAssertEqual(analytics.video.adBreaksStarted.map { $0.info[CIS_SSDK_AD_BREAK_POD_INDEX] as? String }, ["1", "2"])
        XCTAssertEqual(analytics.ad.adFailed.count, 1)
        withExtendedLifetime((endpoints, storage, forwarder)) {}
    }

#if canImport(THEOplayerTHEOadsIntegration)
    private struct FakeInterstitial: Interstitial {
        var id = "interstitial"
        var type: InterstitialType = .adbreak
        var startTime: Double
        var duration: Double?
        var adTagParameters: [String: String] = [:]
    }

    // C10
    func testOnlyInterstitialsThatEndedBeforeCurrentTimeArePast() {
        XCTAssertTrue(AdHandler.isPast(interstitial: FakeInterstitial(startTime: 10, duration: 5), currentTime: 20))
        XCTAssertFalse(AdHandler.isPast(interstitial: FakeInterstitial(startTime: 10, duration: 5), currentTime: 12))
        XCTAssertFalse(AdHandler.isPast(interstitial: FakeInterstitial(startTime: 30, duration: 5), currentTime: 20))
    }

    // C10
    func testPostRollInterstitialIsNeverPast() {
        XCTAssertFalse(AdHandler.isPast(interstitial: FakeInterstitial(startTime: -1, duration: 5), currentTime: 1_000))
        XCTAssertFalse(AdHandler.isPast(interstitial: FakeInterstitial(startTime: .infinity, duration: 5), currentTime: 1_000))
    }

    // C10
    func testInterstitialPodPositionFollowsStartTime() {
        XCTAssertEqual(AdHandler.calculateInterstitialAdBreakPosition(startTime: 0), "Pre-roll")
        XCTAssertEqual(AdHandler.calculateInterstitialAdBreakPosition(startTime: 30), "Mid-roll")
        XCTAssertEqual(AdHandler.calculateInterstitialAdBreakPosition(startTime: -1), "Post-roll")
        XCTAssertEqual(AdHandler.calculateInterstitialAdBreakPosition(startTime: .infinity), "Post-roll")
    }
#endif
}
