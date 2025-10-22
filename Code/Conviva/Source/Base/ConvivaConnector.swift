//
//  ConvivaConnector.swift
//

import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public class ConvivaConnector {
    private let storage = ConvivaStorage()
    private let endPoints: ConvivaEndpoints
    private let appEventForwarder: AppEventForwarder
    private let appHandler: AppHandler
    private let playerEventForwarder: PlayerEventForwarder
    private let playerHandler: PlayerHandler
    private let adEventForwarder: AdEventForwarder
    private let adHandler: AdHandler
    
#if canImport(THEOplayerTHEOliveIntegration)
    private let theoliveForwarder: THEOliveEventForwarder
    private let theoliveHandler: THEOliveHandler
#endif
    
    public convenience init?(
        configuration: ConvivaConfiguration,
        player: THEOplayer,
        externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil
    ) {
        guard let endPoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endPoints, player: player, externalEventDispatcher: externalEventDispatcher)
    }
    
    init(conviva: ConvivaEndpoints, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol? = nil) {
        self.endPoints = conviva
        
        // App level handling
        self.appHandler = AppHandler(endpoints: self.endPoints, storage: self.storage)
        self.appEventForwarder = AppEventForwarder(handler: self.appHandler)
        
        // Player level handling
        self.playerHandler = PlayerHandler(endpoints: self.endPoints, storage: self.storage)
        self.playerEventForwarder = PlayerEventForwarder(player: player, handler: self.playerHandler)
        
        // Ad level handling
        self.adHandler = AdHandler(endpoints: self.endPoints, storage: self.storage)
        self.adEventForwarder = AdEventForwarder(player: player, externalEventDispatcher: externalEventDispatcher, handler: self.adHandler)
        
#if canImport(THEOplayerTHEOliveIntegration)
        // THEOlive level handling
        self.theoliveHandler = THEOliveHandler(endpoints: self.endPoints, storage: self.storage)
        self.theoliveForwarder = THEOliveEventForwarder(player: player, handler: self.theoliveHandler)
#endif
    }
    
    public func destroy() {
        self.endPoints.destroy()
        self.playerHandler.destroy()
    }
    
    public func setContentInfo(_ contentInfo: [String: Any]) {
        self.playerHandler.setContentInfo(contentInfo)
    }
    
    public func setAdInfo(_ adInfo: [String: Any]) {
        self.adHandler.setAdInfo(adInfo)
    }
    
    public func reportPlaybackFailed(message: String) {
        self.playerHandler.reportPlaybackFailed(message: message)
    }
    
    public func reportPlaybackEvent(eventType: String, eventDetail: [String: Any]) {
        self.playerHandler.reportPlaybackEvent(eventType: eventType, eventDetail: eventDetail)
    }
    
    public func stopAndStartNewSession(contentInfo: [String: Any]) {
        self.playerHandler.stopAndStartNewSession(contentInfo: contentInfo)
    }    
}
