//
//  YospaceError.swift
//
//  Created by Raffi on 11/06/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import YOAdManagement

enum YospaceError: LocalizedError {
    case error(msg: String)

    var errorDescription: String? {
        switch self {
        case .error(msg: let msg):
            return msg
        }
    }
}

extension YOSession {
    enum YOSessionResultCode: Int {
        case CONNECTION_ERROR = -1
        case CONNECTION_TIMEOUT = -2
        case MALFORMED_URL = -3
        case UNKNOWN_FORMAT = -20

        func message() -> String {
            switch self {
            case .CONNECTION_ERROR:
                return "Yospace: Connection error"
            case .CONNECTION_TIMEOUT:
                return "Yospace: Connection timeout"
            case .MALFORMED_URL:
                return "Yospace: The stream URL is not correctly formatted"
            case .UNKNOWN_FORMAT:
                return "Yospace: Unknown format"
            }
        }
    }
}

extension YOSessionError {
    var errorMessage: String {
        switch self {
        case .sessionTimeout:
            return "Yospace: The session with the Yospace Central Streaming Manager (CSM) service timed-out. No further analytics will be signalled after this event."
        case .unresolvedBreak:
            return "Yospace: The fulfilment payload for an initial partial VMAP response was not received or did not contain the expected data."
        case .parseError:
            return "Yospace: The parser returned error(s) during XML parsing."
        case .trackError:
            return "Yospace: The result of a tracking beacon was unsuccessful."
        @unknown default:
            return "Yospace: An unknown error occured."
        }
    }
}
