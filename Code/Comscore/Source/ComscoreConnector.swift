import THEOplayerSDK
import ComScore

public struct ComscoreConnector {
    public let comscore: ComScoreStreamingAnalytics
    public let player: THEOplayer


    public init(configuration: ComScoreConfiguration, player: THEOplayer) {
        ComScoreAnalytics.start(configuration: configuration)
        self.player = player
        self.comscore = ComScoreAnalytics.THEOplayerComscoreSDK(player: player, playerVersion: THEOplayer.version, metadata: nil)
    }
}
