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
}
