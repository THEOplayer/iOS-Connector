//
//  UplynkEventListener.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 31/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

public protocol UplynkEventListener: AnyObject {
    func onPreplayLiveResponse(_ response: PrePlayLiveResponse)
    func onPreplayVODResponse(_ response: PrePlayVODResponse)
    
    func onAssetInfoResponse(_ response: AssetInfoResponse)
    
    func onPingResponse(_ response: PingResponse)
    
    func onError(_ error: UplynkError)
}
