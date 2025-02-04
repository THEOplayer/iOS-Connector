//
//  AdScheduler.swift
//  
//
//  Created by Khalid, Yousif on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

final class AdScheduler {
    private(set) var adBreaks: [UplynkAdBreakState] = []
    private let adHandler: AdHandlerProtocol
    
    init(adBreaks: [UplynkAdBreak], adHandler: AdHandlerProtocol) {
        self.adHandler = adHandler
        adBreaks.forEach {
            self.createAdBreak($0)
        }
    }
    
    func onTimeUpdate(time: Double) {
        guard let currentAdBreak = adBreaks.first(where: {
            ($0.adBreak.timeOffset...($0.adBreak.timeOffset + $0.adBreak.duration)).contains(time)
        }) else {
            endAllAdBreaks()
            return
        }
        let currentAd = beginCurrentAdBreak(adBreakState: currentAdBreak, time: time)
        endAllStartedAds(adBreakState: currentAdBreak, currentAd: currentAd)
        beginCurrentAd(adBreakState: currentAdBreak, currentAd: currentAd, time: time)
        endAllAdBreaksExcept(adBreakState: currentAdBreak)
    }
    
    func add(ads: UplynkAds) {
        ads.breaks.forEach {
            createAdBreak($0)
        }
    }
}

private extension AdScheduler {
    func beginCurrentAdBreak(adBreakState: UplynkAdBreakState, time: Double) -> UplynkAdState? {
        let currentAd = findCurrentAd(adBreakState: adBreakState, time: time)
        if (adBreakState.state != .started) {
            moveAdBreakToState(adBreakState: adBreakState, state: .started)
        }
        return currentAd
    }
    
    func beginCurrentAd(adBreakState: UplynkAdBreakState,
                        currentAd: UplynkAdState?,
                        time: Double) {
        guard let currentAd else {
            // TODO: Add Logging
            return
        }
        switch currentAd.state {
        case .completed, .notPlayed:
            moveAdToState(adState: currentAd, state: .started)
        case .started:
            adHandler.onAdProgressUpdate(currentAd: currentAd, adBreak: adBreakState.adBreak, time: time)
        }
    }
    
    func moveAdBreakToState(adBreakState: UplynkAdBreakState, state: AdBreakState) {
        guard adBreakState.state != state else {
            return
        }
        adBreakState.state = state
        if adBreakState.state == .completed {
            endAllStartedAds(adBreakState: adBreakState)
        }
    }
    
    func moveAdToState(adState: UplynkAdState, state: AdState) {
        guard adState.state != state else {
            return
        }
        adState.state = state
        switch adState.state {
        case .started:
            adHandler.onAdBegin(uplynkAd: adState.ad)
        case .completed:
            adHandler.onAdEnd(uplynkAd: adState.ad)
        default:
            // no-op
            break
        }
    }
    
    func findCurrentAd(adBreakState: UplynkAdBreakState, time: Double) -> UplynkAdState? {
        var adStart = adBreakState.adBreak.timeOffset
        for ad in adBreakState.ads {
            let adEnd = adStart + ad.ad.duration
            if (adStart...adEnd).contains(time) {
                return ad
            }
            adStart = adEnd
        }
        return nil
    }
        
    func endAllStartedAds(adBreakState: UplynkAdBreakState,
                          currentAd: UplynkAdState? = nil) {
        adBreakState.ads
            .filter { $0.state == .started && $0 != currentAd }
            .forEach {
                moveAdToState(adState: $0, state: .completed)
            }
    }
    
    func endAllAdBreaks() {
        adBreaks
            .filter { $0.state == .started }
            .forEach {
                moveAdBreakToState(adBreakState: $0, state: .completed)
            }
    }
    
    func endAllAdBreaksExcept(adBreakState: UplynkAdBreakState) {
        adBreaks
            .filter { $0.state == .started && $0 != adBreakState }
            .forEach {
                moveAdBreakToState(adBreakState: $0, state: .completed)
            }
    }
    
    func createAdBreak(_ adBreak: UplynkAdBreak) {
        adHandler.createAdBreak(adBreak: adBreak)
        adBreaks.append(UplynkAdBreakState(adBreak: adBreak, state: .notPlayed))
    }
}
