//
//  UplynkServerSideAdIntegrationConfigurationURLBuilderTests.swift
//  THEOplayerConnectorUplynkTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import XCTest
@testable import THEOplayerConnectorUplynk
import RegexBuilder

final class UplynkServerSideAdIntegrationConfigurationURLBuilderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func preplayURLIsCorrectWithNoQueryParameters(assetType: UplynkServerSideAdIntegrationConfiguration.AssetType) {
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        let externalID = "e123"
        let userID = "u123"
        let validLiveWithAssetIDURL = "\(prefix)/preplay\(assetType  == .channel ? "/channel" : "")/\(assetID).json"
        let validLiveWithExternalIDURL = "\(prefix)/preplay\(assetType  == .channel ? "/channel" : "")/ext/\(userID)/\(externalID).json"
        
        let configurationWithAssetID = UplynkServerSideAdIntegrationConfiguration(
            assetIDs: [assetID],
            externalIDs: [],
            assetType: assetType,
            prefix: prefix
        )
        
        let configurationWithExternalID = UplynkServerSideAdIntegrationConfiguration(
            assetIDs: [],
            externalIDs: [externalID],
            assetType: assetType,
            prefix: prefix,
            userID: userID
        )
        
        let (builtURLWithAssetID, builtURLWithExternalID) = switch assetType {
        case .asset:
            (UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL(),
             UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: configurationWithExternalID).buildPreplayVODURL())
        case .channel:
            (UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayLiveURL(),
             UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: configurationWithExternalID).buildPreplayLiveURL())
        }
        XCTAssertTrue(builtURLWithAssetID.starts(with:validLiveWithAssetIDURL))
        XCTAssertTrue(builtURLWithExternalID.starts(with:validLiveWithExternalIDURL))
    }
    
    func testLiveURLIsCorrectWithNoQueryParameters() throws {
        preplayURLIsCorrectWithNoQueryParameters(assetType: .channel)
    }
    
    func testVodURLIsCorrectWithNoQueryParameters() throws {
        preplayURLIsCorrectWithNoQueryParameters(assetType: .asset)
    }
    
    func preplayURLPingQueryParameter(pingFeature: UplynkPingFeatures) {
        
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        let externalID = "e123"
        let userID = "u123"
        
        let validNoPingQueryParameter = "ad.pingc=0"
        let validPingQueryParameter = "ad.pingc=1&ad.pingf=\(pingFeature.rawValue)"
        
        let pingConfiguration = switch pingFeature {
        case .noPing:
            UplynkPingConfiguration()
        case .adImpressions:
            UplynkPingConfiguration(adImpressions: true)
        case .fwVideoViews:
            UplynkPingConfiguration(freeWheelVideoViews: true)
        case .adImpressionsAndFwVideoViews:
            UplynkPingConfiguration(adImpressions: true, freeWheelVideoViews: true)
        case .linearAdData:
            UplynkPingConfiguration(linearAdData: true)
        }
        
        let configurationWithAssetID = UplynkServerSideAdIntegrationConfiguration(
            assetIDs: [assetID],
            externalIDs: [],
            assetType: .asset,
            prefix: prefix,
            uplynkPingConfiguration: pingConfiguration
        )
        
        let builtPreplayURL = UplynkServerSideAdInjectionURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL()
        switch (pingFeature) {
        case .noPing:
            XCTAssertTrue(builtPreplayURL.hasSuffix(validNoPingQueryParameter))
        default:
            XCTAssertTrue(builtPreplayURL.hasSuffix(validPingQueryParameter))
            
        }
    }
    
    func testPreplayURLPingQueryParameter() throws {
        preplayURLPingQueryParameter(pingFeature: .noPing)
        preplayURLPingQueryParameter(pingFeature: .adImpressions)
        preplayURLPingQueryParameter(pingFeature: .fwVideoViews)
        preplayURLPingQueryParameter(pingFeature: .adImpressionsAndFwVideoViews)
        preplayURLPingQueryParameter(pingFeature: .linearAdData)
    }
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
