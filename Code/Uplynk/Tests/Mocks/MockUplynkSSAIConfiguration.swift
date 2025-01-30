//
//  MockUplynkSSAIConfiguration.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

extension UplynkSSAIConfiguration {
    static var vodConfig: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["41afc04d34ad4cbd855db52402ef210e",
                                           "c6b61470c27d44c4842346980ec2c7bd",
                                           "588f9d967643409580aa5dbe136697a1",
                                           "b1927a5d5bd9404c85fde75c307c63ad",
                                           "7e9932d922e2459bac1599938f12b272",
                                           "a4c40e2a8d5b46338b09d7f863049675",
                                           "bcf7d78c4ff94c969b2668a6edc64278"],
                                externalIDs: [],
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "adtest",
                                    "ad.lib": "15_sec_spots"
                                ],
                                uplynkPingConfiguration: .init(adImpressions: true,
                                                               freeWheelVideoViews: true,
                                                               linearAdData: false))
    }
    
    static var liveConfig: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["3c367669a83b4cdab20cceefac253684"],
                                externalIDs: [],
                                assetType: .channel,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "cleardashnew",
                                ],
                                contentProtected: true,
                                uplynkPingConfiguration: .init(adImpressions: false,
                                                               freeWheelVideoViews: false,
                                                               linearAdData: true))
    }
}
