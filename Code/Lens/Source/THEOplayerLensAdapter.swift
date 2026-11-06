//
//  THEOplayerLensAdapter.swift
//

import Foundation
import LensSDK
import THEOplayerConnectorUtilities
import THEOplayerSDK

/// Returns the content ID (1-128 printable ASCII) to report for a source, or nil to report the default one.
public typealias ContentIdProvider = (SourceDescription) -> String?

/// Reports a THEOplayer to the OptiView Lens SDK, through the player's public API.
///
/// A `LensConnector` creates one and joins Lens with it; use the adapter directly only to join Lens yourself.
///
/// - Remark:
///     - Create one adapter per player and hand the same instance to every `Lens.join` that observes it: Lens tells
///       players apart by adapter identity.
///     - Use it on the main queue, as the player.
///     - The adapter does not retain the player.
///     - Do not enable THEOplayer's own CMCD reporting for a player that Lens observes.
public final class THEOplayerLensAdapter: LensPlayerAdapter {
    public let playerName = "THEOplayer"
    public let playerVersion: String? = THEOplayer.version

    private weak var player: THEOplayer?
    private let contentId: ContentIdProvider?
    private var listeners: [(id: Int, listener: (LensPlayerFact) -> Void)] = []
    private var nextListenerId = 0
    private var lifetimeObserver: DispatchObserver?
    private var observers: [DispatchObserver] = []
    private var trackObservers: [DispatchObserver] = []
    private var destroyed = false
    /// The description whose source was last reported, and the typed source that report named.
    private var announced: SourceDescription?
    private var announcedTypedSource: TypedSource?
    private var source: LensPlayerSource?
    /// The source THEOplayer plays, which only `CURRENT_SOURCE_CHANGE` tells.
    private var currentSource: TypedSource?
    /// The description `SOURCE_CHANGE` last confirmed: until then the player's values are the previous source's.
    private var loadedSource: SourceDescription?
    private var lastProperties = LensPlayerProperties()
    private var lastSnapshot = LensPlayerSnapshot(currentTime: 0, paused: true, ended: false)

    /// - Parameters:
    ///   - player: The player to report.
    ///   - contentId: Returns the content ID to report for a source. Without it, or when it returns nil, a Google DAI
    ///     source is reported by its asset IDs, and Lens derives the content ID of any other source from its URL.
    public init(player: THEOplayer, contentId: ContentIdProvider? = nil) {
        self.player = player
        self.contentId = contentId
        loadedSource = player.source
        // Kept for the player's lifetime: which source THEOplayer chose and loaded is only ever told by an event.
        lifetimeObserver = DispatchObserver(
            dispatcher: player,
            eventListeners: [
                on(player, PlayerEventTypes.CURRENT_SOURCE_CHANGE) { $0.currentSource = $1.currentSource },
                on(player, PlayerEventTypes.SOURCE_CHANGE) { $0.loadedSource = $1.source },
                on(player, PlayerEventTypes.DESTROY) { $0.onDestroy() },
            ]
        )
    }

    public func subscribe(_ listener: @escaping (LensPlayerFact) -> Void) -> () -> Void {
        if listeners.isEmpty && !destroyed {
            attach()
        }
        let id = nextListenerId
        nextListenerId += 1
        listeners.append((id, listener))
        lastProperties = properties(known: loaded)
        listener(.initial(source: destroyed ? nil : source, properties: lastProperties))
        return { [weak self] in
            guard let self, let index = self.listeners.firstIndex(where: { $0.id == id }) else { return }
            self.listeners.remove(at: index)
            if self.listeners.isEmpty {
                self.detach()
            }
        }
    }

    /// Whether Lens observes the adapter.
    var subscribed: Bool { !listeners.isEmpty }

    public func snapshot() -> LensPlayerSnapshot {
        guard let player, !destroyed, !player.isDestroyed else { return lastSnapshot }
        let hasSource = loaded
        lastSnapshot = LensPlayerSnapshot(
            currentTime: player.currentTime,
            paused: player.paused,
            ended: player.ended,
            playheadDateTime: hasSource ? player.currentProgramDateTime : nil,
            duration: hasSource ? duration(player) : nil,
            seekable: hasSource ? timeRanges(player.seekable) : nil,
            buffered: hasSource ? [LensBufferedRanges(ranges: timeRanges(player.buffered))] : nil,
            measuredThroughput: positive(player.metrics.currentBandwidthEstimate),
            droppedFrames: hasSource ? player.metrics.droppedVideoFrames : nil,
            viewWidth: positive(Double(player.bounds.width)),
            viewHeight: positive(Double(player.bounds.height))
        )
        return lastSnapshot
    }

