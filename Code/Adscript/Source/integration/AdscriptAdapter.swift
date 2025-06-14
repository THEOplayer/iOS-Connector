import THEOplayerSDK
import AdScriptApiClient

public struct AdscriptAdapter {
    private let player: THEOplayer
    private let contentMetadata: AdScriptDataObject
    private let configuration: AdscriptConfiguration
    private let adscriptCollector: AdScriptCollector

    public init(configuration: AdscriptConfiguration, player: THEOplayer, metadata: AdScriptDataObject) {
        self.player = player
        self.contentMetadata = metadata
        self.configuration = configuration
        
        self.adscriptCollector = AdScriptCollector(implementationId: configuration.implementationId, isDebug: configuration.debug)
        
        addEventListeners()
    }
    
    public func sessionStart() {
        self.adscriptCollector.sessionStart()
    }
    
    public func update(metadata: AdScriptDataObject) {
        // TODO
    }
    
    public func updateUser(i12n: AdScriptI12n) {
        // TODO
    }
    
    private func addEventListeners() {
        // TODO
    }
}
