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
    func testActiveQualityIsReportedInKbpsToContentEndpoint() {
        let harness = makeHarness()
        let bandwidths = recordActiveQualityBandwidths(of: harness.player)
        harness.player.source = TestSources.hls()
        harness.player.play()

        waitUntil("content bitrate reported") { !harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty }

        let reported = harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).compactMap { ($0 as? NSNumber)?.intValue }
        XCTAssertEqual(reported.first, bandwidths.values.first.map { $0 / 1000 })
        XCTAssertTrue(harness.ad.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty)
    }

    // C8
    func testActiveQualityDuringAdIsReportedToAdEndpoint() {
        let harness = makeHarness()
        let controller = harness.registerCustomAdIntegration()
        harness.player.source = TestSources.hls()
        let adBreak = controller.createAdBreak(params: AdBreakInit(timeOffset: 0, maxDuration: 30))
        controller.beginAd(ad: controller.createAd(params: AdInit(type: "linear", duration: 30), adBreak: adBreak))
        XCTAssertTrue(harness.player.ads.playing)
        harness.player.play()

        waitUntil("ad bitrate reported") { !harness.ad.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty }

        XCTAssertTrue(harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty)
    }

    // C8
    func testBitrateIsReportedAgainForNewSession() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()
        harness.player.play()
        waitUntil("content bitrate reported") { !harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).isEmpty }
        let lastBitrate = harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).last as? NSNumber
        harness.player.pause()
        drainMainQueue()
        let reportedBefore = harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE).count

        harness.connector.stopAndStartNewSession(contentInfo: [:])

        let reported = harness.video.metricValues(CIS_SSDK_PLAYBACK_METRIC_BITRATE)
        XCTAssertEqual(reported.count, reportedBefore + 1)
        XCTAssertEqual(reported.last as? NSNumber, lastBitrate)
    }

    private final class Bandwidths { var values: [Int] = [] }

    private func recordActiveQualityBandwidths(of player: THEOplayer) -> Bandwidths {
        let bandwidths = Bandwidths()
        _ = player.videoTracks.addEventListener(type: VideoTrackListEventTypes.ADD_TRACK) { event in
            _ = (event.track as? VideoTrack)?.addEventListener(type: MediaTrackEventTypes.ACTIVE_QUALITY_CHANGED) {
                bandwidths.values.append($0.quality.bandwidth)
            }
        }
        return bandwidths
    }
}
