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
        guard !orderedPreplayParameters.isEmpty else { return "" }
        
        var components = URLComponents()
        components.percentEncodedQueryItems = orderedPreplayParameters.map(URLQueryItem.encodedForUplynk)
        return "&\(components.percentEncodedQuery!)"
    }
    
    var pingFeature: UplynkPingFeature {
        UplynkPingFeature(ssaiConfiguration: self)
    }
    
    var pingParameters: String {
        let pingFeature = pingFeature
        if pingFeature == .noPing {
            return ""
        } else {
            return "&ad.cping=1&ad.pingf=\(pingFeature.rawValue)"
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

extension CharacterSet {
    fileprivate static let uplynkUrlQueryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?,"))
}
extension URLQueryItem {
    fileprivate static func encodedForUplynk(name: String, value: String) -> URLQueryItem {
        URLQueryItem(
            name: name,
            value: value.addingPercentEncoding(withAllowedCharacters: .uplynkUrlQueryValueAllowed)
        )
    }
}
