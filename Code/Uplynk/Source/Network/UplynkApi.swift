//
//  UplynkAPI.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class UplynkAPI {
    
    static func request(preplaySrcURL: String) async -> PreplayResponse? {
        do {
            let data = try await HTTPSConnection.request(type: .get, urlString: preplaySrcURL)
            let decoder: JSONDecoder = .init()
            guard let preplayResponse: PreplayResponse = try? decoder.decode(PreplayResponse.self, from: data) else {
                return nil
            }
            return preplayResponse
        } catch {
            // TODO: Add logging here?
            return nil
        }
    }
}
