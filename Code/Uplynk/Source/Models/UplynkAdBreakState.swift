//
//  UplynkAdBreakState.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

enum AdState: Equatable {
    case notPlayed
    case started
    case completed
}

enum AdBreakState: Equatable {
    case notPlayed
    case started
    case completed
}

class UplynkAdState {
    let ad: UplynkAd
    var state: AdState
    init(ad: UplynkAd, state: AdState) {
        self.ad = ad
        self.state = state
    }
}

class UplynkAdBreakState {
    let adBreak: UplynkAdBreak
    var state: AdBreakState
    var ads: [UplynkAdState] {
        adBreak.ads.map { UplynkAdState(ad: $0, state: AdState.notPlayed) }
    }
    init(adBreak: UplynkAdBreak, state: AdBreakState) {
        self.state = state
        self.adBreak = adBreak
    }
}

extension UplynkAdBreakState: Equatable {
    static func == (lhs: UplynkAdBreakState, rhs: UplynkAdBreakState) -> Bool {
        return lhs.state == rhs.state && lhs.adBreak == rhs.adBreak
    }
}

extension UplynkAdState: Equatable {
    static func == (lhs: UplynkAdState, rhs: UplynkAdState) -> Bool {
        return lhs.ad == rhs.ad && lhs.state == rhs.state
    }
}
