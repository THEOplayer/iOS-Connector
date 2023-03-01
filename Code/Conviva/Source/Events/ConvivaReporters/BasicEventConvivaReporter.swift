//
//  BasicEventConvivaReporter.swift
//  
//
//  Created by Damiaan Dufaux on 01/09/2022.
//

import ConvivaSDK
import THEOplayerSDK

class BasicEventConvivaReporter: BasicEventProcessor {
    
    /// The endpoint to which all the events are sent
    let conviva: CISVideoAnalytics
    
    var currentSourceHasNotYetPlayedSinceSourceChange = true
        
    init(conviva: CISVideoAnalytics) {
        self.conviva = conviva
    }

    func play(event: PlayEvent) {
        guard currentSourceHasNotYetPlayedSinceSourceChange else { return }
        currentSourceHasNotYetPlayedSinceSourceChange = false
        
        conviva.reportPlaybackRequested(nil)
    }
    
    func playing(event: PlayingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PLAYING.rawValue)
    }
    
    func timeUpdate(event: TimeUpdateEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAY_HEAD_TIME, value: NSNumber(value: event.currentTime))
    }
    
    func pause(event: PauseEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_PAUSED.rawValue)
    }
    
    func waiting(event: WaitingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_BUFFERING.rawValue)
    }
    
    func seeking(event: SeekingEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_STARTED, value: NSNumber(value: event.currentTime))
    }
    
    func seeked(event: SeekedEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_SEEK_ENDED, value: NSNumber(value: event.currentTime))
    }
    
    func error(event: ErrorEvent) {
        conviva.reportPlaybackFailed(event.error, contentInfo: nil)
    }
    
    func sourceChange(event: SourceChangeEvent, selectedSource: String?) {
        reportEndedIfPlayed()
        
        currentSourceHasNotYetPlayedSinceSourceChange = true
        
        if let source = selectedSource {
            var contentInfo = [
                CIS_SSDK_METADATA_PLAYER_NAME: Utilities.playerFrameworkName,
                CIS_SSDK_METADATA_STREAM_URL: source,
                CIS_SSDK_METADATA_ASSET_NAME: event.source?.metadata?.title ?? "NA"
            ]
            conviva.setContentInfo(contentInfo)
        }
    }
    
    func ended(event: EndedEvent) {
        conviva.reportPlaybackMetric(CIS_SSDK_PLAYBACK_METRIC_PLAYER_STATE, value: PlayerState.CONVIVA_STOPPED.rawValue)
        reportEndedIfPlayed()
    }
    
    func reportEndedIfPlayed() {
        let hasPlayed = !currentSourceHasNotYetPlayedSinceSourceChange
        if hasPlayed {
            conviva.reportPlaybackEnded()
            currentSourceHasNotYetPlayedSinceSourceChange = true
        }
    }
    
    func durationChange(event: DurationChangeEvent) {
        if let duration = event.duration {
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
}
