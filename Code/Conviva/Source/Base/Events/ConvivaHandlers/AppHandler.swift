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
