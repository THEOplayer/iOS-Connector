//
//  AdHandler.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

final class AdHandler {
    private let controller: ServerSideAdIntegrationController
    
    private var scheduledAds: [UplynkAd: Ad] = [:]

    init(controller: ServerSideAdIntegrationController) {
        self.controller = controller
    }
    
    func createAdBreak(adBreak: UplynkAdBreak) {
        let adBreakInit = AdBreakInit(timeOffset: Int(adBreak.timeOffset), 
                                      maxDuration: Int(adBreak.duration))
        let currentAdBreak = controller.createAdBreak(params: adBreakInit)
        
        adBreak.ads.forEach {
            let adInit = AdInit(type: adBreak.type,
                                duration: Int($0.duration))
            scheduledAds[$0] = controller.createAd(params: adInit, adBreak: currentAdBreak)
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
