//
//  VerizonAdEventConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 22/09/2022.
//

#if VERIZONMEDIA

import THEOplayerSDK
import ConvivaSDK

class VerizonAdEventConvivaReporter: VerizonAdEventProcessor, ConvivaAdPlaybackEventsReporter {
    let videoAnalytics: CISVideoAnalytics
    let adAnalytics: CISAdAnalytics
    
    init(videoAnalytics: CISVideoAnalytics, adAnalytics: CISAdAnalytics) {
        self.videoAnalytics = videoAnalytics
        self.adAnalytics = adAnalytics
    }
    
    func adBreakBegin(event: VerizonMediaAdBreakBeginEvent) {
        if let adBreak = event.adBreak {
            var info: [AnyHashable : Any] = [
                CIS_SSDK_AD_BREAK_POD_INDEX: AdEventConvivaReporter.serialize(number: NSNumber(value: adBreak.startTime))
            ]
            if let duration = adBreak.duration {
                info[CIS_SSDK_AD_BREAK_POD_DURATION] = AdEventConvivaReporter.serialize(number: NSNumber(value: duration))
            }
            videoAnalytics.reportAdBreakStarted(.ADPLAYER_CONTENT, adType: .SERVER_SIDE, adBreakInfo: info)
        }
    }
    
    func adBreakSkip(event: VerizonMediaAdBreakSkipEvent) {
        adAnalytics.reportAdSkipped()
        adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        videoAnalytics.reportAdBreakEnded()
    }
    
    func adBreakEnd(event: VerizonMediaAdBreakEndEvent) {
        videoAnalytics.reportAdBreakEnded()
    }
    
    func adBegin(event: VerizonMediaAdBeginEvent) {
        if let ad = event.ad {
            let metadata: [String : Any] = [
                CIS_SSDK_METADATA_ASSET_NAME: ad.creative,
                CIS_SSDK_METADATA_DURATION: ad.duration,
                CIS_SSDK_METADATA_IS_LIVE: ad.duration.isInfinite
            ]
            adAnalytics.setAdInfo(metadata)
            adAnalytics.reportAdLoaded(metadata)
            adAnalytics.reportAdStarted(metadata)
            adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
            adAnalytics.reportAdMetric(CIS_SSDK_PLAYBACK_METRIC_RESOLUTION, value: NSValue(cgSize: .init(
                width: ad.width,
                height: ad.height
            )))
        }
    }
    
    func adEnd(event: VerizonMediaAdEndEvent) {
        adAnalytics.reportAdEnded()
    }
}

#endif
