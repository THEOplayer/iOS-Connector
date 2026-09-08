import Foundation
import Swifter
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
        let rangeValues = ["bytes=0-1", "bytes=100-200", "bytes=500-", "items=0-1"]

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
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RangeAwareURLProtocol.self]
        let session = URLSession(configuration: configuration)

        let (partialData, partialResponse) = try await session.data(for: request)
        XCTAssertEqual((partialResponse as? HTTPURLResponse)?.statusCode, 206)
        XCTAssertEqual(String(data: partialData, encoding: .utf8), "#E")

        let modifiedRequest = try await loader.didInterceptPlaylistRequest(type: .master, request: request)
        let (data, response) = try await session.data(for: modifiedRequest)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), RangeAwareURLProtocol.manifest)
    }

    func testSanitizedManifestReloadsTransformCompletePlaylists() async throws {
        let server = HttpServer()
        let masterManifest = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8"
        let variantManifest = "#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXT-X-PLAYLIST-TYPE:VOD\n#EXTINF:10.000,\nsegment.ts\n#EXT-X-ENDLIST"
        let lock = NSLock()
        var rangedRequestPaths: [String] = []

        func manifestResponse(for request: HttpRequest, manifest: String) -> HttpResponse {
            guard request.headers["range"] == nil else {
                lock.withLock {
                    rangedRequestPaths.append(request.path)
                }
                return .raw(
                    206,
                    "Partial Content",
                    ["Content-Range": "bytes 0-1/\(manifest.utf8.count)"],
                    { try $0.write([UInt8]("#E".utf8)) }
                )
            }
            return .ok(.data(Data(manifest.utf8), contentType: "application/vnd.apple.mpegurl"))
        }

        server["/master.m3u8"] = { manifestResponse(for: $0, manifest: masterManifest) }
        server["/video.m3u8"] = { manifestResponse(for: $0, manifest: variantManifest) }
        server["/subtitle-en.vtt"] = { _ in .ok(.text("WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nEnglish")) }
        server["/subtitle-es.vtt"] = { _ in .ok(.text("WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nSpanish")) }
        try server.start(0, forceIPv4: true, priority: .userInitiated)
        defer { server.stop() }

        let port = try server.port()
        let baseURL = URL(string: "http://127.0.0.1:\(port)")!
        let masterURL = baseURL.appendingPathComponent("master.m3u8")
        let variantURL = baseURL.appendingPathComponent("video.m3u8")
        let englishSubtitleURL = baseURL.appendingPathComponent("subtitle-en.vtt")
        let spanishSubtitleURL = baseURL.appendingPathComponent("subtitle-es.vtt")
        let englishSubtitle = SSTextTrackDescription(
            src: englishSubtitleURL.absoluteString,
            srclang: "en",
            isDefault: true,
            kind: .subtitles,
            label: "English",
            format: .WebVTT
        )
        let spanishSubtitle = SSTextTrackDescription(
            src: spanishSubtitleURL.absoluteString,
            srclang: "es",
            isDefault: false,
            kind: .subtitles,
            label: "Spanish",
            format: .WebVTT
        )
        let loader = AVSubtitlesLoader(subtitles: [englishSubtitle, spanishSubtitle], id: #function, player: nil)

        var masterRequest = URLRequest(url: masterURL)
        masterRequest.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        let sanitizedMasterRequest = try await loader.didInterceptPlaylistRequest(type: .master, request: masterRequest)
        let (masterData, masterResponse) = try await URLSession.shared.data(for: sanitizedMasterRequest)
        let transformedMaster = try await loader.didInterceptPlaylistResponse(
            type: .master,
            url: masterURL,
            response: masterResponse,
            data: masterData
        )

        let transformedMasterString = String(decoding: transformedMaster, as: UTF8.self)
        XCTAssertTrue(transformedMasterString.contains("#EXT-X-MEDIA:TYPE=SUBTITLES"))
        XCTAssertTrue(transformedMasterString.contains("SUBTITLES=\"THEOsubs\""))
        XCTAssertTrue(transformedMasterString.contains("NAME=\"English\""))
        XCTAssertTrue(transformedMasterString.contains("NAME=\"Spanish\""))

        var variantRequest = URLRequest(url: variantURL)
        variantRequest.setValue("bytes=100-200", forHTTPHeaderField: "Range")
        let sanitizedVariantRequest = try await loader.didInterceptPlaylistRequest(type: .video, request: variantRequest)
        let (variantData, variantResponse) = try await URLSession.shared.data(for: sanitizedVariantRequest)
        let transformedVariant = try await loader.didInterceptPlaylistResponse(
            type: .video,
            url: variantURL,
            response: variantResponse,
            data: variantData
        )

        let transformedVariantString = String(decoding: transformedVariant, as: UTF8.self)
        XCTAssertTrue(transformedVariantString.contains("#EXTINF:10.000"))
        XCTAssertTrue(transformedVariantString.contains(baseURL.appendingPathComponent("segment.ts").absoluteString))

        for subtitleURL in [englishSubtitleURL, spanishSubtitleURL] {
            let subtitleManifest = try XCTUnwrap(loader.handleSubtitles(subtitleURL))
            let subtitleManifestString = String(decoding: subtitleManifest, as: UTF8.self)
            XCTAssertTrue(subtitleManifestString.contains("#EXT-X-TARGETDURATION:10"))
            XCTAssertTrue(subtitleManifestString.contains("#EXTINF:10.000"))
            XCTAssertTrue(subtitleManifestString.contains(subtitleURL.absoluteString))
        }

        let interceptedRanges = lock.withLock {
            rangedRequestPaths
        }
        XCTAssertTrue(interceptedRanges.isEmpty)
    }

    func testSourceReplacementWithSubtitlesDoesNotThrow() {
        let player = THEOplayer(with: nil)
        player.preload = .none
        let source = makeSourceDescription()

        XCTAssertNoThrow(player.setSourceWithSubtitles(source: source))
        XCTAssertNotNil(player.source)
        XCTAssertNoThrow(player.setSourceWithSubtitles(source: nil))
        XCTAssertNil(player.source)
    }

    #if os(iOS)
    func testCachingTaskCreationWithSubtitlesDoesNotThrow() {
        let task = THEOplayer.cache.createTaskWithSubtitles(source: makeSourceDescription(), parameters: nil)
        defer { task?.remove() }

        XCTAssertNotNil(task)
    }
    #endif

    private func makeSourceDescription() -> SourceDescription {
        let source = TypedSource(src: "https://example.com/master.m3u8", type: "application/x-mpegurl")
        let subtitle = SSTextTrackDescription(
            src: "https://example.com/subtitle.vtt",
            srclang: "en",
            isDefault: true,
            kind: .subtitles,
            label: "English",
            format: .WebVTT
        )
        return SourceDescription(source: source, textTracks: [subtitle])
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
