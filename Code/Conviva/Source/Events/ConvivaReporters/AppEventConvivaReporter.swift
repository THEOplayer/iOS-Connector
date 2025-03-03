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
    private var prerollAdPlaying: Bool = false
    
    func adDidLoad(event: THEOplayerSDK.AdLoadedEvent)  {
        prerollAdPlaying = true
    }
    func adDidEnd(event: THEOplayerSDK.AdEndEvent)  {
        prerollAdPlaying = false
    }
    
    
    func appWillEnterForeground(notification: Notification) {
        self.analytics.reportAppForegrounded()
    }
    
    func appDidEnterBackground(notification: Notification) {
        self.analytics.reportAppBackgrounded()
    }
    
    func appGotNewAccessLogEntry(event: AVPlayerItemAccessLogEvent, isPlayingAd: Bool) {
        // If the ad did load but we haven't started playing it,
        // we will report the bitrate to the ad endpoint regardless.
        // Previously, we were incorrectly reporting to the video endpoint
        // when the ad loaded but was not playing.
        let toSendToAdEndpoint = prerollAdPlaying || isPlayingAd
        let endpoint = toSendToAdEndpoint ? self.adAnalytics : self.videoAnalytics
        
        self.handleBitrateChange(bitrate: event.indicatedBitrate, endpoint: endpoint)
        
        if event.numberOfDroppedVideoFrames >= 0 {
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_DROPPED_FRAMES_TOTAL, value: NSNumber(value: event.numberOfDroppedVideoFrames))
        }
    }

    func appGotBitrateChangeEvent(bitrate: Double, isPlayingAd: Bool) {
        let toSendToAdEndpoint = prerollAdPlaying || isPlayingAd
        let endpoint = toSendToAdEndpoint ? self.adAnalytics : self.videoAnalytics
        self.handleBitrateChange(bitrate: bitrate, endpoint: endpoint)
    }

    private func handleBitrateChange(bitrate: Double, endpoint: CISStreamAnalyticsProtocol) {
        guard bitrate >= 0 else { return }

        let bitrateValue = NSNumber(value: bitrate / 1000)

        endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
        self.storage.storeKeyValuePair(key: CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
    }
}
