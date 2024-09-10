//
//  UplynkServerSideAdIntegrationConfigurationConverter.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class UplynkServerSideAdIntegrationConfigurationConverter {
    private static let DEFAULT_PREFIX: String = "https://content.uplynk.com"

    static func buildPreplayUrl(ssaiDescription: UplynkServerSideAdIntegrationConfiguration) -> String {
        let prefix: String = ssaiDescription.prefix ?? Self.DEFAULT_PREFIX
        let userId: String = ssaiDescription.userId ?? "null"
        let assetIds: [String] = ssaiDescription.assetIds
        let externalIds: [String] = ssaiDescription.externalIds
        let preplayParameters: [String: String] = ssaiDescription.preplayParameters

        var assetIdsStr: String = ""
        if assetIds.isEmpty && externalIds.count == 1 {
            assetIdsStr = "\(userId)/\(externalIds.first!).json"
        } else if assetIds.isEmpty && externalIds.count > 1 {
            let externalIdsStr: String = externalIds.joined(separator: ",")
            assetIdsStr = "\(userId)/\(externalIdsStr)/multiple.json"
        } else if assetIds.count == 1 {
            assetIdsStr = "\(assetIds.first!).json"
        } else {
            assetIdsStr = assetIds.joined(separator: ",") + "/multiple.json"
        }

        let preplayParametersArr: [String] = preplayParameters.map { "\($0.key)=\($0.value)" }
        let preplayParametersStr: String = preplayParametersArr.joined(separator: "&")

        return "\(prefix)/preplay/\(assetIdsStr)?v=2&\(preplayParametersStr)"
    }
}
