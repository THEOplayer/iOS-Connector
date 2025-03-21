//
//  MockServerSideAdIntegrationController.swift
//
//
//  Created by Raveendran, Aravind on 3/2/2025.
//

import Foundation
import THEOplayerSDK

final class MockServerSideAdIntegrationController: ServerSideAdIntegrationController {
    var integration: String = "MockServerSideAdIntegrationController"
    var ads: [Ad] = []
    var adBreaks: [AdBreak] = []
    
    enum Event {
        case createAd(params: AdInit, adBreak: (AdBreak)?)
        case updateAd(ad: Ad, params: AdInit)
        case updateAdProgress(ad: Ad, progress: Double)
        case beginAd(ad: Ad)
        case endAd(ad: Ad)
        case skipAd(ad: Ad)
        case removeAd(ad: Ad)
        case createAdBreak(params: AdBreakInit)
        case updateAdBreak(adBreak: AdBreak, params: AdBreakInit)
        case removeAdBreak(adBreak: AdBreak)
        case removeAllAds
        case error(error: Error)
        case fatalError(error: Error, code: THEOErrorCode?)
    }
    private(set) var events: [Event] = []
    
    var adToReturn: MockAd?
    func createAd(params: AdInit, adBreak: (AdBreak)?) -> Ad {
        events.append(.createAd(params: params, adBreak: adBreak))
        return adToReturn ?? MockAd()
    }
    
    func updateAd(ad: Ad, params: AdInit) {
        events.append(.updateAd(ad: ad, params: params))
    }
    
    func updateAdProgress(ad: Ad, progress: Double) {
        events.append(.updateAdProgress(ad: ad, progress: progress))
    }
    
    func beginAd(ad: Ad) {
        events.append(.beginAd(ad: ad))
    }
    
    func endAd(ad: Ad) {
        events.append(.endAd(ad: ad))
    }
    
    func skipAd(ad: Ad) {
        events.append(.skipAd(ad: ad))
    }
    
    func removeAd(ad: Ad) {
        events.append(.removeAd(ad: ad))
    }
    
    var adBreakToReturn: MockAdBreak?
    func createAdBreak(params: AdBreakInit) -> AdBreak {
        events.append(.createAdBreak(params: params))
        return adBreakToReturn ?? MockAdBreak()
    }
    
    func updateAdBreak(adBreak: AdBreak, params: AdBreakInit) {
        events.append(.updateAdBreak(adBreak: adBreak, params: params))
    }
    
    func removeAdBreak(adBreak: AdBreak) {
        events.append(.removeAdBreak(adBreak: adBreak))
    }
    
    func removeAllAds() {
        events.append(.removeAllAds)
    }
    
    func error(error: Error) {
        events.append(.error(error: MockError.mock("mock error")))
    }
    
    func fatalError(error: Error, code: THEOErrorCode?) {
        events.append(.fatalError(error: MockError.mock("mock error"), code: nil))
    }
}
