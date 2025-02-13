//
//  AdHandler.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation
import OSLog
import THEOplayerSDK

protocol AdHandlerFactory: AnyObject {
    static func makeAdHandler(controller: ServerSideAdIntegrationController,
                              skipOffset: Int) -> AdHandlerProtocol
}

protocol AdHandlerProtocol: AnyObject {
    func createAdBreak(adBreak: UplynkAdBreak)
    func onAdBegin(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak)
    func onAdEnd(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak)
    func onAdProgressUpdate(currentAd: UplynkAdState, adBreak: UplynkAdBreak, time: Double)
}

final class AdHandler: AdHandlerProtocol, AdHandlerFactory {
    private let controller: ServerSideAdIntegrationController
    private var scheduledAds: [UplynkAd: Ad] = [:]
    private let skipOffset: Int
    
    static func makeAdHandler(controller: ServerSideAdIntegrationController,
                              skipOffset: Int) -> AdHandlerProtocol {
        AdHandler(controller: controller, skipOffset: skipOffset)
    }
    
    init(controller: ServerSideAdIntegrationController, skipOffset: Int) {
        self.controller = controller
        self.skipOffset = skipOffset
        os_log(.debug,log: .adHandler, "AdHandler init", skipOffset)
    }
    
    func createAdBreak(adBreak: UplynkAdBreak) {
        let adBreakInit = AdBreakInit(timeOffset: Int(adBreak.timeOffset), 
                                      maxDuration: Int(adBreak.duration))
        let currentAdBreak = controller.createAdBreak(params: adBreakInit)
        os_log(.debug,log: .adHandler, "CreateAdBreak: created ad break time offset %f", currentAdBreak.timeOffset)
        adBreak.ads.forEach {
            let adInit = AdInit(type: adBreak.type,
                                skipOffset: skipOffset,
                                duration: Int($0.duration))
            scheduledAds[$0] = controller.createAd(params: adInit,
                                                   adBreak: currentAdBreak)
            os_log(.debug,log: .adHandler, "CreateAdBreak: created ad of type %@ and duration %f", adBreak.type, $0.duration)
        }
    }
    
    func onAdBegin(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak) {
        let indexOfAd = adBreak.ads.firstIndex(of: uplynkAd).map { $0 + 1 } ?? -1
        let count = adBreak.ads.count

        os_log(.debug,log: .adHandler, "OnAdBegin: beginning ad `%d of %d` and has a duration %f", indexOfAd, count, uplynkAd.duration)
        guard let ad = scheduledAds[uplynkAd] else {
            os_log(.debug,log: .adHandler, "OnAdBegin: Skipping ad is not found in the scheduled ads")
            return
        }
        controller.beginAd(ad: ad)
    }
    
    func onAdEnd(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak) {
        let indexOfAd = adBreak.ads.firstIndex(of: uplynkAd).map { $0 + 1 } ?? -1
        let count = adBreak.ads.count

        os_log(.debug,log: .adHandler, "OnAdEnd: ending ad `%d of %d` that has a duration %f", indexOfAd, count, uplynkAd.duration)
        guard let ad = scheduledAds[uplynkAd] else {
            os_log(.debug,log: .adHandler, "OnAdEnd: Skipping ad is not found in the scheduled ads")
            return
        }
        controller.endAd(ad: ad)
    }
    
    func onAdProgressUpdate(currentAd: UplynkAdState, adBreak: UplynkAdBreak, time: Double) {
        guard let ad = scheduledAds[currentAd.ad] else {
            os_log(.debug,log: .adHandler, "OnAdEnd: Skipping ad is not found in the scheduled ads")
            return
        }
        let playedDuration = adBreak.ads
            .prefix(while: {  $0 != currentAd.ad })
            .reduce(0, { $0 + $1.duration })
        
        let startTime = adBreak.timeOffset + playedDuration
        let progress = ((time - startTime) / currentAd.ad.duration)
            .clamped(to: 0...1)
        
        let indexOfAd = adBreak.ads.firstIndex(of: currentAd.ad).map { $0 + 1 } ?? -1
        let count = adBreak.ads.count
        os_log(.debug,log: .adHandler, "OnAdProgressUpdate: ad `%d of %d` has progressed to %f", indexOfAd, count, progress)
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
