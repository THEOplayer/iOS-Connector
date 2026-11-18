//
//  ErrorTests.swift
//

import XCTest
import THEOplayerSDK
@testable import THEOplayerConnectorConviva

final class ErrorTests: XCTestCase {
    private let analytics = RecordingAnalytics()
    private lazy var endpoints = ConvivaEndpoints(analytics: analytics)
    private let storage = ConvivaStorage()
    private lazy var handler = PlayerHandler(endpoints: endpoints, storage: storage, convivaMetadata: [:])

    // C4
    func testFatalErrorFailsSessionOnce() {
        handler.maybeReportPlaybackRequested()

        handler.error(event: ErrorEvent(error: "first", errorObject: nil))
        handler.error(event: ErrorEvent(error: "second", errorObject: nil))

        XCTAssertEqual(analytics.video.playbackFailed, ["first"])
    }

    // C4
    func testFatalErrorResetsSession() {
        handler.maybeReportPlaybackRequested()
        handler.error(event: ErrorEvent(error: "fatal", errorObject: nil))

        handler.maybeReportPlaybackRequested()

        XCTAssertEqual(analytics.video.playbackRequested.count, 2)
    }

    // C4
    func testFatalErrorWithoutSessionIsNotReported() {
        handler.error(event: ErrorEvent(error: "fatal", errorObject: nil))

        XCTAssertTrue(analytics.video.playbackFailed.isEmpty)
    }
}
