//
//  theoComscoreConguration.swift
//  theoplayer-comscore-ios-integration
//
//  Copyright © 2021 THEOPlayer. All rights reserved.
//

import Foundation

public class ComScoreConfiguration {
    public let publisherId: String
    public let applicationName: String
    public var userConsent: ComScoreUserConsent
    public let childDirectedAppMode: Bool
    public var debug: Bool

    // MARK: - initializer
    /**
     Initializes a new ComSoreConfiguration with application specific information
     
     - Parameters:
     - publisherId: Publisher id assigned by ComScore
     - applicationName: Application name used for ComScore tracking
     - userConsent: User consent for ComScore data collection
     - enableChildDirectedApplicationMode: Controls collection of advertising id within the app
     - debug: Debug mode
     */
    public init(publisherId: String, applicationName: String, userConsent: ComScoreUserConsent = .unknown, childDirectedAppMode: Bool = false, debug: Bool = false) {
        self.publisherId = publisherId
        self.applicationName = applicationName
        self.userConsent = userConsent
        self.childDirectedAppMode = childDirectedAppMode
        self.debug = debug
    }
}

