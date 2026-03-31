//
//  UplynkSSAIConfigurationURLBuilderTests.swift
//  THEOplayerConnectorUplynkTests
//
//  Created by Khalid, Yousif on 30/1/2025.
//

import XCTest
@testable import THEOplayerConnectorUplynk

final class UplynkSSAIConfigurationURLBuilderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func preplayURLIsCorrectWithNoQueryParameters(assetType: UplynkSSAIConfiguration.AssetType) {
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        let externalID = "e123"
        let userID = "u123"
        let validLiveWithAssetIDURL = "\(prefix)/preplay\(assetType  == .channel ? "/channel" : "")/\(assetID).json"
        let validLiveWithExternalIDURL = "\(prefix)/preplay\(assetType  == .channel ? "/channel" : "")/ext/\(userID)/\(externalID).json"
        
        let configurationWithAssetID = UplynkSSAIConfiguration(
            id: .asset(ids: [assetID]),
            assetType: assetType,
            prefix: prefix
        )
        
        let configurationWithExternalID = UplynkSSAIConfiguration(
            id: .external(ids: [externalID], userID: userID),
            assetType: assetType,
            prefix: prefix
        )
        
        let (builtURLWithAssetID, builtURLWithExternalID) = switch assetType {
        case .asset:
            (UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL(),
             UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithExternalID).buildPreplayVODURL())
        case .channel:
            (UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayLiveURL(),
             UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithExternalID).buildPreplayLiveURL())
        }
        XCTAssertTrue(builtURLWithAssetID.starts(with:validLiveWithAssetIDURL))
        XCTAssertTrue(builtURLWithExternalID.starts(with:validLiveWithExternalIDURL))
    }
    
    func testLiveURLIsCorrectWithNoQueryParameters() throws {
        preplayURLIsCorrectWithNoQueryParameters(assetType: .channel)
    }
    
    func testVODURLIsCorrectWithNoQueryParameters() throws {
        preplayURLIsCorrectWithNoQueryParameters(assetType: .asset)
    }
    
    func prePlayURLPingQueryParameter(pingFeature: UplynkPingFeature, assetType: UplynkSSAIConfiguration.AssetType) {
        
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        
        let validNoPingQueryParameter = ""
        let validPingQueryParameter = "ad.cping=1&ad.pingf=\(pingFeature.rawValue)"
        
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
        
        let configurationWithAssetID = UplynkSSAIConfiguration(
            id: .asset(ids: [assetID]),
            assetType: assetType,
            prefix: prefix,
            uplynkPingConfiguration: pingConfiguration
        )
        
        let builtPreplayURL = UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL()
        switch (pingFeature) {
        case .noPing:
            XCTAssertTrue(builtPreplayURL.contains(validNoPingQueryParameter))
        default:
            XCTAssertTrue(builtPreplayURL.contains(validPingQueryParameter))
            
        }
    }
    
    func testPrePlayURLPingQueryParameter() throws {
        prePlayURLPingQueryParameter(pingFeature: .noPing, assetType: .asset)
        prePlayURLPingQueryParameter(pingFeature: .adImpressions, assetType: .asset)
        prePlayURLPingQueryParameter(pingFeature: .fwVideoViews, assetType: .asset)
        prePlayURLPingQueryParameter(pingFeature: .adImpressionsAndFwVideoViews, assetType: .asset)
        // Linear Ad data only works for channel type assets.
        prePlayURLPingQueryParameter(pingFeature: .linearAdData, assetType: .channel)
    }
    
    
    func testPrePlayURLContentProtectionParameters() throws {
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        
        let validDRMParameters = "manifest=m3u8&rmt=fps"
        
        let configurationWithAssetID = UplynkSSAIConfiguration(
            id: .asset(ids: [assetID]),
            assetType: .asset,
            prefix: prefix,
            contentProtected: true
        )
        let builtPreplayURL = UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL()
        XCTAssertTrue(builtPreplayURL.contains(validDRMParameters))
    }
    
    func testPrePlayURLPrePlayParameters() throws {
        let prefix = "https://content.uplynk.com"
        let assetID = "a123"
        
        let validPrePlayParameters = "key1=value1&key2=value2"
        let anotherValidPrePlayParameters = "key2=value2&key1=value1"
        
        let configurationWithAssetID = UplynkSSAIConfiguration(
            id: .asset(ids: [assetID]),
            assetType: .asset,
            prefix: prefix,
            preplayParameters: [ "key1" : "value1", "key2" : "value2" ]
        )
        let builtPreplayURL = UplynkSSAIURLBuilder(ssaiConfiguration: configurationWithAssetID).buildPreplayVODURL()
        XCTAssertTrue(builtPreplayURL.contains(validPrePlayParameters) ||
                      builtPreplayURL.contains(anotherValidPrePlayParameters))
    }
    
    /// Makes sure Uplynk URLs do not contain the sequence "?&"
    /// FIFA raised an issue that the Uplynk backend does not support those kind of URLs.
    /// See [THEOSD-16266] [OPTI-1771]
    func testEmptyQueryParameter() {
        let hasEmptyParameter: (String)->Bool = { $0.contains("?&") }
        let faultyURL = "https://content.uplynk.com/preplay/ID?&sig=signature"
        XCTAssert(hasEmptyParameter(faultyURL))

        let assetID = "a123"
        let vodBuilder = UplynkSSAIURLBuilder(
            ssaiConfiguration: UplynkSSAIConfiguration(
                id: .asset(ids: [assetID]),
                assetType: .asset
            )
        )
        let liveBuilder = UplynkSSAIURLBuilder(
            ssaiConfiguration: UplynkSSAIConfiguration(
                id: .asset(ids: [assetID]),
                assetType: .channel
            )
        )
        
        let preplayVod = vodBuilder.buildPreplayVODURL()
        let preplayFaultyLive = vodBuilder.buildPreplayLiveURL()
        print(preplayVod)
        XCTAssertFalse(hasEmptyParameter(preplayVod))
        print(preplayFaultyLive)
        XCTAssertFalse(hasEmptyParameter(preplayFaultyLive))

        let preplayFaultyVod = liveBuilder.buildPreplayVODURL()
        let preplayLive = liveBuilder.buildPreplayLiveURL()
        print(preplayFaultyVod)
        XCTAssertFalse(hasEmptyParameter(preplayFaultyVod))
        print(preplayLive)
        XCTAssertFalse(hasEmptyParameter(preplayLive))
    }
    
    func testPreplayArray() {
        let normalParameter = [("keyA", "valueA")]
        let specialValue = "?&+=,%"
        let specialEncodedValue = "%3F%26%2B%3D%2C%25"
        let specialParameter = [("special",specialValue)]
        let specialEncodedParameter = ["special": specialEncodedValue]
        let mixedParameters = [("keyA", "valueA"), ("special",specialValue)]
        let mixedEncodedParamteres = ["keyA": "valueA", "special": specialEncodedValue]
        
        let configs: [TestConfig] = [
            TestConfig(assetType: .asset, preplayArray: normalParameter,  expectedParams: ["keyA": "valueA"]),
            TestConfig(assetType: .asset, preplayArray: specialParameter, expectedParams: specialEncodedParameter),
            TestConfig(assetType: .asset, preplayArray: mixedParameters,  expectedParams: mixedEncodedParamteres),
            TestConfig(assetType: .channel, preplayArray: normalParameter,  expectedParams: ["keyA": "valueA"]),
            TestConfig(assetType: .channel, preplayArray: specialParameter, expectedParams: specialEncodedParameter),
            TestConfig(assetType: .channel, preplayArray: mixedParameters,  expectedParams: mixedEncodedParamteres)
        ]
        
        for config in configs {
            config.assertUrlContainsPreplayParams()
        }
        
        let emptyParams = TestConfig(assetType: .asset, preplayArray: [], expectedParams: [:])
        XCTAssertFalse(emptyParams.url.contains("&"), "A config without params should not contain an `&` character")
    }
}

