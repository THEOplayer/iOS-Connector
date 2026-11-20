import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle

final class TimestampStringUtilsTests: XCTestCase {
    private let cue = "\n00:00:01.000 --> 00:00:02.000\nHello\n"

    func testReadsTimestampWithColonsInLocalTime() throws {
        let vtt = "WEBVTT\nX-TIMESTAMP-MAP=LOCAL:01:02:03.456,MPEGTS:90000\n" + cue
        let (pts, localTime) = try XCTUnwrap(TimestampStringUtils.getTimestampValues(from: vtt))

        XCTAssertEqual(pts, "90000")
        XCTAssertEqual(localTime, "01:02:03.456")
    }

    func testOverridesTimestampWithoutChangingCue() {
        let vtt = "WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:90000,LOCAL:00:00:00.000\n" + cue
        let overridden = TimestampStringUtils.overrideTimestamp(in: vtt, with: ("180000", "00:00:01.000"))

        XCTAssertEqual(overridden, "WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:180000,LOCAL:00:00:01.000\n" + cue)
    }

    func testInsertsTimestampWhenTagIsMissing() {
        let vtt = "WEBVTT\n" + cue
        let values = ("180000", "00:00:01.000")

        XCTAssertNil(TimestampStringUtils.getTimestampValues(from: vtt))
        XCTAssertNil(TimestampStringUtils.overrideTimestamp(in: vtt, with: values))
        XCTAssertEqual(
            TimestampStringUtils.insertTimestamp(in: vtt, with: values),
            "WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:180000,LOCAL:00:00:01.000\n" + cue
        )
    }
}
