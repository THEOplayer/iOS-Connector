//
//  UplynkEventListener.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 31/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

public protocol UplynkEventListener: AnyObject {
    func onResponse(preplayLive: PrePlayLiveResponse)
    func onResponse(preplayVOD: PrePlayVODResponse)
    func onError(uplynkError: UplynkError)
}
