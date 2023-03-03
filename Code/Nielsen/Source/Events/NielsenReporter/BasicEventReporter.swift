//
//  BasicEventReporter.swift
//  
//
//  Created by Damiaan Dufaux on 03/03/2023.
//

import THEOplayerSDK
import NielsenAppApi

struct BasicEventReporter: BasicEventProcessor {
    let nielsen: NielsenAppApi
    
    func reportPlayheadPosition(from event: CurrentTimeEvent) {
        nielsen.playheadPosition(.init(event.currentTime.rounded()))
    }
    
    func play(event: THEOplayerSDK.PlayEvent) {
        print("THEO-NIELSEN PLAY: PLAY event should be reported here")
    }
    
    func playing(event: THEOplayerSDK.PlayingEvent) {
        reportPlayheadPosition(from: event)
    }
    
    func timeUpdate(event: THEOplayerSDK.TimeUpdateEvent) {
        reportPlayheadPosition(from: event)
    }
    
    func pause(event: THEOplayerSDK.PauseEvent) {
        nielsen.stop()
    }
    
    func waiting(event: THEOplayerSDK.WaitingEvent) {
        nielsen.stop()
    }
    
    func seeking(event: THEOplayerSDK.SeekingEvent) {
        print("THEO-NIELSEN TODO: seeking event should be reported here")
    }
    
    func seeked(event: THEOplayerSDK.SeekedEvent) {
        print("THEO-NIELSEN TODO: seeked event should be reported here")
    }
    
    func error(event: THEOplayerSDK.ErrorEvent) {
        print("THEO-NIELSEN TODO: error event should be reported here")
    }
    
    func sourceChange(event: THEOplayerSDK.SourceChangeEvent, selectedSource: String?) {
        var playInfo = ["channelName": "TheoDemo"]
        if let selectedSource = selectedSource {
            playInfo["mediaURL"] = selectedSource
        }
        nielsen.play(playInfo)
        nielsen.loadMetadata([
            "type": "content",
            "adModel": "1"
        ])
    }
    
    func ended(event: THEOplayerSDK.EndedEvent) {
        nielsen.end()
    }
    
    func durationChange(event: THEOplayerSDK.DurationChangeEvent) {
        print("THEO-NIELSEN TODO: durationChange event should be reported here")
    }
    
    func destroy(event: THEOplayerSDK.DestroyEvent) {
        print("THEO-NIELSEN TODO: destroy event should be reported here")
    }
}
