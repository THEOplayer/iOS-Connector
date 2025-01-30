//
//  UplynkAPIMock.swift
//  THEOplayerConnectorUplynkTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

class UplynkAPIMock: UplynkAPIProtocol {
    static var basePrefix: String = "https://content-aapm1.uplynk.com" {
        didSet {
            playURL = "\(basePrefix)/preplay2/e70a708265b94a3fa6716666994d877d/f82dae632c127bb6ceb89bb2fd3e4cbc/4apk0GKq2jrzRWih388o9I7VbFoySPOnwfENiuwWUzQB.m3u8?pbs=86e17e502c6b496a882878f03747714bk"
        }
    }
    
    static var playURL = "https://content-aapm1.uplynk.com/preplay2/e70a708265b94a3fa6716666994d877d/f82dae632c127bb6ceb89bb2fd3e4cbc/4apk0GKq2jrzRWih388o9I7VbFoySPOnwfENiuwWUzQB.m3u8?pbs=86e17e502c6b496a882878f03747714bk"
    static var requireDRM: Bool = false
    static var liveAds: [UplynkLiveAd] = []
    static var institutionalURL: String = ""
    static var vODAds: UplynkAds = .init(breaks: [], breakOffsets: [], placeholderOffsets: [])
    
    static func requestLive(preplaySrcURL: String) async -> THEOplayerConnectorUplynk.PrePlayLiveResponse? {
        let drm: PrePlayDRMConfiguration? = requireDRM ? .init(required: true, fairplayCertificateURL: "https://x-drm.uplynk.com/fairplay/public_key/662d0a3da2244ca5b6757a7dd077e538.cer") : nil
        return PrePlayLiveResponse(
            playURL: playURL,
            sid: "123456789",
            prefix: "https://content-aapm1.uplynk.com",
            ads: liveAds,
            drm: drm)
    }
    
    static func requestVOD(preplaySrcURL: String) async -> THEOplayerConnectorUplynk.PrePlayVODResponse? {
        let drm: PrePlayDRMConfiguration? = requireDRM ? .init(required: true, fairplayCertificateURL: "https://x-drm.uplynk.com/fairplay/public_key/662d0a3da2244ca5b6757a7dd077e538.cer") : nil
        return PrePlayVODResponse(
            playURL: playURL,
            sid: "123456789",
            prefix: "https://content-aapm1.uplynk.com",
            ads: vODAds,
            drm: drm, 
            interstitialURL: institutionalURL)
    }
}
