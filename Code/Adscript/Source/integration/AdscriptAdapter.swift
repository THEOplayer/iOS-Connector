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
        
        reportPlayerState()
        addEventListeners()
    }
    
    public func sessionStart() {
        self.adscriptCollector.sessionStart()
    }
    
    public func update(metadata: AdScriptDataObject) {
        self.adscriptCollector.contentMetadata = metadata
    }
    
    public func updateUser(i12n: AdScriptI12n) {
        // TODO
    }
    
    private func reportPlayerState() {
        reportFullscreen(isFullscreen: player.presentationMode == PresentationMode.fullscreen)
        reportDimensions(width: player.videoWidth, height: player.videoHeight)
        reportPlaybackSpeed(playbackRate: player.playbackRate)
        reportVolumeAndMuted(isMuted: player.muted, volume: player.volume)
        reportTriggeredByUser(autoplayEnabled: player.autoplay)
        reportVisibility()
    }
    
    private func reportFullscreen(isFullscreen: Bool) {
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.fullscreen, value: isFullscreen ? 1 : 0)
    }
    
    private func reportDimensions(width: Int, height: Int) {
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.width, value: width)
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.height, value: height)
    }
    
    private func reportPlaybackSpeed(playbackRate: Double) {
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.normalSpeed, value: playbackRate == 1 ? 1 : 0)
    }
    
    private func reportVolumeAndMuted(isMuted: Bool, volume: Float) {
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.muted, value: (isMuted || volume == 0) ? 1 : 0)
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.volume, value: Int(volume))
    }
    private func reportTriggeredByUser(autoplayEnabled: Bool) {
        _ = self.adscriptCollector.playerState.set(key: AdScriptPlayerStateKey.triggeredByUser, value: autoplayEnabled ? 1 : 0)
    }
    
    private func reportVisibility() {
        // TODO
    }
    
    private func addEventListeners() {
        // TODO
    }
}
