//
//  AdSchedulerTests.swift
//  
//
//  Created by Raveendran, Aravind on 4/2/2025.
//

import XCTest
@testable import THEOplayerConnectorUplynk

final class AdSchedulerTests: XCTestCase {

    private var mockAdHandler: MockAdHandler!
    private var adScheduler: AdScheduler!

    override func setUpWithError() throws {
        mockAdHandler = MockAdHandler()
    }

    override func tearDownWithError() throws {
        mockAdHandler = nil
        adScheduler = nil
    }

    func testInitForAdScheduler() {
        let adBreak = UplynkAdBreak.mock
        adScheduler = AdScheduler(adBreaks: [adBreak],
                                  adHandler: mockAdHandler)
        
        XCTAssertEqual(mockAdHandler.events, [
            .createAdBreak(adBreak: adBreak)
        ])
    }
    
    func testOnTimeUpdate() {
        let adBreak = UplynkAdBreak.mock
        adScheduler = AdScheduler(adBreaks: [adBreak],
                                  adHandler: mockAdHandler)
        adScheduler.onTimeUpdate(time: 50)
        
        XCTAssertEqual(mockAdHandler.events,
                       [
                        .createAdBreak(adBreak: adBreak),
                        .onAdBegin(uplynkAd: adBreak.ads[0])
                       ])
        
        adScheduler.onTimeUpdate(time: 55)

        XCTAssertEqual(
            mockAdHandler.events[2],
            .onAdProgressUpdate(currentAd: UplynkAdState(ad: adBreak.ads[0], state: .started),
                                adBreak: adBreak,
                                time: 55)
        )
        
        adScheduler.onTimeUpdate(time: 58)

        XCTAssertEqual(
            mockAdHandler.events[3],
            .onAdEnd(uplynkAd: adBreak.ads[0])
        )
    }
}
