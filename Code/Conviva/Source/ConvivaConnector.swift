//
//  ConvivaConnector.swift
//

import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnector {
    private let storage = ConvivaConnectorStorage()
    private let convivaVPFDetector = ConvivaVPFDetector()
    
    private var endPoints: ConvivaEndpoints?
    private var appEventForwarder: AppEventForwarder?
    private var basicEventForwarder: BasicEventForwarder?
    private var adEventHandler: AdEventForwarder?
    
    public init?(configuration: ConvivaConfiguration, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil) {
        guard let endPoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endPoints, player: player, externalEventDispatcher: externalEventDispatcher)
    }
    
    init(conviva: ConvivaEndpoints, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil) {
        self.endPoints = conviva
        
        if let endPoints = self.endPoints {
            self.appEventForwarder = AppEventForwarder(player: player,
                                                  eventProcessor: AppEventConvivaReporter(analytics: endPoints.analytics,
                                                                                          videoAnalytics: endPoints.videoAnalytics,
                                                                                          adAnalytics: endPoints.adAnalytics,
                                                                                          storage: self.storage)
            )
            
            self.basicEventForwarder = BasicEventForwarder(player: player,
                                                      vpfDetector: self.convivaVPFDetector,
                                                      eventProcessor: BasicEventConvivaReporter(videoAnalytics: endPoints.videoAnalytics,
                                                                                                storage: self.storage)
            )
            
            self.adEventHandler = AdEventForwarder(player: player,
                                              externalEventDispatcher: externalEventDispatcher,
                                              eventProcessor: AdEventConvivaReporter(videoAnalytics: endPoints.videoAnalytics,
                                                                                     adAnalytics: endPoints.adAnalytics,
                                                                                     storage: self.storage,
                                                                                     player: player)
                                              
            )
        }
    }
        
    public func destroy() {
        self.endPoints?.destroy()
    }
        
    public func setContentInfo(_ contentInfo: [String: Any]) {
        self.endPoints?.videoAnalytics.setContentInfo(contentInfo)
    }
        
    public func setAdInfo(_ adInfo: [String: Any]) {
        self.endPoints?.adAnalytics.setAdInfo(adInfo)
    }
        
    public func reportPlaybackFailed(message: String) {
        self.endPoints?.videoAnalytics.reportPlaybackFailed(message, contentInfo: nil)
    }
        
    public func stopAndStartNewSession(contentInfo: [String: Any]) {
        self.endPoints?.videoAnalytics.reportPlaybackEnded()
        self.endPoints?.videoAnalytics.reportPlaybackRequested(contentInfo)
        self.endPoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        if let bitrate = self.storage.valueForKey(CIS_SSDK_PLAYBACK_METRIC_BITRATE) as? NSNumber {
            self.endPoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrate)
        }
    }
        
    public func setErrorCallback(onNativeError: (([String: Any]) -> Void)? ) {
        self.convivaVPFDetector.setVideoPlaybackFailureCallback(onNativeError)
    }
}
