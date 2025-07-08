import THEOplayerSDK
#if canImport(GemiusSDK)
import GemiusSDK
#endif

public struct GemiusConfiguration {
    let playerId: String
    let hitCollectorHost: String
    let gemiusId: String
    let debug: Bool

    public init(playerId: String, hitCollectorHost: String, gemiusId: String, debug: Bool) {
        self.playerId = playerId
        self.hitCollectorHost = hitCollectorHost
        self.gemiusId = gemiusId
        self.debug = debug
    }
}

public struct GemiusConnector {
    private let adapter: GemiusAdapter
    private let player: THEOplayer


    public init(configuration: GemiusConfiguration, player: THEOplayer) {
        self.player = player
        self.adapter = GemiusAdapter(configuration: configuration, player: player)
    }

    public func update(programId: String, programData: GemiusSDK.GSMProgramData) {
        self.adapter.update(programId: programId, programData: programData)
    }

}
