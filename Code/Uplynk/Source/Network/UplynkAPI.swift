//
//  UplynkAPI.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation


protocol UplynkAPIProtocol {
    static func requestLive(preplaySrcURL: String) async -> PrePlayLiveResponse?
    static func requestVOD(preplaySrcURL: String) async -> PrePlayVODResponse?
}

class UplynkAPI: UplynkAPIProtocol {
    
    static func requestLive(preplaySrcURL: String) async -> PrePlayLiveResponse? {
        do {
            let data = try await HTTPSConnection.request(type: .get, urlString: preplaySrcURL)
            let decoder: JSONDecoder = .init()
            let preplayResponse: PrePlayLiveResponse = try decoder.decode(PrePlayLiveResponse.self, from: data)
            return preplayResponse
        } catch {
            // TODO: Add logging here?
            return nil
        }
    }
    
    static func requestVOD(preplaySrcURL: String) async -> PrePlayVODResponse? {
        do {
            let data = try await HTTPSConnection.request(type: .get, urlString: preplaySrcURL)
            let decoder: JSONDecoder = .init()
            let preplayResponse: PrePlayVODResponse = try decoder.decode(PrePlayVODResponse.self, from: data)
            return preplayResponse
        } catch {
            // TODO: Add logging here?
            return nil
        }
    }
}
