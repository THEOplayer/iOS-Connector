import Foundation
import Swifter
import UIKit
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class SubtitlesTransformerTests: XCTestCase {
    func testSRTRouteConvertsCueTimingsAndText() async throws {
        let origin = HttpServer()
        origin["/subtitle.srt"] = { _ in
            .ok(.text("1\r\n00:00:01,234 --> 00:00:03,456\r\nHello from SRT\r\n\r\n"))
        }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        defer { origin.stop() }
        let source = "http://127.0.0.1:\(try origin.port())/subtitle.srt"
        let transformer = SubtitlesTransformer()
        let url = try XCTUnwrap(URL(string: transformer.composeTranformationUrl(
            with: source, format: .SRT, timestamp: nil
        )))

        let (data, response) = try await URLSession.shared.data(from: url)
        let vtt = String(decoding: data, as: UTF8.self)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue(vtt.hasPrefix("WEBVTT\n\n"))
        XCTAssertTrue(vtt.contains("\n00:00:01.234 --> 00:00:03.456\nHello from SRT\n"))
    }

    func testRecomposingTransformationURLChangesCacheBusterEveryCall() throws {
        let transformer = SubtitlesTransformer()
        let source = "https://example.com/subtitle.srt"
        let urls = (0..<100).map { _ in
            transformer.composeTranformationUrl(with: source, format: .SRT, timestamp: nil)
        }
        let cacheBusters = try urls.map { url in
            let items = URLComponents(string: url)?.queryItems
            return try XCTUnwrap(items?.first { $0.name == "t" }?.value)
        }

        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        XCTExpectFailure("Calls within the same millisecond can reuse t=.", options: options) {
            XCTAssertEqual(Set(cacheBusters).count, cacheBusters.count)
        }
    }

    func testForegroundRestartsStoppedServerOnSamePort() async throws {
        let origin = HttpServer()
        origin["/subtitle.srt"] = { _ in .ok(.text("1\n00:00:00,000 --> 00:00:01,000\nHello\n")) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        defer { origin.stop() }
        let originURL = "http://127.0.0.1:\(try origin.port())/subtitle.srt"

        let transformer = SubtitlesTransformer()
        let url = URL(string: transformer.composeTranformationUrl(with: originURL, format: .SRT, timestamp: nil))!

        let (data, response) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue(String(decoding: data, as: UTF8.self).hasPrefix("WEBVTT"))

        let oldServer = transformer.server
        let oldPort = try oldServer.port()
        transformer.server.stop()

        do {
            _ = try await URLSession.shared.data(from: url)
            XCTFail("Expected the transformation URL to fail while the server is stopped")
        } catch {
        }

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        let restarted = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in transformer.server !== oldServer }, object: nil)
        await fulfillment(of: [restarted], timeout: 5)

        XCTAssertTrue(transformer.server !== oldServer)
        XCTAssertEqual(try transformer.server.port(), oldPort)

        let (restartedData, restartedResponse) = try await URLSession.shared.data(from: url)
        XCTAssertEqual((restartedResponse as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertTrue(String(decoding: restartedData, as: UTF8.self).hasPrefix("WEBVTT"))
    }

    func testForegroundKeepsReachableServer() async throws {
        let origin = HttpServer()
        origin["/subtitle.srt"] = { _ in .ok(.text("1\n00:00:00,000 --> 00:00:01,000\nHello\n")) }
        try origin.start(0, forceIPv4: true, priority: .userInitiated)
        defer { origin.stop() }
        let originURL = "http://127.0.0.1:\(try origin.port())/subtitle.srt"

        let transformer = SubtitlesTransformer()
        let server = transformer.server
        let url = URL(string: transformer.composeTranformationUrl(with: originURL, format: .SRT, timestamp: nil))!
        _ = try await URLSession.shared.data(from: url)

        await withCheckedContinuation { continuation in
            transformer.restartServerIfUnreachable { continuation.resume() }
        }

        XCTAssertTrue(transformer.server === server)
        XCTAssertTrue(server.operating)
    }

    func testReleasedTransformerStopsServer() {
        weak var weakTransformer: SubtitlesTransformer?
        let server: HttpServer
        do {
            let transformer = SubtitlesTransformer()
            weakTransformer = transformer
            server = transformer.server
        }

        XCTAssertNil(weakTransformer)
        XCTAssertFalse(server.operating)

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}
