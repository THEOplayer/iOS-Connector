//
//  VerizonAdEventForwarder.swift
//  
//
//  Created by Damiaan Dufaux on 21/09/2022.
//

import THEOplayerSDK
import THEOplayerConnectorConviva

struct VerizonAdEventForwarder {
    let playerObserver: DispatchObserver
    let verizonObserver: DispatchObserver

    init(player: THEOplayer, eventProcessor: VerizonAdEventProcessor) {
        let adBreaksObserver = AdBreaksObserver(eventProcessor: eventProcessor)
        playerObserver = .init(
            dispatcher: player,
            eventListeners: AdEventForwarder.forwardAdPlaybackEvents(from: player, to: eventProcessor, using: adBreaksObserver.adFilter)
        )
        let adBreaksList = player.verizonMedia.ads.adBreaks
        verizonObserver = .init(
            dispatcher: adBreaksList,
            eventListeners: Self.observeAdBreakList(from: adBreaksList, adBreaksObserver: adBreaksObserver)
        )
    }
    
    static func observeAdBreakList(from list: VerizonMediaAdBreakArray, adBreaksObserver: AdBreaksObserver) -> [RemovableEventListenerProtocol] {
        [
            list.addRemovableEventListener(type: VerizonMediaAdBreakArrayEventTypes.ADD_AD_BREAK) { event in
                guard let adBreak = event.adBreak else { return }
                adBreaksObserver.forwardEvents(of: adBreak)
            },
            list.addRemovableEventListener(type: VerizonMediaAdBreakArrayEventTypes.REMOVE_AD_BREAK) { event in
                guard let adBreak = event.adBreak else { return }
                adBreaksObserver.stopForwardingEvents(of: adBreak)
            }
        ]
    }
    
    class AdBreaksObserver {
        let adFilter = Filter()
        let eventProcessor: VerizonAdEventProcessor
        
        /// Dictionary that maps adBreaks to their coresponding observer
        var dynamicObservers = [AnyHashable: AdBreakObservers]()
        
        init(eventProcessor: VerizonAdEventProcessor) {
            self.eventProcessor = eventProcessor
        }
        
        func forwardEvents(of adBreak: VerizonMediaAdBreak) {
            let filter = adFilter
            let observers = AdBreakObservers(
                breakObserver: DispatchObserver(
                    dispatcher: adBreak,
                    eventListeners: [
                        adBreak.addRemovableEventListener(
                            type: VerizonMediaAdBreakEventTypes.AD_BREAK_BEGIN,
                            listener: filter.togglingSender(eventProcessor.adBreakBegin, setLetThroughTo: true)
                        ),
                        adBreak.addRemovableEventListener(
                            type: VerizonMediaAdBreakEventTypes.AD_BREAK_END,
                            listener: filter.togglingSender(eventProcessor.adBreakEnd, setLetThroughTo: false)
                        ),
                        adBreak.addRemovableEventListener(
                            type: VerizonMediaAdBreakEventTypes.AD_BREAK_SKIP,
                            listener: filter.togglingSender(eventProcessor.adBreakSkip, setLetThroughTo: false)
                        )
                    ]
                ),
                adObservers: adBreak.ads.map { ad in
                    DispatchObserver(
                        dispatcher: ad,
                        eventListeners: [
                            ad.addRemovableEventListener(
                                type: VerizonMediaAdEventTypes.AD_BEGIN,
                                listener: filter.togglingSender(self.eventProcessor.adBegin, setLetThroughTo: true)
                            ),
                            ad.addRemovableEventListener(
                                type: VerizonMediaAdEventTypes.AD_END,
                                listener: self.eventProcessor.adEnd
                            )
                        ]
                    )
                }
            )
            let key = HashableVerizonMediaAdBreak(adBreak: adBreak)
            dynamicObservers[key] = observers
        }
                
        func stopForwardingEvents(of adBreak: VerizonMediaAdBreak) {
            let key = HashableVerizonMediaAdBreak(adBreak: adBreak)
            dynamicObservers.removeValue(forKey: key)
        }
        
        struct AdBreakObservers {
            let breakObserver: DispatchObserver
            let adObservers:  [DispatchObserver]
        }
    }
}

protocol VerizonAdEventProcessor: AdPlaybackEventProcessor {
    func adBreakBegin(event: VerizonMediaAdBreakBeginEvent)
    func adBreakSkip(event: VerizonMediaAdBreakSkipEvent)
    func adBreakEnd(event: VerizonMediaAdBreakEndEvent)
    func adBegin(event: VerizonMediaAdBeginEvent)
    func adEnd(event: VerizonMediaAdEndEvent)
}
