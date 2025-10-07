//
//  AppStateConvivaReporter.swift
//  

import ConvivaSDK
import AVFoundation
import THEOplayerSDK

class AppEventConvivaReporter: AppEventProcessor {
    
    
    let analytics: CISAnalytics
    let videoAnalytics: CISVideoAnalytics
    let adAnalytics: CISAdAnalytics
    let storage: ConvivaConnectorStorage
    
    init(analytics: CISAnalytics, videoAnalytics: CISVideoAnalytics, adAnalytics: CISAdAnalytics, storage: ConvivaConnectorStorage) {
        self.analytics = analytics
        self.videoAnalytics = videoAnalytics
        self.adAnalytics = adAnalytics
        self.storage = storage
    }
    
    // This is a workaround for THEOSD-14780
    // Access log entries for preroll ads come in before the player.ads.playing is updated, which means
    // bitrate information gets reported to the main content instead, which is incorrect.
    // Ads get loaded always before access log entries come, which we can use to report
    // the ad bitrate to the correct endpoint.
    private var adLoaded: Bool = false
    private var lastPlayerItem: AVPlayerItem?
    private var lastAccessLogEvent: AVPlayerItemAccessLogEvent?
    
    func adDidLoad(event: THEOplayerSDK.AdLoadedEvent)  {
        adLoaded = true
    }
    func adDidEnd(event: THEOplayerSDK.AdEndEvent)  {
        adLoaded = false
    }
    
    func sourceChanged(event: THEOplayerSDK.SourceChangeEvent) {
        self.reset()
    }
    
    func appWillEnterForeground(notification: Notification) {
        self.analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        self.analytics.reportAppBackgrounded()
    }
    
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, item: AVPlayerItem, isPlayingAd: Bool) {
        // This indicates that the current access log we got belongs
        // to an ad that is not playing, we will receive the same
        // access log bitrate shortly after when we start playing, so
        // we can ignore this bitrate.
        if adLoaded, !isPlayingAd {
            return
        }
        
        // if we get the same number of dropped frames for the same item in a row, we don't need to report that.
        // I see this happens when we get an access log towards the end of an ad.
        if lastPlayerItem == item,
           event.numberOfDroppedVideoFrames == event.numberOfDroppedVideoFrames
        {
            return
        }
        
        let endpoint = isPlayingAd ? self.adAnalytics : self.videoAnalytics
        
        if event.numberOfDroppedVideoFrames >= 0 {
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: NSNumber(value: event.numberOfDroppedVideoFrames))
        }
        
        lastPlayerItem = item
        lastAccessLogEvent = event
    }
    
    private func reset() {
        self.adLoaded = false
        self.lastPlayerItem = nil
        self.lastAccessLogEvent = nil
    }
}
