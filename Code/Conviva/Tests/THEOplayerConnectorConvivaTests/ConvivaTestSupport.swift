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

    /// Waits for the next matching event, optionally after Conviva's queued ad forwarding.
    @discardableResult
    func waitForEvent<E: EventProtocol>(
        _ type: EventType<E>,
        on dispatcher: EventDispatcherProtocol,
        timeout: TimeInterval = 30,
        afterAdForwarding: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line,
        matching: @escaping (E) -> Bool = { _ in true },
        after trigger: () -> Void = {}
    ) -> E? {
        let eventReceived = expectation(description: "\(type.name) event")
        var received: E?
        let listener = dispatcher.addEventListener(type: type) { event in
            guard received == nil, matching(event) else { return }
            received = event
            if afterAdForwarding {
                DispatchQueue.main.async { eventReceived.fulfill() }
            } else {
                eventReceived.fulfill()
            }
        }
        trigger()
        wait(for: [eventReceived], timeout: timeout)
        dispatcher.removeEventListener(type: type, listener: listener)
        if received == nil {
            XCTFail("No \(type.name) event within \(timeout)s", file: file, line: line)
        }
        return received
    }

    /// Loads the video tracks before starting playback and waits for the first active quality.
    func playAndWaitForActiveQuality(
        of player: THEOplayer,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line,
        prepare: () -> Void
    ) -> Quality? {
        let qualityChanged = expectation(description: "ACTIVE_QUALITY_CHANGED event")
        var received: Quality?
        var qualityListeners: [(VideoTrack, EventListener)] = []
        let trackListener = player.videoTracks.addEventListener(type: VideoTrackListEventTypes.ADD_TRACK) { event in
            guard let track = event.track as? VideoTrack else { return }
            let listener = track.addEventListener(type: MediaTrackEventTypes.ACTIVE_QUALITY_CHANGED) { event in
                guard received == nil else { return }
                received = event.quality
                qualityChanged.fulfill()
            }
            qualityListeners.append((track, listener))
        }
        defer {
            player.videoTracks.removeEventListener(type: VideoTrackListEventTypes.ADD_TRACK, listener: trackListener)
            for (track, listener) in qualityListeners {
                track.removeEventListener(type: MediaTrackEventTypes.ACTIVE_QUALITY_CHANGED, listener: listener)
            }
        }

        player.preload = .auto
        guard waitForEvent(PlayerEventTypes.LOADED_META_DATA, on: player, timeout: timeout, file: file, line: line, after: prepare) != nil else {
            return nil
        }

        let playing = expectation(description: "PLAYING event")
        playing.assertForOverFulfill = false
        let playingListener = player.addEventListener(type: PlayerEventTypes.PLAYING) { _ in playing.fulfill() }
        defer { player.removeEventListener(type: PlayerEventTypes.PLAYING, listener: playingListener) }

        player.play()
        wait(for: [playing, qualityChanged], timeout: timeout)
        if received == nil {
            XCTFail("No ACTIVE_QUALITY_CHANGED event within \(timeout)s", file: file, line: line)
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
}
