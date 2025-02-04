//
//  AdHandlerTests.swift
//  
//
//  Created by Raveendran, Aravind on 4/2/2025.
//

import XCTest
@testable import THEOplayerConnectorUplynk

final class AdHandlerTests: XCTestCase {
    
    private var mockController: MockServerSideAdIntegrationController!
    private var adHandler: AdHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockController = MockServerSideAdIntegrationController()
        adHandler = AdHandler(controller: mockController)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockController = nil
        adHandler = nil
    }
    
    func testCreateAdBreak() {
        let adBreak = UplynkAdBreak.mock
        adHandler.createAdBreak(adBreak: adBreak)
        XCTAssertEqual(mockController.events.count, 2)
        
        // Note: AdInit and AdBreakInit
        switch mockController.events[0] {
        case .createAdBreak(params: _):
            break
        default:
            XCTFail("Unexpected event")
        }
        
        switch mockController.events[1] {
        case let .createAd(params: _, adBreak: adBreak):
            XCTAssertEqual(adBreak?.maxDuration, 0)
            XCTAssertEqual(adBreak?.timeOffset, 0)
        default:
            XCTFail("Unexpected event")
        }
    }
    
    func testOnAdBegin() {
        // Given
        let adBreak = UplynkAdBreak.mock
        var adToReturn = MockAd()
        adToReturn.id = "ad-id"
        mockController.adToReturn = adToReturn
        adHandler.createAdBreak(adBreak: adBreak)

        // When
        adHandler.onAdBegin(uplynkAd: adBreak.ads[0])
        
        // Then
        XCTAssertEqual(mockController.events.count, 3)

        switch mockController.events[2] {
        case let .beginAd(ad: ad):
            XCTAssertEqual(ad.id, adToReturn.id)
        default:
            XCTFail("Unexpected event")
        }
    }
    
    func testOnAdEnd() {
        // Given
        let adBreak = UplynkAdBreak.mock
        var adToReturn = MockAd()
        adToReturn.id = "ad-id"
        mockController.adToReturn = adToReturn
        adHandler.createAdBreak(adBreak: adBreak)
        
        // When
        adHandler.onAdEnd(uplynkAd: adBreak.ads[0])
        
        // Then
        XCTAssertEqual(mockController.events.count, 3)
        
        switch mockController.events[2] {
        case let .endAd(ad: ad):
            XCTAssertEqual(ad.id, adToReturn.id)
        default:
            XCTFail("Unexpected event")
        }
    }
    
    func testOnAdProgressUpdateWhenAdHasStarted() {
        // Given
        let adBreak = UplynkAdBreak.mock
        var adToReturn = MockAd()
        adToReturn.id = "ad-id"
        mockController.adToReturn = adToReturn
        adHandler.createAdBreak(adBreak: adBreak)

        // When
        let adState = UplynkAdState(ad: adBreak.ads[0],
                                    state: .started)
        adHandler.onAdProgressUpdate(currentAd: adState,
                                     adBreak: adBreak,
                                     time: 50.0)
        
        // Then
        XCTAssertEqual(mockController.events.count, 3)
        switch mockController.events[2] {
        case let .updateAdProgress(ad: ad, 
                                   progress: progress):
            XCTAssertEqual(ad.id, adToReturn.id)
            XCTAssertEqual(progress, 0.2539480728051393)
        default:
            XCTFail("Unexpected event")
        }
    }
    
    func testOnAdProgressUpdateWhenAdHasNotStarted() {
        // Given
        let adBreak = UplynkAdBreak.mock
        var adToReturn = MockAd()
        adToReturn.id = "ad-id"
        mockController.adToReturn = adToReturn
        adHandler.createAdBreak(adBreak: adBreak)

        // When
        let adState = UplynkAdState(ad: adBreak.ads[0],
                                    state: .notPlayed)
        adHandler.onAdProgressUpdate(currentAd: adState,
                                     adBreak: adBreak,
                                     time: 45.0)
        
        // Then
        XCTAssertEqual(mockController.events.count, 3)
        switch mockController.events[2] {
        case let .updateAdProgress(ad: ad,
                                   progress: progress):
            XCTAssertEqual(ad.id, adToReturn.id)
            XCTAssertEqual(progress, 0)
        default:
            XCTFail("Unexpected event")
        }
    }
    
    func testOnAdProgressUpdateWhenAdHasNotCompleted() {
        // Given
        let adBreak = UplynkAdBreak.mock
        var adToReturn = MockAd()
        adToReturn.id = "ad-id"
        mockController.adToReturn = adToReturn
        adHandler.createAdBreak(adBreak: adBreak)

        // When
        let adState = UplynkAdState(ad: adBreak.ads[0],
                                    state: .notPlayed)
        adHandler.onAdProgressUpdate(currentAd: adState,
                                     adBreak: adBreak,
                                     time: 100.0)
        
        // Then
        XCTAssertEqual(mockController.events.count, 3)
        switch mockController.events[2] {
        case let .updateAdProgress(ad: ad,
                                   progress: progress):
            XCTAssertEqual(ad.id, adToReturn.id)
            XCTAssertEqual(progress, 1.0)
        default:
            XCTFail("Unexpected event")
        }
    }
}
