//
//  UplynkServerSideAdIntegrationConfiguration+Extensions.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 28/1/2025.
//

import Foundation

extension UplynkServerSideAdIntegrationConfiguration {
    var drmParameters: String {
        contentProtected ? "&manifest=mpd&rmt=wv" : ""
    }
    
    var urlParameters: String {
        guard !preplayParameters.isEmpty else {
            return ""
        }
        let joinedParameters = preplayParameters.map {
            "\($0.key)=\($0.value)"
        }.joined(separator: "&")
        
        return "&\(joinedParameters)"
    }
    
    var pingParameters: String {
        let feature = UplynkPingFeatures(ssaiConfiguration: self)
        if feature == .noPing {
            return "&ad.pingc=0"
        } else {
            return "&ad.pingc=1&ad.pingf=\(feature)"
        }
    }
    
    var urlAssetType: String {
        switch assetType {
        case .asset:
            return ""
        case .channel:
            return "channel"
        }
    }
    
    var urlAssetID: String {
        if assetIDs.count == 1, let first = assetIDs.first {
            return "\(first).json"
        }
     
        if assetIDs.count > 1 {
            return "\(assetIDs.joined(separator: ","))/multiple.json"
        }
        
        guard let userId = userID else {
            return ""
        }
        
        if externalIDs.count == 1, let first = externalIDs.first {
            return "\(userId)/\(first).json"
        }
        
        if externalIDs.count > 1 {
            return "\(userId)/\(externalIDs.joined(separator: ","))/multiple.json"
        }
        return ""
    }
}
