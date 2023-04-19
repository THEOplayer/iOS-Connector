//
//  BasicEventConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 01/09/2022.
//

import ConvivaSDK
import THEOplayerSDK

class BasicEventConvivaReporter: BasicEventProcessor {
    
    struct Source {
        var hasNotPlayedSinceSourceChange = true
        var url: String?
    }
    
    /// The endpoint to which all the events are sent
    let conviva: CISVideoAnalytics
    
    var currentSource = Source()
        
    init(conviva: CISVideoAnalytics) {
        self.conviva = conviva
    }

    func play(event: PlayEvent) {
        guard currentSource.hasNotPlayedSinceSourceChange else { return }
        currentSource.hasNotPlayedSinceSourceChange = false
        
        conviva.reportPlaybackRequested(nil)
    }
    
    func playing(event: PlayingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func timeUpdate(event: TimeUpdateEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: event.currentTimeInMilliseconds)
    }
    
    func pause(event: PauseEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
    
    func waiting(event: WaitingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_BUFFERING.rawValue)
    }
    
    func seeking(event: SeekingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED, value: event.currentTimeInMilliseconds)
    }
    
    func seeked(event: SeekedEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED, value: event.currentTimeInMilliseconds)
    }
    
    func error(event: ErrorEvent) {
        conviva.reportPlaybackFailed(event.error, contentInfo: nil)
    }
    
    func networkError(event: NetworkErrorEvent) {
        conviva.reportPlaybackError(event.error?.message ?? Utilities.defaultStringValue, errorSeverity: .ERROR_WARNING)
    }
    
    func sourceChange(event: SourceChangeEvent, selectedSource: String?) {
        reportEndedIfPlayed()
        
        currentSource = Source()
        
        if let source = selectedSource {
            currentSource.url = source
            let contentInfo = [
                CIS_SSDK_METADATA_PLAYER_NAME: Utilities.playerFrameworkName,
                CIS_SSDK_METADATA_STREAM_URL: source,
                CIS_SSDK_METADATA_ASSET_NAME: event.source?.metadata?.title ?? Utilities.defaultStringValue,
                CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                CIS_SSDK_METADATA_DURATION: NSNumber(value: -1)
            ] as [String: Any]
            conviva.setContentInfo(contentInfo)
        } else {
            #if DEBUG
            print("[THEOplayerConnectorConviva] setting unknown source")
            #endif
        }
    }
    
    func renderedFramerateUpdate(framerate: Float) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_RENDERED_FRAMERATE, value: NSNumber(value: Int(framerate.rounded())))
    }
    
    func ended(event: EndedEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        reportEndedIfPlayed()
    }
    
    func reportEndedIfPlayed() {
        let hasPlayed = !currentSource.hasNotPlayedSinceSourceChange
        if hasPlayed {
            conviva.reportPlaybackEnded()
            currentSource = Source()
        }
    }
    
    func durationChange(event: DurationChangeEvent) {
        if let duration = event.duration, currentSource.url != nil {
            if duration.isInfinite {
                conviva.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: true)
                ])
            } else {
                conviva.setContentInfo([
                    CIS_SSDK_METADATA_IS_LIVE: NSNumber(value: false),
                    CIS_SSDK_METADATA_DURATION: NSNumber(value: duration)
                ])
            }
        }
    }
    
    func destroy(event: DestroyEvent) {
        reportEndedIfPlayed()
    }
    
    deinit {
        reportEndedIfPlayed()
    }
}
