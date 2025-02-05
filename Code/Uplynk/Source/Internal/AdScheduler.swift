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
    
    var isPlayingAd: Bool {
        adBreaks.contains { $0.state == .started }
    }
    
    func onTimeUpdate(time: Double) {
        guard let currentAdBreak = adBreaks.first(where: {
            ($0.adBreak.timeOffset...($0.adBreak.timeOffset + $0.adBreak.duration)).contains(time)
        }) else {
            completeAllStartedAdBreaks()
            return
        }
        startCurrentAdBreak(adBreakState: currentAdBreak, time: time)
        let currentAd = findCurrentUnplayedAd(adBreakState: currentAdBreak, time: time)
        completeAllStartedAds(adBreakState: currentAdBreak, except: currentAd)
        if let currentAd {
            startCurrentAd(adBreakState: currentAdBreak, currentAd: currentAd, time: time)
        }
        completeAllAdBreaks(except: currentAdBreak)
    }
    
    func add(ads: UplynkAds) {
        ads.breaks.forEach {
            createAdBreak($0)
        }
    }
    
    func adBreakEndTimeIfPlayingAlreadyWatchedAdBreak(for time: Double) -> Double? {
        guard let currentAdBreak = adBreaks.first(where: {
            ($0.adBreak.timeOffset...($0.adBreak.timeOffset + $0.adBreak.duration)).contains(time)
        }), currentAdBreak.state == .completed else {
            return nil
        }
        
        return currentAdBreak.adBreak.timeOffset + currentAdBreak.adBreak.duration
    }
    
    func firstUnwatchedAdBreakOffset(before time: Double) -> Double? {
        adBreaks
            .first { $0.state == .notPlayed && $0.adBreak.timeOffset <= time }?
            .adBreak.timeOffset
    }
    
    func lastUnwatchedAdBreakOffset(before time: Double) -> Double? {
        guard let lastAdBreakBeforeTheSeekedTimed = adBreaks.last (where: { $0.adBreak.timeOffset <= time }),
              lastAdBreakBeforeTheSeekedTimed.state == .notPlayed else {
            return nil
        }
        
        return lastAdBreakBeforeTheSeekedTimed.adBreak.timeOffset
    }
    
    func getCurrentAdBreakEndTime() -> Double? {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }) else {
            return nil
        }
        return currentAdBreak.adBreak.timeOffset + currentAdBreak.adBreak.duration
    }
}

private extension AdScheduler {
    func startCurrentAdBreak(adBreakState: UplynkAdBreakState, time: Double) {
        if (adBreakState.state != .started && adBreakState.state == .notPlayed) {
            moveAdBreakToState(adBreakState: adBreakState, state: .started)
        }
    }
    
    func startCurrentAd(adBreakState: UplynkAdBreakState,
                        currentAd: UplynkAdState,
                        time: Double) {
        switch currentAd.state {
        case .notPlayed:
            moveAdToState(adState: currentAd, state: .started)
        case .started:
            adHandler.onAdProgressUpdate(currentAd: currentAd, adBreak: adBreakState.adBreak, time: time)
        case .completed:
            // No-op
            break
        }
    }
    
    func moveAdBreakToState(adBreakState: UplynkAdBreakState, state: AdBreakState) {
        guard adBreakState.state != state else {
            return
        }
        adBreakState.state = state
        if adBreakState.state == .completed {
            completeAllStartedAds(adBreakState: adBreakState)
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
    
    func findCurrentUnplayedAd(adBreakState: UplynkAdBreakState, time: Double) -> UplynkAdState? {
        var adStart = adBreakState.adBreak.timeOffset
        for ad in adBreakState.ads.filter({ $0.state == .notPlayed }) {
            let adEnd = adStart + ad.ad.duration
            if (adStart...adEnd).contains(time) {
                return ad
            }
            adStart = adEnd
        }
        return nil
    }
        
    func completeAllStartedAds(adBreakState: UplynkAdBreakState,
                          except currentAd: UplynkAdState? = nil) {
        adBreakState.ads
            .filter { $0.state == .started && $0 != currentAd }
            .forEach {
                moveAdToState(adState: $0, state: .completed)
            }
    }
    
    func completeAllStartedAdBreaks() {
        adBreaks
            .filter { $0.state == .started }
            .forEach {
                moveAdBreakToState(adBreakState: $0, state: .completed)
            }
    }
    
    func completeAllAdBreaks(except adBreakState: UplynkAdBreakState) {
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
