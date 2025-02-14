//
//  MockAdScheduler.swift
//  
//
//  Created by Raveendran, Aravind on 14/2/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

final class MockAdScheduler: AdSchedulerProtocol {
    var isPlayingAd: Bool = false
    var isPlayingLastAdInAdBreak: Bool = false
    var currentAdStartTime: Double?
    var currentAdEndTime: Double?
    var currentAdBreakStartTime: Double?
    var currentAdBreakEndTime: Double?
    
    func onTimeUpdate(time: Double) {
        
    }
    
    func add(ads: UplynkAds) {
        
    }
    
    var adBreakOffsetToReturnIfAdBreakContains: Double?
    func adBreakOffsetIfAdBreakContains(time: Double) -> Double? {
        adBreakOffsetToReturnIfAdBreakContains
    }
    
    var adBreakEndTimeToReturnIfAdBreakContains: Double?
    func adBreakEndTimeIfAdBreakContains(time: Double) -> Double? {
        adBreakEndTimeToReturnIfAdBreakContains
    }
    
    var firstUnwatchedAdBreakOffsetToReturn: Double?
    func firstUnwatchedAdBreakOffset(before time: Double) -> Double? {
        firstUnwatchedAdBreakOffsetToReturn
    }
    
    var lastUnwatchedAdBreakOffsetToReturn: Double?
    func lastUnwatchedAdBreakOffset(before time: Double) -> Double? {
        lastUnwatchedAdBreakOffsetToReturn
    }
}
