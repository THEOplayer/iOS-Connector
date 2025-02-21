//
//  AdEventsManager.swift
//  UplynkExample
//
//  Created by Raveendran, Aravind on 11/2/2025.
//

import Foundation
import THEOplayerSDK
import os

extension ViewController {
    
    func addAdsEventListeners() {
        listeners["ADD_AD_BREAK"] = player.ads.addEventListener(type: AdsEventTypes.ADD_AD_BREAK) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Add Ad Break Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--> scheduled ad breaks are \(String(describing: self?.player.ads.scheduledAdBreaks))")
            os_log("--------------------------------------->")
        }
        
        listeners["REMOVE_AD_BREAK"] = player.ads.addEventListener(type: AdsEventTypes.REMOVE_AD_BREAK) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Remove Ad Break Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--> scheduled ad breaks are \(String(describing: self?.player.ads.scheduledAdBreaks))")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_BREAK_BEGIN"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_BEGIN) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Ad break begin Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--> current ads \(String(describing: self?.player.ads.currentAds))")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_BREAK_END"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_END) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Ad break end Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--> current ads \(String(describing: self?.player.ads.currentAds))")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_BREAK_CHANGE"] = player.ads.addEventListener(type: AdsEventTypes.AD_BREAK_CHANGE) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Ad break change Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--------------------------------------->")
        }
        
        listeners["UPDATE_AD_BREAK"] = player.ads.addEventListener(type: AdsEventTypes.UPDATE_AD_BREAK) { [weak self] in
            os_log("--------------------------------------->")
            os_log("--> Ad Break Update Event occured: \($0)")
            os_log("--> current ad break is \(String(describing: self?.player.ads.currentAdBreak))")
            os_log("--> current ads \(String(describing: self?.player.ads.currentAds))")
            os_log("--------------------------------------->")
        }
        
        listeners["ADD_AD"] = player.ads.addEventListener(type: AdsEventTypes.ADD_AD) {
            os_log("--------------------------------------->")
            os_log("--> Add Ad Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_BEGIN"] = player.ads.addEventListener(type: AdsEventTypes.AD_BEGIN) {
            os_log("--------------------------------------->")
            os_log("--> Ad Begin Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["UPDATE_AD"] = player.ads.addEventListener(type: AdsEventTypes.UPDATE_AD) {
            os_log("--------------------------------------->")
            os_log("--> Ad Update Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_FIRST_QUARTILE"] = player.ads.addEventListener(type: AdsEventTypes.AD_FIRST_QUARTILE) {
            os_log("--------------------------------------->")
            os_log("--> Ad First Quartile Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_MIDPOINT"] = player.ads.addEventListener(type: AdsEventTypes.AD_MIDPOINT) {
            os_log("--------------------------------------->")
            os_log("--> Ad Mid Point Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_THIRD_QUARTILE"] = player.ads.addEventListener(type: AdsEventTypes.AD_THIRD_QUARTILE) {
            os_log("--------------------------------------->")
            os_log("--> Ad Third Quartile Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_END"] = player.ads.addEventListener(type: AdsEventTypes.AD_END) {
            os_log("--------------------------------------->")
            os_log("--> Ad End Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_LOADED"] = player.ads.addEventListener(type: AdsEventTypes.AD_LOADED) {
            os_log("--------------------------------------->")
            os_log("--> Ad Loaded Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_IMPRESSION"] = player.ads.addEventListener(type: AdsEventTypes.AD_IMPRESSION) {
            os_log("--------------------------------------->")
            os_log("--> Ad Impresssion Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_ERROR"] = player.ads.addEventListener(type: AdsEventTypes.AD_ERROR) {
            os_log("--------------------------------------->")
            os_log("--> Ad Error Event occured: \($0.error ?? "")")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_SKIP"] = player.ads.addEventListener(type: AdsEventTypes.AD_SKIP) {
            os_log("--------------------------------------->")
            os_log("--> Ad Skip Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_TAPPED"] = player.ads.addEventListener(type: AdsEventTypes.AD_TAPPED) {
            os_log("--------------------------------------->")
            os_log("--> Ad Tapped Event occured: \($0)")
            os_log("--------------------------------------->")
        }
        
        listeners["AD_CLICKED"] = player.ads.addEventListener(type: AdsEventTypes.AD_CLICKED) {
            os_log("--------------------------------------->")
            os_log("--> Ad Clicked Event occured: \($0)")
            os_log("--------------------------------------->")
        }
    }
}
