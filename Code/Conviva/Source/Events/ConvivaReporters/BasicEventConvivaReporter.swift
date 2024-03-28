//
//  BasicEventConvivaReporter.swift
//  

import ConvivaSDK
import THEOplayerSDK

class BasicEventConvivaReporter: BasicEventProcessor {
    
    struct Session {
        struct Source {
            let description: SourceDescription
            let url: String?
        }
        var started = false
        var source: Source?
    }
    
    /// The endpoint to which all the events are sent
    private let videoAnalytics: CISVideoAnalytics
    private let storage: ConvivaConnectorStorage
    
    var currentSession = Session()
        
    init(videoAnalytics: CISVideoAnalytics, storage: ConvivaConnectorStorage) {
        self.videoAnalytics = videoAnalytics
        self.storage = storage
    }

    func play(event: PlayEvent) {
        guard !self.currentSession.started else { return }
        self.videoAnalytics.reportPlaybackRequested(nil)
        self.currentSession.started = true
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
        self.videoAnalytics.reportPlaybackFailed(event.error, contentInfo: nil)
    }
    
    func networkError(event: NetworkErrorEvent) {
        self.videoAnalytics.reportPlaybackError(event.error?.message ?? Utilities.defaultStringValue, errorSeverity: .ERROR_WARNING)
    }
    
    func sourceChange(event: SourceChangeEvent, selectedSource: String?) {
        if event.source != self.currentSession.source?.description, self.currentSession.source != nil {
            self.reportEndedIfPlayed()
        }
        
        // clear all stored values for the previous source
        self.storage.clear()
        
        let newSource: Session.Source?
        
        if let source = event.source, let url = selectedSource {
            newSource = .init(description: source, url: url)
            let assetName = source.metadata?.title ?? Utilities.defaultStringValue;
            let contentInfo = [
                CIS_SSDK_METADATA_PLAYER_NAME: Utilities.playerFrameworkName,
                CIS_SSDK_METADATA_STREAM_URL: url,
                CIS_SSDK_METADATA_ASSET_NAME: assetName,
                CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                CIS_SSDK_METADATA_DURATION: NSNumber(value: -1)
            ] as [String: Any]
            self.videoAnalytics.setContentInfo(contentInfo)
            self.storage.storeKeyValuePair(key: CIS_SSDK_METADATA_ASSET_NAME, value: assetName)
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
    
    func destroy(event: DestroyEvent) {
        self.reportEndedIfPlayed()
    }
    
    deinit {
        self.reportEndedIfPlayed()
    }
}
