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
    public let orderedPreplayParameters: [(String, String)]
    public let assetType: AssetType
    public let contentProtected: Bool
    public let assetInfo: Bool
    public let pingConfiguration: UplynkPingConfiguration
    public let playbackURLParameters: [(String, String)]

    @available(*, deprecated, message: "Use the initializer with orderedPreplayParameters instead.")
    public init(
        id: ID,
        assetType: AssetType,
        prefix: String? = nil,
        preplayParameters: [String: String] = [:],
        contentProtected: Bool = false,
        assetInfo: Bool = false,
        uplynkPingConfiguration: UplynkPingConfiguration = .init(),
        playbackURLParameters: [(String, String)] = []
    ) {
        self.id = id
        self.assetType = assetType
        self.prefix = prefix
        self.orderedPreplayParameters = Array(preplayParameters)
        self.contentProtected = contentProtected
        self.assetInfo = assetInfo
        self.pingConfiguration = uplynkPingConfiguration
        self.playbackURLParameters = playbackURLParameters
    }
    
    public init(
        id: ID,
        assetType: AssetType,
        orderedPreplayParameters: [(String, String)],
        prefix: String? = nil,
        contentProtected: Bool = false,
        assetInfo: Bool = false,
        uplynkPingConfiguration: UplynkPingConfiguration = .init(),
        playbackURLParameters: [(String, String)] = []
    ) {
        self.id = id
        self.assetType = assetType
        self.orderedPreplayParameters = orderedPreplayParameters
        self.prefix = prefix
        self.contentProtected = contentProtected
        self.assetInfo = assetInfo
        self.pingConfiguration = uplynkPingConfiguration
        self.playbackURLParameters = playbackURLParameters
    }

    @available(*, deprecated, renamed: "orderedPreplayParameters", message: "Passing preplayParameters as a dictionary is no longer supported. Use orderedPreplayParameters instead.")
    var preplayParameters: [String: String] {
        Dictionary(orderedPreplayParameters) { left, right in left }
    }
}
