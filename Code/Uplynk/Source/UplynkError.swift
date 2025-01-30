//
//  UplynkError.swift
//  THEOplayer-Connector-Uplynk
//
//  Created by Khalid, Yousif on 31/1/2025.
//  Copyright © 2025 THEOplayer. All rights reserved.
//

import Foundation

/// Possible Error Codes for the Uplynk connector
public enum UplynkErrorCode: Int {
    case UPLYNK_ERROR_CODE_UNKNOWN = 0
    case UPLYNK_ERROR_CODE_PREPLAY_REQUEST_FAILED
    case UPLYNK_ERROR_CODE_PING_REQUEST_FAILED
}

/// Uplynk Error type.
public struct UplynkError: Error, Equatable {
    /// The Uplynk URL which the error refers to. Empty if irrelevant.
    public let url: String
    /// The error code
    public let code: UplynkErrorCode
    
    public let description: String
    
    init(url: String, description: String, code: UplynkErrorCode) {
        self.url = url
        self.description = description
        self.code = code
    }
    
    public var localizedDescription: String {
        description
    }
}
