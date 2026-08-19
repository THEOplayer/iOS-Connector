//
//  THEOadsEventForwarder.swift
//

import THEOplayerSDK
import THEOplayerConnectorUtilities
#if canImport(THEOplayerTHEOadsIntegration)
import THEOplayerTHEOadsIntegration

/// A handle that registers THEOads listeners on a theoplayer and removes them on deinit
class THEOadsEventForwarder {
    private let theoadsObserver: DispatchObserver?

    init(player: THEOplayer, handler: AdHandler) {
        if let theoads = player.theoads {
            self.theoadsObserver = .init(
                dispatcher: theoads,
                eventListeners: Self.forwardEvents(from: theoads, to: handler) { [weak player] in
                    player?.currentTime ?? 0
                }
            )
        } else {
            self.theoadsObserver = nil
        }
    }

    static func forwardEvents<Dispatcher: EventDispatcherProtocol>(
        from theoads: Dispatcher,
        to handler: AdHandler,
        currentTime: @escaping () -> Double
    ) -> [RemovableEventListenerProtocol] {
        [
            theoads.addRemovableEventListener(type: THEOadsEventTypes.INTERSTITIAL_ERROR) { event in
                handler.interstitialError(event: event, currentTime: currentTime())
            }
        ]
    }
}
#endif
