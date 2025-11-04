//
//  THEOliveEventForwarder.swift
//

import THEOplayerSDK
import THEOplayerConnectorUtilities
import AVFoundation
#if canImport(THEOplayerTHEOliveIntegration)
import THEOplayerTHEOliveIntegration

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
class THEOliveEventForwarder {
    private let theoliveObserver: DispatchObserver?
    
    init(player: THEOplayer, handler: THEOliveHandler) {
        if let theolive = player.theoLive {
            self.theoliveObserver = .init(
                dispatcher: theolive,
                eventListeners: Self.forwardEvents(from: theolive, to: handler)
            )
        } else {
            self.theoliveObserver = nil
        }
    }
    
    static func forwardEvents(from theolive: THEOplayerTHEOliveIntegration.THEOlive, to handler: THEOliveHandler) -> [RemovableEventListenerProtocol] {
        [
            theolive.addRemovableEventListener(type: THEOliveEventTypes.ENDPOINT_LOADED, listener: handler.onEndpointLoaded),
            theolive.addRemovableEventListener(type: THEOliveEventTypes.INTENT_TO_FALLBACK, listener: handler.onIntentToFallback)
        ]
    }
}
#endif
