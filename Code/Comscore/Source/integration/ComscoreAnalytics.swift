//
//  theoComscoreAnalytics.swift
//  theoplayer-comscore-ios-integration
//
//  Copyright © 2021 THEOPlayer. All rights reserved.
//

import ComScore
import THEOplayerSDK

public final class ComScoreAnalytics {
    private static let serialQueue = DispatchQueue(label: "com.theoplayer.comscore.ios.integration")
    private static var started: Bool = false
    private static var configuration: ComScoreConfiguration?

    /**
     Start ComScoreAnalytics app level tracking
     - Parameters:
     - configuration: The ComScoreConfiguration that contains application specific information
     */
    public static func start(configuration: ComScoreConfiguration) {
        serialQueue.sync {
            if !started {
                ComScoreAnalytics.configuration = configuration
                let publisherConfig = SCORPublisherConfiguration(builderBlock: { builder in
                    builder?.publisherId = configuration.publisherId
                })
                SCORAnalytics.configuration().addClient(with: publisherConfig)
                SCORAnalytics.configuration().applicationName = configuration.applicationName
                if configuration.userConsent != .unknown {
                    SCORAnalytics.configuration().setPersistentLabelWithName(
                        "cs_ucfr",
                        value: configuration.userConsent.rawValue
                    )
                }
                if configuration.childDirectedAppMode {
                    SCORAnalytics.configuration().enableChildDirectedApplicationMode()
                }
                SCORAnalytics.start()
                started = true
            } else {
                print("ComScoreAnalytics has already been started. Ignoring call to start")
            }
        }
    }

    /**
     Set a persistent label on the ComScore PublisherConfiguration
     - Parameters:
     - label: The label name
     - value: The label value
     */
    public static func setPersistentLabel(label: String, value: String) {
        serialQueue.sync {
            if started {
                notifyHiddenEvent(publisherId: ComScoreAnalytics.configuration?.publisherId, label: label, value: value)
                print("ComScore persistent label set: [\(label):\(value)]")
            }
        }
    }

    /**
     Set persistent labels on the ComScore PublisherConfiguration
     - Parameters:
     - label: The labels to set
     */
    public static func setPersistentLabels(labels: [String: String]) {
        serialQueue.sync {
            if started {
                notifyHiddenEvents(publisherId: ComScoreAnalytics.configuration?.publisherId, labels: labels)
                print("ComScore persistent labels set: [\(labels.map { "\($0.key):\($0.value)"})]")
            }
        }
    }

    // Only call after you started app level tracking with start()
    public static func THEOplayerComscoreSDK(player: THEOplayer, playerVersion: String, metadata: ComScoreMetadata?) -> ComScoreStreamingAnalytics {
        return ComScoreStreamingAnalytics(player: player, playerVersion: playerVersion, configuration: ComScoreAnalytics.configuration!, metadata: metadata)
    }

}

@frozen
public enum ComScoreError: Error {
    case notStarted
}
