//
//  EncodingTypeTests.swift
//

import XCTest
import THEOplayerSDK
import THEOplayerTHEOliveIntegration
@testable import THEOplayerConnectorConviva

@MainActor
final class EncodingTypeTests: XCTestCase {
    // C6
    func testHlsEncodingTypeIsReportedAtSessionStart() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls()
        XCTAssertTrue(harness.video.contentInfoValues(ENCODING_TYPE).isEmpty)

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        XCTAssertEqual(harness.video.contentInfoValues(ENCODING_TYPE).first as? String, "HLS")
    }

    // C6 — HESP needs the THEOlive integration; the connector only learns the type from CURRENT_SOURCE_CHANGE.
    func testHespEncodingTypeIsReportedOnceSourceIsSelected() throws {
        let endpoint = try fetchTHEOliveDemoEndpoint()
        let harness = makeHarness()
        harness.player.addIntegration(THEOliveIntegrationFactory.createIntegration())
        harness.player.source = SourceDescription(source: TypedSource(src: endpoint.hespSrc, type: "application/vnd.theo.hesp+json"))

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }
        XCTAssertEqual(harness.video.playbackRequested.count, 1)

        waitUntil("HESP encoding_type reported") { !harness.video.contentInfoValues(ENCODING_TYPE).isEmpty }
        XCTAssertEqual(Set(harness.video.contentInfoValues(ENCODING_TYPE).compactMap { $0 as? String }), ["HESP"])
    }

    // C6
    func testCustomerEncodingTypeWins() {
        let harness = makeHarness()
        waitForEvent(PlayerEventTypes.SOURCE_CHANGE, on: harness.player) { harness.player.source = TestSources.hls() }
        harness.connector.setContentInfo([ENCODING_TYPE: "CUSTOM"])

        waitForEvent(PlayerEventTypes.PLAY, on: harness.player) { harness.player.play() }

        XCTAssertEqual(Set(harness.video.contentInfoValues(ENCODING_TYPE).compactMap { $0 as? String }), ["CUSTOM"])
    }
}
