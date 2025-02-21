//
//  UplynkConfiguration.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Raveendran, Aravind on 5/2/2025.
//

import Foundation

public struct UplynkConfiguration {
    public let defaultSkipOffset: Int
    public let skippedAdStrategy: SkippedAdStrategy
    
    public init(defaultSkipOffset: Int = -1, skippedAdStrategy: SkippedAdStrategy = .playNone) {
        self.defaultSkipOffset = defaultSkipOffset
        self.skippedAdStrategy = skippedAdStrategy
    }
}
