import Foundation
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle

final class PlaylistParserTests: XCTestCase {
    private let manifestURL = URL(string: "https://cdn.example.com/vod/movie/index.m3u8?token=abc")!

    func testRelativeURIKeepsQueryString() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "video=391132.m3u8?hdntl=st=1~exp=2~acl=/*~hmac=ff")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/video=391132.m3u8?hdntl=st=1~exp=2~acl=/*~hmac=ff")
    }

    func testRelativeURIInSubdirectoryKeepsQueryString() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "keyframes/video.m3u8?accountId=1")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/keyframes/video.m3u8?accountId=1")
    }

    func testRelativeURIInParentDirectoryKeepsQueryString() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "../other/video.m3u8?accountId=1")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/other/video.m3u8?accountId=1")
    }

    func testRelativeURIWithoutQueryIsResolvedAgainstManifestDirectory() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "video.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/video.m3u8")
    }

    func testAbsoluteURIIsNotChanged() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "https://other.example.com/video.m3u8?token=xyz")

        XCTAssertEqual(url?.absoluteString, "https://other.example.com/video.m3u8?token=xyz")
    }
}
