//
//  UplynkAdBreakState.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//

import Foundation

struct UplynkAdBreakState {
    let adBreak: UplynkAdBreak
    let state: AdBreakState
    var ads: [UplynkAdState] {
        adBreak.ads.map { UplynkAdState(ad: $0, state: AdState.notPlayed) }
    }
}

struct UplynkAdState {
    let ad: UplynkAd
    let state: AdState
}

enum AdState {
    case notPlayed
    case started
    case completed
}

enum AdBreakState {
    case notPlayed
    case started
    case completed
}
