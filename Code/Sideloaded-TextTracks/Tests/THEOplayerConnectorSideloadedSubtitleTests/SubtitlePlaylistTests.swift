import Foundation
import Swifter
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class SubtitlePlaylistTests: XCTestCase {
    private let cue = "\n00:00:01.000 --> 00:00:02.000\nHello\n"

    func testTimestampOverrideReplacesOrInsertsMapThroughRoute() async throws {
        let origin = HttpServer()
        let cue = self.cue
        origin["/mapped.vtt"] = { _ in
            .ok(.text("WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:90000,LOCAL:00:00:00.000\n" + cue))
        }
        origin["/unmapped.vtt"] = { _ in .ok(.text("WEBVTT\n" + cue)) }
        let master = try startOrigin(origin)
        defer { origin.stop() }
        let tracks = ["mapped.vtt", "unmapped.vtt"].map { filename in
            let track = subtitle(on: master, filename)
            track.vttTimestamp = .init(pts: "180000", localTime: "00:00:01.000")
            return track
        }
        let loader = AVSubtitlesLoader(subtitles: tracks, id: #function, player: nil)
        _ = try await intercept(master, type: .master, with: loader)

        for track in tracks {
            let transformedURL = try subtitleSegmentURL(for: track, with: loader)
            XCTAssertNotEqual(transformedURL, track.src)
            let (data, response) = try await URLSession.shared.data(from: transformedURL)

            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                "WEBVTT\nX-TIMESTAMP-MAP=MPEGTS:180000,LOCAL:00:00:01.000\n" + cue,
                track.src.lastPathComponent
            )
        }
    }

    func testSubtitlePlaylistUsesOriginOnlyForUnmodifiedWebVTT() async throws {
        let origin = HttpServer()
        origin["/plain.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        origin["/timestamp.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        origin["/autosync.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        origin["/subtitle.srt"] = { _ in .ok(.text("1\n00:00:01,000 --> 00:00:02,000\nHello\n")) }
        let master = try startOrigin(origin)
        defer { origin.stop() }

        let plain = subtitle(on: master, "plain.vtt")
        let timestamped = subtitle(on: master, "timestamp.vtt")
        timestamped.vttTimestamp = .init(pts: "90000", localTime: "00:00:00.000")
        let autosync = subtitle(on: master, "autosync.vtt")
        autosync.automaticTimestampSyncEnabled = true
        let srt = subtitle(on: master, "subtitle.srt")
        srt.format = .SRT
        let loader = AVSubtitlesLoader(subtitles: [plain, timestamped, autosync, srt], id: #function, player: nil)
        _ = try await intercept(master, type: .master, with: loader)

        XCTAssertEqual(try subtitleSegmentURL(for: plain, with: loader), plain.src)
        for track in [timestamped, autosync, srt] {
            let url = try subtitleSegmentURL(for: track, with: loader)
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            XCTAssertEqual(url.host, "localhost")
            XCTAssertEqual(url.path, "/transformSubtitle")
            XCTAssertEqual(items?.first { $0.name == "url" }?.value, track.src.absoluteString)
            XCTAssertNotNil(items?.first { $0.name == "t" }?.value)
        }
    }

    func testSourceValidatorFiltersNonSubtitlesAndIncompleteURLs() {
        let master = URL(string: "https://example.com/master.m3u8")!
        let valid = subtitle(on: master, "valid.vtt")
        let captions = subtitle(on: master, "captions.vtt")
        captions.kind = .captions
        let relative = SSTextTrackDescription(src: "relative.vtt", srclang: "en", kind: .subtitles)
        let hostless = SSTextTrackDescription(src: "file:///subtitle.vtt", srclang: "en", kind: .subtitles)
        let video = TypedSource(src: master.absoluteString, type: "application/x-mpegurl")

        let mixed = SourceDescription(source: video, textTracks: [captions, relative, valid, hostless])
        XCTAssertEqual(SourceValidator.getValidTextTracks(mixed)?.map(\.src), [valid.src])

        let invalid = SourceDescription(source: video, textTracks: [captions, relative, hostless])
        XCTAssertNil(SourceValidator.getValidTextTracks(invalid))
    }

    func testMasterDropsSubtitleWithNonSuccessStatus() async throws {
        let origin = HttpServer()
        let vtt = "WEBVTT\n" + cue
        origin["/valid.vtt"] = { _ in .ok(.text(vtt)) }
        origin["/missing.vtt"] = { _ in
            .raw(404, "Not Found", ["Content-Type": "text/vtt"], { try $0.write([UInt8](vtt.utf8)) })
        }
        let master = try startOrigin(origin)
        defer { origin.stop() }
        let valid = subtitle(on: master, "valid.vtt")
        let missing = subtitle(on: master, "missing.vtt")
        let loader = AVSubtitlesLoader(subtitles: [valid, missing], id: #function, player: nil)

        let rewritten = try await intercept(master, type: .master, with: loader)

        XCTAssertTrue(rewritten.contains(valid.src.absoluteString))
        XCTAssertFalse(rewritten.contains(missing.src.absoluteString))
        XCTAssertNil(loader.handleSubtitles(missing.src))
    }

    func testMasterRewritesExistingSubtitleGroupAndAddsRenditions() async throws {
        let origin = HttpServer()
        let master = try startOrigin(origin, master: """
            #EXTM3U
            #EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="original",NAME="In-band",URI="subs/original%20track.m3u8",LANGUAGE="es",DEFAULT=NO,AUTOSELECT=YES
            #EXT-X-STREAM-INF:BANDWIDTH=1000,SUBTITLES="original"
            video.m3u8
            """)
        defer { origin.stop() }
        let english = subtitle(on: master, "english.vtt", language: "en", isDefault: true)
        let french = subtitle(on: master, "french track.vtt", language: "fr", isDefault: false)
        let parser = MasterPlaylistParser(url: master, request: nil)
        let data = await parser.sideLoadSubtitles(subtitles: [english, french])
        let lines = String(decoding: try XCTUnwrap(data), as: UTF8.self).components(separatedBy: "\n")
        let renditions = lines.filter { $0.hasPrefix("#EXT-X-MEDIA:") }

        XCTAssertEqual(renditions.count, 3)
        for rendition in renditions {
            XCTAssertTrue(rendition.contains("TYPE=SUBTITLES"))
            XCTAssertTrue(rendition.contains("GROUP-ID=\"THEOsubs\""))
        }
        XCTAssertEqual(renditions.filter { $0.contains("DEFAULT=YES") }.count, 1)

        XCTAssertTrue(renditions.contains { $0.contains("NAME=\"In-band\"") })
        let en = try XCTUnwrap(renditions.first { $0.contains("LANGUAGE=\"en\"") })
        XCTAssertTrue(en.contains("DEFAULT=YES"))
        XCTAssertTrue(en.contains("URI=\"\(english.src.absoluteString)\""))
        let fr = try XCTUnwrap(renditions.first { $0.contains("LANGUAGE=\"fr\"") })
        XCTAssertTrue(fr.contains("DEFAULT=NO"))
        let variant = try XCTUnwrap(lines.first { $0.hasPrefix("#EXT-X-STREAM-INF:") })
        XCTAssertTrue(variant.contains("SUBTITLES=\"THEOsubs\""))
    }

    func testSubtitleTargetDurationUsesFallbackThenSumOfVariantSegments() async throws {
        let origin = HttpServer()
        origin["/subtitle.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        origin["/video.m3u8"] = { _ in .ok(.text("""
            #EXTM3U
            #EXT-X-TARGETDURATION:6
            #EXT-X-PLAYLIST-TYPE:VOD
            #EXTINF:3.250,
            first.ts
            #EXTINF:5.750,
            second.ts
            #EXT-X-ENDLIST
            """)) }
        let master = try startOrigin(origin)
        defer { origin.stop() }
        let track = subtitle(on: master, "subtitle.vtt")
        let loader = AVSubtitlesLoader(subtitles: [track], id: #function, player: nil)
        _ = try await intercept(master, type: .master, with: loader)

        XCTAssertTrue(try subtitleLines(for: track, with: loader).contains("#EXT-X-TARGETDURATION:604800"))

        let variant = master.deletingLastPathComponent().appendingPathComponent("video.m3u8")
        _ = try await intercept(variant, type: .video, with: loader)

        XCTAssertTrue(try subtitleLines(for: track, with: loader).contains("#EXT-X-TARGETDURATION:9"))
    }

    #if os(iOS)
    func testCachingTasksKeepDifferentSourcesAndSubtitleLoaders() async throws {
        let origin = HttpServer()
        origin["/second.m3u8"] = { _ in .ok(.text("#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8")) }
        origin["/first.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        origin["/second.vtt"] = { _ in .ok(.text("WEBVTT\n\n")) }
        let firstMaster = try startOrigin(origin)
        defer { origin.stop() }
        let secondMaster = firstMaster.deletingLastPathComponent().appendingPathComponent("second.m3u8")
        let firstTrack = subtitle(on: firstMaster, "first.vtt")
        let secondTrack = subtitle(on: secondMaster, "second.vtt")
        let countBefore = AVSubtitlesLoader.instances.count

        func createTask(for master: URL, track: SSTextTrackDescription) throws -> CachingTask {
            let video = TypedSource(src: master.absoluteString, type: "application/x-mpegurl")
            let source = SourceDescription(source: video, textTracks: [track])
            return try XCTUnwrap(THEOplayer.cache.createTaskWithSubtitles(source: source, parameters: nil))
        }

        let first = try createTask(for: firstMaster, track: firstTrack)
        defer {
            first.remove()
            AVSubtitlesLoader.removeInstance(by: first.id)
        }
        let firstLoader = try XCTUnwrap(AVSubtitlesLoader.instances.last)
        let second = try createTask(for: secondMaster, track: secondTrack)
        defer {
            second.remove()
            AVSubtitlesLoader.removeInstance(by: second.id)
        }
        let secondLoader = try XCTUnwrap(AVSubtitlesLoader.instances.last)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertFalse(firstLoader === secondLoader)
        XCTAssertEqual(AVSubtitlesLoader.instances.count, countBefore + 2)

        let firstPlaylist = try await intercept(firstMaster, type: .master, with: firstLoader)
        let secondPlaylist = try await intercept(secondMaster, type: .master, with: secondLoader)
        XCTAssertTrue(firstPlaylist.contains(firstTrack.src.absoluteString))
        XCTAssertFalse(firstPlaylist.contains(secondTrack.src.absoluteString))
        XCTAssertTrue(secondPlaylist.contains(secondTrack.src.absoluteString))
        XCTAssertFalse(secondPlaylist.contains(firstTrack.src.absoluteString))
    }
    #endif
}
