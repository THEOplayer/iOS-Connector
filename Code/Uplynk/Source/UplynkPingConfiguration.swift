//
//  UplynkPingConfiguration.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 28/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

public struct UplynkPingConfiguration {
    
    /// Whether to increase the accuracy of ad events by passing the current playback time in Ping requests. Defaults to false
    /// - Remark: Only available when `UplynkServerSideAdIntegrationConfiguration.assetType` is `'asset'`.
    public let adImpressions: Bool

    /// Whether to enable FreeWheel's Video View by Callback feature to send content impressions to the FreeWheel server. Defaults to false
    /// - Remark: Only available when `UplynkServerSideAdIntegrationConfiguration.assetType` is `'asset'`.
    public let freeWheelVideoViews: Bool

    /// Whether to request information about upcoming ad breaks in the Ping responses. Defaults to false
    public let linearAdData: Bool

    public init(adImpressions: Bool = false, freeWheelVideoViews: Bool = false, linearAdData: Bool = false) {
        self.adImpressions = adImpressions
        self.freeWheelVideoViews = freeWheelVideoViews
        self.linearAdData = linearAdData
    }
}
