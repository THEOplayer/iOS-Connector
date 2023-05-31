import XCTest
import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

final class THEOplayerSideloadedSubtitleConnectorTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let player = THEOplayer(with: nil)
        XCTAssertNoThrow(player.setSourceWithSubtitles(source: nil))
    }
}
