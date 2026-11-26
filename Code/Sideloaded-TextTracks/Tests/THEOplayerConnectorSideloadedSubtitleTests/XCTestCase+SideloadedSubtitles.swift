import Foundation
import Swifter
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
extension XCTestCase {
    func startOrigin(
        _ origin: HttpServer,
        master: String = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8"
    ) throws -> URL {
        origin["/master.m3u8"] = { _ in .ok(.text(master)) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        return try XCTUnwrap(URL(string: "http://127.0.0.1:\(try origin.port())/master.m3u8"))
    }

    func subtitle(
        on master: URL, _ filename: String, language: String = "en", isDefault: Bool? = nil
    ) -> SSTextTrackDescription {
        let url = master.deletingLastPathComponent().appendingPathComponent(filename)
        return SSTextTrackDescription(
            src: url.absoluteString, srclang: language, isDefault: isDefault,
            kind: .subtitles, label: filename, format: .WebVTT
        )
    }

    func intercept(_ url: URL, type: HlsPlaylistType, with loader: AVSubtitlesLoader) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        let rewritten = try await loader.didInterceptPlaylistResponse(type: type, url: url, response: response, data: data)
        return String(decoding: rewritten, as: UTF8.self)
    }

    func subtitleLines(for track: SSTextTrackDescription, with loader: AVSubtitlesLoader) throws -> [String] {
        let data = try XCTUnwrap(loader.handleSubtitles(track.src), "No subtitle playlist for \(track.src)")
        return String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
    }

    func subtitleSegmentURL(for track: SSTextTrackDescription, with loader: AVSubtitlesLoader) throws -> URL {
        let lines = try subtitleLines(for: track, with: loader)
        let uri = try XCTUnwrap(lines.first { !$0.isEmpty && !$0.hasPrefix("#") })
        return try XCTUnwrap(URL(string: uri))
    }
}
