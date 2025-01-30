//
//  UplynkSSAIConfiguration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkSSAIConfiguration: CustomServerSideAdInsertionConfiguration {
    
    public enum AssetType {
        /// A Video-on-demand content asset.
        case asset
        /// A Live content channel.
        case channel
    }
    
    public let integration: SSAIIntegrationId = .CustomSSAIIntegrationID
    public let customIntegration: String = UplynkAdIntegration.INTEGRATION_ID

    public let assetIDs: [String]
    public let externalIDs: [String]
    
    public let prefix: String?
    public let userID: String?
    public let preplayParameters: [String: String]
    public let assetType: AssetType
    public let contentProtected: Bool
    public let pingConfiguration: UplynkPingConfiguration
    
    public init(
        assetIDs: [String],
        externalIDs: [String],
        assetType: AssetType,
        prefix: String? = nil,
        userID: String? = nil,
        preplayParameters: [String: String] = .init(),
        contentProtected: Bool = false,
        uplynkPingConfiguration: UplynkPingConfiguration = .init()
    ) {
        self.externalIDs = externalIDs
        self.assetIDs = assetIDs
        self.assetType = assetType
        self.prefix = prefix
        self.userID = userID
        self.preplayParameters = preplayParameters
        self.contentProtected = contentProtected
        self.pingConfiguration = uplynkPingConfiguration
    }
}
