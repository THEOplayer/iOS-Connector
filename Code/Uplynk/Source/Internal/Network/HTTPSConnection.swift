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
    
    private enum _Error: LocalizedError, CustomStringConvertible {
        case incorrectUrl
        case invalidResponse
        case responseError(statusCode: Int, description: String)
        var description: String {
            switch self {
            case .incorrectUrl:
                return "The URL provided is incorrect."
            case .invalidResponse:
                return "The HTTP response is invalid."
            case .responseError(let statusCode, let description):
                return "The HTTP request failed with status code: \(statusCode) error: \(description)."
            }
        }
        
        public var errorDescription: String? {
            get { description }
        }
    }
    
    static func request(type: RequestType, urlString: String) async throws -> Data {
        guard let url: URL = .init(string: urlString) else {
            throw _Error.incorrectUrl
        }
        var request: URLRequest = .init(url: url)
        request.httpMethod = RequestType.get.rawValue
        request.timeoutInterval = Self.CONNECT_TIMEOUT
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw _Error.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let stringDescription = String(data: data, encoding: .utf8) ?? ""
            throw _Error.responseError(statusCode: httpResponse.statusCode, description: stringDescription)
        }
        return data
    }
}
