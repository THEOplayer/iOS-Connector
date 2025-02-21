//
//  UplynkAds.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

extension UplynkAds {
    static var mock: Self {
        .init(breaks: [.mock],
              breakOffsets: [.mock],
              placeholderOffsets: [.mock])
    }
}

extension UplynkAdBreak {
    static var mock: Self {
        .init(ads: [.mock],
              type: "linear",
              position: "midroll",
              timeOffset: 47.47,
              duration: 90.183041666667, 
              events: ["clickthroughs": ["http://account.v.fwmrm.net/ad/l/1?..."],
                       "completes": ["http://account.v.fwmrm.net/ad/l/1?..."]])
    }
}

extension UplynkAd {
    static var mock: Self {
        .init(apiFramework: nil,
              companions: [],
              mimeType: "uplynk/m3u8",
              creative: "99698c4be3fb41efa36a8b4383dba0f8",
              events: [
                "clickthroughs": [
                    "http://account.v.fwmrm.net/ad/l/1?..."
                ],
                "completes": [
                    "http://account.v.fwmrm.net/ad/l/1?..."
                ],
                "firstquartiles": [
                    "http://account.v.fwmrm.net/ad/l/1?..."
                ],
                "impressions": [
                    "http://account.v.fwmrm.net/ad/l/1?...",
                    "http://sync.adap.tv/sync?type=gif&key;=freewheelmediainc&uid;=a132_6033740266974922981"
                ],
                "midpoints": [
                    "http://account.v.fwmrm.net/ad/l/1?..."
                ],
                "thirdquartiles": [
                    "http://account.v.fwmrm.net/ad/l/1?..."
                ]
              ],
              width: 300,
              height: 250,
              duration: 9.962666666666665,
              extensions: [.mockVASTExtensions1, .mockVASTExtensions2],
              fwParameters: ["_fw_creative_name": "Sample Creative Name",
                             "_fw_campaign_name": "Sample Campaign Name"])
    }
}

extension UplynkAdBreakOffset {
    static var mock: Self {
        .init(timeOffset: 0.0, index: 0)
    }
}

extension UplynkPlaceHolderOffset {
    static var mock: Self {
        .init(startTime: 9.962666666666665,
              endTime: 11.895999999999999,
              breakIndex: 0,
              adsIndex: 1)
    }
}

extension String {
    static var mockVASTExtensions1: String {
        "<Extension fallback_index=\"0\" type=\"waterfall\" />"
    }
    
    static var mockVASTExtensions2: String {
        "<Extension type=\"geo\"><Country>US</Country><Bandwidth>0</Bandwidth></Extension>"
    }
}
