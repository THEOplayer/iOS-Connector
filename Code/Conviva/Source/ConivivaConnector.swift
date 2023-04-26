import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public struct ConvivaConnector: ConvivaEndpointContainer {
    public let conviva: ConvivaEndpoints
    public let player: THEOplayer
    
    let appEventHandler: AppEventForwarder
    let basicPlaybackEventHandler: BasicEventForwarder
    let adEventHandler: AdEventForwarder
    
    public init?(configuration: ConvivaConfiguration, player: THEOplayer) {
        guard let endpoints = ConvivaEndpoints(configuration: configuration) else { return nil }
        self.init(conviva: endpoints, player: player)
    }

    public init(conviva: ConvivaEndpoints, player: THEOplayer) {
        self.conviva = conviva
        self.player = player
        
        let (analytics, videoAnalytics, adAnalytics) = (conviva.analytics, conviva.videoAnalytics, conviva.adAnalytics)
        
        // Report fore- and background changes
        appEventHandler = AppEventForwarder(
            player: player,
            eventProcessor: AppEventConvivaReporter(analytics: analytics, video: videoAnalytics, ads: adAnalytics)
        )
        
        // Report play pause etc
        basicPlaybackEventHandler = BasicEventForwarder(
            player: player,
            eventProcessor: BasicEventConvivaReporter(conviva: videoAnalytics)
        )
        
        // Report ad events
        adEventHandler = AdEventForwarder(
            player: player,
            eventProcessor: AdEventConvivaReporter(video: videoAnalytics, ads: adAnalytics)
        )
    }
}
