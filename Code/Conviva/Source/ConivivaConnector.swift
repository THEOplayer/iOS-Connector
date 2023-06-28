import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnector: ConvivaEndpointContainer {
    public let conviva: ConvivaEndpoints
    public let player: THEOplayer
    public let storage: ConvivaConnectorStorage
    
    let appEventForwarder: AppEventForwarder
    let basicEventForwarder: BasicEventForwarder
    let adEventHandler: AdEventForwarder?
    
    public init?(configuration: ConvivaConfiguration, player: THEOplayer) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endpoints, player: player)
    }

    public init(conviva: ConvivaEndpoints, player: THEOplayer) {
        self.conviva = conviva
        self.player = player
        self.storage = ConvivaConnectorStorage()
        
        let (analytics, videoAnalytics, adAnalytics) = (conviva.analytics, conviva.videoAnalytics, conviva.adAnalytics)
        
        appEventForwarder = AppEventForwarder(
            player: player,
            eventProcessor: AppEventConvivaReporter(analytics: analytics, video: videoAnalytics, ads: adAnalytics, storage: storage)
        )
        
        basicEventForwarder = BasicEventForwarder(
            player: player,
            eventProcessor: BasicEventConvivaReporter(conviva: videoAnalytics, storage: storage)
        )
        
        if player.hasAdsImplementation {
            adEventHandler = AdEventForwarder(
                player: player,
                eventProcessor: AdEventConvivaReporter(video: videoAnalytics, ads: adAnalytics, storage: storage)
            )
        } else {
            adEventHandler = nil
        }
    }
}

extension THEOplayer {
    var hasAdsImplementation: Bool {
        getAllIntegrations().contains { $0.type == .ADS }
    }
}
