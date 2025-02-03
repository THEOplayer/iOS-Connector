//
//  File.swift
//  
//
//  Created by Khalid, Yousif on 31/1/2025.
//

import Foundation
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

// TODO: To be modified later when Ad scheduling tests are written
class ServerSideAdIntegrationControllerProxy: ServerSideAdIntegrationControllerProxyProtocol {
    // We really need to make sure this is set before any of the calls happen,
    // which is guaranteed technically with the way we dependency inject it
    // to the connector.
    var playerController: THEOplayerSDK.ServerSideAdIntegrationController!
    
    func setPlayerController(controller: ServerSideAdIntegrationController) {
        playerController = controller
    }
    
    var integration: String {
        playerController.integration
    }
    
    var ads: [Ad] {
        playerController.ads
    }
    
    var adBreaks: [AdBreak] {
        playerController.adBreaks
    }
    
    func createAd(params: AdInit, adBreak: (AdBreak)?) -> Ad {
        playerController.createAd(params: params, adBreak: adBreak)
    }
    
    func updateAd(ad: Ad, params: AdInit) {
        playerController.updateAd(ad: ad, params: params)
    }
    
    func updateAdProgress(ad: Ad, progress: Double) {
        playerController.updateAdProgress(ad: ad, progress: progress)
    }
    
    func beginAd(ad: Ad) {
        playerController.beginAd(ad: ad)
    }
    
    func endAd(ad: Ad) {
        playerController.endAd(ad: ad)
    }
    
    func skipAd(ad: Ad) {
        playerController.skipAd(ad: ad)
    }
    
    func removeAd(ad: Ad) {
        playerController.removeAd(ad: ad)
    }
    
    func createAdBreak(params: AdBreakInit) -> AdBreak {
        playerController.createAdBreak(params: params)
    }
    
    func updateAdBreak(adBreak: AdBreak, params: AdBreakInit) {
        playerController.updateAdBreak(adBreak: adBreak, params: params)
    }
    
    func removeAdBreak(adBreak: AdBreak) {
        playerController.removeAdBreak(adBreak: adBreak)
    }
    
    func removeAllAds() {
        playerController.removeAllAds()
    }
    
    func error(error: Error) {
        playerController.error(error: error)
    }
    
    func fatalError(error: Error, code: THEOErrorCode?) {
        playerController.fatalError(error: error, code: code)
    }
}
