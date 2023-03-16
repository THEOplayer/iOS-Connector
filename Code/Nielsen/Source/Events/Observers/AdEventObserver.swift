//
//  AdEventObserver.swift
//
//
//  Created by Damiaan on 07/09/2022.
//

import THEOplayerSDK

public struct AdEventForwarder {
    let adsObserver: DispatchObserver

    init(player: THEOplayer, eventProcessor: AdEventProcessor) {
        adsObserver = DispatchObserver(
            dispatcher: player.ads,
            eventListeners: [
                player.ads.addRemovableEventListener(type: AdsEventTypes.AD_BEGIN, listener: eventProcessor.adBegin),
                player.ads.addRemovableEventListener(type: AdsEventTypes.AD_END, listener: eventProcessor.adEnd)
            ]
        )
    }
}

protocol AdEventProcessor {
    func adBegin(event: AdBeginEvent)
    func adEnd(event: AdEndEvent)
}
