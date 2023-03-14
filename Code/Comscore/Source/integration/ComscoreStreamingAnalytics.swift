//
//  ComscoreStreamingAnalytics.swift
//  theoplayer-comscore-ios-integration
//
//  Copyright © 2021 THEOPlayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

public class ComScoreStreamingAnalytics {
    let adapter: THEOComScoreAdapter

    // MARK: - initializer
    /**
     Initialize a ComScoreStreamingAnalytics
     
     - Parameters:
     - player: Player instance to track
     - metadata: ComScore metadata associated with the content you are tracking
     */
    init(player: THEOplayer, playerVersion: String, configuration: ComScoreConfiguration, metadata: ComScoreMetadata?) {
        adapter = THEOComScoreAdapter(
            player: player,
            playerVersion: playerVersion,
            configuration: configuration,
            metadata: metadata
        )
    }

    deinit {
        adapter.destroy()
    }

    /**
     Destroy ComScoreStreamingAnalytics and unregister it from player
     */
    public func destroy() {
        adapter.destroy()
    }

    /**
     Update metadata for tracked source. This should be called when changing sources.
     */
    public func update(metadata: ComScoreMetadata) {
        adapter.update(metadata: metadata)
    }

    /**
     Set a persistent label on the ComScore PublisherConfiguration
     - Parameters:
     - label: The label name
     - value: The label value
     */
    public func setPersistentLabel(label: String, value: String) {
        adapter.setPersistentLabel(label: label, value: value)
    }

    /**
     Set persistent labels on the ComScore PublisherConfiguration
     - Parameters:
     - label: The labels to set
     */
    public func setPersistentLabels(labels: [String: String]) {
        adapter.setPersistentLabels(labels: labels)
    }
    
//    /**
//     Enable/disable comscore ad content tracking
//     - Parameters:
//     - suppress: The enable/disable flag
//     */
//    public func suppressAdAnalytics(suppress: Bool) {
//        adapter.suppressAdAnalytics = suppress
//    }
}
