//
//  MockAdHandlerFactory.swift
//  
//
//  Created by Raveendran, Aravind on 14/2/2025.
//

import Foundation
import THEOplayerSDK
@testable import THEOplayerConnectorUplynk

final class MockAdHandlerFactory: AdHandlerFactory {
    static var mockAdHandler: MockAdHandler!
    
    static func makeAdHandler(controller: ServerSideAdIntegrationController, skipOffset: Int) -> AdHandlerProtocol {
        mockAdHandler
    }
    
    static func reset() {
        mockAdHandler = nil
    }
}
