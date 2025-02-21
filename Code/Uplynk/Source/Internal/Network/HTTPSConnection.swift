//
//  HttpsConnection.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class HTTPSConnection {
    private static let CONNECT_TIMEOUT: Double = 30

    enum RequestType: String {
        case get = "GET"
        case post = "POST"
    }
    
    private enum _Error: Error, CustomStringConvertible {
        case incorrectUrl
        public var description: String {
            switch self {
            case .incorrectUrl:
                return "The URL provided is incorrect."
            }
        }
    }
    
    static func request(type: RequestType, urlString: String) async throws -> Data {
        guard let url: URL = .init(string: urlString) else {
            throw _Error.incorrectUrl
        }
        var request: URLRequest = .init(url: url)
        request.httpMethod = RequestType.get.rawValue
        request.timeoutInterval = Self.CONNECT_TIMEOUT
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return data
    }
}
