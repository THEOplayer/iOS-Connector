//
//  ConvivaConnector+objc.swift
//

import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
@objc public class THEOplayerConvivaConnector: NSObject {
    let internalConnector: ConvivaConnector
    
    @objc public convenience init?(configuration: THEOplayerConnectorConvivaConfiguration, player: THEOplayer) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endpoints, player: player)
    }
    
    init(conviva: ConvivaEndpoints, player: THEOplayer) {
        internalConnector = ConvivaConnector(conviva: conviva, player: player)
    }
    
    @objc
    public func destroy() {
        internalConnector.destroy()
    }
    
    @objc
    public func setContentInfo(_ contentInfo: [String: Any]) {
        internalConnector.setContentInfo(contentInfo)
    }
    
    @objc
    public func setAdInfo(_ adInfo: [String: Any]) {
        internalConnector.setAdInfo(adInfo)
    }
    
    @objc
    public func reportPlaybackFailed(message: String) {
        internalConnector.reportPlaybackFailed(message: message)
    }
    
    @objc
    public func stopAndStartNewSession(contentInfo: [String: Any]) {
        internalConnector.stopAndStartNewSession(contentInfo: contentInfo)
    }
    
    @objc
    public func setErrorCallback(onNativeError: (([String: Any]) -> Void)? ) {
        internalConnector.setErrorCallback(onNativeError: onNativeError)
    }
}
