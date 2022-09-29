import THEOplayerSDK
import ConvivaSDK

/// Connects to a THEOplayer instance and reports its events to conviva
public class ConvivaConnector {
    public let analytics: CISAnalytics
    public let videoAnalytics: CISVideoAnalytics
    public let adAnalytics: CISAdAnalytics
    public let player: THEOplayer
    
    let appEventHandler: AppEventForwarder
    let basicPlaybackEventHandler: BasicEventForwarder
    let adEventHandler: AdEventForwarder
    
    #if VERIZONMEDIA
    let verizonMediaEventHandler: VerizonAdEventForwarder
    #endif

    public init?(configuration: ConvivaConfiguration, player: THEOplayer) {
        
        guard let analytics = CISAnalyticsCreator.create(
            withCustomerKey: configuration.customerKey,
            settings: configuration.convivaSettingsDictionary
        ) else {
            return nil
        }
        
        self.analytics = analytics
        videoAnalytics = analytics.createVideoAnalytics()
        adAnalytics = analytics.createAdAnalytics(withVideoAnalytics: videoAnalytics)
        self.player = player
        
        videoAnalytics.setPlayerInfo(Utilities.playerInfo)
        
        // Report fore- and background changes
        appEventHandler = AppEventForwarder(
            eventProcessor: AppEventConvivaReporter(analytics: analytics)
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
        
        #if VERIZONMEDIA
        // Report verizon specific ads
        verizonMediaEventHandler = VerizonAdEventForwarder(
            player: player,
            eventProcessor: VerizonAdEventConvivaReporter(videoAnalytics: videoAnalytics, adAnalytics: adAnalytics)
        )
        #endif
    }
    
    public func report(viewerID: String) {
        videoAnalytics.setContentInfo([
            CIS_SSDK_METADATA_VIEWER_ID: viewerID
        ])
    }
    
    public func report(assetName: String) {
        videoAnalytics.setContentInfo([
            CIS_SSDK_METADATA_ASSET_NAME: assetName
        ])
    }
    
    deinit {
        adAnalytics.cleanup()
        videoAnalytics.cleanup()
        analytics.cleanup()
    }
}
