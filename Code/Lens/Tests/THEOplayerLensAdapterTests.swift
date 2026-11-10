import LensSDK
import XCTest
@testable import THEOplayerConnectorLens
import THEOplayerSDK

@MainActor
final class THEOplayerLensAdapterTests: XCTestCase {
    // Local sources need no network, and THEOplayer's license allows them.
    private let hlsUrl = localUrl("stream.m3u8")
    private lazy var hlsSource = SourceDescription(source: TypedSource(src: hlsUrl, type: "application/x-mpegurl"))
    private let mp4Source = SourceDescription(source: TypedSource(src: TestMedia.mp4.absoluteString, type: "video/mp4"))

    func testIdentifiesThePlayer() {
        let adapter = THEOplayerLensAdapter(player: THEOplayer())
        XCTAssertEqual(adapter.playerName, "THEOplayer")
        XCTAssertEqual(adapter.playerVersion, THEOplayer.version)
    }

    func testInitialFactDescribesAPlayerWithoutSource() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))

        XCTAssertEqual(
            recorder.facts,
            [
                .initial(
                    source: nil,
                    properties: LensPlayerProperties(playbackRate: 1, muted: false, volume: 1, presentationMode: .inline)
                )
            ]
        )
    }

    func testInitialFactCarriesASourceSetBeforeSubscribing() {
        let player = THEOplayer()
        player.autoplay = true
        let adapter = THEOplayerLensAdapter(player: player)
        load(hlsSource, into: player)

        let recorder = Recorder(adapter)

        guard case .initial(let source, _) = recorder.facts.first else {
            return XCTFail("expected initial, got \(recorder.facts)")
        }
        XCTAssertEqual(source, LensPlayerSource(url: hlsUrl, mimeType: "application/x-mpegurl", autoplay: true, preload: .auto))
    }

    func testSettingASourceReportsItWithoutTheOldSourcesProperties() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))

        load(hlsSource, into: player)

        XCTAssertEqual(recorder.sources.count, 1)
        let reported = recorder.sources.first
        XCTAssertEqual(reported?.source, LensPlayerSource(url: hlsUrl, mimeType: "application/x-mpegurl", autoplay: false, preload: .off))
        XCTAssertEqual(reported?.continuation, false)
        XCTAssertNil(reported?.properties.tracks)
        XCTAssertNil(reported?.properties.live)
        XCTAssertNil(reported?.properties.bufferStable)
        XCTAssertNil(reported?.properties.hasMediaData)
        // Loaded, but THEOplayer does not know the duration yet.
        XCTAssertNotNil(recorder.changes.last?.bufferStable)
        XCTAssertNil(recorder.changes.last?.live)
    }

    func testReplacingAndRemovingTheSourceReportsEachChange() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        let mp4Url = Self.localUrl("other.mp4")

        load(hlsSource, into: player)
        load(SourceDescription(source: TypedSource(src: mp4Url, type: "video/mp4")), into: player)
        load(nil, into: player)

        XCTAssertEqual(recorder.sources.map(\.source?.url), [hlsUrl, mp4Url, nil])
    }

    func testTheSameDescriptionSetAgainKeepsItsSource() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))

        load(hlsSource, into: player)
        load(hlsSource, into: player)

        XCTAssertEqual(recorder.sources.count, 1)
    }

    func testTheSourceTheDescriptionPlaysIsReported() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))

        load(
            SourceDescription(sources: [
                TypedSource(src: Self.localUrl("stream.mpd"), type: "application/dash+xml"),
                TypedSource(src: hlsUrl, type: "application/x-mpegurl"),
            ]),
            into: player
        )

        XCTAssertEqual(recorder.sources.last?.source?.url, hlsUrl)
    }

    func testGoogleDAISourcesAreNamedByTheirAssetIds() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        let dai = GoogleDAITypedSource(
            ssai: GoogleDAIVodConfiguration(
                videoID: "tears-of-steel",
                contentSourceID: "2548831",
                apiKey: "",
                authToken: nil,
                streamActivityMonitorID: nil,
                adTagParameters: nil
            )
        )
        dai.src = hlsUrl

        load(SourceDescription(source: dai), into: player)

        XCTAssertEqual(recorder.sources.map(\.source?.contentId), ["2548831/tears-of-steel"])
        XCTAssertEqual(recorder.sources.map(\.source?.url), [nil])
    }

    func testPlaybackIsReportedInOrder() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        load(mp4Source, into: player)

        player.play()
        recorder.wait(in: self) { $0 == .ended }

        let order = [
            recorder.facts.firstIndex { if case .source = $0 { return true } else { return false } },
            recorder.facts.firstIndex(of: .play),
            recorder.facts.firstIndex(of: .playing),
            recorder.facts.firstIndex(of: .ended),
        ]
        XCTAssertEqual(order.compactMap { $0 }, order.compactMap { $0 }.sorted())
        XCTAssertEqual(order.compactMap { $0 }.count, 4, "\(recorder.facts)")
    }

    func testPlayingANewSourceWhilePlayingIsAPlayRequest() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        load(mp4Source, into: player)
        player.play()
        recorder.wait(in: self) { $0 == .playing }

        load(SourceDescription(source: TypedSource(src: TestMedia.mp4.absoluteString, type: "video/mp4")), into: player)
        let sourceIndex = recorder.facts.count - 1
        player.play()
        recorder.wait(in: self) { _ in recorder.facts[sourceIndex...].contains(.playing) }

        let next = Array(recorder.facts[sourceIndex...])
        XCTAssertLessThan(next.firstIndex(of: .play) ?? .max, next.firstIndex(of: .playing) ?? .max, "\(next)")
    }

    func testAPreloadedSourceReportsItsOwnProperties() {
        let player = THEOplayer()
        player.preload = .auto
        let adapter = THEOplayerLensAdapter(player: player)
        let recorder = Recorder(adapter)
        load(mp4Source, into: player)

        recorder.wait(in: self) {
            guard case .change(let properties) = $0 else { return false }
            return properties.live == false && properties.bufferStable == true && properties.hasMediaData == true
        }

        XCTAssertNil(recorder.changes.last?.lowLatency)
        XCTAssertEqual(adapter.snapshot().duration ?? 0, TestMedia.duration, accuracy: 0.1)
    }

    func testAFailingSourceIsReportedAsAFatalError() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))

        load(hlsSource, into: player)
        player.play()
        recorder.wait(in: self) { if case .error = $0 { return true } else { return false } }

        guard case .error(let fatal, let code, let message) = recorder.facts.last else {
            return XCTFail("expected an error, got \(recorder.facts)")
        }
        XCTAssertTrue(fatal)
        XCTAssertNotNil(Int32(code).flatMap(THEOErrorCode.init(rawValue:)))
        XCTAssertNotNil(message)
        XCTAssertFalse(message?.contains("\n") ?? false)
    }

    func testPlayerSettingsArePushedWhenTheyChange() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        loadMedia(into: player, recorder)

        player.muted = true
        recorder.wait(in: self) { if case .change(let properties) = $0 { return properties.muted == true } else { return false } }
        player.volume = 0.5
        recorder.wait(in: self) { if case .change(let properties) = $0 { return properties.volume == 0.5 } else { return false } }
        player.playbackRate = 2
        recorder.wait(in: self) { if case .change(let properties) = $0 { return properties.playbackRate == 2 } else { return false } }
    }

    func testUnchangedPropertiesAreNotPushedAgain() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        loadMedia(into: player, recorder)
        player.muted = true
        recorder.wait(in: self) { if case .change(let properties) = $0 { return properties.muted == true } else { return false } }

        player.muted = true

        for (previous, next) in zip(recorder.changes, recorder.changes.dropFirst()) {
            XCTAssertNotEqual(previous, next)
        }
    }

    func testEverySubscriberStartsWithInitial() {
        let adapter = THEOplayerLensAdapter(player: THEOplayer())
        let first = Recorder(adapter)
        let second = Recorder(adapter)

        XCTAssertEqual(first.facts.count, 1)
        XCTAssertEqual(second.facts.count, 1)
        guard case .initial = second.facts.first else { return XCTFail("expected initial") }
    }

    func testNoFactsAfterUnsubscribing() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player))
        recorder.unsubscribe()

        load(hlsSource, into: player)
        player.play()

        XCTAssertEqual(recorder.facts.count, 1)
    }

    func testSnapshotWithoutSource() {
        let player = THEOplayer(with: CGRect(x: 0, y: 0, width: 320, height: 180))
        let snapshot = THEOplayerLensAdapter(player: player).snapshot()

        XCTAssertEqual(snapshot.currentTime, 0)
        XCTAssertTrue(snapshot.paused)
        XCTAssertFalse(snapshot.ended)
        XCTAssertNil(snapshot.duration)
        XCTAssertNil(snapshot.buffered)
        XCTAssertNil(snapshot.seekable)
        XCTAssertNil(snapshot.droppedFrames)
        XCTAssertEqual(snapshot.viewWidth, 320)
        XCTAssertEqual(snapshot.viewHeight, 180)
    }

    func testSnapshotWithSource() {
        let player = THEOplayer()
        let adapter = THEOplayerLensAdapter(player: player)
        load(hlsSource, into: player)

        let snapshot = adapter.snapshot()

        XCTAssertEqual(snapshot.buffered, [LensBufferedRanges(ranges: [])])
        XCTAssertEqual(snapshot.seekable, [])
        XCTAssertNotNil(snapshot.droppedFrames)
    }

    func testReleasingThePlayerRemovesItsSource() {
        var player: THEOplayer? = THEOplayer()
        let adapter = THEOplayerLensAdapter(player: player!)
        let recorder = Recorder(adapter)
        load(hlsSource, into: player!)

        player = nil

        XCTAssertEqual(recorder.sources.map(\.source?.url), [hlsUrl, nil])
        XCTAssertEqual(adapter.snapshot().paused, true)
    }

    func testAContentIdProviderNamesTheSource() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player) { $0.sources.first?.src == self.hlsUrl ? "movie-1" : nil })

        load(hlsSource, into: player)
        load(SourceDescription(source: TypedSource(src: Self.localUrl("other.mp4"), type: "video/mp4")), into: player)

        XCTAssertEqual(recorder.sources.map(\.source?.contentId), ["movie-1", nil])
        XCTAssertEqual(recorder.sources.first?.source?.url, hlsUrl)
    }

    func testAContentIdProviderOverridesTheGoogleDAIAssetIds() {
        let player = THEOplayer()
        let recorder = Recorder(THEOplayerLensAdapter(player: player) { _ in "movie-1" })
        let dai = GoogleDAITypedSource(
            ssai: GoogleDAILiveConfiguration(
                assetKey: "live-asset",
                apiKey: "",
                authToken: nil,
                streamActivityMonitorID: nil,
                adTagParameters: nil
            )
        )
        dai.src = hlsUrl

        load(SourceDescription(source: dai), into: player)

        XCTAssertEqual(recorder.sources.map(\.source?.contentId), ["movie-1"])
        XCTAssertEqual(recorder.sources.map(\.source?.url), [nil])
    }

    func testLowLatencyNeedsALatencyConfigurationOrALowLatencyType() {
        func source(_ type: String, latency: SourceLatencyConfiguration? = nil) -> TypedSource {
            TypedSource(src: hlsUrl, type: type, latencyConfiguration: latency)
        }
        XCTAssertTrue(isLowLatency(source("application/x-mpegurl", latency: SourceLatencyConfiguration(targetOffset: 3))))
        XCTAssertTrue(isLowLatency(source("application/vnd.theo.hesp+json")))
        XCTAssertTrue(isLowLatency(source("application/millicast")))
        XCTAssertFalse(isLowLatency(source("application/vnd.theo.live+channel")))
        XCTAssertFalse(isLowLatency(source("application/x-mpegurl")))
    }

    func testTheConnectorStartsASessionAtTheFirstPlayRequest() throws {
        let player = THEOplayer()
        let connector = try connect(player)
        defer { connector.destroy() }
        load(mp4Source, into: player)
        XCTAssertNil(connector.handle.session)

        player.play()

        waitForSession(of: connector.handle)
    }

    func testAnSDKJoiningWithThePlayerSharesTheSession() throws {
        let player = THEOplayer()
        let connector = try connect(player)
        defer { connector.destroy() }
        let other = try Lens.join(LensJoinOptions(namespace: "other_sdk", player: player))
        defer { other.dispose() }
        load(mp4Source, into: player)
        player.play()
        waitForSession(of: connector.handle)

        XCTAssertNotNil(other.session)
        XCTAssertEqual(other.session?.sessionId, connector.handle.session?.sessionId)
    }

    /// Lens keeps the player alive while a handle on it exists, disposed or not.
    func testDestroyingAndReleasingTheConnectorReleasesThePlayer() throws {
        var player: THEOplayer? = THEOplayer()
        weak var released = player
        var connector: LensConnector? = try connect(player!)
        load(mp4Source, into: player!)
        player?.play()
        waitForSession(of: connector!.handle)

        connector?.destroy()
        connector = nil
        player = nil

        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in released == nil }, object: nil)], timeout: 5)
    }

    func testDestroyingTheConnectorEndsTheSession() throws {
        let player = THEOplayer()
        let connector = try connect(player)
        load(mp4Source, into: player)
        player.play()
        waitForSession(of: connector.handle)

        connector.destroy()

        XCTAssertNil(connector.handle.session)
        waitForRelease(of: connector.adapter)
    }

    func testTheConnectorRejectsInvalidOptions() {
        XCTAssertThrowsError(try LensConnector(player: THEOplayer(), configuration: LensConfiguration(heartbeatMs: 10)))
    }

    private func connect(_ player: THEOplayer) throws -> LensConnector {
        try Lens.configure(LensConfigureOptions(backend: .disabled))
        return try LensConnector(player: player)
    }

    private func waitForSession(of handle: LensHandle) {
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in handle.session != nil }, object: nil)], timeout: 5)
    }

    /// Lens releases its subscription once its last handle on the player is disposed.
    private func waitForRelease(of adapter: THEOplayerLensAdapter) {
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !adapter.subscribed }, object: nil)], timeout: 5)
    }

    /// Sets the source and waits for THEOplayer to take it: it holds sources until it has selected its license.
    private func load(_ source: SourceDescription?, into player: THEOplayer) {
        let loaded = expectation(description: "sourcechange")
        loaded.assertForOverFulfill = false
        let listener = player.addEventListener(type: PlayerEventTypes.SOURCE_CHANGE) { _ in loaded.fulfill() }
        player.source = source
        wait(for: [loaded], timeout: 5)
        player.removeEventListener(type: PlayerEventTypes.SOURCE_CHANGE, listener: listener)
    }

    /// Loads playable media and waits until THEOplayer knows it: it only reports its settings for a loaded item.
    private func loadMedia(into player: THEOplayer, _ recorder: Recorder) {
        player.preload = .auto
        load(mp4Source, into: player)
        recorder.wait(in: self) { if case .change(let properties) = $0 { return properties.live == false } else { return false } }
    }

    private static func localUrl(_ name: String) -> String {
        FileManager.default.temporaryDirectory.appendingPathComponent(name).absoluteString
    }
}

