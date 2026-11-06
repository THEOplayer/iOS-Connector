//
//  Scenario.swift
//  LensExample
//

import Foundation
import THEOplayerSDK

/// The same playback on every platform's Lens demo, so their reports can be compared in the backend. Keep the steps
/// and timings in line with the other platforms (see README).
@MainActor
final class Scenario {
    /// The content ID the scenario's source is reported with, to find its sessions in the backend.
    static let contentId = "lens-connector-demo-scenario"
    static let src = "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8"

    enum Failure: Error, CustomStringConvertible {
        case timeout(String)
        var description: String {
            switch self {
            case .timeout(let event): return "no \(event) in time"
            }
        }
    }

    /// The source of the current run; the connector reports it with `contentId`.
    private(set) var source: SourceDescription?
    /// Called on every step, and once more when the run is over.
    var onStep: ((String) -> Void)?
    var isRunning: Bool { task != nil }

    private let player: THEOplayer
    private var task: Task<Void, Never>?

    init(player: THEOplayer) {
        self.player = player
    }

    func run() {
        guard task == nil else { return }
        task = Task { [weak self] in
            guard let self else { return }
            let outcome: String
            do {
                try await self.steps()
                outcome = "Scenario done"
            } catch is CancellationError {
                outcome = "Scenario stopped"
            } catch {
                outcome = "Scenario failed: \(error)"
            }
            self.restore()
            self.task = nil
            self.onStep?(outcome)
        }
    }

    func stop() {
        task?.cancel()
    }

    private func steps() async throws {
        restore()
        step("1/9 Load Big Buck Bunny")
        // A new description, so each run is a new source and a new session.
        let source = SourceDescription(source: TypedSource(src: Self.src, type: "application/x-mpegurl"))
        self.source = source
        try await next(PlayerEventTypes.SOURCE_CHANGE) { player.source = source }
        step("2/9 Play for 10 s")
        try await next(PlayerEventTypes.PLAYING) { player.play() }
        try await wait(10)
        step("3/9 Pause for 3 s")
        try await next(PlayerEventTypes.PAUSE) { player.pause() }
        try await wait(3)
        step("4/9 Play for 5 s")
        try await next(PlayerEventTypes.PLAYING) { player.play() }
        try await wait(5)
        step("5/9 Seek to 120 s, play for 5 s")
        try await next(PlayerEventTypes.SEEKED) { player.currentTime = 120 }
        try await wait(5)
        step("6/9 Mute for 3 s, unmute for 2 s")
        player.muted = true
        try await wait(3)
        player.muted = false
        try await wait(2)
        step("7/9 Rate 2× for 5 s, 1× for 2 s")
        player.playbackRate = 2
        try await wait(5)
        player.playbackRate = 1
        try await wait(2)
        step("8/9 Picture-in-picture for 5 s, inline for 2 s")
        try await next(PlayerEventTypes.PRESENTATION_MODE_CHANGE) { player.presentationMode = .pictureInPicture }
        try await wait(5)
        try await next(PlayerEventTypes.PRESENTATION_MODE_CHANGE) { player.presentationMode = .inline }
        try await wait(2)
        step("9/9 Seek to 5 s before the end, play to the end, wait 2 s, unload")
        let duration = player.duration ?? 0
        try await next(PlayerEventTypes.SEEKED) { player.currentTime = max(duration - 5, 0) }
        try await next(PlayerEventTypes.ENDED, timeout: 30) {}
        try await wait(2)
        try await next(PlayerEventTypes.SOURCE_CHANGE) { player.stop() }
    }

    private func restore() {
        player.muted = false
        player.playbackRate = 1
        player.presentationMode = .inline
    }

    private func step(_ name: String) {
        onStep?(name)
    }

    private func wait(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Runs `action`, then waits for the player's next event of `type`.
    private func next<E: EventProtocol>(_ type: EventType<E>, timeout: Double = 20, after action: () -> Void) async throws {
        var fired = false
        let listener = player.addEventListener(type: type) { _ in fired = true }
        defer { player.removeEventListener(type: type, listener: listener) }
        action()
        let deadline = Date().addingTimeInterval(timeout)
        while !fired {
            guard Date() < deadline else { throw Failure.timeout(type.name) }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
