//
//  HttpsConnection.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class HttpsConnection {
    private static let CONNECT_TIMEOUT: Double = 30

    enum RequestType: String {
        case get = "GET"
        case post = "POST"
    }

    static func request(type: RequestType, urlString: String, completion: @escaping (_ content: String?, _ error: Error?) -> Void) {
        enum _Error: Error, CustomStringConvertible {
            case incorrectUrl
            public var description: String {
                switch self {
                case .incorrectUrl:
                    return "The URL provided is incorrect."
                }
            }
        }

        guard let url: URL = .init(string: urlString) else {
            completion(.init(), _Error.incorrectUrl)
            return
        }

        var request: URLRequest = .init(url: url)
        request.httpMethod = RequestType.get.rawValue
        request.timeoutInterval = Self.CONNECT_TIMEOUT
        let task = URLSession.shared.dataTask(with: request) { data, res, err in
            if let _data: Data = data,
               let contentString = String(data: _data, encoding: .utf8),
               err == nil {
                completion(contentString, nil)
            } else {
                completion(nil, err)
            }
        }
        task.resume()
    }
}