/// Records the facts an adapter delivers to one subscriber, holding the adapter as Lens does.
@MainActor
private final class Recorder {
    private(set) var facts: [LensPlayerFact] = []
    private let adapter: THEOplayerLensAdapter
    private var release: (() -> Void)?
    private var awaited: (predicate: (LensPlayerFact) -> Bool, expectation: XCTestExpectation)?

    init(_ adapter: THEOplayerLensAdapter) {
        self.adapter = adapter
        release = adapter.subscribe { [weak self] fact in
            self?.facts.append(fact)
            if let awaited = self?.awaited, awaited.predicate(fact) {
                awaited.expectation.fulfill()
                self?.awaited = nil
            }
        }
    }

    func unsubscribe() {
        release?()
        release = nil
    }

    /// Waits for a fact that matches, unless one already arrived: the player delivers some facts asynchronously.
    func wait(in test: XCTestCase, timeout: TimeInterval = 5, for predicate: @escaping (LensPlayerFact) -> Bool) {
        guard !facts.contains(where: predicate) else { return }
        let expectation = test.expectation(description: "fact")
        awaited = (predicate, expectation)
        test.wait(for: [expectation], timeout: timeout)
    }

    var sources: [(source: LensPlayerSource?, properties: LensPlayerProperties, continuation: Bool)] {
        facts.compactMap {
            guard case .source(let source, let properties, let continuation) = $0 else { return nil }
            return (source, properties, continuation)
        }
    }

    var changes: [LensPlayerProperties] {
        facts.compactMap {
            guard case .change(let properties) = $0 else { return nil }
            return properties
        }
    }
}
