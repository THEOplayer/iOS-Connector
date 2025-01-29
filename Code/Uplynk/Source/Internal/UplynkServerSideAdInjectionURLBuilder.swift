//
//  UplynkServerSideAdInjectionURLBuilder.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class UplynkServerSideAdInjectionURLBuilder {
    private static let DEFAULT_PREFIX: String = "https://content.uplynk.com"
    
    private let ssaiConfiguration: UplynkServerSideAdIntegrationConfiguration
    
    init(ssaiConfiguration: UplynkServerSideAdIntegrationConfiguration) {
        self.ssaiConfiguration = ssaiConfiguration
    }
    
    private var prefix: String {
        ssaiConfiguration.prefix ?? UplynkServerSideAdInjectionURLBuilder.DEFAULT_PREFIX
    }
    
    lazy private var urlAssetType = ssaiConfiguration.urlAssetType
    lazy private var urlAssetID = ssaiConfiguration.urlAssetID
    lazy private var drmParameters = ssaiConfiguration.drmParameters
    lazy private var pingParameters = ssaiConfiguration.pingParameters
    lazy private var urlParameters = ssaiConfiguration.urlParameters
    lazy private var assetIDs = ssaiConfiguration.assetIDs
    lazy private var externalIDs = ssaiConfiguration.externalIDs
    lazy private var userID = ssaiConfiguration.userID
    
    func buildPreplayVodUrl() -> String {
        return "\(prefix)/preplay/\(urlAssetID)?v=2\(drmParameters)\(pingParameters)\(urlParameters)"
    }

    func buildPreplayLiveUrl() -> String {
        return "\(prefix)/preplay/\(urlAssetType)/\(urlAssetID)?v=2\(drmParameters)\(pingParameters)\(urlParameters)"
    }

    func buildAssetInfoUrls(
        sessionID: String,
        prefix: String
    ) -> [String] {
        let urlList: [String] = if !assetIDs.isEmpty {
            assetIDs.map {
                "\(prefix)/player/assetinfo/\($0).json"
            }
        } else if !externalIDs.isEmpty, let userID = userID {
            externalIDs.map {
                "\(prefix)/player/assetinfo/ext/\(userID)/\($0).json"
            }
        } else {
            []
        }
        
        return if sessionID.isEmpty {
            urlList
        } else {
            urlList.map {
                "\($0)?pbs=\(sessionID)"
            }
        }
    }

    func buildSeekedPingUrl(
        prefix: String, sessionID: String, currentTimeSeconds: Int, seekStartTimeSeconds: Int
    ) -> String {
        return buildPingUrl(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds) + "&ev=seek&ft=\(seekStartTimeSeconds)"
    }

    func buildStartPingUrl(
        prefix: String, sessionID: String, currentTimeSeconds: Int
    ) -> String {
        return buildPingUrl(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds) + "&ev=start"
    }

    func buildPingUrl(
        prefix: String, sessionID: String, currentTimeSeconds: Int
    ) -> String  {
        return "\(prefix)/session/ping/\(sessionID).json?v=3&pt=\(currentTimeSeconds)"
    }
}
