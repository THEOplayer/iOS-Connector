//
//  ConvivaTestSupport.swift
//

import XCTest
import THEOplayerSDK
@testable import THEOplayerConnectorConviva

enum TestSources {
    // The default (unlicensed) player only plays sources hosted on theoplayer.com.
    static let bigBuckBunny = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"
    static let elephantsDream = "https://cdn.theoplayer.com/video/elephants-dream/playlist.m3u8"
    // Segment 4 (18-24 s) of every video variant returns HTTP 403.
    static let missingSegment = "https://cdn.theoplayer.com/video/elephants-dream/404/index.m3u8"
    static let theoliveDemoChannel = "demo"

    static func hls(_ url: String = bigBuckBunny) -> SourceDescription {
        SourceDescription(source: TypedSource(src: url, type: "application/x-mpegurl"))
    }
}

/// The public THEOlive demo channel. The default license implicitly allows theo.live sources.
struct THEOliveDemoEndpoint: Decodable {
    let hlsSrc: String
}

/// A real player with a `ConvivaConnector` that reports to a `RecordingAnalytics`.
final class ConvivaHarness {
    let player = THEOplayer(with: nil)
    let analytics = RecordingAnalytics()
    let connector: ConvivaConnector
    var video: RecordingVideoAnalytics { analytics.video }
    var ad: RecordingAdAnalytics { analytics.ad }

    init(convivaMetadata: [String: Any] = [:]) {
        connector = ConvivaConnector(conviva: ConvivaEndpoints(analytics: analytics), player: player, convivaMetadata: convivaMetadata)
    }

    /// Registers a custom server-side ad integration so tests can drive real ad break and ad events.
    func registerCustomAdIntegration() -> ServerSideAdIntegrationController {
        var controller: ServerSideAdIntegrationController!
        player.ads.registerServerSideIntegration(integrationId: "conviva-tests") {
            controller = $0
            return NoopAdIntegrationHandler()
        }
        return controller
    }
}

struct NoopAdIntegrationHandler: ServerSideAdIntegrationHandler {}

struct MockAdBreak: AdBreak {
    var id: String?
    var ads: [Ad] = []
    var maxDuration: Int = 0
    var maxRemainingDuration: Double = 0
    var timeOffset: Int = 0
    var integration: AdIntegrationKind = .custom
    var customIntegration: String?
}

extension XCTestCase {
    func makeHarness(convivaMetadata: [String: Any] = [:]) -> ConvivaHarness {
        let harness = ConvivaHarness(convivaMetadata: convivaMetadata)
        addTeardownBlock {
            harness.connector.destroy()
            harness.player.stop()
        }
        return harness
    }

    /// Waits for the next `type` event, triggered by `trigger`, and lets the main queue drain afterwards.
    @discardableResult
    func waitForEvent<E: EventProtocol>(
        _ type: EventType<E>,
        on dispatcher: EventDispatcherProtocol,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line,
        after trigger: () -> Void = {}
    ) -> E? {
        let eventReceived = expectation(description: "\(type.name) event")
        var received: E?
        let listener = dispatcher.addEventListener(type: type) { event in
            guard received == nil else { return }
            received = event
            eventReceived.fulfill()
        }
        trigger()
        wait(for: [eventReceived], timeout: timeout)
        dispatcher.removeEventListener(type: type, listener: listener)
        drainMainQueue()
        if received == nil {
            XCTFail("No \(type.name) event within \(timeout)s", file: file, line: line)
        }
        return received
    }

    /// Asks THEOlive discovery for the demo channel's current endpoint, so tests don't depend on its engine path.
    func fetchTHEOliveDemoEndpoint(file: StaticString = #filePath, line: UInt = #line) throws -> THEOliveDemoEndpoint {
        struct Distribution: Decodable { let endpoints: [THEOliveDemoEndpoint] }
        let fetched = expectation(description: "THEOlive discovery response")
        let url = URL(string: "https://discovery.theo.live/v2/distributions/\(TestSources.theoliveDemoChannel)")!
        var result: Result<Data, Error> = .failure(URLError(.timedOut))
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data, (response as? HTTPURLResponse)?.statusCode == 200 {
                    result = .success(data)
                } else {
                    result = .failure(error ?? URLError(.badServerResponse))
                }
                fetched.fulfill()
            }
        }
        task.resume()
        defer { task.cancel() }
        wait(for: [fetched], timeout: 30)
        let distribution = try JSONDecoder().decode(Distribution.self, from: result.get())
        return try XCTUnwrap(distribution.endpoints.first, "No THEOlive demo endpoint", file: file, line: line)
    }

    func waitUntil(_ description: String, timeout: TimeInterval = 30, _ condition: @escaping () -> Bool) {
        let conditionMet = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        conditionMet.expectationDescription = description
        wait(for: [conditionMet], timeout: timeout)
    }

    /// The connector forwards ad events through `DispatchQueue.main.async`; this lets those run.
    func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { DispatchQueue.main.async { drained.fulfill() } }
        wait(for: [drained], timeout: 5)
    }
}
