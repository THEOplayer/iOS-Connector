//
//  TestSources.swift
//  UplynkExample
//
//  Created by Raveendran, Aravind on 7/2/2025.
//

import Foundation
import RegexBuilder
import THEOplayerConnectorUplynk
import THEOplayerSDK

extension SourceDescription {
    private static var bigBuckBunnyURL: String { "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny.m3u8" }

    static var live: SourceDescription {
        let typedSource = TypedSource(src: Self.bigBuckBunnyURL,
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkLive)
        return SourceDescription(source: typedSource)
    }
    
    static var ads: SourceDescription {
        let typedSource = TypedSource(src: Self.bigBuckBunnyURL,
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkAds)
        return SourceDescription(source: typedSource)
    }
    
    static var multiDRM: SourceDescription {
        let typedSource = TypedSource(src: Self.bigBuckBunnyURL,
                                      type: "application/x-mpegurl",
                                      ssai: UplynkSSAIConfiguration.uplynkDRM)
        return SourceDescription(source: typedSource)
    }
    
    static func source(for fifaSource: FIFASource, useExternalID: Bool) async -> SourceDescription? {
        guard let ssai = await UplynkSSAIConfiguration.source(for: fifaSource, useExternalID: useExternalID) else {
            return nil
        }
        let typedSource = TypedSource(src: Self.bigBuckBunnyURL,
                                      type: "application/x-mpegurl",
                                      ssai: ssai)
        return SourceDescription(source: typedSource)
    }
}

private extension UplynkSSAIConfiguration {
        
    static var uplynkAds: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["41afc04d34ad4cbd855db52402ef210e",
                                           "c6b61470c27d44c4842346980ec2c7bd",
                                           "588f9d967643409580aa5dbe136697a1",
                                           "b1927a5d5bd9404c85fde75c307c63ad",
                                           "7e9932d922e2459bac1599938f12b272",
                                           "a4c40e2a8d5b46338b09d7f863049675",
                                           "bcf7d78c4ff94c969b2668a6edc64278"],
                                externalIDs: [],
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "adtest",
                                    "ad.lib": "15_sec_spots"
                                ],
                                assetInfo: true,
                                uplynkPingConfiguration: .init(adImpressions: true,
                                                               freeWheelVideoViews: true,
                                                               linearAdData: false))
    }
    
    static var uplynkLive: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["3c367669a83b4cdab20cceefac253684"],
                                externalIDs: [],
                                assetType: .channel,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [
                                    "ad": "cleardashnew",
                                ],
                                contentProtected: true,
                                assetInfo: true,
                                uplynkPingConfiguration: .init(adImpressions: false,
                                                               freeWheelVideoViews: false,
                                                               linearAdData: true))
    }
    
    static var uplynkDRM: UplynkSSAIConfiguration {
        UplynkSSAIConfiguration(assetIDs: ["e973a509e67241e3aa368730130a104d",
                                           "e70a708265b94a3fa6716666994d877d"],
                                externalIDs: [],
                                assetType: .asset,
                                prefix: "https://content.uplynk.com",
                                userID: nil,
                                preplayParameters: [:],
                                contentProtected: true,
                                assetInfo: true)
    }
    
    static func source(for fifaSource: FIFASource, useExternalID: Bool) async -> UplynkSSAIConfiguration? {
        var playbackURLComponents: [(String, String)] = []
        if fifaSource.tokenRequired {
            let request = URLRequest(url: fifaSource.url)
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let responseString = String(data: data, encoding: .utf8)
                let regex = Regex {
                    /let playbackUrl = "/
                    Capture(
                        OneOrMore(.anyNonNewline)
                    )
                    /";/
                }
                guard let playbackURLString = responseString?.firstMatch(of: regex)?.output.1 else {
                    return nil
                }
                let components = URLComponents(string: String(playbackURLString))

                components?.queryItems?.forEach {
                    if let value = $0.value {
                        playbackURLComponents.append(($0.name, value))
                    }
                }
            } catch {
                return nil
            }
        }
        
        if useExternalID {
            return UplynkSSAIConfiguration(assetIDs: [],
                                           externalIDs: fifaSource.externalID.map { [$0] } ?? [],
                                           assetType: .asset,
                                           prefix: "https://content.uplynk.com",
                                           userID: fifaSource.userID,
                                           contentProtected: false,
                                           assetInfo: true,
                                           playbackURLParameters: playbackURLComponents)
        } else {
            return UplynkSSAIConfiguration(assetIDs: [fifaSource.assetID],
                                           externalIDs: [],
                                           assetType: .asset,
                                           prefix: "https://content.uplynk.com",
                                           userID: nil,
                                           contentProtected: false,
                                           assetInfo: true,
                                           playbackURLParameters: playbackURLComponents)
        }
    }
}
