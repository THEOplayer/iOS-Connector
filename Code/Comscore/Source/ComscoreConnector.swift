import THEOplayerSDK
import ComScore
import THEOplayerConnectorUtilities

public struct ComscoreConnector {
    public let streamingAnalytics: ComScoreStreamingAnalytics
    public let player: THEOplayer


    public init(configuration: ComScoreConfiguration, player: THEOplayer, metadata: ComScoreMetadata) {
        ComScoreAnalytics.start(configuration: configuration)
        self.player = player
        self.streamingAnalytics = ComScoreAnalytics.THEOplayerComscoreSDK(player: player, playerVersion: THEOplayer.version, metadata: metadata, configuration: configuration)
    }
    
    public static var version: String {
        return VersionHelper.version("THEOplayer-Connector-Comscore")
    }
}
