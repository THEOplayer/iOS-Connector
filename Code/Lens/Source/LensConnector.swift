//
//  LensConnector.swift
//

import LensSDK
@_spi(Core) import THEOplayerSDK

/// The configuration of a `LensConnector`: the options of `Lens.join`, without the namespace and the player, which the
/// connector provides.
public struct LensConfiguration {
    public var destinations: [LensDestination]
    public var consent: LensConsent
    public var strict: Bool
    /// The cadence of the session's liveness report; nil for Lens's default.
    public var heartbeatMs: Int64?
    public var batch: LensBatch?
    /// Returns the content ID to report for a source. Without it, or when it returns nil, a Google DAI source is
    /// reported by its asset IDs, and Lens derives the content ID of any other source from its URL.
    public var contentId: ContentIdProvider?

    public init(
        destinations: [LensDestination] = [],
        consent: LensConsent = .granted,
        strict: Bool = false,
        heartbeatMs: Int64? = nil,
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
/// playback on its own: sessions, playback states, errors and the player's CMCD keys. It keeps the player's
/// `cmcd.linkedSessionId` equal to the Lens session ID, so the player's own CMCD data links to the Lens session.
///
/// - Important: Lens keeps the player alive while the connector is joined. Call `destroy()` when you are done with the
///   player, before you release it.
public final class LensConnector {
    /// The Lens handle the connector joined with, in the `theoplayer` namespace. Use it to set consent or flush. To
    /// report events of your own, join Lens in your own namespace with the player.
    public let handle: LensHandle

    /// The Lens player adapter for the player.
    public let adapter: THEOplayerLensAdapter

    private let sessionLink: SessionLink

    /// Creates a connector for the given player and joins Lens.
    ///
    /// - Parameters:
    ///   - player: The player to report.
    ///   - configuration: The options to join Lens with.
    /// - Throws: The error of `Lens.join` for invalid options.
    public init(player: THEOplayer, configuration: LensConfiguration = LensConfiguration()) throws {
        adapter = THEOplayerLensAdapter(player: player, contentId: configuration.contentId)
        var options = LensJoinOptions(
            namespace: "theoplayer",
            destinations: configuration.destinations,
            consent: configuration.consent,
            strict: configuration.strict,
            player: adapter,
            batch: configuration.batch
        )
        if let heartbeatMs = configuration.heartbeatMs { options.heartbeatMs = heartbeatMs }
        handle = try Lens.join(options)
        sessionLink = SessionLink(player: player)
        handle.addSessionDelegate(sessionLink)
        player.cmcd.linkedSessionId = handle.session?.sessionId
    }

    /// Ends the session, stops reporting the player, and lets Lens release it.
    public func destroy() {
        handle.removeSessionDelegate(sessionLink)
        sessionLink.player?.cmcd.linkedSessionId = nil
        handle.dispose()
    }
}

/// Keeps the player's linked CMCD session ID on the Lens session the handle is in.
private final class SessionLink: LensSessionDelegate {
    weak var player: THEOplayer?

    init(player: THEOplayer) {
        self.player = player
    }

    func lensHandle(_ handle: LensHandle, didChangeSession session: LensSession?) {
        player?.cmcd.linkedSessionId = session?.sessionId
    }
}
