import Foundation
import Swifter
import UIKit
import XCTest
@testable import THEOplayerConnectorSideloadedSubtitle
import THEOplayerSDK

@MainActor
final class SubtitlesTransformerTests: XCTestCase {
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

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

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
