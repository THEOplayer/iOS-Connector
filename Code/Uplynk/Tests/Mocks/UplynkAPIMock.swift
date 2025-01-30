//
//  UplynkAPIMock.swift
//  THEOplayerConnectorUplynkTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

enum MockError: Error {
    case mock(String)
}

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
    static var willFailRequestLive: Bool = false
    static var willFailRequestVOD: Bool = false
    
    enum Event: Equatable {
        case requestLive(preplaySrcURL: String)
        case requestVOD(preplaySrcURL: String)
        case requestPing(url: String)
    }
    
    private(set) var events: [Event] = []
    
    static func requestLive(preplaySrcURL: String) async throws -> PrePlayLiveResponse {
        if willFailRequestLive {
            throw MockError.mock("Failing Live response")
        }

        let drm: PrePlayDRMConfiguration? = requireDRM ? .init(required: true, fairplayCertificateURL: "https://x-drm.uplynk.com/fairplay/public_key/662d0a3da2244ca5b6757a7dd077e538.cer") : nil
        return PrePlayLiveResponse(
            playURL: playURL,
            sid: "123456789",
            prefix: "https://content-aapm1.uplynk.com",
            ads: liveAds,
            drm: drm)
    }
    
    static func requestVOD(preplaySrcURL: String) async throws -> PrePlayVODResponse {
        if willFailRequestVOD {
            throw MockError.mock("Failing VOD response")
        }
        let drm: PrePlayDRMConfiguration? = requireDRM ? .init(required: true, fairplayCertificateURL: "https://x-drm.uplynk.com/fairplay/public_key/662d0a3da2244ca5b6757a7dd077e538.cer") : nil
        return PrePlayVODResponse(
            playURL: playURL,
            sid: "123456789",
            prefix: "https://content-aapm1.uplynk.com",
            ads: vODAds,
            drm: drm, 
            interstitialURL: institutionalURL)
    }
    
    static func reset() {
        playURL = "https://content-aapm1.uplynk.com/preplay2/e70a708265b94a3fa6716666994d877d/f82dae632c127bb6ceb89bb2fd3e4cbc/4apk0GKq2jrzRWih388o9I7VbFoySPOnwfENiuwWUzQB.m3u8?pbs=86e17e502c6b496a882878f03747714bk"
        basePrefix = "https://content-aapm1.uplynk.com"
        requireDRM = false
        liveAds = []
        institutionalURL = ""
        vODAds = .init(breaks: [], breakOffsets: [], placeholderOffsets: [])
        willFailRequestLive = false
        willFailRequestVOD = false
        pingResponseToReturn = nil
    }
    
    static var pingResponseToReturn: PingResponse?
    static func requestPing(url: String) async throws -> PingResponse {
        pingResponseToReturn ?? .pingResponseWithAdsAndValidNextTime
    }
}
