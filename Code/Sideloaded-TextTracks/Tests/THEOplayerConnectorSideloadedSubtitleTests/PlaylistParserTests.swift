import Foundation
import Swifter
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle

final class PlaylistParserTests: XCTestCase {
    private let manifestURL = URL(string: "https://cdn.example.com/vod/movie/index.m3u8?token=abc")!
    private let manifestURLWithoutQuery = URL(string: "https://cdn.example.com/vod/movie/index.m3u8")!

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

    // MARK: - Percent-encoding (PR37 regression: %20 must not become %2520)

    func testRelativeURIWithEncodedSpacesIsNotDoubleEncoded() {
        let parser = PlaylistParser(url: manifestURLWithoutQuery, request: nil)

        let url = parser.getFullURL(from: "MK-CB-S01E05-es-419-227%20Soy%20una%20tazaUHD.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/MK-CB-S01E05-es-419-227%20Soy%20una%20tazaUHD.m3u8")
    }

    func testRelativeURIKeepsEncodedLiteralPercent() {
        let parser = PlaylistParser(url: manifestURLWithoutQuery, request: nil)

        let url = parser.getFullURL(from: "100%25.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/100%25.m3u8")
    }

    func testRelativeURIKeepsDoubleEncodedSpace() {
        let parser = PlaylistParser(url: manifestURLWithoutQuery, request: nil)

        let url = parser.getFullURL(from: "a%2520b.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/a%2520b.m3u8")
    }

    func testRelativeURIKeepsEscapedQuestionMarkInFileName() {
        let parser = PlaylistParser(url: manifestURLWithoutQuery, request: nil)

        let url = parser.getFullURL(from: "video%3Falt.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/video%3Falt.m3u8")
        XCTAssertNil(url?.query)
    }

