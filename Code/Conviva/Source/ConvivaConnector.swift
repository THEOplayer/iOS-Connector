//
//  ConvivaConnector.swift
//

import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnector {
    private let storage = ConvivaConnectorStorage()
    
    private var endPoints: ConvivaEndpoints
    private var appEventForwarder: AppEventForwarder
    private var basicEventForwarder: BasicEventForwarder
    private var adEventHandler: AdEventForwarder
    
    public init?(configuration: ConvivaConfiguration, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil) {
        guard let endPoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endPoints, player: player, externalEventDispatcher: externalEventDispatcher)
    }
    
    init(conviva: ConvivaEndpoints, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil) {
        self.endPoints = conviva
        self.appEventForwarder = AppEventForwarder(player: player,
                                                   eventProcessor: AppEventConvivaReporter(analytics: endPoints.analytics,
                                                                                           videoAnalytics: endPoints.videoAnalytics,
                                                                                           adAnalytics: endPoints.adAnalytics,
                                                                                           storage: self.storage))
        self.basicEventForwarder = BasicEventForwarder(player: player,
                                                       eventProcessor: BasicEventConvivaReporter(videoAnalytics: endPoints.videoAnalytics,
                                                                                                 storage: self.storage))
        self.adEventHandler = AdEventForwarder(player: player,
                                               externalEventDispatcher: externalEventDispatcher,
                                               eventProcessor: AdEventConvivaReporter(videoAnalytics: endPoints.videoAnalytics,
                                                                                      adAnalytics: endPoints.adAnalytics,
                                                                                      storage: self.storage,
                                                                                      player: player))
    }
    
    public func destroy() {
        self.endPoints.destroy()
    }
    
    public func setContentInfo(_ contentInfo: [String: Any]) {
        self.endPoints.videoAnalytics.setContentInfo(contentInfo)
        self.storeClientMetadata(contentInfo)
    }
    
    public func setAdInfo(_ adInfo: [String: Any]) {
        self.endPoints.adAnalytics.setAdInfo(adInfo)
    }
    
    public func reportPlaybackFailed(message: String) {
        self.endPoints.videoAnalytics.reportPlaybackFailed(message, contentInfo: nil)
    }
    
    public func reportPlaybackEvent(eventType: String, eventDetail: [String: Any]) {
        self.endPoints.videoAnalytics.reportPlaybackEvent(eventType, withAttributes: eventDetail)
    }
    
    public func stopAndStartNewSession(contentInfo: [String: Any]) {
        self.storeClientMetadata(contentInfo)
        self.endPoints.videoAnalytics.reportPlaybackEnded()
        self.endPoints.videoAnalytics.cleanup()
        let extendedContentInfo = Utilities.extendedContentInfo(contentInfo: contentInfo, storage: self.storage)
        self.endPoints.videoAnalytics.reportPlaybackRequested(extendedContentInfo)
        self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
        if let bitrate = self.storage.valueForKey(CIS_SSDK_PLAYBACK_METRIC_BITRATE) as? NSNumber {
            self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrate)
        }
        if let avgBitrate = self.storage.valueForKey(CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE) as? NSNumber {
            self.endPoints.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE, value: avgBitrate)
        }
    }
    
    @available(*, deprecated, message: "This will be removed in version 10.0. Instead use addEventListener on THEOplayer with a type of PlayerEventTypes.ERROR")
    public func setErrorCallback(onNativeError: (([String: Any]) -> Void)? ) {
        self.basicEventForwarder.vpfHandler.callback = onNativeError
    }
    
    private func storeClientMetadata(_ contentInfo: [String: Any]) {
        contentInfo.forEach { (key, value) in
            self.storage.clientMetadata[key] = value
        }
    }
}
