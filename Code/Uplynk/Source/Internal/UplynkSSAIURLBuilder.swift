//
//  UplynkSSAIURLBuilder.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class UplynkSSAIURLBuilder {
    private static let DEFAULT_PREFIX: String = "https://content.uplynk.com"
    
    private let ssaiConfiguration: UplynkSSAIConfiguration
    
    init(ssaiConfiguration: UplynkSSAIConfiguration) {
        self.ssaiConfiguration = ssaiConfiguration
    }
    
    private var prefix: String {
        ssaiConfiguration.prefix ?? UplynkSSAIURLBuilder.DEFAULT_PREFIX
    }
    
    private var urlAssetType: String { ssaiConfiguration.urlAssetType }
    private var urlAssetID: String { ssaiConfiguration.urlAssetID }
    private var drmParameters: String { ssaiConfiguration.drmParameters }
    private var pingParameters: String { ssaiConfiguration.pingParameters }
    private var urlParameters: String { ssaiConfiguration.urlParameters }
    private var assetIDs: [String] { ssaiConfiguration.assetIDs }
    private var externalIDs: [String] { ssaiConfiguration.externalIDs }
    private var userID: String? { ssaiConfiguration.userID }

    func buildPreplayVODURL() -> String {
        return "\(prefix)/preplay/\(urlAssetID)?v=2\(drmParameters)\(pingParameters)\(urlParameters)"
    }

    func buildPreplayLiveURL() -> String {
        return "\(prefix)/preplay/\(urlAssetType)/\(urlAssetID)?v=2\(drmParameters)\(pingParameters)\(urlParameters)"
    }

    func buildAssetInfoURLs(
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

    func buildStartPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int) -> String {
        makePingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds) + "&ev=start"
    }
    
    func buildPingURL(prefix: String, sessionID: String, currentTimeSeconds: Int) -> String  {
        makePingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds)
    }
    
    func buildSeekedPingURL(
        prefix: String,
        sessionID: String,
        currentTimeSeconds: Int,
        seekStartTimeSeconds: Int
    ) -> String {
        makePingURL(prefix: prefix, sessionID: sessionID, currentTimeSeconds: currentTimeSeconds) + "&ev=seek&ft=\(seekStartTimeSeconds)"
    }
    
    private func makePingURL(prefix: String, sessionID: String, currentTimeSeconds: Int) -> String {
        "\(prefix)/session/ping/\(sessionID).json?v=3&pt=\(currentTimeSeconds)"
    }
}
