//
//  UplynkAdIntegrationTests.swift
//  UplynkAdIntegrationTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import XCTest
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

@MainActor
final class UplynkAdIntegrationTests: XCTestCase {
    var mockEventListener: UplynkEventListenerMock!
    var mockUplynkAPI: UplynkAPIMock.Type!
    var mockSource: TypedSource!
    var mockPlayer: MockPlayer!
    var mockController: MockServerSideAdIntegrationController!
    var mockUplynkConfiguration: UplynkConfiguration!
    var mockAdHandler: MockAdHandler!
    var mockAdHandlerFactory: MockAdHandlerFactory.Type!
    var mockAdScheduler: MockAdScheduler!
    var mockAdSchedulerFactory: MockAdSchedulerFactory.Type!

    var integration: UplynkAdIntegration!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUplynkAPI = UplynkAPIMock.self
        mockEventListener = UplynkEventListenerMock()
        mockPlayer = MockPlayer()
        mockSource = TypedSource(
            src: "whatever",
            type: "application/x-mpegurl"
        )
        mockController = MockServerSideAdIntegrationController()
        mockUplynkConfiguration = UplynkConfiguration()
        mockAdHandler = MockAdHandler()
        mockAdScheduler = MockAdScheduler()
        mockAdHandlerFactory = MockAdHandlerFactory.self
        mockAdHandlerFactory.mockAdHandler = mockAdHandler
        mockAdSchedulerFactory = MockAdSchedulerFactory.self
        mockAdSchedulerFactory.mockAdScheduler = mockAdScheduler

        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        mockUplynkAPI.reset()
        mockEventListener = nil
        mockPlayer = nil
        mockSource = nil
        mockController = nil
        mockUplynkConfiguration = nil
        mockAdHandler = nil
        mockAdScheduler = nil
        mockAdHandlerFactory.reset()
        mockAdSchedulerFactory.reset()

