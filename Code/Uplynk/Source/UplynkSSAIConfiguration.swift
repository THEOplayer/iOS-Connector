//
//  UplynkSSAIConfiguration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkSSAIConfiguration: CustomServerSideAdInsertionConfiguration {
    
    public enum ID {
        case asset(ids: [String])
        case external(ids: [String], userID: String)
    }
    
    public enum AssetType {
        /// A Video-on-demand content asset.
        case asset
        /// A Live content channel.
        case channel
    }
    
    public let integration: SSAIIntegrationId = .CustomSSAIIntegrationID
    public let customIntegration: String = UplynkAdIntegration.INTEGRATION_ID
    
    public let id: ID
    public let prefix: String?
    public let preplayParameters: [String: String]
    public let orderedPreplayParameters: [(String, String)]?
    public let assetType: AssetType
    public let contentProtected: Bool
    public let assetInfo: Bool
    public let pingConfiguration: UplynkPingConfiguration
    public let playbackURLParameters: [(String, String)]

    public init(
        id: ID,
        assetType: AssetType,
        prefix: String? = nil,
        preplayParameters: [String: String] = [:],
        orderedPreplayParameters: [(String, String)]? = nil,
        contentProtected: Bool = false,
        assetInfo: Bool = false,
        uplynkPingConfiguration: UplynkPingConfiguration = .init(),
        playbackURLParameters: [(String, String)] = []
    ) {
        self.id = id
        self.assetType = assetType
        self.prefix = prefix
        self.preplayParameters = preplayParameters
        self.orderedPreplayParameters = orderedPreplayParameters
        self.contentProtected = contentProtected
        self.assetInfo = assetInfo
        self.pingConfiguration = uplynkPingConfiguration
        self.playbackURLParameters = playbackURLParameters
    }
}
