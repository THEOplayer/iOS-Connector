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
    static func requestPing(url: String) async -> PingResponse?
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
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let preplayResponse: PrePlayVODResponse = try decoder.decode(PrePlayVODResponse.self, from: data)
            return preplayResponse
        } catch {
            // TODO: Add logging here?
            return nil
        }
    }
    
    static func requestPing(url: String) async -> PingResponse? {
        do {
            let data = try await HTTPSConnection.request(type: .get, urlString: url)
            let decoder: JSONDecoder = .init()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let response = try? decoder.decode(PingResponse.self, from: data) else {
                return nil
            }
            return response
        } catch {
            // TODO: Add logging here?
            return nil
        }
    }
}
