//
//  PingResponse.swift
//  
//
//  Created by Raveendran, Aravind on 30/1/2025.
//

import Foundation

public struct PingResponse: Decodable, Equatable {
    
    /// Indicates the next playback position, in seconds, at which the player should request this endpoint.
    /// The player should not issue additional API requests when this parameter returns -1.0.
    public let nextTime: Double
    
    public let ads: UplynkAds?
    
    /// VAST Only
    ///
    /// Contains the custom set of VAST extensions returned by the ad server.
    /// Each custom extension is an `xml` content
    ///
    /// You could build deserialization logic if needed depending on the expected structure of this field
    ///
    /// Check more info in [documentation](https://docs.edgecast.com/video/#AdIntegration/VAST-VPAID.htm#CustomVASTExt)
    public let extensions: [String]?
    
    /// Error Response Only
    ///
    /// Describes the error that occurred.
    public let error: String?
}
