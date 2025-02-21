//
//  UplynkPingFeature.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 28/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

enum UplynkPingFeature: Int {
    case noPing
    case adImpressions
    case fwVideoViews
    case adImpressionsAndFwVideoViews
    case linearAdData
    
    init(ssaiConfiguration: UplynkSSAIConfiguration) {
        let isVod = ssaiConfiguration.assetType == .asset
        let pingConfiguration = ssaiConfiguration.pingConfiguration
        switch (isVod,
                pingConfiguration.adImpressions,
                pingConfiguration.freeWheelVideoViews,
                pingConfiguration.linearAdData) {
        case (true, true, true, _):
            self = .adImpressionsAndFwVideoViews
        case (true, true, false, _):
            self = .adImpressions
        case (true, false, true, _):
            self = .fwVideoViews
        case (false, false, false, true):
            self = .linearAdData
        default:
            self = .noPing
        }
    }
}
