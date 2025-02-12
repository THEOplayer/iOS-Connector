//
//  AdScheduler.swift
//  
//
//  Created by Khalid, Yousif on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import OSLog

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
        let currentAd = findCurrentAd(adBreakState: currentAdBreak, time: time)
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
    
    func checkIfThereIsAnAdBreak(on time: Double) -> Bool {
        adBreaks.contains(where: {
            ($0.adBreak.timeOffset...($0.adBreak.timeOffset + $0.adBreak.duration)).contains(time)
        })
    }
    
    func adBreakOffsetIfAdBreakContains(time: Double) -> Double? {
        guard let adBreakContainingTheTime = adBreaks.first (where: {
            if $0.adBreak.timeOffset <= time {
                let adBreakStartTime = $0.adBreak.timeOffset
                let adBreakEndTime = $0.adBreak.timeOffset + $0.adBreak.duration

                return (adBreakStartTime...adBreakEndTime).contains(time)
            } else {
                return false
            }
        }) else {
            return nil
        }
        
        return adBreakContainingTheTime.adBreak.timeOffset
    }
    
    func firstUnwatchedAdBreakOffset(before time: Double) -> Double? {
        // If we have an unplayed adbreak before the passed in time, play the adbreak from the beginning
        guard let firstUnplayedAdBreak = adBreaks
            .first (where: { $0.state == .notPlayed && $0.adBreak.timeOffset <= time })?
            .adBreak
        else {
            return nil
        }
        return firstUnplayedAdBreak.timeOffset
    }
    
    func lastUnwatchedAdBreakOffset(before time: Double) -> Double? {
        // Get the last adbreak before the passed in time
        guard 
            let lastAdBreakBeforeTheSeekedTimed = adBreaks.last (where: { $0.adBreak.timeOffset <= time }),
            lastAdBreakBeforeTheSeekedTimed.state == .notPlayed
        else {
            return nil
        }

        // If there is an ad break after the current candidate ad break that is already completed,
        // we won't play the candidate ad break
        if adBreaks.first(where: { $0.adBreak.timeOffset > time && $0.state == .completed }) != nil {
            return nil
        }

        return lastAdBreakBeforeTheSeekedTimed.adBreak.timeOffset
    }
    
    func getCurrentAdEndTime() -> Double? {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }),
              let currentAd = currentAdBreak.ads.first(where: { $0.state == .started }) else {
            return nil
        }
        let currentAdOffset = currentAdBreak.ads
            .prefix(while: { $0.state != .started })
            .reduce(currentAdBreak.adBreak.timeOffset) {
                $0 + $1.ad.duration
            }
        
        return currentAdOffset + currentAd.ad.duration
    }
    
    func getCurrentAdStartTime() -> Double? {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }) else {
            return nil
        }
        let currentAdOffset = currentAdBreak.ads
            .prefix(while: { $0.state != .started })
            .reduce(currentAdBreak.adBreak.timeOffset) {
                $0 + $1.ad.duration
            }
        
        return currentAdOffset
    }
}

private extension AdScheduler {
    func startCurrentAdBreak(adBreakState: UplynkAdBreakState, time: Double) {
        if (adBreakState.state != .started) {
            moveAdBreakToState(adBreakState: adBreakState, state: .started)
        }
    }
    
    func startCurrentAd(adBreakState: UplynkAdBreakState,
                        currentAd: UplynkAdState,
                        time: Double) {
        switch currentAd.state {
        case .notPlayed, .completed:
            moveAdToState(adState: currentAd, state: .started, in: adBreakState.adBreak)
        case .started:
            adHandler.onAdProgressUpdate(currentAd: currentAd, adBreak: adBreakState.adBreak, time: time)
        }
    }
    
    func moveAdBreakToState(adBreakState: UplynkAdBreakState, state: AdBreakState) {
        guard adBreakState.state != state else {
            return
        }
        let previousState = adBreakState.state
        adBreakState.state = state
        os_log(.debug,log: .adHandler, "MoveAdBreakToState: adbreak with offset %f changed from %@ to state %@", adBreakState.adBreak.timeOffset, previousState.rawValue, state.rawValue)
        if adBreakState.state == .completed {
            completeAllStartedAds(adBreakState: adBreakState)
        }
    }
    
    func moveAdToState(adState: UplynkAdState, state: AdState, in adBreak: UplynkAdBreak) {
        guard adState.state != state else {
            return
        }
        let previousState = adState.state
        adState.state = state

        let indexOfAd = adBreak.ads.firstIndex(of: adState.ad).map { $0 + 1 } ?? -1
        let count = adBreak.ads.count
        os_log(.debug,log: .adHandler, "MoveAdToState: Ad `%d of %d` in adbreak with offset %f changed from %@ to %@", indexOfAd, count, adBreak.timeOffset, previousState.rawValue, state.rawValue)

        switch adState.state {
        case .started:
            adHandler.onAdBegin(uplynkAd: adState.ad, in: adBreak)
        case .completed:
            adHandler.onAdEnd(uplynkAd: adState.ad, in: adBreak)
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
        
    func completeAllStartedAds(adBreakState: UplynkAdBreakState,
                               except currentAd: UplynkAdState? = nil) {
        adBreakState.ads
            .filter { $0.state == .started && $0 != currentAd }
            .forEach {
                moveAdToState(adState: $0, state: .completed, in: adBreakState.adBreak)
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
