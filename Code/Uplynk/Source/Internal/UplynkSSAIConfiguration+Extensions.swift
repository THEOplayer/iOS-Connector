//
//  UplynkSSAIConfiguration+Extensions.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 28/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

extension UplynkSSAIConfiguration {
    var drmParameters: String {
        contentProtected ? "&manifest=m3u8&rmt=fps" : ""
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
    
    var pingFeature: UplynkPingFeature {
        UplynkPingFeature(ssaiConfiguration: self)
    }
    
    var pingParameters: String {
        let pingFeature = pingFeature
        if pingFeature == .noPing {
            return "&ad.pingc=0"
        } else {
            return "&ad.pingc=1&ad.pingf=\(pingFeature.rawValue)"
        }
    }
    
    var playbackURLParametersString: String {
        guard !playbackURLParameters.isEmpty else {
            return ""
        }
        
        return playbackURLParameters.reduce("") { $0 + "\(!$0.isEmpty ? "&" : "")\($1.0)=\($1.1)" }
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
            return "ext/\(userId)/\(first).json"
        }
        
        if externalIDs.count > 1 {
            return "ext/\(userId)/\(externalIDs.joined(separator: ","))/multiple.json"
        }
        return ""
    }
}