        integration = nil
    }

    func setSourceSendsValidPrePlayResponseEvent(type: UplynkSSAIConfiguration.AssetType) async {
        let expectation = XCTestExpectation(description: "Valid PrePlay Response is sent")
                
        switch type {
        case .asset:
            mockEventListener.preplayVODResponseCallback = { _ in
                expectation.fulfill()
            }
        case .channel:
            mockEventListener.preplayLiveResponseCallback = { _ in
                expectation.fulfill()
            }
        }
        
        mockSource.ssai = UplynkSSAIConfiguration(
            assetIDs: ["123"], externalIDs: [], assetType: type)
        
        XCTAssertTrue(integration.setSource(source: SourceDescription(source: mockSource)))
        await fulfillment(of: [expectation])
    }
    
    func testSetSourceSendsValidPrePlayVODResponseEvent() async throws {
        await setSourceSendsValidPrePlayResponseEvent(type: .asset)
    }
    
    func testSetSourceSendsValidPrePlayLiveResponseEvent() async throws {
        await setSourceSendsValidPrePlayResponseEvent(type: .channel)
    }
    
    func testSetSourceSendsErrorOnNetworkError() async throws {
        let expectation = XCTestExpectation(description: "Error response is sent")
        mockUplynkAPI.willFailRequestVOD = true
        
        mockEventListener.errorCallback = { error in
            XCTAssertTrue(error.url.contains("preplay"))
            XCTAssertEqual(error.code, .UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED)
            expectation.fulfill()
        }
        
        mockSource.ssai = UplynkSSAIConfiguration(
            assetIDs: ["123"], externalIDs: [], assetType: .asset)
        
        XCTAssertTrue(integration.setSource(source: SourceDescription(source: mockSource)))
        await fulfillment(of: [expectation])
    }
    
    func testSeekingOverAdBreakForStrategyPlayNone() async {
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [], 
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 10
        let seekEvent = SeekedEvent(currentTime: 10, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 10)
    }
    
    func testSeekingOnAdBreakForStrategyPlayNone() async {
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 10
        mockAdScheduler.adBreakEndTimeToReturnIfAdBreakContains = 15.0
        let seekEvent = SeekedEvent(currentTime: 10, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 15.0)
    }
    
    func testSeekingOverAdBreakForStrategyPlayAllWhenThereIsAnUnWatchedAd() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playAll)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 20
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 5.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 5.0)
    }
    
    func testSeekingOnAdBreakForStrategyPlayAllWhenThereIsAnUnWatchedAd() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playAll)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 20
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 20.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 20.0)
    }
    
    func testSeekingOverAdBreakForStrategyPlayLastWhenThereIsAnUnWatchedAd() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playLast)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 20
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 10.0
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = 10.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 10.0)
    }
    
    func testSeekingOnAdBreakForStrategyPlayLastWhenThereIsNoUnwatchedAd() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playLast)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 20
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 10.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 10.0)
    }
    
    func testTimeUpdatesWhenPlayingSeekedOverAdBreakForStrategyPlayAll() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playAll)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 100
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 20.0
        let seekEvent = SeekedEvent(currentTime: 100, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 20.0)
        
        // Time update to 30 sec
        // Continuing to playing ad
        mockPlayer.currentTime = 30
        mockAdScheduler.isPlayingAd = true
        let timeUpdateEvent = TimeUpdateEvent(currentTime: 30, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent)
        XCTAssertEqual(mockPlayer.currentTime, 30.0)
        
        // Time update to 40 sec
        // Finished playing ad
        mockPlayer.currentTime = 40
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 50.0
        let timeUpdateEvent2 = TimeUpdateEvent(currentTime: 40, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent2)
        XCTAssertEqual(mockPlayer.currentTime, 50.0)
        
        // Time update to 60 sec
        // Finished playing all unwatched ads
        // This should seek over to the original seek point requested by the user
        mockPlayer.currentTime = 60
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = nil
        let timeUpdateEvent3 = TimeUpdateEvent(currentTime: 60, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent3)
        XCTAssertEqual(mockPlayer.currentTime, 100.0)
    }
    
    func testTimeUpdatesWhenPlayingSeekedOverAdBreakForStrategyPlayAllAndSeekedPositionIsOnTheLastUnwatchedAdBreak() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playAll)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 100
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 20.0
        let seekEvent = SeekedEvent(currentTime: 100, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 20.0)
        
        // Time update to 30 sec
        // Continuing to playing ad
        mockPlayer.currentTime = 30
        mockAdScheduler.isPlayingAd = true
        let timeUpdateEvent = TimeUpdateEvent(currentTime: 30, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent)
        XCTAssertEqual(mockPlayer.currentTime, 30.0)
        
        // Time update to 40 sec
        // Finished playing ad
        mockPlayer.currentTime = 40
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 50.0
        let timeUpdateEvent2 = TimeUpdateEvent(currentTime: 40, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent2)
        XCTAssertEqual(mockPlayer.currentTime, 50.0)
        
        // Time update to 60 sec
        // Playing next unwatched adbreak
        mockPlayer.currentTime = 60
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 80.0
        let timeUpdateEvent3 = TimeUpdateEvent(currentTime: 80, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent3)
        XCTAssertEqual(mockPlayer.currentTime, 80.0)
        
        // Time update to 85 sec
        // Playing next unwatched adbreak
        mockPlayer.currentTime = 85
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 90.0
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 90.0
        let timeUpdateEvent4 = TimeUpdateEvent(currentTime: 85, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent4)
        XCTAssertEqual(mockPlayer.currentTime, 90.0)
        
        // Time update to 105 sec
        // Finished playing ad
        mockPlayer.currentTime = 105
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 90.0
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = nil
        let timeUpdateEvent5 = TimeUpdateEvent(currentTime: 105, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent5)
        XCTAssertEqual(mockPlayer.currentTime, 105)
    }
    
    func testTimeUpdatesWhenPlayingSeekedOverAdBreakForStrategyPlayLast() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playLast)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockPlayer.currentTime = 100
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = 20.0
        let seekEvent = SeekedEvent(currentTime: 100, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 20.0)
        
        // Time update to 30 sec
        // Continuing to playing ad
        mockPlayer.currentTime = 30
        mockAdScheduler.isPlayingAd = true
        let timeUpdateEvent = TimeUpdateEvent(currentTime: 30, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent)
        XCTAssertEqual(mockPlayer.currentTime, 30.0)
        
        // Time update to 40 sec
        // Finished playing ad
        mockPlayer.currentTime = 40
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = nil
        let timeUpdateEvent2 = TimeUpdateEvent(currentTime: 40, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent2)
        XCTAssertEqual(mockPlayer.currentTime, 100.0)
    }
    
    func testTimeUpdatesWhenPlayingSeekedOverAdBreakForStrategyPlayLastAndSeekedPositionIsOnTheLastUnwatchedAdBreak() async {
        mockUplynkConfiguration = UplynkConfiguration(skippedAdStrategy: .playLast)
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let result = integration.setSource(source: SourceDescription(source: mockSource))
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 40.0
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = 40.0
        mockPlayer.currentTime = 50
        let seekEvent = SeekedEvent(currentTime: 50, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 40.0)
        
        // Time update to 55 sec
        // Continuing to playing ad
        mockPlayer.currentTime = 55
        mockAdScheduler.isPlayingAd = true
        let timeUpdateEvent = TimeUpdateEvent(currentTime: 55, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent)
        XCTAssertEqual(mockPlayer.currentTime, 55.0)
        
        // Time update to 60 sec
        // Finished playing ad
        mockPlayer.currentTime = 60
        mockAdScheduler.isPlayingAd = false
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = nil
        let timeUpdateEvent2 = TimeUpdateEvent(currentTime: 60, currentProgramDateTime: Date(), date: Date())
        mockPlayer.timeUpdateListener?(timeUpdateEvent2)
        XCTAssertEqual(mockPlayer.currentTime, 60.0)
    }
    
    // Covers SkipAd for a normal playback (not a seeked over ad)
    func testSkipAdBreakWhenPlayingAdBreakInANormalFlowWhereSkipOffsetIsNotReached() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playNone)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        mockAdScheduler.currentAdBreakStartTime = 10.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 11.0
        
        // When
        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources)
        ])
    }
    
    func testSkipAdBreakWhenPlayingAdBreakInANormalFlowWhereSkipOffsetHasReached() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playNone)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        mockAdScheduler.currentAdBreakStartTime = 10.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 12.0
        
        // When
        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources),
            .setCurrentTime(15.0)
        ])
    }
    
    func testSkipAdBreakWhenPlayingSeekedOverAdBreakWithStrategyPlayAll() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playAll)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])

        // When
        mockPlayer.currentTime = 20
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 5.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 5.0)
        
        mockAdScheduler.currentAdBreakStartTime = 5.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 8.0
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = nil

        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources),
            .setCurrentTime(5.0),
            .setCurrentTime(20.0)
        ])
    }
    
    func testSkipAdBreakWhenPlayingSeekedOnAdBreakWithStrategyPlayAll() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playAll)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])

        // When
        mockPlayer.currentTime = 20
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = 5.0
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 5.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 5.0)
        
        mockAdScheduler.currentAdBreakStartTime = 5.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 8.0
        mockAdScheduler.firstUnwatchedAdBreakOffsetToReturn = nil

        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources),
            .setCurrentTime(5.0),
            .setCurrentTime(15.0)
        ])
    }
    
    func testSkipAdBreakWhenPlayingSeekedOverAdBreakWithStrategyPlayLast() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playLast)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])

        // When
        mockPlayer.currentTime = 20
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = 5.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 5.0)
        
        mockAdScheduler.currentAdBreakStartTime = 5.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 8.0
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = nil

        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources),
            .setCurrentTime(5.0),
            .setCurrentTime(20.0)
        ])
    }
    
    func testSkipAdBreakWhenPlayingSeekedOnAdBreakWithStrategyPlayLast() async {
        mockUplynkConfiguration = UplynkConfiguration(defaultSkipOffset: 2, skippedAdStrategy: .playLast)
        mockPlayer = MockPlayer()
        integration = UplynkAdIntegration(uplynkAPI: mockUplynkAPI,
                                          player: mockPlayer,
                                          controller: mockController,
                                          configuration: mockUplynkConfiguration,
                                          eventListener: mockEventListener,
                                          adSchedulerFactory: mockAdSchedulerFactory,
                                          adHandlerFactory: mockAdHandlerFactory)
        // Set source
        mockSource.ssai = UplynkSSAIConfiguration(assetIDs: ["123"],
                                                  externalIDs: [],
                                                  assetType: .asset)
        let sourceDescription = SourceDescription(source: mockSource)
        let result = integration.setSource(source: sourceDescription)
        XCTAssertTrue(result)
        let expectation = XCTestExpectation(description: "Receive PrePlay Response")
        mockEventListener.preplayVODResponseCallback = { _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])

        // When
        mockPlayer.currentTime = 20
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = 5.0
        mockAdScheduler.adBreakOffsetToReturnIfAdBreakContains = 5.0
        let seekEvent = SeekedEvent(currentTime: 20, date: Date())
        mockPlayer.seekedListener?(seekEvent)
        XCTAssertEqual(mockPlayer.currentTime, 5.0)
        
        mockAdScheduler.currentAdBreakStartTime = 5.0
        mockAdScheduler.currentAdBreakEndTime = 15.0
        mockPlayer.currentTime = 8.0
        mockAdScheduler.lastUnwatchedAdBreakOffsetToReturn = nil

        let handled = integration.skipAd(ad: MockAd())
        
        // Then
        XCTAssertTrue(handled)
        XCTAssertEqual(mockPlayer.events, [
            .addEventListener(name: "timeupdate"),
            .addEventListener(name: "seeking"),
            .addEventListener(name: "seeked"),
            .addEventListener(name: "play"),
            .setSource(sourceDescription.sources),
            .setCurrentTime(5.0),
            .setCurrentTime(15.0)
        ])
    }
}
