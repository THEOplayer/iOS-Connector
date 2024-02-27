//
//  ComscoreAnalytics.swift
//
//  Copyright © THEOPlayer. All rights reserved.
//

import ComScore
import THEOplayerSDK

final class ComScoreAnalytics {
    private static let serialQueue = DispatchQueue(label: "com.theoplayer.comscore.ios.integration")
    private static var started: Bool = false
    private static var configuration: ComScoreConfiguration?

    /**
     Start ComScoreAnalytics app level tracking
     - Parameters:
     - configuration: The ComScoreConfiguration that contains application specific information
     */
    static func start(configuration: ComScoreConfiguration) {
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
                if configuration.debug { print("[THEOplayerConnectorComscore] ComScoreAnalytics has already been started. Ignoring call to start") }
            }
        }
    }

    // Only call after you started app level tracking with start()
    static func THEOplayerComscoreSDK(player: THEOplayer, playerVersion: String, metadata: ComScoreMetadata, configuration: ComScoreConfiguration) -> ComScoreStreamingAnalytics {
        return ComScoreStreamingAnalytics(player: player, playerVersion: playerVersion, configuration: configuration, metadata: metadata)
    }
}
