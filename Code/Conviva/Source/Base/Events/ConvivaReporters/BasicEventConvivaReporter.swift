//
//  BasicEventConvivaReporter.swift
//  

import ConvivaSDK
import THEOplayerSDK

let ENCODING_TYPE: String = "encoding_type"

protocol Sessiondelegate: AnyObject {
    func onSessionStarted()
    func onSessionEnded()
}

struct Session {
    struct Source {
        let description: SourceDescription
        let url: String?
    }
    var started = false
    var source: Source?
}

class BasicEventConvivaReporter {
    /// The endpoint to which all the events are sent
    private let videoAnalytics: CISVideoAnalytics
    private let adAnalytics: CISAdAnalytics
    private let storage: ConvivaConnectorStorage
    private var currentSession = Session()
    weak var sessionDelegate: Sessiondelegate?
        
    init(videoAnalytics: CISVideoAnalytics, adAnalytics: CISAdAnalytics, storage: ConvivaConnectorStorage) {
        self.videoAnalytics = videoAnalytics
        self.adAnalytics = adAnalytics
        self.storage = storage
    }

    func play(event: PlayEvent) {
        guard !self.currentSession.started else { return }
        let initialContentInfo = Utilities.extendedContentInfo(contentInfo: [:], storage: self.storage)
        self.videoAnalytics.reportPlaybackRequested(initialContentInfo)
        self.currentSession.started = true
        if let delegate = self.sessionDelegate {
            delegate.onSessionStarted()
        }
    }
    
    func playing(event: PlayingEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func timeUpdate(event: TimeUpdateEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: event.currentTimeInMilliseconds)
    }
    
    func pause(event: PauseEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
    
    func waiting(event: WaitingEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_BUFFERING.rawValue)
    }
    
    func seeking(event: SeekingEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED, value: event.currentTimeInMilliseconds)
    }
    
    func seeked(event: SeekedEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED, value: event.currentTimeInMilliseconds)
    }
    
    func error(event: ErrorEvent) {
        if self.currentSession.started {
            self.videoAnalytics.reportPlaybackFailed(event.error, contentInfo: nil)
            // the reportPlaybackFailed will close the session on the Conviva backend.
            self.currentSession.started = false
            if let delegate = self.sessionDelegate {
                delegate.onSessionEnded()
            }
        }
    }
    
    func networkError(event: NetworkErrorEvent) {
        self.videoAnalytics.reportPlaybackError(event.error?.message ?? Utilities.defaultStringValue, errorSeverity: .ERROR_WARNING)
    }
    
    func currentSourceChange(event: CurrentSourceChangeEvent) {
        guard let sourceType = event.currentSource?.type else {
            return
        }
        var encodingType: String?
        switch sourceType {
        case "application/vnd.theo.hesp+json":
            encodingType = "HESP"
        case "application/x-mpegurl":
            encodingType = "HLS"
        default:
            encodingType = nil
        }
        
        if self.storage.valueForKey(ENCODING_TYPE) == nil,
           let encodingType = encodingType {
            self.videoAnalytics.setContentInfo([ENCODING_TYPE:encodingType])
            self.storage.storeKeyValuePair(key: ENCODING_TYPE, value: encodingType)
        }
    }
    
    func sourceChange(event: SourceChangeEvent, selectedSource: String?) {
        if event.source != self.currentSession.source?.description, self.currentSession.source != nil {
            self.reportEndedIfPlayed()
        }
        
        // clear all session specific stored values for the previous source
        self.storage.clearValueForKey(CIS_SSDK_METADATA_ASSET_NAME)                 // asset name from the previous source
        self.storage.clearValueForKey(CIS_SSDK_PLAYBACK_METRIC_BITRATE)             // last reported bitrate for previous source
        self.storage.clearValueForKey(CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE)     // last reported average bitrate for previous source
        self.storage.clearValueForKey(CIS_SSDK_METADATA_DEFAULT_RESOURCE)           // last reported cdn for previous source
        self.storage.clearValueForKey(ENCODING_TYPE)                                // last reported encodingtype
        
        let newSource: Session.Source?
        
        if let source = event.source, let url = selectedSource {
            newSource = .init(description: source, url: url)
            let assetName = source.metadata?.title ?? Utilities.defaultStringValue;
            let contentInfo = [
                CIS_SSDK_METADATA_PLAYER_NAME: Utilities.playerName,
                CIS_SSDK_METADATA_STREAM_URL: url,
                CIS_SSDK_METADATA_ASSET_NAME: assetName,
                CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                CIS_SSDK_METADATA_DURATION: NSNumber(value: -1)
            ] as [String: Any]
            self.videoAnalytics.setContentInfo(contentInfo)
            self.storage.storeKeyValuePair(key: CIS_SSDK_METADATA_ASSET_NAME, value: assetName)
            self.storage.storeKeyValuePair(key: CIS_SSDK_METADATA_STREAM_URL, value: url)
        } else {
            newSource = nil
            #if DEBUG
            print("[THEOplayerConnectorConviva] setting unknown source")
            #endif
        }
        self.currentSession.source = newSource
    }
    
    func renderedFramerateUpdate(framerate: Float) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: NSNumber(value: Int(framerate.rounded())))
    }
    
    func ended(event: EndedEvent) {
        self.videoAnalytics.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        self.reportEndedIfPlayed()
    }
    
    func reportEndedIfPlayed() {
        if self.currentSession.started {
            self.videoAnalytics.reportPlaybackEnded()
            self.videoAnalytics.cleanup()
            if let delegate = self.sessionDelegate {
                delegate.onSessionEnded()
            }
            self.currentSession = Session()
        }
    }
    
    func durationChange(event: DurationChangeEvent) {
        if let duration = event.duration, self.currentSession.source?.url != nil {
            if duration.isInfinite {
                self.videoAnalytics.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: true)
                ])
            } else {
                self.videoAnalytics.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                    CIS_SSDK_METADATA_DURATION: NSNumber(value: duration)
                ])
            }
        }
    }
    
    func onDestroy(event: DestroyEvent) {
        self.destroy()
    }
    
    func destroy() {
        self.reportEndedIfPlayed()
    }
    
    func encrypted(event: EncryptedEvent) {
        videoAnalytics.reportPlaybackEvent(event.type, withAttributes: nil)
    }

    func contentProtectionSuccess(event: ContentProtectionSuccessEvent) {
        videoAnalytics.reportPlaybackEvent(event.type, withAttributes: nil)
    }

    func videoTrackAdded(event: AddTrackEvent, player: THEOplayer) {
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
        let bandwidth = event.quality.bandwidth
        let endpoint = isPlayingAd ? self.adAnalytics : self.videoAnalytics
        self.handleBitrateChange(bitrate: Double(bandwidth), avgBitrate: -1, endpoint: endpoint)
    }

    private func handleBitrateChange(bitrate: Double, avgBitrate: Double, endpoint: CISStreamAnalyticsProtocol) {
        if bitrate >= 0 {
            let bitrateValue = NSNumber(value: bitrate / 1000)
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
            self.storage.storeKeyValuePair(key: CIS_SSDK_PLAYBACK_METRIC_BITRATE, value: bitrateValue)
        }
        if avgBitrate >= 0 {
            let avgBitrateValue = NSNumber(value: avgBitrate / 1000)
            endpoint.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE, value: avgBitrateValue)
            self.storage.storeKeyValuePair(key: CIS_SSDK_PLAYBACK_METRIC_AVERAGE_BITRATE, value: avgBitrateValue)
        }
    }

    deinit {
        self.reportEndedIfPlayed()
    }
}
