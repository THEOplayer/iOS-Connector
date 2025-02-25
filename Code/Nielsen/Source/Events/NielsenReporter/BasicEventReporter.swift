//
//  BasicEventReporter.swift
//  
//
//  Created by Damiaan Dufaux on 03/03/2023.
//

import THEOplayerSDK

#if os(iOS)
import NielsenAppApi
#elseif os(tvOS)
import NielsenTVAppApi
#endif

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
    
    deinit {
        reportEndedIfPlayed()
    }
    
    func sourceChange(event: THEOplayerSDK.SourceChangeEvent, selectedSource: String?) {
        reportEndedIfPlayed()
        currentSourceHasNotYetPlayedSinceSourceChange = true
    }
    
    func play(event: THEOplayerSDK.PlayEvent, selectedSource: String?) {
        if currentSourceHasNotYetPlayedSinceSourceChange {
            currentSourceHasNotYetPlayedSinceSourceChange = false
        }
    }
    
    func loadedMetadata(event: THEOplayerSDK.LoadedMetaDataEvent, duration: Double?) {
        nielsen.loadMetadata(nielsenDefaultMetadata)
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
        reportEndedIfPlayed()
    }
            
    func destroy(event: THEOplayerSDK.DestroyEvent) {
        reportEndedIfPlayed()
    }
    
    func reportEndedIfPlayed() {
        let hasPlayed = !currentSourceHasNotYetPlayedSinceSourceChange
        if hasPlayed {
            nielsen.end()
            currentSourceHasNotYetPlayedSinceSourceChange = true
        }
    }    
    
    static func createSerializationFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 6
        return formatter
    }
}
