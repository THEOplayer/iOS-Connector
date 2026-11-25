//
//  BitrateTests.swift
//

import XCTest
import THEOplayerSDK
import ConvivaSDK
@testable import THEOplayerConnectorConviva

/// These tests need real playback: the player only reports an active quality once it renders media.
@MainActor
final class BitrateTests: XCTestCase {
    // C8
    func testActiveQualityIsReportedInKbpsToContentEndpoint() throws {
        let harness = makeHarness()
        let player = harness.player

        let quality = try XCTUnwrap(playAndWaitForActiveQuality(of: player) {
            player.source = TestSources.hls()
        })

        let reported = harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).compactMap { ($0 as? NSNumber)?.intValue }
        XCTAssertEqual(reported.first, quality.bandwidth / 1000)
        XCTAssertTrue(harness.ad.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty)
    }

    // C8
    func testActiveQualityDuringAdIsReportedToAdEndpoint() throws {
        let harness = makeHarness()
        let player = harness.player
        let controller = harness.registerCustomAdIntegration()

        let quality = try XCTUnwrap(playAndWaitForActiveQuality(of: player) {
            player.source = TestSources.hls()
            let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: 0, maxDuration: 30))
            controller.beginAd(ad: controller.createAd(params: AdInit(type: "linear", duration: 30), adBreak: adBreak))
        })

        XCTAssertTrue(player.ads.playing)
        let reported = harness.ad.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).compactMap { ($0 as? NSNumber)?.intValue }
        XCTAssertEqual(reported.first, quality.bandwidth / 1000)
        XCTAssertTrue(harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty)
    }

    // C8
    func testBitrateIsReportedAgainForNewSession() throws {
        let harness = makeHarness()
        let player = harness.player
        _ = try XCTUnwrap(playAndWaitForActiveQuality(of: player) {
            player.source = TestSources.hls()
        })

        let lastBitrate = try XCTUnwrap(harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).last as? NSNumber)
        XCTAssertEqual(harness.video.playbackRequested.count, 1)
        XCTAssertEqual(harness.video.playerStates.last, .CONVIVA_PLAYING)

        harness.connector.stopAndStartNewSession(contentInfo: [:])

        XCTAssertEqual(harness.video.playbackEndedCount, 1)
        XCTAssertEqual(harness.video.playbackRequested.count, 2)
        let newSessionStart = try XCTUnwrap(harness.video.metricCountAtPlaybackRequested.last)
        let replayed = harness.video.metrics[newSessionStart...]
            .filter { $0.key == CIS_SSDK_PLAYBACK_METRIC_BITRATE }
            .map { $0.value as? NSNumber }
        XCTAssertEqual(replayed, [lastBitrate])
    }
}
