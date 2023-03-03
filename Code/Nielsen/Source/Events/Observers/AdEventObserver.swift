//
//  AdEventObserver.swift
//
//
//  Created by Damiaan on 07/09/2022.
//

import THEOplayerSDK

public struct AdEventForwarder {
    let playerObserver: DispatchObserver
    let adsObserver: DispatchObserver

    init(player: THEOplayer, eventProcessor: AdEventProcessor) {
        let filter = Filter()
        playerObserver = DispatchObserver(dispatcher: player, eventListeners: Self.forwardAdPlaybackEvents(from: player, to: eventProcessor, using: filter))
        adsObserver = DispatchObserver(dispatcher: player.ads, eventListeners: Self.forwardAdEvents(from: player.ads, to: eventProcessor, using: filter))
    }
 
    public static func forwardAdPlaybackEvents(from player: THEOplayer, to processor: AdPlaybackEventProcessor, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            player.addRemovableEventListener(type: PlayerEventTypes.PLAY, listener: filter.conditionalSender(processor.adPlay)),
            player.addRemovableEventListener(type: PlayerEventTypes.PLAYING, listener: filter.conditionalSender(processor.adPlaying)),
            player.addRemovableEventListener(type: PlayerEventTypes.TIME_UPDATE, listener: filter.conditionalSender(processor.adTimeUpdate)),
            player.addRemovableEventListener(type: PlayerEventTypes.PAUSE, listener: filter.conditionalSender(processor.adPause))
        ]
    }

    static func forwardAdEvents(from ads: Ads, to processor: AdEventProcessor, using filter: Filter) -> [RemovableEventListenerProtocol] {
        [
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_BEGIN,
                listener: filter.togglingSender(processor.adBreakBegin, setLetThroughTo: true)
            ),
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BREAK_END,
                listener: filter.togglingSender(processor.adBreakEnd, setLetThroughTo: false)
            ),
            ads.addRemovableEventListener(
                type: AdsEventTypes.AD_BEGIN,
                listener: filter.togglingSender(processor.adBegin, setLetThroughTo: true)
            ),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_END, listener: processor.adEnd),
            ads.addRemovableEventListener(type: AdsEventTypes.AD_ERROR, listener: processor.adError)
        ]
    }
}

protocol AdEventProcessor: AdPlaybackEventProcessor {
    func adBreakBegin(event: AdBreakBeginEvent)
    func adBreakEnd(event: AdBreakEndEvent)
    func adBegin(event: AdBeginEvent)
    func adEnd(event: AdEndEvent)
    func adError(event: AdErrorEvent)
}

public protocol AdPlaybackEventProcessor {
    func adPlay(event: PlayEvent)
    func adPlaying(event: PlayingEvent)
    func adTimeUpdate(event: TimeUpdateEvent)
    func adPause(event: PauseEvent)
}
