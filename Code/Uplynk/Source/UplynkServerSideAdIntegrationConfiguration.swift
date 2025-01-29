//
//  UplynkServerSideAdIntegrationConfiguration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkServerSideAdIntegrationConfiguration: THEOplayerSDK.CustomServerSideAdInsertionConfiguration {
    
    public enum AssetType {
        /// A Video-on-demand content asset.
        case asset
        /// A Live content channel.
        case channel
    }
    
    public let integration: THEOplayerSDK.SSAIIntegrationId = .CustomSSAIIntegrationID
    public let customIntegration: String = UplynkAdIntegration.INTEGRATION_ID

    public let prefix: String?
    public let userID: String?
    public let assetIDs: [String]
    public let externalIDs: [String]
    public let preplayParameters: [String: String]
    public let assetType: AssetType
    public let contentProtected: Bool
    public let pingConfiguration: UplynkPingConfiguration
    
    public init(
        prefix: String?,
        userID: String?,
        assetIDs: [String],
        externalIDs: [String],
        preplayParameters: [String: String],
        assetType: AssetType = .asset,
        contentProtected: Bool = false,
        uplynkPingConfiguration: UplynkPingConfiguration = .init()
    ) {
        self.prefix = prefix
        self.userID = userID
        self.assetIDs = assetIDs
        self.externalIDs = externalIDs
        self.preplayParameters = preplayParameters
        self.assetType = assetType
        self.contentProtected = contentProtected
        self.pingConfiguration = uplynkPingConfiguration
    }
}
