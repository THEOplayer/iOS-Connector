//
//  THEOliveEventConvivaReporter.swift
//

import ConvivaSDK
import AVFoundation
import THEOplayerSDK

#if canImport(THEOplayerTHEOliveIntegration)
import THEOplayerTHEOliveIntegration

let PROP_ENDPOINT_HESP_SRC: String = "hespSrc"
let PROP_ENDPOINT_HLS_SRC: String = "hlsSrc"
let PROP_ENDPOINT_CDN: String = "cdn"
let PROP_ENDPOINT_AD_SRC: String = "adSrc"
let PROP_ENDPOINT_WEIGHT: String = "weight"
let PROP_ENDPOINT_PRIORITY: String = "priority"
let PROP_ENDPOINT_CONTENT_PROTECTION: String = "contentProtection"
let PROP_REASON_ERROR_CODE: String = "errorCode"
let PROP_REASON_ERROR_MESSAGE: String = "errorMessage"

class THEOliveEventConvivaReporter {
    private let videoAnalytics: CISVideoAnalytics
    private let storage: ConvivaConnectorStorage
    
    init(videoAnalytics: CISVideoAnalytics, storage: ConvivaConnectorStorage) {
        self.videoAnalytics = videoAnalytics
        self.storage = storage
    }
    
    func onEndpointLoaded(event: THEOplayerTHEOliveIntegration.EndpointLoadedEvent)  {
        // placeholder:
        //self.videoAnalytics.reportPlaybackEvent("endpointLoaded", withAttributes: self.fromEndpoint(endpoint: event.endpoint))
        
        // Update CDN
        let cdn = event.endpoint.cdn ?? "unknown"
        self.videoAnalytics.setContentInfo([ CIS_SSDK_METADATA_DEFAULT_RESOURCE: cdn ])
        self.storage.storeKeyValuePair(key: CIS_SSDK_METADATA_DEFAULT_RESOURCE, value: cdn)
    }
    
    func onIntentToFallback(event: THEOplayerTHEOliveIntegration.IntentToFallbackEvent)  {
        self.videoAnalytics.reportPlaybackEvent("intentToFallback", withAttributes: self.fromReason(reason: event.reason))
    }
    
    func fromEndpoint(endpoint: THEOplayerTHEOliveIntegration.EndpointAPI?) -> [String:String] {
        guard let endpoint = endpoint else {
            return [:]
        }
        
        var endpointData: [String:String] = [:]
        if let hespSrc = endpoint.hespSrc {
            endpointData[PROP_ENDPOINT_HESP_SRC] = hespSrc
        }
        if let hlsSrc = endpoint.hlsSrc {
            endpointData[PROP_ENDPOINT_HLS_SRC] = hlsSrc
        }
        if let cdn = endpoint.cdn {
            endpointData[PROP_ENDPOINT_CDN] = cdn
        }
        if let adSrc = endpoint.adSrc {
            endpointData[PROP_ENDPOINT_AD_SRC] = adSrc
        }
        //if let contentProtection = endpoint.contentProtection {
            // TODO: not yet available on native iOS SDK.
        //}
        endpointData[PROP_ENDPOINT_WEIGHT] = String(endpoint.weight)
        endpointData[PROP_ENDPOINT_PRIORITY] = String(endpoint.priority)
        return endpointData
    }
    
    func fromReason(reason: THEOplayerSDK.THEOError?) -> [String:String] {
        guard let reason = reason else {
            return [:]
        }
        
        return [
            PROP_REASON_ERROR_CODE: String(reason.code.rawValue),
            PROP_REASON_ERROR_MESSAGE: reason.message
        ]
    }
}
#endif
