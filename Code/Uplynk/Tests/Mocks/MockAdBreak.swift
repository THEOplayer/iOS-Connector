//
//  MockAdBreak.swift
//
//
//  Created by Raveendran, Aravind on 4/2/2025.
//

import Foundation
import THEOplayerSDK

struct MockAdBreak: AdBreak {
    let id: String? = UUID().uuidString
    var ads: [Ad] = []
    var maxDuration: Int = 0
    var maxRemainingDuration: Double = 0
    var timeOffset: Int = 0
    var integration: AdIntegrationKind = .theoads
    var customIntegration: String?
}

struct MockAd: Ad {
    let isSlate = false
    var adBreak: AdBreak? = MockAdBreak()
    var companions: [CompanionAd] = []
    var type: String = ""
    var id: String?
    var skipOffset: Int?
    var resourceURI: String?
    var width: Int?
    var height: Int?
    var integration: AdIntegrationKind = .theoads
    var duration: Int?
    var clickThrough: String?
    var customIntegration: String?
}