    // MARK: Subscription

    private func attach() {
        guard let player else { return }
        announced = player.source
        announcedTypedSource = typedSource(of: announced)
        source = lensSource(of: announced)
        let playerListeners: [RemovableEventListenerProtocol] = [
            fact(player, PlayerEventTypes.PLAY, .play),
            fact(player, PlayerEventTypes.PLAYING, .playing),
            fact(player, PlayerEventTypes.PAUSE, .pause),
            fact(player, PlayerEventTypes.WAITING, .waiting),
            fact(player, PlayerEventTypes.SEEKING, .seeking),
            fact(player, PlayerEventTypes.SEEKED, .seeked),
            fact(player, PlayerEventTypes.ENDED, .ended),
            on(player, PlayerEventTypes.RATE_CHANGE) { $0.change() },
            on(player, PlayerEventTypes.VOLUME_CHANGE) { $0.change() },
            on(player, PlayerEventTypes.DURATION_CHANGE) { $0.change() },
            on(player, PlayerEventTypes.READY_STATE_CHANGE) { $0.change() },
            on(player, PlayerEventTypes.PROGRESS) { $0.change() },
            on(player, PlayerEventTypes.PRESENTATION_MODE_CHANGE) { $0.change() },
            on(player, PlayerEventTypes.SOURCE_CHANGE) {
                $0.loadedSource = $1.source
                $0.change()
            },
            on(player, PlayerEventTypes.CURRENT_SOURCE_CHANGE) { $0.currentSourceChanged($1.currentSource) },
            on(player, PlayerEventTypes.ERROR) { $0.error($1) },
        ]
        observers = [
            DispatchObserver(dispatcher: player, eventListeners: playerListeners),
            trackListObserver(
                player.videoTracks,
                VideoTrackListEventTypes.ADD_TRACK,
                VideoTrackListEventTypes.REMOVE_TRACK,
                VideoTrackListEventTypes.CHANGE
            ),
            trackListObserver(
                player.audioTracks,
                AudioTrackListEventTypes.ADD_TRACK,
                AudioTrackListEventTypes.REMOVE_TRACK,
                AudioTrackListEventTypes.CHANGE
            ),
            trackListObserver(
                player.textTracks,
                TextTrackListEventTypes.ADD_TRACK,
                TextTrackListEventTypes.REMOVE_TRACK,
                TextTrackListEventTypes.CHANGE
            ),
        ]
        watchTracks()
    }

    private func detach() {
        observers = []
        trackObservers = []
    }

    private func on<E: EventProtocol>(
        _ dispatcher: EventDispatcherProtocol,
        _ type: EventType<E>,
        _ handle: @escaping (THEOplayerLensAdapter, E) -> Void
    ) -> RemovableEventListenerProtocol {
        dispatcher.addRemovableEventListener(type: type) { [weak self] event in
            guard let self else { return }
            handle(self, event)
        }
    }

    private func on<E: EventProtocol>(
        _ dispatcher: EventDispatcherProtocol,
        _ type: EventType<E>,
        _ handle: @escaping (THEOplayerLensAdapter) -> Void
    ) -> RemovableEventListenerProtocol {
        on(dispatcher, type) { adapter, _ in handle(adapter) }
    }

    private func fact<E: EventProtocol>(_ player: THEOplayer, _ type: EventType<E>, _ fact: LensPlayerFact) -> RemovableEventListenerProtocol {
        on(player, type) {
            $0.syncSource()
            $0.emit(fact)
        }
    }

    private func trackListObserver(
        _ list: EventDispatcherProtocol,
        _ add: EventType<AddTrackEvent>,
        _ remove: EventType<RemoveTrackEvent>,
        _ change: EventType<TrackChangeEvent>
    ) -> DispatchObserver {
        DispatchObserver(
            dispatcher: list,
            eventListeners: [
                on(list, add) { $0.tracksChanged() },
                on(list, remove) { $0.tracksChanged() },
                on(list, change) { $0.tracksChanged() },
            ]
        )
    }

    /// The active quality of a media track only changes on the track itself.
    private func watchTracks() {
        guard let player else { return }
        let mediaTracks = (0..<player.videoTracks.count).map { player.videoTracks[$0] }
            + (0..<player.audioTracks.count).map { player.audioTracks[$0] }
        trackObservers = mediaTracks.map { track in
            DispatchObserver(
                dispatcher: track,
                eventListeners: [
                    on(track, MediaTrackEventTypes.ACTIVE_QUALITY_CHANGED) { $0.change() },
                    on(track, TrackEventTypes.UPDATE) { $0.change() },
                ]
            )
        }
    }

