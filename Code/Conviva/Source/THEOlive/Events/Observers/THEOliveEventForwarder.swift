//
//  THEOliveEventForwarder.swift
//

import THEOplayerSDK
import THEOplayerConnectorUtilities
import AVFoundation
import THEOplayerTHEOliveIntegration

/// A handle that registers basic playback listeners on a theoplayer and removes them on deinit
class THEOliveEventForwarder {
    private let theoliveObserver: DispatchObserver?
    weak var player: THEOplayer?
    weak var eventProcessor: THEOliveEventConvivaReporter?
    
    init(player: THEOplayer, eventProcessor: THEOliveEventConvivaReporter) {
        if let theolive = player.theoLive {
            theoliveObserver = .init(
                dispatcher: theolive,
                eventListeners: Self.forwardEvents(from: theolive, to: eventProcessor)
            )
        } else {
            theoliveObserver = nil
        }
        
        self.player = player
        self.eventProcessor = eventProcessor
    }
    
    static func forwardEvents(from theolive: THEOplayerTHEOliveIntegration.THEOlive, to processor: THEOliveEventConvivaReporter) -> [RemovableEventListenerProtocol] {
        [
            theolive.addRemovableEventListener(type: THEOliveEventTypes.ENDPOINT_LOADED, listener: processor.onEndpointLoaded),
            theolive.addRemovableEventListener(type: THEOliveEventTypes.INTENT_TO_FALLBACK, listener: processor.onIntentToFallback)
        ]
    }
}
