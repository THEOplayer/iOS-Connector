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

    func appWillEnterForeground(notification: Notification) {
        analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        analytics.reportAppBackgrounded()
    }
    
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent) {
        if event.indicatedBitrate >= 0 {
            video.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: NSNumber(value: event.indicatedBitrate / 1000))
        }
        
        if event.numberOfDroppedVideoFrames >= 0 {
            video.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: NSNumber(value: event.numberOfDroppedVideoFrames))
        }
    }
}
