//
//  AppStateConvivaReporter.swift
//  

import ConvivaSDK
import AVFoundation
import THEOplayerSDK

class AppHandler {
    // This is a workaround for THEOSD-14780
    // Access log entries for preroll ads come in before the player.ads.playing is updated, which means
    // bitrate information gets reported to the main content instead, which is incorrect.
    // Ads get loaded always before access log entries come, which we can use to report
    // the ad bitrate to the correct endpoint.
    private var adLoaded: Bool = false
    private var lastPlayerItem: AVPlayerItem?
    private var lastAccessLogEvent: AVPlayerItemAccessLogEvent?
    private weak var storage: ConvivaStorage?
    private weak var endpoints: ConvivaEndpoints?
    
    init(endpoints: ConvivaEndpoints, storage: ConvivaStorage) {
        self.endpoints = endpoints
        self.storage = storage
    }
    
    func adDidLoad(event: THEOplayerSDK.AdLoadedEvent)  {
        self.adLoaded = true
    }
    
    func adDidEnd(event: THEOplayerSDK.AdEndEvent)  {
        self.adLoaded = false
    }
    
    func sourceChanged(event: THEOplayerSDK.SourceChangeEvent) {
        log("sourceChanged")
        self.reset()
    }
    
    func appWillEnterForeground(notification: Notification) {
        log("analytics.reportAppForegrounded")
        self.endpoints?.analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        log("analytics.reportAppBackgrounded")
        self.endpoints?.analytics.reportAppBackgrounded()
    }
    
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, item: AVPlayerItem, isPlayingAd: Bool) {
        log("handling appGotNewAccessLogEntry")
        // This indicates that the current access log we got belongs
        // to an ad that is not playing, we will receive the same
        // access log bitrate shortly after when we start playing, so
        // we can ignore this bitrate.
        if self.adLoaded, !isPlayingAd {
            return
        }
        
        // if we get the same number of dropped frames for the same item in a row, we don't need to report that.
        // I see this happens when we get an access log towards the end of an ad.
        if self.lastPlayerItem == item,
           event.numberOfDroppedVideoFrames == event.numberOfDroppedVideoFrames
        {
            return
        }
        
        if let endpoint: CISStreamAnalyticsProtocol = isPlayingAd ? self.endpoints?.adAnalytics : self.endpoints?.videoAnalytics {
            if event.numberOfDroppedVideoFrames >= 0 {
                let droppedFrames = NSNumber(value: event.numberOfDroppedVideoFrames)
                log("endpoint.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL : \(droppedFrames)]")
                endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: droppedFrames)
            }
            if event.indicatedBitrate >= 0 {
                let bitrateValue = NSNumber(value: event.indicatedBitrate / 1000)
                log("endpoint.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_BITRATE : \(bitrateValue)]")
                endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
                self.storage?.storeMetric(key: CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
            }
            if event.indicatedAverageBitrate >= 0 {
                let avgBitrateValue = NSNumber(value: event.indicatedAverageBitrate / 1000)
                log("endpoint.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE : \(avgBitrateValue)]")
                endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE, value: avgBitrateValue)
                self.storage?.storeMetric(key: CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE, value: avgBitrateValue)
            }
        }
        
        self.lastPlayerItem = item
        self.lastAccessLogEvent = event
    }
    
    private func reset() {
        log("reset")
        self.adLoaded = false
        self.lastPlayerItem = nil
        self.lastAccessLogEvent = nil
    }
    
    private func log(_ message: String) {
        if DEBUG_LOGGING {
            print("[THEOplayerConnector-Conviva] AppHandler: \(message)")
        }
    }
}
