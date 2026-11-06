//
//  LensConnector.swift
//

import LensSDK
import THEOplayerConnectorUtilities
import THEOplayerSDK

/// The configuration of a `LensConnector`: the options of `Lens.join`, without the namespace and the player, which the
/// connector provides.
public struct LensConfiguration {
    public var destinations: [LensDestination]
    public var consent: LensConsent
    public var strict: Bool
    public var heartbeatMs: Int64
    public var batch: LensBatch?
    /// Returns the content ID to report for a source. Without it, or when it returns nil, a Google DAI source is
    /// reported by its asset IDs, and Lens derives the content ID of any other source from its URL.
    public var contentId: ContentIdProvider?

    public init(
        destinations: [LensDestination] = [],
        consent: LensConsent = .granted,
        strict: Bool = false,
        heartbeatMs: Int64 = 30_000,
        batch: LensBatch? = nil,
        contentId: ContentIdProvider? = nil
    ) {
        self.destinations = destinations
        self.consent = consent
        self.strict = strict
        self.heartbeatMs = heartbeatMs
        self.batch = batch
        self.contentId = contentId
    }
}

/// The connector between a THEOplayer and Dolby OptiView Lens.
///
/// The connector joins Lens with a player adapter for the given player, in the `theoplayer` namespace, so Lens reports
/// playback on its own: sessions, playback states, errors and the player's CMCD keys.
public final class LensConnector {
    /// The Lens handle the connector joined with, in the `theoplayer` namespace. Use it to set consent or flush. To
    /// report events of your own, join Lens in your own namespace with `adapter`.
    public let handle: LensHandle

    /// The Lens player adapter for the player. Another SDK reporting to Lens joins with this same adapter to share the
    /// player's session.
    public let adapter: THEOplayerLensAdapter

    private var destroyObserver: DispatchObserver?

    /// Creates a connector for the given player and joins Lens.
    ///
    /// - Parameters:
    ///   - player: The player to report. The connector does not retain it.
    ///   - configuration: The options to join Lens with.
    /// - Throws: The error of `Lens.join` for invalid options.
    public init(player: THEOplayer, configuration: LensConfiguration = LensConfiguration()) throws {
        adapter = THEOplayerLensAdapter(player: player, contentId: configuration.contentId)
        handle = try Lens.join(
            LensJoinOptions(
                namespace: "theoplayer",
                destinations: configuration.destinations,
                consent: configuration.consent,
                strict: configuration.strict,
                heartbeatMs: configuration.heartbeatMs,
                player: adapter,
                batch: configuration.batch
            )
        )
        destroyObserver = DispatchObserver(
            dispatcher: player,
            eventListeners: [
                player.addRemovableEventListener(type: PlayerEventTypes.DESTROY) { [weak self] _ in self?.destroy() }
            ]
        )
    }

    /// Ends the session and stops reporting the player. The connector is destroyed with its player.
    public func destroy() {
        destroyObserver = nil
        handle.dispose()
    }
}
