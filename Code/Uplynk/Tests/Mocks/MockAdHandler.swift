//
//  MockAdHandler.swift
//
//
//  Created by Raveendran, Aravind on 4/2/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

final class MockAdHandler: AdHandlerProtocol {
    enum Event: Equatable {
        case createAdBreak(adBreak: UplynkAdBreak)
        case onAdBegin(uplynkAd: UplynkAd)
        case onAdEnd(uplynkAd: UplynkAd)
        case onAdProgressUpdate(currentAd: UplynkAdState, adBreak: UplynkAdBreak, time: Double)
    }
    private(set) var events: [Event] = []
    func createAdBreak(adBreak: UplynkAdBreak) {
        events.append(.createAdBreak(adBreak: adBreak))
    }
    
    func onAdBegin(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak) {
        events.append(.onAdBegin(uplynkAd: uplynkAd))
    }
    
    func onAdEnd(uplynkAd: UplynkAd, in adBreak: UplynkAdBreak) {
        events.append(.onAdEnd(uplynkAd: uplynkAd))
    }
    
    func onAdProgressUpdate(currentAd: UplynkAdState,
                            adBreak: UplynkAdBreak,
                            time: Double) {
        events.append(.onAdProgressUpdate(currentAd: currentAd, adBreak: adBreak, time: time))
    }
}