    private func onDestroy() {
        destroyed = true
        if source != nil {
            source = nil
            lastProperties = LensPlayerProperties()
            emit(.source(nil, properties: lastProperties))
        }
        detach()
        lifetimeObserver = nil
    }

    // MARK: Facts

    private func emit(_ fact: LensPlayerFact) {
        for entry in listeners {
            entry.listener(fact)
        }
    }

    /// Pushes the properties whole, as the contract asks, but only when one of them changed.
    private func push(_ next: LensPlayerProperties) {
        guard next != lastProperties else { return }
        lastProperties = next
        emit(.change(next))
    }

    private func change() {
        syncSource()
        push(properties(known: loaded))
    }

    private func tracksChanged() {
        watchTracks()
        change()
    }

    /// Reports the source the application set before any other fact: the old source's teardown, which THEOplayer runs
    /// once `source` is set, comes ahead of `SOURCE_CHANGE`. The same description set again, as Google DAI does once it
    /// resolved the stream, keeps its source.
    private func syncSource() {
        guard let player, player.source !== announced else { return }
        announced = player.source
        announce(continuation: false)
    }

    /// A source's own properties start over unless it continues the one before.
    private func announce(continuation: Bool) {
        announcedTypedSource = typedSource(of: announced)
        source = lensSource(of: announced)
        lastProperties = properties(known: continuation && loaded)
        emit(.source(source, properties: lastProperties, continuation: continuation))
    }

    /// Another source chosen from the same description keeps the viewing session.
    private func currentSourceChanged(_ next: TypedSource?) {
        currentSource = next
        syncSource()
        if source != nil, typedSource(of: announced) !== announcedTypedSource {
            announce(continuation: true)
        }
        change()
    }

    private func error(_ event: ErrorEvent) {
        syncSource()
        // Errors without an error object carry no code to report.
        guard let error = event.errorObject else { return }
        let message = error.message.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        emit(.error(fatal: true, code: String(error.code.rawValue), message: message.isEmpty ? nil : message))
    }

    // MARK: Player model

    /// Whether THEOplayer has loaded the application's source.
    private var loaded: Bool {
        guard let source = player?.source else { return false }
        return source === loadedSource
    }

    /// The description's source THEOplayer plays, else its first.
    private func typedSource(of description: SourceDescription?) -> TypedSource? {
        guard let description else { return nil }
        if let currentSource, description.sources.contains(where: { $0 === currentSource }) {
            return currentSource
        }
        return description.sources.first
    }

    private func lensSource(of description: SourceDescription?) -> LensPlayerSource? {
        guard let player, let description, let typedSource = typedSource(of: description) else { return nil }
        // Google DAI replaces the source URL with the stream it resolved, so that URL is left out.
        let googleDAI = typedSource.ssai is GoogleDAIConfiguration
        let contentId = self.contentId?(description).flatMap(nonEmpty) ?? googleDAIContentId(typedSource)
        let url = googleDAI ? nil : nonEmpty(typedSource.src)
        guard url != nil || contentId != nil else { return nil }
        return LensPlayerSource(
            url: url,
            contentId: contentId,
            mimeType: nonEmpty(typedSource.type),
            autoplay: player.autoplay,
            preload: lensPreload(player.preload)
        )
    }

    /// The properties; without `known`, those of the source are left out.
    private func properties(known: Bool) -> LensPlayerProperties {
        guard let player, !destroyed, !player.isDestroyed else { return LensPlayerProperties() }
        let live = known ? duration(player).map { $0.isInfinite } : nil
        return LensPlayerProperties(
            live: live,
            lowLatency: isLowLatency(typedSource(of: announced)) ? true : nil,
            tracks: known ? tracks(player) : nil,
            targetBuffer: positive(player.abr.targetBuffer),
            bufferStable: known ? player.readyState == .HAVE_ENOUGH_DATA : nil,
            hasMediaData: known ? !player.buffered.isEmpty : nil,
            playbackRate: player.playbackRate,
            muted: player.muted,
            volume: Double(player.volume),
            presentationMode: lensPresentationMode(player.presentationMode)
        )
    }

