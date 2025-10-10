//
//  PlayerHandler.swift
//

import ConvivaSDK
import THEOplayerSDK

#if DEBUG
let DEBUG_LOGGING = true
#else
let DEBUG_LOGGING = false
#endif

let ENCODING_TYPE: String = "encoding_type"

struct THEOConvivaSession {
    protocol Delegate: AnyObject {
        func onSessionStarted()
        func onSessionEnded()
    }
    
    struct Source {
        let description: SourceDescription
        let url: String?
    }
    
    var started = false
    var source: Source?
}

class PlayerHandler {
    /// The endpoint to which all the events are sent
    private var currentConvivaSession = THEOConvivaSession()
    private weak var sessionDelegate: THEOConvivaSession.Delegate?
    private weak var endpoints: ConvivaEndpoints?
    private weak var storage: ConvivaStorage?
        
    init(endpoints: ConvivaEndpoints, storage: ConvivaStorage) {
        self.endpoints = endpoints
        self.storage = storage
    }
    
    func setContentInfo(_ contentInfo: [String: Any]) {
        if let storage = self.storage {
            storage.storeMetadata(contentInfo)
            log("videoAnalytics.setContentInfo: \(storage.metadata)")
            self.endpoints?.videoAnalytics.setContentInfo(storage.metadata)
        }
    }
    
    func reportPlaybackEvent(eventType: String, eventDetail: [String: Any]) {
        log("handling reportPlaybackEvent \(eventType)")
        self.endpoints?.videoAnalytics.reportPlaybackEvent(eventType, withAttributes: eventDetail)
    }
    
    func maybeReportPlaybackEnded() {
        log("handling maybeReportPlaybackEnded")
        if self.currentConvivaSession.started {
            // end session on conviva
            self.endpoints?.videoAnalytics.reportPlaybackEnded()
            self.endpoints?.videoAnalytics.cleanup()
            self.sessionDelegate?.onSessionEnded()
            
            // reset the local convivaSession data
            self.currentConvivaSession = THEOConvivaSession()
        }
    }
    
    func maybeReportPlaybackRequested() {
        log("handling maybeReportPlaybackRequested")
        guard !self.currentConvivaSession.started else { return }
        
        // collect standard metadata like playerName, assetName, stramUrl, isLive, ...
        self.updateMetadata()
        
        // start session on conviva
        if let storage = self.storage {
            self.endpoints?.videoAnalytics.reportPlaybackRequested(storage.metadata)
        }
        
        // mark conviva session as started
        self.currentConvivaSession.started = true
        if let delegate = self.sessionDelegate {
            delegate.onSessionStarted()
        }
    }
    
    func reportPlaybackFailed(message: String) {
        log("handling reportPlaybackFailed")
        self.endpoints?.videoAnalytics.reportPlaybackFailed(message, contentInfo: nil)
    }
    
    func stopAndStartNewSession(contentInfo: [String: Any]) {
        log("handling stopAndStartNewSession")
        // stop current conviva session
        self.maybeReportPlaybackEnded()
        
        // start new conviva session
        self.maybeReportPlaybackRequested()
        
        // store and push the passed metadata
        self.setContentInfo(contentInfo)
        
        // push stored metric that remain valid across the sessions
        self.storage?.metrics.forEach { (key, value) in
            log("videoAnalytics.reportPlaybackMetric from storage [\(key) : \(value)]")
            self.endpoints?.videoAnalytics.reportPlaybackMetric(key, value: value)
        }
    }

    func play(event: PlayEvent) {
        log("handling play")
        self.maybeReportPlaybackRequested()
    }
    
    func playing(event: PlayingEvent) {
        log("handling playing")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PLAYING]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func timeUpdate(event: TimeUpdateEvent) {
        //log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME : \(event.currentTimeInMilliseconds)]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: event.currentTimeInMilliseconds)
    }
    
    func pause(event: PauseEvent) {
        log("handling pause")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_PAUSED]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
    
