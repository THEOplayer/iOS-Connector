//
//  UplynkSSAIConfiguration+Extensions.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 28/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

extension UplynkSSAIConfiguration {
    var drmParameters: [URLQueryItem] {
        guard contentProtected else {return []}
        return [
            URLQueryItem(name: "manifest", value: "m3u8"),
            URLQueryItem(name: "rmt", value: "fps")
        ]
    }
    
    var pingFeature: UplynkPingFeature {
        UplynkPingFeature(ssaiConfiguration: self)
    }
    
    var pingParameters: [URLQueryItem] {
        let pingFeature = pingFeature
        if pingFeature == .noPing { return [] }
        else {
            return [
                URLQueryItem(name: "ad.cping", value: "1"),
                URLQueryItem(name: "ad.pingf", value: pingFeature.rawValue.description)
            ]
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
        switch (id) {
        case let .asset(ids):
            guard !ids.isEmpty else {
                return ""
            }
            if ids.count == 1, let first = ids.first {
                return "\(first).json"
            }
            return "\(ids.joined(separator: ","))/multiple.json"
        case let .external(ids, userID):
            guard !ids.isEmpty else {
                return ""
            }
            if ids.count == 1, let first = ids.first {
                return "ext/\(userID)/\(first).json"
            }
        
            return "ext/\(userID)/\(ids.joined(separator: ","))/multiple.json"
        }
    }
}
