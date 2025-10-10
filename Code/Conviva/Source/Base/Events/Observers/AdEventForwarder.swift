//
//  AdEventForwarder.swift
//

import THEOplayerSDK
import THEOplayerConnectorUtilities

struct AdEventForwarder {
    let playerObserver: DispatchObserver
    let adsObserver: DispatchObserver
    let externalAdEventsObserver: DispatchObserver?

    init(player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil, handler: AdHandler) {
        let filter = Filter()
        self.playerObserver = DispatchObserver(dispatcher: player, eventListeners: Self.forwardAdPlaybackEvents(from: player, to: handler, using: filter))
        self.adsObserver = DispatchObserver(dispatcher: player.ads, eventListeners: Self.forwardAdEvents(from: player.ads, player: player, to: handler, using: filter))
        
        if let externalDispatcher = externalEventDispatcher {
            self.externalAdEventsObserver = DispatchObserver(dispatcher: externalDispatcher, eventListeners: Self.forwardAdEvents(from: externalDispatcher, player: player, to: handler, using: filter))
        } else {
            self.externalAdEventsObserver = nil
        }
    }
 
    static func forwardAdPlaybackEvents(from player: THEOplayer, to handler: AdHandler, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: filter.conditionalSender(handler.adPlay)),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: filter.conditionalSender(handler.adPlaying)),
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE) {
                filter.conditionalSender(handler.adTimeUpdate)($0)
                if let rate = player.renderedFramerate {
                    filter.conditionalSender(handler.adRenderedFramerateUpdate)(rate)
                }
            },
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: filter.conditionalSender(handler.adPause))
        ]
    }

    static func forwardAdEvents(from ads: THEOplayerSDK.EventDispatcherProtocol, player: THEOplayer, to handler: AdHandler, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_BEGIN,
                listener: filter.togglingSender(handler.adBreakBegin, setLetThroughTo: true)
            ),
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_END,
                listener: filter.togglingSender(handler.adBreakEnd, setLetThroughTo: false)
            ),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_BEGIN) {
                filter.togglingSender(handler.adBegin, setLetThroughTo: true)(AdBeginWithDurationEvent(beginEvent: $0, duration: player.duration))
            },
            ads.addRemovableEventListener(type: AdsEventTypes.AD_END, listener: handler.adEnd),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_ERROR, listener: handler.adError)
        ]
    }
}

// Temporary workaround for missing LinearAd in Native THEOplayerGoogleIMAIntegration. Can be removed after THEO-10161 is completed.
struct AdBeginWithDurationEvent {
    let beginEvent: AdBeginEvent
    let duration: Double?
}
