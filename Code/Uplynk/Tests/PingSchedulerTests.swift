//
//  PingSchedulerTests.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Combine
import XCTest
@testable import THEOplayerConnectorUplynk

final class PingSchedulerTests: XCTestCase {
    
    private let mockUplynkApiType = UplynkAPIMock.self
    private let mockPrefix: String = "https://content-aaps1.uplynk.com"
    private let mockSessionId: String = "5633bc226a084e34a69ac6e154d03171"
    private var mockUrlBuilder: MockUplynkSSAIURLBuilder!
    private var mockEventDispatcher: MockUplynkEventDispatcher!
    private var cancellables: Set<AnyCancellable> = []

    private var pingScheduler: PingScheduler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUrlBuilder = MockUplynkSSAIURLBuilder(ssaiConfiguration: .vodConfig)
        mockEventDispatcher = MockUplynkEventDispatcher()
        pingScheduler = PingScheduler(uplynkApiType: mockUplynkApiType,
                                      urlBuilder: mockUrlBuilder,
                                      prefix: mockPrefix,
                                      sessionId: mockSessionId)
        pingScheduler.eventDispatcher = mockEventDispatcher
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        pingScheduler = nil
        mockUplynkApiType.pingResponseToReturn = nil
        cancellables.removeAll()
    }
    
    func testOnTimeUpdateWhenNextRequestTimeIsNil() {
        pingScheduler.onTimeUpdate(time: 0.0)
        
        XCTAssertEqual(mockUrlBuilder.events, [])
    }
    
    func testOnTimeUpdateWhenNextRequestTimeIsMinusOne() {
        // Given
        let onStartExpectation = expectation(description: "Received ping response on start")
        mockUplynkApiType.pingResponseToReturn = .pingResponseWithoutAdsWithNoNextTime
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithoutAdsWithNoNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])
        
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
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithAdsAndValidNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])

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
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithAdsAndValidNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])

        // When
        let onTimeUpdateExpectation = expectation(description: "Received ping response on time update")
        let newPingResponse = PingResponse(nextTime: -1, ads: nil, extensions: nil, error: nil)
        mockUplynkApiType.pingResponseToReturn = newPingResponse
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(newPingResponse))
                onTimeUpdateExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onTimeUpdate(time: 431.0)
        wait(for: [onTimeUpdateExpectation])

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
        pingScheduler.onStart(time: 0.0)
        
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
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithoutAdsWithNoNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])
        
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
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithoutAdsWithNoNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])
        
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
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(.pingResponseWithAdsAndValidNextTime))
                onStartExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onStart(time: 0.0)
        wait(for: [onStartExpectation])
        pingScheduler.onSeeking(time: 200)

        // When
        let onSeekedExpectation = expectation(description: "Received ping response on seek")
        let newPingResponse = PingResponse(nextTime: -1, ads: nil, extensions: nil, error: nil)
        mockUplynkApiType.pingResponseToReturn = newPingResponse
        mockEventDispatcher.eventSubject
            .prefix(1)
            .sink {
                XCTAssertEqual($0, .dispatchPingEvent(newPingResponse))
                onSeekedExpectation.fulfill()
            }
            .store(in: &cancellables)
        pingScheduler.onSeeked(time: 400)
        
        // Then
        XCTAssertEqual(mockUrlBuilder.events, [
            .buildStartPingURL(prefix: "https://content-aaps1.uplynk.com",
                               sessionID: "5633bc226a084e34a69ac6e154d03171",
                               currentTimeSeconds: 0),
            .buildSeekedPingURL(prefix: "https://content-aaps1.uplynk.com",
                                sessionID: "5633bc226a084e34a69ac6e154d03171",
                                currentTimeSeconds: 400,
                                seekStartTimeSeconds: 200)
        ])
        wait(for: [onSeekedExpectation])
    }
}
