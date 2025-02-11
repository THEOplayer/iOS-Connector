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
    var uplynkAPI: UplynkAPIMock.Type!
    var source: TypedSource!
    var integration: UplynkAdIntegration!
    var player: THEOplayer!
    override func setUpWithError() throws {
        uplynkAPI = UplynkAPIMock.self
        mockEventListener = UplynkEventListenerMock()
        source = TypedSource(
            src: "whatever",
            type: "application/x-mpegurl"
        )
        player = .init()
        executionTimeAllowance = 1 // 1 minute?
    }

    override func tearDownWithError() throws {
        uplynkAPI.reset()
        mockEventListener = nil
        source = nil
        player = nil
    }

    func setSourceSendsValidPrePlayResponseEvent(type: UplynkSSAIConfiguration.AssetType) async {
        let expectation = XCTestExpectation(description: "Valid PrePlay Response is sent")
        
        integration = UplynkAdIntegration(uplynkAPI: uplynkAPI, player: player, controller: MockServerSideAdIntegrationController(), configuration: .init(), eventListener: mockEventListener)
        
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
        
        source.ssai = UplynkSSAIConfiguration(
            assetIDs: ["123"], externalIDs: [], assetType: type)
        
        XCTAssertTrue(integration.setSource(source: SourceDescription(source: source)))
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
        uplynkAPI.willFailRequestVOD = true
        integration = UplynkAdIntegration(uplynkAPI: uplynkAPI, player: player, controller: MockServerSideAdIntegrationController(), configuration: .init(), eventListener: mockEventListener)
        
        mockEventListener.errorCallback = { error in
            XCTAssertTrue(error.url.contains("preplay"))
            XCTAssertEqual(error.code, .UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED)
            expectation.fulfill()
        }
        
        source.ssai = UplynkSSAIConfiguration(
            assetIDs: ["123"], externalIDs: [], assetType: .asset)
        
        XCTAssertTrue(integration.setSource(source: SourceDescription(source: source)))
        await fulfillment(of: [expectation])
    }
}
