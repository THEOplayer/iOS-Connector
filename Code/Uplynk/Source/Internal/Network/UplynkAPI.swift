//
//  UplynkAPI.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

protocol UplynkAPIProtocol {
    static func requestLive(preplaySrcURL: String) async throws -> PrePlayLiveResponse
    static func requestVOD(preplaySrcURL: String) async throws -> PrePlayVODResponse
    static func requestPing(url: String) async throws -> PingResponse
    static func requestAssetInfo(url: String) async throws -> AssetInfoResponse
}

class UplynkAPI: UplynkAPIProtocol {
    
    static func requestLive(preplaySrcURL: String) async throws -> PrePlayLiveResponse {
        let data = try await HTTPSConnection.request(type: .get, urlString: preplaySrcURL)
        let decoder: JSONDecoder = .init()
        let preplayResponse: PrePlayLiveResponse = try decoder.decode(PrePlayLiveResponse.self, from: data)
        return preplayResponse
    }
    
    static func requestVOD(preplaySrcURL: String) async throws -> PrePlayVODResponse {
        let data = try await HTTPSConnection.request(type: .get, urlString: preplaySrcURL)
        let decoder: JSONDecoder = .init()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let preplayResponse: PrePlayVODResponse = try decoder.decode(PrePlayVODResponse.self, from: data)
        return preplayResponse
    }
    
    static func requestPing(url: String) async throws -> PingResponse {
        let data = try await HTTPSConnection.request(type: .get, urlString: url)
        let decoder: JSONDecoder = .init()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PingResponse.self, from: data)
    }
    
    static func requestAssetInfo(url: String) async throws -> AssetInfoResponse {
        let data = try await HTTPSConnection.request(type: .get, urlString: url)
        let decoder: JSONDecoder = .init()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let successResponse = try? decoder.decode(AssetInfoResponse.self, from: data) else {
            let errorResponse = try decoder.decode(AssetInfoErrorResponse.self, from: data)
            throw UplynkError(url: url, 
                              description: errorResponse.msg,
                              code: .UPLYNK_ERROR_CODE_ASSET_INFO_REQUEST_FAILED)
        }
        return successResponse
    }
}
