//
//  File.swift
//  
//
//  Created by Khalid, Yousif on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

class UplynkEventListenerMock: UplynkEventListener {
    func onResponse(preplayLive: THEOplayerConnectorUplynk.PrePlayLiveResponse) {
        preplayLiveResponseCallback?(preplayLive)
    }
    
    func onResponse(preplayVOD: THEOplayerConnectorUplynk.PrePlayVODResponse) {
        preplayVODResponseCallback?(preplayVOD)
    }
    
    func onError(uplynkError: UplynkError) {
        preplayErrorCallback?(uplynkError)
    }
    
    var preplayLiveResponseCallback: ((PrePlayLiveResponse) -> Void)? = nil
    var preplayVODResponseCallback: ((PrePlayVODResponse) -> Void)? = nil
    var preplayErrorCallback: ((UplynkError) -> Void)? = nil
    
    
}
