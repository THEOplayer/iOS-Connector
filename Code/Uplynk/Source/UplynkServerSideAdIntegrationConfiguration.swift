//
//  UplynkServerSideAdIntegrationConfiguration.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import THEOplayerSDK

public class UplynkServerSideAdIntegrationConfiguration: THEOplayerSDK.CustomServerSideAdInsertionConfiguration {
    public let integration: THEOplayerSDK.SSAIIntegrationId = .CustomSSAIIntegrationID
    public let customIntegration: String = UplynkAdIntegration.INTEGRATION_ID

    public let prefix: String?
    public let userId: String?
    public let assetIds: [String]
    public let externalIds: [String]
    public let preplayParameters: [String: String]

    init(prefix: String?, userId: String?, assetIds: [String], externalIds: [String], preplayParameters: [String: String]) {
        self.prefix = prefix
        self.userId = userId
        self.assetIds = assetIds
        self.externalIds = externalIds
        self.preplayParameters = preplayParameters
    }

    public struct Builder {
        public var prefix: String?
        public var userId: String?
        public var assetIds: [String] = []
        public var externalIds: [String] = []
        public var preplayParameters: [String: String] = [:]

        public func build() -> UplynkServerSideAdIntegrationConfiguration {
            return .init(
                prefix: self.prefix,
                userId: self.userId,
                assetIds: self.assetIds,
                externalIds: self.externalIds,
                preplayParameters: self.preplayParameters
            )
        }
    }
}
