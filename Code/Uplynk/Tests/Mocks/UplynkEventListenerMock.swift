//
//  File.swift
//  
//
//  Created by Khalid, Yousif on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

class UplynkEventListenerMock: UplynkEventListener {
    

    enum Event: Equatable {
        case onPreplayLiveResponse(PrePlayLiveResponse)
        case onPreplayVODResponse(PrePlayVODResponse)
        case onPingResponse(PingResponse)
        case onAssetInfoResponse(AssetInfoResponse)
        case onError(UplynkError)
    }
    
    private(set) var events: [Event] = []

    var preplayLiveResponseCallback: ((PrePlayLiveResponse) -> Void)? = nil
    var preplayVODResponseCallback: ((PrePlayVODResponse) -> Void)? = nil
    var errorCallback: ((UplynkError) -> Void)? = nil
    var pingResponseCallback: ((PingResponse) -> Void)? = nil
    var assetInfoResponseCallback: ((AssetInfoResponse) -> Void)? = nil

    func onPreplayLiveResponse(_ response: PrePlayLiveResponse) {
        events.append(.onPreplayLiveResponse(response))
        preplayLiveResponseCallback?(response)
    }
    
    func onPreplayVODResponse(_ response: PrePlayVODResponse) {
        events.append(.onPreplayVODResponse(response))
        preplayVODResponseCallback?(response)
    }
        
    func onPingResponse(_ response: PingResponse) {
        events.append(.onPingResponse(response))
        pingResponseCallback?(response)
    }
    
    func onAssetInfoResponse(_ response: THEOplayerConnectorUplynk.AssetInfoResponse) {
        events.append(.onAssetInfoResponse(response))
        assetInfoResponseCallback?(response)
    }
    
    func onError(_ error: UplynkError) {
        events.append(.onError(error))
        errorCallback?(error)
    }
}