    func testRelativeURIKeepsEscapedQueryValueBytesAndOrder() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "video.m3u8?b=2&token=a%26b%2Bc%3Dd%25e&a=1")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/video.m3u8?b=2&token=a%26b%2Bc%3Dd%25e&a=1")
    }

    func testAbsoluteEncodedURIIsNotChanged() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "https://other.example.com/path%20x/video%3Falt.m3u8?token=a%26b")

        XCTAssertEqual(url?.absoluteString, "https://other.example.com/path%20x/video%3Falt.m3u8?token=a%26b")
    }

    func testRelativeURIKeepsEncodedURLInPathSegment() {
        let parser = PlaylistParser(url: manifestURLWithoutQuery, request: nil)

        let url = parser.getFullURL(from: "proxy/https%3A%2F%2Forigin.com%2Fvideo.m3u8%3Ftoken%3Dabc")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/proxy/https%3A%2F%2Forigin.com%2Fvideo.m3u8%3Ftoken%3Dabc")
    }

    // MARK: - Reference forms

    func testRootRelativeURIIsResolvedAgainstManifestHost() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "/root/video.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/root/video.m3u8")
    }

    func testRootRelativeURIKeepsQueryString() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "/root/video.m3u8?accountId=1")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/root/video.m3u8?accountId=1")
    }

    func testSchemeRelativeURIUsesManifestScheme() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "//other.example.com/live/video.m3u8?token=xyz")

        XCTAssertEqual(url?.absoluteString, "https://other.example.com/live/video.m3u8?token=xyz")
    }

    func testRelativeURIIsTrimmed() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: " \tvideo.m3u8?accountId=1 \r\n")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/movie/video.m3u8?accountId=1")
    }

    func testEmptyURIReturnsNil() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        XCTAssertNil(parser.getFullURL(from: ""))
    }

    func testWhitespaceOnlyURIReturnsNil() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        XCTAssertNil(parser.getFullURL(from: " \t\r\n"))
    }

    func testRelativeURIInParentDirectoryDoesNotInheritManifestQuery() {
        let parser = PlaylistParser(url: manifestURL, request: nil)

        let url = parser.getFullURL(from: "../other/video.m3u8")

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/vod/other/video.m3u8")
    }

    // MARK: - Playlist rewriting (local HTTP fixtures)

    func testMasterPlaylistRewritesVariantAndMediaURIs() async throws {
        let master = """
        #EXTM3U
        #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="English",URI="audio/en%20main.m3u8?token=a1"
        #EXT-X-STREAM-INF:BANDWIDTH=1000,AUDIO="aud"
        video=391132.m3u8?hdntl=st=1~exp=2~acl=/*~hmac=ff
        #EXT-X-STREAM-INF:BANDWIDTH=2000,AUDIO="aud"
        MK-CB-S01E05-es-419-227%20Soy%20una%20tazaUHD.m3u8
        #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=500,URI="iframes/i.m3u8"

        """
        let (server, base) = try startServer(["/vod/master.m3u8": master])
        defer { server.stop() }
        let parser = MasterPlaylistParser(url: URL(string: "\(base)/vod/master.m3u8?token=parent")!, request: nil)

        let data = await parser.sideLoadSubtitles(subtitles: [])

        let lines = String(decoding: try XCTUnwrap(data), as: UTF8.self).components(separatedBy: "\n")
        XCTAssertTrue(lines.contains("\(base)/vod/video=391132.m3u8?hdntl=st=1~exp=2~acl=/*~hmac=ff"), "\(lines)")
        XCTAssertTrue(lines.contains("\(base)/vod/MK-CB-S01E05-es-419-227%20Soy%20una%20tazaUHD.m3u8"), "\(lines)")
        XCTAssertTrue(lines.contains { $0.hasPrefix("#EXT-X-MEDIA:") && $0.contains("URI=\"\(base)/vod/audio/en%20main.m3u8?token=a1\"") }, "\(lines)")
        XCTAssertTrue(lines.contains { $0.hasPrefix("#EXT-X-I-FRAME-STREAM-INF:") && $0.contains("URI=\"\(base)/vod/iframes/i.m3u8\"") }, "\(lines)")
    }

    func testMasterPlaylistResolvesAgainstRedirectedURL() async throws {
        let master = "#EXTM3U\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"English\",URI=\"audio.m3u8\"\n#EXT-X-STREAM-INF:BANDWIDTH=1000,AUDIO=\"aud\"\nvideo.m3u8?sig=1\n"
        let (server, base) = try startServer(["/final/dir/master.m3u8": master])
        defer { server.stop() }
        server["/start/master.m3u8"] = { _ in .movedTemporarily("/final/dir/master.m3u8") }
        let parser = MasterPlaylistParser(url: URL(string: "\(base)/start/master.m3u8")!, request: nil)

        let data = await parser.sideLoadSubtitles(subtitles: [])

        XCTAssertEqual(parser.manifestURL.absoluteString, "\(base)/final/dir/master.m3u8")
        let lines = String(decoding: try XCTUnwrap(data), as: UTF8.self).components(separatedBy: "\n")
        XCTAssertTrue(lines.contains("\(base)/final/dir/video.m3u8?sig=1"), "\(lines)")
        XCTAssertTrue(lines.contains { $0.contains("URI=\"\(base)/final/dir/audio.m3u8\"") }, "\(lines)")
    }

    func testVariantPlaylistRewritesSegmentKeyAndMapURIs() async throws {
        let variant = """
        #EXTM3U
        #EXT-X-VERSION:7
        #EXT-X-TARGETDURATION:6
        #EXT-X-MAP:URI="init%20file.mp4?sig=a1"
        #EXT-X-KEY:METHOD=AES-128,URI="keys/key.bin?token=k1&exp=2"
        #EXTINF:6.000,
        #EXT-X-BYTERANGE:1000@0
        seg%20one.ts?hdntl=exp=2~acl=/*~hmac=ff
        #EXTINF:4.500,
        #EXT-X-PROGRAM-DATE-TIME:2024-01-01T00:00:06.000Z
        ../shared/seg2.ts
        #EXT-X-ENDLIST

        """
        let (server, base) = try startServer(["/vod/movie/video.m3u8": variant])
        defer { server.stop() }
        let parser = VariantPlaylistParser(url: URL(string: "\(base)/vod/movie/video.m3u8?token=parent")!, request: nil)

        let result = await parser.parse()

        let parsed = try XCTUnwrap(result)
        XCTAssertEqual(parsed.totalPlayListDuration, 10.5, accuracy: 0.0001)
        let lines = String(decoding: try XCTUnwrap(parsed.manifestData), as: UTF8.self).components(separatedBy: "\n")
        // Only the duration is compared for EXTINF: the parser drops the empty title separator.
        let comparableLines = lines.map { $0.hasPrefix("#EXTINF:") ? String($0.prefix { $0 != "," }) : $0 }
        XCTAssertEqual(comparableLines, [
            "#EXTM3U",
            "#EXT-X-VERSION:7",
            "#EXT-X-TARGETDURATION:6",
            "#EXT-X-MAP:URI=\"\(base)/vod/movie/init%20file.mp4?sig=a1\"",
            lines.first { $0.hasPrefix("#EXT-X-KEY:") } ?? "<missing EXT-X-KEY>",
            "#EXTINF:6.000",
            "#EXT-X-BYTERANGE:1000@0",
            "\(base)/vod/movie/seg%20one.ts?hdntl=exp=2~acl=/*~hmac=ff",
            "#EXTINF:4.500",
            "#EXT-X-PROGRAM-DATE-TIME:2024-01-01T00:00:06.000Z",
            "\(base)/vod/shared/seg2.ts",
            "#EXT-X-ENDLIST",
        ])
        let keyLine = try XCTUnwrap(lines.first { $0.hasPrefix("#EXT-X-KEY:") })
        XCTAssertTrue(keyLine.contains("METHOD=AES-128"), keyLine)
        XCTAssertTrue(keyLine.contains("URI=\"\(base)/vod/movie/keys/key.bin?token=k1&exp=2\""), keyLine)
    }

    func testVariantPlaylistKeepsEscapedSignatureBytes() async throws {
        let variant = """
        #EXTM3U
        #EXT-X-TARGETDURATION:6
        #EXT-X-KEY:METHOD=AES-128,URI="key.bin?sig=k%2F1%2B%3D"
        #EXTINF:6.000,
        seg1.ts?exp=2&sig=ab%2Fcd%2B%3D%3D
        #EXT-X-ENDLIST

        """
        let (server, base) = try startServer(["/vod/movie/video.m3u8": variant])
        defer { server.stop() }
        let parser = VariantPlaylistParser(url: URL(string: "\(base)/vod/movie/video.m3u8")!, request: nil)

        let result = await parser.parse()

        let lines = String(decoding: try XCTUnwrap(try XCTUnwrap(result).manifestData), as: UTF8.self).components(separatedBy: "\n")
        XCTAssertTrue(lines.contains("\(base)/vod/movie/seg1.ts?exp=2&sig=ab%2Fcd%2B%3D%3D"), "\(lines)")
        let keyLine = try XCTUnwrap(lines.first { $0.hasPrefix("#EXT-X-KEY:") })
        XCTAssertTrue(keyLine.contains("URI=\"\(base)/vod/movie/key.bin?sig=k%2F1%2B%3D\""), keyLine)
    }

    private func startServer(_ playlists: [String: String]) throws -> (HttpServer, String) {
        let server = HttpServer()
        for (path, playlist) in playlists {
            server[path] = { _ in .ok(.data(Data(playlist.utf8), contentType: "application/vnd.apple.mpegurl")) }
        }
        try server.start(0, forceIPv4: true, priority: .userInitiated)
        return (server, "http://127.0.0.1:\(try server.port())")
    }
}
