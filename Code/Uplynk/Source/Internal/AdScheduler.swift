//
//  AdScheduler.swift
//  
//
//  Created by Khalid, Yousif on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import OSLog

protocol AdSchedulerFactory {
    static func makeAdScheduler(adBreaks: [UplynkAdBreak], adHandler: AdHandlerProtocol) -> AdSchedulerProtocol
}

protocol AdSchedulerProtocol {
    var isPlayingAd: Bool { get }
    var isPlayingLastAdInAdBreak: Bool { get }
    var currentAdStartTime: Double? { get }
    var currentAdEndTime: Double? { get }
    var currentAdBreakStartTime: Double? { get }
    var currentAdBreakEndTime: Double? { get }

    func onTimeUpdate(time: Double)
    func add(ads: UplynkAds)
    func adBreakOffsetIfAdBreakContains(time: Double) -> Double?
    func adBreakEndTimeIfAdBreakContains(time: Double) -> Double?
    func firstUnwatchedAdBreakOffset(before time: Double) -> Double?
    func lastUnwatchedAdBreakOffset(before time: Double) -> Double?
}

final class AdScheduler: AdSchedulerProtocol, AdSchedulerFactory {
    private(set) var adBreaks: [UplynkAdBreakState] = []
    private let adHandler: AdHandlerProtocol
    
    static func makeAdScheduler(adBreaks: [UplynkAdBreak], adHandler: AdHandlerProtocol) -> AdSchedulerProtocol {
        AdScheduler(adBreaks: adBreaks, adHandler: adHandler)
    }
    
    init(adBreaks: [UplynkAdBreak], adHandler: AdHandlerProtocol) {
        self.adHandler = adHandler
        adBreaks.forEach {
            self.createAdBreak($0)
        }
    }
    
    var isPlayingAd: Bool {
        adBreaks.contains { $0.state == .started }
    }
    
    var isPlayingLastAdInAdBreak: Bool {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }),
              let currentAd = currentAdBreak.ads.first(where: { $0.state == .started }) else {
            return false
        }
        
        return currentAdBreak.ads.last == currentAd
    }
    
    var currentAdStartTime: Double? {
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
    
    var currentAdEndTime: Double? {
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
    
    var currentAdBreakStartTime: Double? {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }) else {
            return nil
        }
        
        return currentAdBreak.adBreak.timeOffset
    }
    
    var currentAdBreakEndTime: Double? {
        guard let currentAdBreak = adBreaks.first(where: { $0.state == .started }) else {
            return nil
        }
        
        return currentAdBreak.adBreak.timeOffset + currentAdBreak.adBreak.duration
    }
    
    func onTimeUpdate(time: Double) {
        os_log(.debug, log: .adScheduler, "TIME_UPDATE: Handling time update %f",time)
        guard let currentAdBreak = adBreaks.first(where: {
            let rangeToCheck = ($0.adBreak.timeOffset...($0.adBreak.timeOffset + $0.adBreak.duration))
            let containsAd = rangeToCheck.containsWithAccuracy(time)
            
            os_log(.debug, log: .adScheduler, "TIME_UPDATE: Checking range %f-%f contains %f - returns %d", rangeToCheck.lowerBound, rangeToCheck.upperBound, time, containsAd)
            return containsAd
        }) else {
            os_log(.debug, log: .adScheduler, "TIME_UPDATE: No adbreak found for %f", time)
            completeAllStartedAdBreaks()
            return
        }
        if currentAdBreak.state == .completed || currentAdBreak.state == .notPlayed {
            os_log(.debug, log: .adScheduler, "TIME_UPDATE: starting ad break with offset %f", currentAdBreak.adBreak.timeOffset)
        } else {
            os_log(.debug, log: .adScheduler, "TIME_UPDATE: Handling progress for ad break with offset %f", currentAdBreak.adBreak.timeOffset)
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
    
    func adBreakOffsetIfAdBreakContains(time: Double) -> Double? {
        guard let adBreakContainingTheTime = adBreaks.first (where: {
            if $0.adBreak.timeOffset <= time {
                let adBreakStartTime = $0.adBreak.timeOffset
                let adBreakEndTime = $0.adBreak.timeOffset + $0.adBreak.duration

                return (adBreakStartTime...adBreakEndTime).containsWithAccuracy(time)
            } else {
                return false
            }
        }) else {
            return nil
        }
        
        return adBreakContainingTheTime.adBreak.timeOffset
    }
    
    func adBreakEndTimeIfAdBreakContains(time: Double) -> Double? {
        guard let adBreakContainingTheTime = adBreaks.first (where: {
            if $0.adBreak.timeOffset <= time {
                let adBreakStartTime = $0.adBreak.timeOffset
                let adBreakEndTime = $0.adBreak.timeOffset + $0.adBreak.duration

                return (adBreakStartTime...adBreakEndTime).containsWithAccuracy(time)
            } else {
                return false
            }
        }) else {
            return nil
        }
        
        return adBreakContainingTheTime.adBreak.timeOffset + adBreakContainingTheTime.adBreak.duration
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
            if (adStart...adEnd).containsWithAccuracy(time) {
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

private extension ClosedRange where Bound == Double {
    func containsWithAccuracy(_ value: Double, accuracy: Double = 0.000001) -> Bool {
        return (value - lowerBound) > -accuracy && (upperBound - value) > -accuracy
    }
}
