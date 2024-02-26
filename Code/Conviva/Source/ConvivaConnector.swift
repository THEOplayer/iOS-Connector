import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnector {
    private let endPoints: ConvivaEndpoints
    private let convivaObserver: ConvivaObserver
    private let convivaReporter: ConvivaReporter
    private let convivaVPFDetector: ConvivaVPFDetector
    
    public init?(configuration: ConvivaConfiguration, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endpoints, player: player, externalEventDispatcher: externalEventDispatcher)
    }

    init(conviva: ConvivaEndpoints, player: THEOplayer, externalEventDispatcher: THEOplayerSDK.EventDispatcherProtocol) {
        self.endPoints = conviva
        self.convivaReporter = ConvivaReporter(endPoints: endPoints)
        self.convivaVPFDetector = ConvivaVPFDetector()
        self.convivaObserver = ConvivaObserver(player: player, 
                                               reporter: self.convivaReporter,
                                               vpfDetector: self.convivaVPFDetector,
                                               externalEventDispatcher: externalEventDispatcher)
    }
    
    public func destroy() {
        self.convivaObserver.destroy()
        self.convivaReporter.destroy()
        self.endPoints.destroy()
    }
    
    public func setContentInfo(_ contentInfo: [String: Any]) {
        self.convivaReporter.reportContentInfo(contentInfo: contentInfo)
    }
    
    public func setAdInfo(_ adInfo: [String: Any]) {
        self.convivaReporter.reportAdInfo(adInfo: adInfo)
    }
    
    public func reportPlaybackFailed(message: String) {
        self.convivaReporter.reportError(error: message)
    }
    
    public func stopAndStartNewSession(contentInfo: [String: Any]) {
        self.convivaReporter.reportStopAndStartNewSession(contentInfo: contentInfo)
    }
    
    public func setErrorCallback(onNativeError: (([String: Any]) -> Void)? ) {
        self.convivaVPFDetector.setVideoPlaybackFailureCallback(onNativeError)
    }
}