    private func tracks(_ player: THEOplayer) -> [LensTrack]? {
        let hls = isHls(currentSource ?? typedSource(of: announced))
        var result: [LensTrack] = []
        for index in 0..<player.videoTracks.count {
            result.append(mediaTrack(player.videoTracks[index], kind: .video, hls: hls))
        }
        for index in 0..<player.audioTracks.count {
            result.append(mediaTrack(player.audioTracks[index], kind: .audio, hls: hls))
        }
        for index in 0..<player.textTracks.count {
            let track = player.textTracks[index]
            guard track.kind == "subtitles" || track.kind == "captions" else { continue }
            result.append(
                LensTrack(
                    id: String(track.uid),
                    kind: .text,
                    selected: track.mode == .showing,
                    language: nonEmpty(track.language),
                    label: nonEmpty(track.label)
                )
            )
        }
        return result.isEmpty ? nil : result
    }
}

/// A THEOlive channel alone says nothing: it can be regular HLS, LL-HLS or HESP.
private let lowLatencyTypes: Set<String> = ["application/vnd.theo.hesp+json", "application/millicast"]

func isLowLatency(_ source: TypedSource?) -> Bool {
    guard let source else { return false }
    return source.latencyConfiguration != nil || lowLatencyTypes.contains(source.type.lowercased())
}

private func mediaTrack(_ track: MediaTrack, kind: LensTrackKind, hls: Bool) -> LensTrack {
    // HLS declares a bitrate on variants only, which THEOplayer also gives the audio qualities.
    let ladder = kind == .audio && hls ? nil : track.qualities
    var renditions: [LensRendition] = []
    var ids = Set<String>()
    for index in 0..<(ladder?.count ?? 0) {
        guard let quality = ladder?[index], quality.bandwidth > 0 else { continue }
        // THEOplayer identifies a quality by its bandwidth.
        let id = String(quality.bandwidth)
        guard ids.insert(id).inserted else { continue }
        let video = quality as? VideoQuality
        renditions.append(
            LensRendition(
                id: id,
                bitrate: Double(quality.bandwidth),
                averageBitrate: quality.averageBandwidth.flatMap { positive(Double($0)) },
                // An HLS variant's BANDWIDTH counts every media type it plays with.
                combinedBitrate: kind == .video && hls ? true : nil,
                width: video.flatMap { $0.width > 0 ? $0.width : nil },
                height: video.flatMap { $0.height > 0 ? $0.height : nil }
            )
        )
    }
    let rendered = track.activeQuality.map { String($0.bandwidth) }
    return LensTrack(
        id: String(track.uid),
        kind: kind,
        selected: track.enabled,
        language: nonEmpty(track.language),
        label: nonEmpty(track.label),
        renditions: renditions.isEmpty ? nil : renditions,
        renderedRenditionId: rendered.flatMap { ids.contains($0) ? $0 : nil }
    )
}

private func googleDAIContentId(_ source: TypedSource) -> String? {
    switch source.ssai {
    case let live as GoogleDAILiveConfiguration:
        return nonEmpty(live.assetKey)
    case let vod as GoogleDAIVodConfiguration:
        return vod.contentSourceID.isEmpty || vod.videoID.isEmpty ? nil : "\(vod.contentSourceID)/\(vod.videoID)"
    default:
        return nil
    }
}

private func isHls(_ source: TypedSource?) -> Bool {
    guard let source else { return false }
    let type = source.type.lowercased()
    if !type.isEmpty {
        return type.contains("mpegurl")
    }
    return URL(string: source.src)?.pathExtension.lowercased() == "m3u8"
}

private func lensPreload(_ preload: Preload) -> LensPreload? {
    switch preload {
    case Preload.none: return .off
    case .auto: return .auto
    #if os(iOS)
    case .metadata: return .metadata
    #endif
    @unknown default: return nil
    }
}

private func lensPresentationMode(_ mode: PresentationMode) -> LensPresentationMode? {
    switch mode {
    case .inline: return .inline
    case .fullscreen: return .fullscreen
    case .pictureInPicture: return .pictureInPicture
    @unknown default: return nil
    }
}

/// THEOplayer reports 0 until it knows the duration.
private func duration(_ player: THEOplayer) -> Double? {
    player.duration.flatMap { $0 > 0 ? $0 : nil }
}

private func timeRanges(_ ranges: [TimeRange]) -> [LensTimeRange] {
    ranges.map { LensTimeRange(start: $0.start, end: $0.end) }
}

private func positive(_ value: Double) -> Double? {
    value.isFinite && value > 0 ? value : nil
}

private func nonEmpty(_ value: String) -> String? {
    value.isEmpty ? nil : value
}
