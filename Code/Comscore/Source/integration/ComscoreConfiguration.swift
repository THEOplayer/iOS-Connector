//
//  ComscoreConguration.swift
//
//  Copyright © THEOPlayer. All rights reserved.
//

import Foundation
import THEOplayerSDK

public class ComScoreConfiguration {
    public let publisherId: String
    public let applicationName: String
    public var userConsent: ComScoreUserConsent
    public let usagePropertiesAutoUpdateMode: ComscoreUsagePropertiesAutoUpdateMode
    public let usagePropertiesAutoUpdateInterval: Int
    public let childDirectedAppMode: Bool
    public var adIdProcessor: ((THEOplayerSDK.Ad) -> String)? = nil
    public var debug: Bool

    // MARK: - initializer
    /**
     Initializes a new ComSoreConfiguration with application specific information
     
     - Parameters:
     - publisherId: Publisher id assigned by ComScore
     - applicationName: Application name used for ComScore tracking
     - userConsent: User consent for ComScore data collection
     - usagePropertiesAutoUpdateMode: controls if the library will update application usage times at a regular interval when it is in the foreground and/or background
     - usagePropertiesAutoUpdateInterval: The interval in seconds at which the library automatically updates usage times if the auto-update is enabled. The default value is 60, which is also the minimum value.
     - enableChildDirectedApplicationMode: Controls collection of advertising id within the app
     - adIdProcessor: Provide a closure if you want to customize how the ad id is determined. By default, the integration uses Ad.id.
     - debug: Debug mode
     */
    public init(publisherId: String, applicationName: String, userConsent: ComScoreUserConsent = .unknown, usagePropertiesAutoUpdateMode: ComscoreUsagePropertiesAutoUpdateMode = .foregroundOnly, usagePropertiesAutoUpdateInterval: Int = 60, childDirectedAppMode: Bool = false, adIdProcessor: ((THEOplayerSDK.Ad) -> String)?,debug: Bool = false) {
        self.publisherId = publisherId
        self.applicationName = applicationName
        self.userConsent = userConsent
        self.usagePropertiesAutoUpdateMode = usagePropertiesAutoUpdateMode
        if (usagePropertiesAutoUpdateInterval < 60) {
            self.usagePropertiesAutoUpdateInterval = 60
        } else {
            self.usagePropertiesAutoUpdateInterval = usagePropertiesAutoUpdateInterval

        }
        self.childDirectedAppMode = childDirectedAppMode
        self.adIdProcessor = adIdProcessor
        self.debug = debug
    }
}

