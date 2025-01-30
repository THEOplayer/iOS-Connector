//
//  MockPingResponse.swift
//
//
//  Created by Raveendran, Aravind on 31/1/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

extension PingResponse {
    static var pingResponseWithAdsAndValidNextTime: Self {
        PingResponse(nextTime: 430,
                     ads: .mock,
                     extensions: [.mockVASTExtensions1, .mockVASTExtensions2],
                     error: nil)
    }
    
    static var pingResponseWithoutAdsWithNoNextTime: Self {
        PingResponse(nextTime: -1,
                     ads: nil,
                     extensions: nil,
                     error: nil)
    }
}
