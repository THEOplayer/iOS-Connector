//
//  AdHandler.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

protocol AdHandlerProtocol: AnyObject {
    func createAdBreak(adBreak: UplynkAdBreak)
    func onAdBegin(uplynkAd: UplynkAd)
    func onAdEnd(uplynkAd: UplynkAd)
    func onAdProgressUpdate(currentAd: UplynkAdState, adBreak: UplynkAdBreak, time: Double)
}

final class AdHandler: AdHandlerProtocol {
    private let controller: ServerSideAdIntegrationController
    private let defaultSkipOffset: Int

    private var scheduledAds: [UplynkAd: Ad] = [:]

    init(controller: ServerSideAdIntegrationController, defaultSkipOffset: Int) {
        self.controller = controller
        self.defaultSkipOffset = defaultSkipOffset
    }
    
    func createAdBreak(adBreak: UplynkAdBreak) {
        let adBreakInit = AdBreakInit(timeOffset: Int(adBreak.timeOffset), 
                                      maxDuration: Int(adBreak.duration))
        let currentAdBreak = controller.createAdBreak(params: adBreakInit)
        adBreak.ads.forEach {
            let adInit = AdInit(type: adBreak.type,
                                skipOffset: defaultSkipOffset,
                                duration: Int($0.duration))
            scheduledAds[$0] = controller.createAd(params: adInit,
                                                   adBreak: currentAdBreak)
        }
    }
    
    func onAdBegin(uplynkAd: UplynkAd) {
        guard let ad = scheduledAds[uplynkAd] else {
            // TODO: Add logging
            return
        }
        controller.beginAd(ad: ad)
    }
    
    func onAdEnd(uplynkAd: UplynkAd) {
        guard let ad = scheduledAds[uplynkAd] else {
            // TODO: Add logging
            return
        }
        controller.endAd(ad: ad)
    }
    
    func onAdProgressUpdate(currentAd: UplynkAdState, adBreak: UplynkAdBreak, time: Double) {
        guard let ad = scheduledAds[currentAd.ad] else {
            // TODO: Add logging
            return
        }
        let playedDuration = adBreak.ads
            .prefix(while: {  $0 != currentAd.ad })
            .reduce(0, { $0 + $1.duration })
        
        let startTime = adBreak.timeOffset + playedDuration
        let progress = ((time - startTime) / currentAd.ad.duration)
            .clamped(to: 0...1)
        controller.updateAdProgress(ad: ad, progress: progress)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self > range.upperBound {
            return range.upperBound
        } else if self < range.lowerBound {
            return range.lowerBound
        } else {
            return self
        }
    }
}
