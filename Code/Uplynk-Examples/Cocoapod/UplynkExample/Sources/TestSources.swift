//
//  TestSources.swift
//  UplynkExample
//
//  Created by Raveendran, Aravind on 7/2/2025.
//

import Foundation
import RegexBuilder
import THEOplayerConnectorUplynk
import THEOplayerSDK

extension SourceDescription {
    static var live: SourceDescription {
        let typedSource = TypedSource(src: "",
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkLive)
        return SourceDescription(source: typedSource)
    }
    
    static var ads: SourceDescription {
        let typedSource = TypedSource(src: "",
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkAds)
        return SourceDescription(source: typedSource)
    }
    
    static var multiDRM: SourceDescription {
        let typedSource = TypedSource(src: "",
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkDRM)
        return SourceDescription(source: typedSource)
    }
}

private extension UplynkSSAIConfiguration {
        
    static var uplynkAds: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(id: .asset(ids:["41afc04d34ad4cbd855db52402ef210e",
                                                "c6b61470c27d44c4842346980ec2c7bd",
                                                "588f9d967643409580aa5dbe136697a1",
                                                "b1927a5d5bd9404c85fde75c307c63ad",
                                                "7e9932d922e2459bac1599938f12b272",
                                                "a4c40e2a8d5b46338b09d7f863049675",
                                                "bcf7d78c4ff94c969b2668a6edc64278"]),
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                preplayParameters: [
                                    "ad": "adtest",
                                    "ad.lib": "15_sec_spots"
                                ],
                                assetInfo: true,
                                uplynkPingConfiguration: .init(adImpressions: true,
                                                               freeWheelVideoViews: true,
                                                               linearAdData: false))
    }
    
    static var uplynkLive: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(id: .asset(ids: ["3c367669a83b4cdab20cceefac253684"]),
                                assetType: .channel,
                                prefix: "https://content.uplynk.com",
                                preplayParameters: [
                                    "ad": "cleardashnew",
                                ],
                                contentProtected: true,
                                assetInfo: true,
                                uplynkPingConfiguration: .init(adImpressions: false,
                                                               freeWheelVideoViews: false,
                                                               linearAdData: true))
    }
    
    static var uplynkDRM: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(id: .asset(ids: ["e973a509e67241e3aa368730130a104d",
                                                 "e70a708265b94a3fa6716666994d877d"]),
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                preplayParameters: [:],
                                contentProtected: true,
                                assetInfo: true)
    }
}
