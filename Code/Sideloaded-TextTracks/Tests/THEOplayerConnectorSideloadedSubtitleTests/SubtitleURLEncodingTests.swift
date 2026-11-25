import Foundation
import Swifter
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class SubtitleURLEncodingTests: XCTestCase {
    func testPercentEncodedSubtitleURLsReachOriginUnchanged() async throws {
        let origin = HttpServer()
        let master = try startOrigin(origin)
        defer { origin.stop() }
        let directory = master.deletingLastPathComponent().absoluteString
        let space = subtitle(on: master, "french track.vtt", language: "fr")
        let signed = SSTextTrackDescription(
            src: directory + "signed.vtt?sig=ab%2Bcd%2Fef%3D&exp=1", srclang: "de", kind: .subtitles, label: "signed"
        )
        let srt = SSTextTrackDescription(
            src: directory + "espa%C3%B1ol.srt?sig=ab%2Bcd%2Fef%3D", srclang: "es", kind: .subtitles, label: "SRT", format: .SRT
        )
        let timestamped = subtitle(on: master, "timestamp track.vtt", language: "it")
        timestamped.vttTimestamp = .init(pts: "90000", localTime: "00:00:00.000")
        let tracks = [space, signed, srt, timestamped]
        let served = Dictionary(uniqueKeysWithValues: tracks.map { track in
            let components = URLComponents(url: track.src, resolvingAgainstBaseURL: false)!
            return (components.percentEncodedPath + (components.percentEncodedQuery.map { "?" + $0 } ?? ""), track)
        })
        var requested: [String] = []
        let lock = NSLock()
        // Swifter percent-encodes the request target once more before parsing it,
        // so the path and query values seen here are the escapes the client sent.
        origin.middleware.append { request in
            let query = request.queryParams.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
            let target = request.path + (query.isEmpty ? "" : "?" + query)
            lock.lock()
            requested.append(target)
            lock.unlock()
            guard let track = served[target] else { return nil }
            return .ok(.text(track.format == .SRT
                ? "1\n00:00:01,000 --> 00:00:02,000\n\(track.srclang)\n"
                : "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\n\(track.srclang)\n"))
        }
        let video = TypedSource(src: master.absoluteString, type: "application/x-mpegurl")
        let valid = try XCTUnwrap(SourceValidator.getValidTextTracks(SourceDescription(source: video, textTracks: tracks)))
        XCTAssertEqual(valid.map(\.src), tracks.map(\.src))
        let loader = AVSubtitlesLoader(subtitles: valid, id: #function, player: nil)

        let rewritten = try await intercept(master, type: .master, with: loader)

        for track in tracks {
            XCTAssertTrue(rewritten.contains("URI=\"\(track.src.absoluteString)\""), track.src.absoluteString)
            let (data, response) = try await URLSession.shared.data(from: try subtitleSegmentURL(for: track, with: loader))
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("\n\(track.srclang)\n"), track.src.absoluteString)
        }
        let recorded = { () -> [String] in
            lock.lock()
            defer { lock.unlock() }
            return requested
        }
        XCTAssertEqual(Set(recorded()), Set(served.keys).union(["/master.m3u8"]))
    }


    private func startOrigin(_ origin: HttpServer) throws -> URL {
        origin["/master.m3u8"] = { _ in .ok(.text("#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8")) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        return try XCTUnwrap(URL(string: "http://127.0.0.1:\(try origin.port())/master.m3u8"))
    }

    private func subtitle(on master: URL, _ filename: String, language: String) -> SSTextTrackDescription {
        let url = master.deletingLastPathComponent().appendingPathComponent(filename)
        return SSTextTrackDescription(
            src: url.absoluteString, srclang: language, kind: .subtitles, label: filename, format: .WebVTT
        )
    }

    private func intercept(_ url: URL, type: HlsPlaylistType, with loader: AVSubtitlesLoader) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        let rewritten = try await loader.didInterceptPlaylistResponse(type: type, url: url, response: response, data: data)
        return String(decoding: rewritten, as: UTF8.self)
    }

    private func subtitleSegmentURL(for track: SSTextTrackDescription, with loader: AVSubtitlesLoader) throws -> URL {
        let data = try XCTUnwrap(loader.handleSubtitles(track.src), "No subtitle playlist for \(track.src)")
        let lines = String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
        let uri = try XCTUnwrap(lines.first { !$0.isEmpty && !$0.hasPrefix("#") })
        return try XCTUnwrap(URL(string: uri))
    }
}
