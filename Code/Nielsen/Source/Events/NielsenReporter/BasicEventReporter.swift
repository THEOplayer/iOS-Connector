//
//  BasicEventReporter.swift
//  
//
//  Created by Damiaan Dufaux on 03/03/2023.
//

import THEOplayerSDK
import NielsenAppApi

let nielsenDefaultMetadata = [
    "type": "content",
    "adModel": "1"
]

class BasicEventReporter: BasicEventProcessor {
    let nielsen: NielsenAppApi
    static let numberFormatter = createSerializationFormatter()

    var currentSourceHasNotYetPlayedSinceSourceChange = true
    
    init(nielsen: NielsenAppApi) {
        self.nielsen = nielsen
    }
    
    func sourceChange(event: THEOplayerSDK.SourceChangeEvent, selectedSource: String?) {
        reportEndedIfPlayed()
        currentSourceHasNotYetPlayedSinceSourceChange = true
    }
    
    func play(event: THEOplayerSDK.PlayEvent, selectedSource: String?) {
        if currentSourceHasNotYetPlayedSinceSourceChange {
            currentSourceHasNotYetPlayedSinceSourceChange = false

            nielsen.play( selectedSource.map {["channelname": $0]} )
        }
    }
    
    func loadedMetadata(event: THEOplayerSDK.LoadedMetaDataEvent, duration: Double?) {
        let metadata: [String: String]
        if let duration = duration {
            metadata = Self.append(duration: duration, to: nielsenDefaultMetadata)
        } else {
            metadata = nielsenDefaultMetadata
        }
        nielsen.loadMetadata(metadata)
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
    
    func cueEnter(event: THEOplayerSDK.EnterCueEvent) {
        if let dictionary = event.cue.content as? [String:Any],
           let owner = dictionary["ownerIdentifier"] as? String,
           owner.starts(with: "www.nielsen.com") {
            nielsen.sendID3(owner)
        }
    }
    
    func ended(event: THEOplayerSDK.EndedEvent) {
        nielsen.end()
    }
    
    func reportPlayheadPosition(from event: CurrentTimeEvent) {
        nielsen.playheadPosition(.init(event.currentTime.rounded()))
    }
    
    func durationChange(event: THEOplayerSDK.DurationChangeEvent, duration: Double) {
        let metadata = Self.append(duration: duration, to: nielsenDefaultMetadata)
        nielsen.loadMetadata(metadata)
    }
    
    func destroy(event: THEOplayerSDK.DestroyEvent) {
        nielsen.end()
    }
    
    func reportEndedIfPlayed() {
        let hasPlayed = !currentSourceHasNotYetPlayedSinceSourceChange
        if hasPlayed {
            nielsen.end()
            currentSourceHasNotYetPlayedSinceSourceChange = true
        }
    }
    
    static func append(duration: Double, to metadata: [String: String]) -> [String: String] {
        var appendedMetadata = metadata
        appendedMetadata["length"] = Self.numberFormatter.string(from: duration as NSNumber)
        return appendedMetadata
    }
    
    static func createSerializationFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 6
        return formatter
    }
}
