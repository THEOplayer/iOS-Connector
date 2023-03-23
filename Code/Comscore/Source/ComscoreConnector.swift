import THEOplayerSDK
import ComScore

public struct ComscoreConnector {
    public let streamingAnalytics: ComScoreStreamingAnalytics
    public let player: THEOplayer


    public init(configuration: ComScoreConfiguration, player: THEOplayer, metadata: ComScoreMetadata) {
        ComScoreAnalytics.start(configuration: configuration)
        self.player = player
        self.streamingAnalytics = ComScoreAnalytics.THEOplayerComscoreSDK(player: player, playerVersion: THEOplayer.version, metadata: metadata)
    }
}