struct TestConfig {
    let assetType: UplynkSSAIConfiguration.AssetType
    let preplayArray: [(String,String)]
    let expectedParams: [String:String]
    
    var url: String {
        let assetID = UplynkSSAIConfiguration.ID.asset(ids: ["a123"])
        let config = UplynkSSAIConfiguration(id: assetID, assetType: assetType, orderedPreplayParameters: preplayArray)
        let builder = UplynkSSAIURLBuilder(ssaiConfiguration: config)
        switch assetType {
        case .asset:   return builder.buildPreplayVODURL()
        case .channel: return builder.buildPreplayLiveURL()
        }
    }
    
    func assertUrlContainsPreplayParams() {
        let url = self.url
        for (key, value) in expectedParams {
            let exptectation = "\(key)=\(value)"
            if !url.contains(exptectation) {
                XCTFail("Generated url (\(url)) does not contain \(exptectation)")
            }
        }
        guard let parsedUrl = URLComponents(string: url) else {
            return XCTFail("Could not parse the generated URL \(url)")
        }
        let parsedQueryItems = parsedUrl.queryItems ?? []
        for (key, value) in preplayArray {
            guard parsedQueryItems.contains(where: { item in
                item.name == key && item.value == value
            }) else {
                return XCTFail("Generated URL does not contain preplay param \(key)=\(value)")
            }
        }
    }
}
