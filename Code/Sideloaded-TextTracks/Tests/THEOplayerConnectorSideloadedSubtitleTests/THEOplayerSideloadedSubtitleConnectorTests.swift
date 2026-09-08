import Foundation
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class THEOplayerSideloadedSubtitleConnectorTests: XCTestCase {
    func testSetNilSourceDoesNotThrow() {
        let player = THEOplayer(with: nil)
        XCTAssertNoThrow(player.setSourceWithSubtitles(source: nil))
    }

    func testPlaylistRequestsRemoveRangeHeaders() async throws {
        let loader = AVSubtitlesLoader(subtitles: [], id: #function, player: nil)
        let rangeValues = ["bytes=0-1", "bytes=100-200", "bytes=500-"]

        for type in HlsPlaylistType.allCases {
            for rangeValue in rangeValues {
                var request = URLRequest(url: URL(string: "https://example.com/playlist.m3u8")!)
                request.setValue(rangeValue, forHTTPHeaderField: "rAnGe")
                request.setValue("\"etag\"", forHTTPHeaderField: "iF-rAnGe")

                let modifiedRequest = try await loader.didInterceptPlaylistRequest(type: type, request: request)

                XCTAssertNil(modifiedRequest.value(forHTTPHeaderField: "Range"), "Range was retained for \(type)")
                XCTAssertNil(modifiedRequest.value(forHTTPHeaderField: "If-Range"), "If-Range was retained for \(type)")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), rangeValue)
                XCTAssertEqual(request.value(forHTTPHeaderField: "If-Range"), "\"etag\"")

                let sanitizedRequest = try await loader.didInterceptPlaylistRequest(type: type, request: modifiedRequest)
                XCTAssertNil(sanitizedRequest.value(forHTTPHeaderField: "Range"))
                XCTAssertNil(sanitizedRequest.value(forHTTPHeaderField: "If-Range"))
            }
        }
    }

    func testPlaylistRequestPreservesUnrelatedProperties() async throws {
        let loader = AVSubtitlesLoader(subtitles: [], id: #function, player: nil)
        var request = URLRequest(
            url: URL(string: "https://example.com/playlist.m3u8?token=value")!,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 42
        )
        request.httpMethod = "POST"
        request.httpBody = Data("body".utf8)
        request.setValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.setValue("session=value", forHTTPHeaderField: "Cookie")

        let modifiedRequest = try await loader.didInterceptPlaylistRequest(type: .master, request: request)

        XCTAssertEqual(modifiedRequest.url, request.url)
        XCTAssertEqual(modifiedRequest.httpMethod, request.httpMethod)
        XCTAssertEqual(modifiedRequest.httpBody, request.httpBody)
        XCTAssertEqual(modifiedRequest.cachePolicy, request.cachePolicy)
        XCTAssertEqual(modifiedRequest.timeoutInterval, request.timeoutInterval)
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Cookie"), "session=value")
    }

    func testSanitizedRequestObtainsCompleteManifest() async throws {
        let loader = AVSubtitlesLoader(subtitles: [], id: #function, player: nil)
        var request = URLRequest(url: URL(string: "https://example.com/master.m3u8")!)
        request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        let modifiedRequest = try await loader.didInterceptPlaylistRequest(type: .master, request: request)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RangeAwareURLProtocol.self]

        let (data, response) = try await URLSession(configuration: configuration).data(for: modifiedRequest)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), RangeAwareURLProtocol.manifest)
    }
}

private final class RangeAwareURLProtocol: URLProtocol {
    static let manifest = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8"

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let isRanged = request.value(forHTTPHeaderField: "Range") != nil
        let data = Data((isRanged ? "#E" : Self.manifest).utf8)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: isRanged ? 206 : 200,
            httpVersion: "HTTP/1.1",
            headerFields: isRanged ? ["Content-Range": "bytes 0-1/\(Self.manifest.utf8.count)"] : nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
