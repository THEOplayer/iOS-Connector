//
//  AdEventForwarder.swift
//
//
//  Created by Damiaan on 07/09/2022.
//

import THEOplayerSDK
import THEOplayerConnectorUtilities

public struct AdEventForwarder {
    let playerObserver: DispatchObserver
    let adsObserver: DispatchObserver

    init(player: THEOplayer, eventProcessor: AdEventProcessor) {
        let filter = Filter()
        playerObserver = DispatchObserver(dispatcher: player, eventListeners: Self.forwardAdPlaybackEvents(from: player, to: eventProcessor, using: filter))
        adsObserver = DispatchObserver(dispatcher: player.ads, eventListeners: Self.forwardAdEvents(from: player.ads, player: player, to: eventProcessor, using: filter))
    }
 
    public static func forwardAdPlaybackEvents(from player: THEOplayer, to processor: AdPlaybackEventProcessor, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: filter.conditionalSender(processor.adPlay)),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: filter.conditionalSender(processor.adPlaying)),
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE) { [unowned player] in
                filter.conditionalSender(processor.adTimeUpdate)($0)
                if let rate = player.renderedFramerate {
                    filter.conditionalSender(processor.adRenderedFramerateUpdate)(rate)
                }
            },
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: filter.conditionalSender(processor.adPause))
        ]
    }

    static func forwardAdEvents(from ads: Ads, player: THEOplayer, to processor: AdEventProcessor, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_BEGIN,
                listener: filter.togglingSender(processor.adBreakBegin, setLetThroughTo: true)
            ),
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_END,
                listener: filter.togglingSender(processor.adBreakEnd, setLetThroughTo: false)
            ),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_BEGIN) { [unowned player] in
                filter.togglingSender(processor.adBegin, setLetThroughTo: true)(AdBeginWithDurationEvent(beginEvent: $0, duration: player.duration))
            },
            ads.addRemovableEventListener(type: AdsEventTypes.AD_END, listener: processor.adEnd),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_ERROR, listener: processor.adError)
        ]
    }
}

// Temporary workaround for missing LinearAd in Native THEOplayerGoogleIMAIntegration. Can be removed after THEO-10161 is completed.
public struct AdBeginWithDurationEvent {
    let beginEvent: AdBeginEvent
    let duration: Double?
}

protocol AdEventProcessor: AdPlaybackEventProcessor {
    func adBreakBegin(event: AdBreakBeginEvent)
    func adBreakEnd(event: AdBreakEndEvent)
    func adBegin(event: AdBeginWithDurationEvent)
    func adEnd(event: AdEndEvent)
    func adError(event: AdErrorEvent)
}

public protocol AdPlaybackEventProcessor {
    func adPlay(event: PlayEvent)
    func adPlaying(event: PlayingEvent)
    func adTimeUpdate(event: TimeUpdateEvent)
    func adRenderedFramerateUpdate(framerate: Float)
    func adPause(event: PauseEvent)
}
