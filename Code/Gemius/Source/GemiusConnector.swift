import THEOplayerSDK
#if canImport(GemiusSDK)
import GemiusSDK
#endif

public struct GemiusConfiguration {
    let implementationId: String
    let debug: Bool

    public init(implementationId: String, debug: Bool) {
        self.implementationId = implementationId
        self.debug = debug
    }
}

public struct GemiusConnector {
//    private let adapter: GemiusAdapter
    private let player: THEOplayer


    public init(configuration: GemiusConfiguration, player: THEOplayer) {
        self.player = player
//        self.adapter = GemiusAdapter(configuration: configuration, player: player, metadata: metadata)
    }

    public func update() {
        // TODO
//        self.adapter.update()
    }

}
