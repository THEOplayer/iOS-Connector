import Swifter
import XCTest
import THEOplayerConnectorSideloadedSubtitle

@MainActor
final class SourceTimestampTests: XCTestCase {
    func testExtractSourceTimestampReturnsValuesWithoutSettingOverride() async throws {
        let origin = HttpServer()
        origin["/mapped.vtt"] = { _ in .ok(.text("WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:90000,LOCAL:01:02:03.456\n\n")) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        defer { origin.stop() }
        let track = SSTextTrackDescription(src: "http://127.0.0.1:\(try origin.port())/mapped.vtt", srclang: "en")
        let extracted = expectation(description: "Timestamp extracted")

        track.extractSourceTimestamp { timestamp, error in
            XCTAssertNil(error)
            XCTAssertEqual(timestamp.pts, "90000")
            XCTAssertEqual(timestamp.localTime, "01:02:03.456")
            extracted.fulfill()
        }

        await fulfillment(of: [extracted], timeout: 5)
        XCTAssertNil(track.vttTimestamp.pts)
        XCTAssertNil(track.vttTimestamp.localTime)
    }

    func testExtractSourceTimestampReportsMissingTag() async throws {
        let origin = HttpServer()
        origin["/unmapped.vtt"] = { _ in .ok(.text("WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHello\n")) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        defer { origin.stop() }
        let track = SSTextTrackDescription(src: "http://127.0.0.1:\(try origin.port())/unmapped.vtt", srclang: "en")
        let extracted = expectation(description: "Missing timestamp reported")

        track.extractSourceTimestamp { timestamp, error in
            XCTAssertNil(timestamp.pts)
            XCTAssertNil(timestamp.localTime)
            XCTAssertEqual(error.map { String(describing: $0) }, "Could not find a timestamp in the WebVTT file.")
            extracted.fulfill()
        }

        await fulfillment(of: [extracted], timeout: 5)
    }
}
