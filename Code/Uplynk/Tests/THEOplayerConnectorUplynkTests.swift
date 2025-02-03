//
//  THEOplayerConnectorUplynkTests.swift
//  THEOplayerConnectorUplynkTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import XCTest
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

final class THEOplayerConnectorUplynkTests: XCTestCase {
    var mockEventListener: UplynkEventListenerMock!
    var proxySSAIController: ServerSideAdIntegrationControllerProxy!
    var uplynkAPI: UplynkAPIMock.Type!
    var source: TypedSource!
    var connector: UplynkConnector!
    var theoplayer: THEOplayer!
    override func setUpWithError() throws {
        uplynkAPI = UplynkAPIMock.self
        mockEventListener = UplynkEventListenerMock()
        proxySSAIController = ServerSideAdIntegrationControllerProxy()
        theoplayer = THEOplayer(with: nil, configuration: nil)
        source = TypedSource(
            src: "whatever",
            type: "application/x-mpegurl"
        )
        executionTimeAllowance = 1 // 1 minute?
    }

    override func tearDownWithError() throws {
        uplynkAPI.reset()
        mockEventListener = nil
        connector = nil
        proxySSAIController = nil
        source = nil
        theoplayer = nil
    }

    func setSourceSendsValidPrePlayResponseEvent(type: UplynkSSAIConfiguration.AssetType) async {
        let expectation = XCTestExpectation(description: "Valid PrePlay Response is sent")
        connector = UplynkConnector(player: theoplayer, proxyController: proxySSAIController!, uplynkAPI: uplynkAPI, eventListener: mockEventListener)
        
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
        
        theoplayer.source = SourceDescription(source: source)
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
        connector = UplynkConnector(player: theoplayer, proxyController: proxySSAIController!, uplynkAPI: uplynkAPI, eventListener: mockEventListener)
        
        mockEventListener.preplayErrorCallback = { error in
            XCTAssertTrue(error.url.contains("preplay"))
            XCTAssertEqual(error.code, .UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED)
            expectation.fulfill()
        }
        
        source.ssai = UplynkSSAIConfiguration(
            assetIDs: ["123"], externalIDs: [], assetType: .asset)
        
        theoplayer.source = SourceDescription(source: source)
        await fulfillment(of: [expectation])
    }
}
