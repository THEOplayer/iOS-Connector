//
//  AppStateConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 27/09/2022.
//

import ConvivaSDK
import AVFoundation

struct AppEventConvivaReporter: AppEventProcessor {
    let analytics: CISAnalytics
    let video: CISVideoAnalyticsProtocol
    let ads: CISAdAnalyticsProtocol

    func appWillEnterForeground(notification: Notification) {
        analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        analytics.reportAppBackgrounded()
    }
    
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, isPlayingAd: Bool) {
        let endpoint = isPlayingAd ? ads : video
        
        if event.indicatedBitrate >= 0 {
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: NSNumber(value: event.indicatedBitrate / 1000))
        }
        
        if event.numberOfDroppedVideoFrames >= 0 {
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: NSNumber(value: event.numberOfDroppedVideoFrames))
        }
    }
}
