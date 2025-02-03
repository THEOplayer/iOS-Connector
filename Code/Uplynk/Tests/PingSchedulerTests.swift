//
//  PingSchedulerTests.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import XCTest
@testable import THEOplayerConnectorUplynk

final class PingSchedulerTests: XCTestCase {
    
    private let mockUplynkApiType = UplynkAPIMock.self
    private let mockPrefix: String = "https://content-aaps1.uplynk.com"
    private let mockSessionId: String = "5633bc226a084e34a69ac6e154d03171"
    private var mockUrlBuilder: MockUplynkSSAIURLBuilder!
    private var mockEventListener: UplynkEventListenerMock!
    private var mockServerSideAdIntegrationController: MockServerSideAdIntegrationController!

    private var pingScheduler: PingScheduler!
    private var adScheduler: AdScheduler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        adScheduler = AdScheduler(adBreaks: [])
        mockUrlBuilder = MockUplynkSSAIURLBuilder(ssaiConfiguration: .vodConfig)
        mockEventListener = UplynkEventListenerMock()
        mockServerSideAdIntegrationController = MockServerSideAdIntegrationController()
        pingScheduler = PingScheduler(urlBuilder: mockUrlBuilder,
                                      prefix: mockPrefix,
                                      sessionId: mockSessionId,
                                      controller: mockServerSideAdIntegrationController,
                                      listener: mockEventListener,
                                      adScheduler: adScheduler,
                                      uplynkApiType: mockUplynkApiType)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        pingScheduler = nil
        mockEventListener = nil
        mockServerSideAdIntegrationController = nil
        mockUplynkApiType.reset()
    }
    
    func testOnTimeUpdateWhenNextRequestTimeIsNil() {
        pingScheduler.onTimeUpdate(time: 0.0)
        
        XCTAssertEqual(mockUrlBuilder.events, [])
    }
    
    func testOnTimeUpdateWhenNextRequestTimeIsMinusOne() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockUplynkApiType.pingResponseToReturn = .pingResponseWithoutAdsWithNoNextTime
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithoutAdsWithNoNextTime)
            onStartExpectation.fulfill()
        }
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)
        
        // When
        pingScheduler.onTimeUpdate(time: 120.0)
        
        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0)
        ])
    }
    
    func testOnTimeUpdateWhenCurrentTimeIsLessThanNextRequestTime() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithAdsAndValidNextTime)
            onStartExpectation.fulfill()
        }
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)

        // When
        pingScheduler.onTimeUpdate(time: 120.0)
        
        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0)
        ])
    }
    
    func testOnTimeUpdateWhenCurrentTimeIsGreaterThanNextRequestTime() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithAdsAndValidNextTime)
            onStartExpectation.fulfill()
        }

        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)

        // When
        let onTimeUpdateExpectation = expectation(description: "Received ping response on time update")
        let newPingResponse = PingResponse(nextTime: -1, ads: nil, extensions: nil, error: nil)
        mockUplynkApiType.pingResponseToReturn = newPingResponse
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, newPingResponse)
            onTimeUpdateExpectation.fulfill()
        }

        pingScheduler.onTimeUpdate(time: 431.0)
        wait(for: [onTimeUpdateExpectation], timeout: 5.0)

        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0),
            .buildPingURL(prefix: "https://content-aaps1.uplynk.com",
                          sessionID: "5633bc226a084e34a69ac6e154d03171",
                          currentTimeSeconds: 431)
        ])
    }
    
    func testOnStart() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithAdsAndValidNextTime)
            onStartExpectation.fulfill()
        }

        // When
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)

        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                                sessionID: "5633bc226a084e34a69ac6e154d03171",
                                currentTimeSeconds: 0)
        ])
    }
    
    func testOnSeekedWhenPingIsSetToStop() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockUplynkApiType.pingResponseToReturn = .pingResponseWithoutAdsWithNoNextTime
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithoutAdsWithNoNextTime)
            onStartExpectation.fulfill()
        }

        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)
        
        pingScheduler.onSeeking(time: 200)
        
        // When
        pingScheduler.onSeeked(time: 400)
        
        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0)
        ])
    }
    
    func testOnSeekedWhenThereIsNoSeekInProgress() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockUplynkApiType.pingResponseToReturn = .pingResponseWithoutAdsWithNoNextTime
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithoutAdsWithNoNextTime)
            onStartExpectation.fulfill()
        }

        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)
        
        // When
        pingScheduler.onSeeked(time: 400)
        
        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0)
        ])
    }
    
    func testOnSeekedWhenThereIsSeekInProgress() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockUplynkApiType.pingResponseToReturn = .pingResponseWithAdsAndValidNextTime
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, .pingResponseWithAdsAndValidNextTime)
            onStartExpectation.fulfill()
        }

        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation], timeout: 5.0)
        pingScheduler.onSeeking(time: 200)

        // When
        let onSeekedExpectation = expectation(description: "Received ping response on seek")
        let newPingResponse = PingResponse(nextTime: -1, ads: nil, extensions: nil, error: nil)
        mockUplynkApiType.pingResponseToReturn = newPingResponse
        mockEventListener.pingResponseCallback = {
            XCTAssertEqual($0, newPingResponse)
            onSeekedExpectation.fulfill()
        }
        pingScheduler.onSeeked(time: 400)
        
        // Then
        wait(for: [onSeekedExpectation], timeout: 5.0)
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0),
            .buildSeekedPingURL(prefix: "https://content-aaps1.uplynk.com",
                                sessionID: "5633bc226a084e34a69ac6e154d03171",
                                currentTimeSeconds: 400,
                                seekStartTimeSeconds: 200)
        ])
    }
    
    func testOnStartForPingError() {
        // Given
        let onStartFailExpectation = expectation(description: "Received failure on start")
        mockUplynkApiType.willFailRequestPing = true
        mockEventListener.pingResponseCallback = { _ in
            XCTFail("Should receive error response on ping")
        }

        mockEventListener.errorCallback = { error in
            XCTAssertEqual(error.code, .UPLYNK_ERROR_CODE_PING_REQUEST_FAILED)
            onStartFailExpectation.fulfill()
        }
        
        // When
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartFailExpectation], timeout: 5.0)

        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                                sessionID: "5633bc226a084e34a69ac6e154d03171",
                                currentTimeSeconds: 0)
        ])
        
        switch mockServerSideAdIntegrationController.events.first {
        case .error(error: MockError.mock("mock error")):
            break
        default:
            XCTFail("Unexpected event")
        }
    }
}
