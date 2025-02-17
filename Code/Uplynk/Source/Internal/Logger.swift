//
//  Logger.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Raveendran, Aravind on 11/2/2025.
//

import Foundation
import OSLog

extension OSLog {
    static let adIntegration = OSLog(
        subsystem: String(describing: UplynkConnector.self),
        category: String(describing: UplynkAdIntegration.self)
    )
    
    static let adHandler = OSLog(
        subsystem: String(describing: AdHandler.self),
        category: String(describing: UplynkAdIntegration.self)
    )
    
    static let adScheduler = OSLog(
        subsystem: String(describing: AdScheduler.self),
        category: String(describing: UplynkAdIntegration.self)
    )
    
    static let drmIntegration = OSLog(
        subsystem: String(describing: UplynkDRMIntegration.self),
        category: String(describing: UplynkAdIntegration.self)
    )
}