    func waiting(event: WaitingEvent) {
        log("handling waiting")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_BUFFERING]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_BUFFERING.rawValue)
    }
    
    func seeking(event: SeekingEvent) {
        log("handling seeking")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED : \(event.currentTimeInMilliseconds)]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED, value: event.currentTimeInMilliseconds)
    }
    
    func seeked(event: SeekedEvent) {
        log("handling seeked")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED : \(event.currentTimeInMilliseconds)]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED, value: event.currentTimeInMilliseconds)
    }
    
    func error(event: ErrorEvent) {
        log("handling error")
        if self.currentConvivaSession.started {
            // end session on conviva with failure
            self.reportPlaybackFailed(message: event.error)
            self.sessionDelegate?.onSessionEnded()
            
            // reset the local convivaSession data
            self.currentConvivaSession = THEOConvivaSession()
        }
    }
    
    func networkError(event: NetworkErrorEvent) {
        log("handling networkError")
        let message = event.error?.message ?? Utilities.defaultStringValue
        log("videoAnalytics.reportPlaybackError: \(message) as WARNING")
        self.endpoints?.videoAnalytics.reportPlaybackError(message, errorSeverity: .ERROR_WARNING)
    }
    
    func currentSourceChange(event: CurrentSourceChangeEvent) {
        log("handling currentSourceChange")
        guard let sourceType = event.currentSource?.type else {
            return
        }
        var encodingType: String?
        switch sourceType.lowercased() {
        case "application/vnd.theo.hesp+json":
            encodingType = "HESP"
        case "application/x-mpegurl",
            "application/vnd.apple.mpegurl",
            "video/mp2t":
            encodingType = "HLS"
        default:
            encodingType = nil
        }
        
        if self.storage?.metadataEntryForKey(ENCODING_TYPE) == nil,
           let encodingType = encodingType {
            self.setContentInfo([ENCODING_TYPE:encodingType])
        }
    }
    
    func sourceChange(event: SourceChangeEvent, selectedSource: String?) {
        log("handling sourceChange")
        // end the session for the previous source
        if self.currentConvivaSession.source != nil,
           self.currentConvivaSession.source?.description != event.source {
            self.maybeReportPlaybackEnded()
        }
        
        // cleanup storage
        self.storage?.clearAllMetadata()
        self.storage?.clearAllMetrics()
        
        // store source for next session (to be started on PLAY event)
        var newSource: THEOConvivaSession.Source? = nil
        if let source = event.source {
            newSource = .init(description: source, url: selectedSource ?? "unknown")
        }
        self.currentConvivaSession.source = newSource
    }
    
    func renderedFramerateUpdate(framerate: Float) {
        //log("renderedFramerateUpdate")
        let rate = NSNumber(value: Int(framerate.rounded()))
        //log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE : \(rate)]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: rate)
    }
    
    func ended(event: EndedEvent) {
        log("handling ended")
        log("videoAnalytics.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE : CONVIVA_STOPPED]")
        self.endpoints?.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        self.maybeReportPlaybackEnded()
    }
    
    func updateMetadata() {
        log("handling updateMetadata")
        guard let convivaSessionSource = self.currentConvivaSession.source,
              let url = self.currentConvivaSession.source?.url as? String else {
            return
        }
        
        let metadata: [String: Any] = [
            CIS_SSDK_METADATA_PLAYER_NAME: self.storage?.metadataEntryForKey(CIS_SSDK_METADATA_PLAYER_NAME) ?? Utilities.playerName,
            CIS_SSDK_METADATA_STREAM_URL: url,
            CIS_SSDK_METADATA_ASSET_NAME: convivaSessionSource.description.metadata?.title ?? Utilities.defaultStringValue,
        ]
        self.setContentInfo(metadata)
    }
    
    func durationChange(event: DurationChangeEvent) {
        log("handling durationChange")
        var metadata: [String: Any] = [:]
        if let storage = self.storage,
           !storage.hasMetadataEntryForKey(CIS_SSDK_METADATA_IS_LIVE) {
            if let duration = event.duration, !duration.isNaN {
                if duration.isInfinite {
                    metadata[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: true)
                } else {
                    metadata[CIS_SSDK_METADATA_IS_LIVE] = NSNumber(value: false)
                    metadata[CIS_SSDK_METADATA_DURATION] = NSNumber(value: duration)
                }
            }
        }
        self.setContentInfo(metadata)
    }
    
    func onDestroy(event: DestroyEvent) {
        self.destroy()
    }
    
    func destroy() {
        log("destroy")
        self.maybeReportPlaybackEnded()
    }
    
    func encrypted(event: EncryptedEvent) {
        log("encrypted")
        log("videoAnalytics.reportPlaybackEvent \(event.type)")
        self.endpoints?.videoAnalytics.reportPlaybackEvent(event.type, withAttributes: nil)
    }

    func contentProtectionSuccess(event: ContentProtectionSuccessEvent) {
        log("contentProtectionSuccess")
        log("videoAnalytics.reportPlaybackEvent \(event.type)")
        self.endpoints?.videoAnalytics.reportPlaybackEvent(event.type, withAttributes: nil)
    }

    func videoTrackAdded(event: AddTrackEvent, player: THEOplayer) {
        log("videoTrackAdded")
        // With the current player SDK we should only have a single videoTrack with multiple qualities.
        // If more than one videoTrack is supported by the player SDK we should adjust the code.
        guard let videoTrack = event.track as? VideoTrack else { return }
        _ = videoTrack.addRemovableEventListener(
            type: MediaTrackEventTypes.ACTIVE_QUALITY_CHANGED
        ) { [weak self, weak player] activeQualityChangedEvent in
            guard let self, let player else { return }
            self.activeQualityChangedEvent(event: activeQualityChangedEvent, isPlayingAd: player.ads.playing)
        }
    }

    private func activeQualityChangedEvent(event: ActiveQualityChangedEvent, isPlayingAd: Bool) {
        log("activeQualityChangedEvent")
        if let endpoint: CISStreamAnalyticsProtocol = isPlayingAd ? self.endpoints?.adAnalytics : self.endpoints?.videoAnalytics {
            let bitrateValue = NSNumber(value: event.quality.bandwidth / 1000)
            log("endpoint.reportPlaybackMetric [CIS_SSDK_PLAYBACK_METRIC_BITRATE : \(bitrateValue)]")
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
            self.storage?.storeMetric(key: CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
        }
    }

    deinit {
        log("deinit")
        self.maybeReportPlaybackEnded()
    }
    
    private func log(_ message: String) {
        if DEBUG_LOGGING {
            print("[THEOplayerConnector-Conviva] PlayerHandler: \(message)")
        }
    }
}
