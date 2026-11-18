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

    // C4
    func testNetworkErrorIsReportedAsWarningAndKeepsSession() {
        let harness = makeHarness()
        harness.player.source = TestSources.hls(TestSources.missingSegment)
        harness.player.currentTime = 15

        // Snapshot inside the listener: AVPlayer may give up on the stream later and raise a fatal ERROR.
        let networkErrorReceived = expectation(description: "network ERROR event")
        var errorsAtNetworkError: [(message: String, severity: ErrorSeverity)] = []
        var failedAtNetworkError: [String] = []
        var endedAtNetworkError = -1
        let listener = harness.player.network.addEventListener(type: NetworkEventTypes.ERROR) { _ in
            guard endedAtNetworkError < 0 else { return }
            errorsAtNetworkError = harness.video.playbackErrors
            failedAtNetworkError = harness.video.playbackFailed
            endedAtNetworkError = harness.video.playbackEndedCount
            networkErrorReceived.fulfill()
        }
        harness.player.play()
        wait(for: [networkErrorReceived], timeout: 60)
        harness.player.network.removeEventListener(type: NetworkEventTypes.ERROR, listener: listener)

        XCTAssertEqual(harness.video.playbackRequested.count, 1)
        XCTAssertEqual(errorsAtNetworkError.map(\.severity), [.ERROR_WARNING])
        XCTAssertEqual(failedAtNetworkError, [])
        XCTAssertEqual(endedAtNetworkError, 0)
    }
}
