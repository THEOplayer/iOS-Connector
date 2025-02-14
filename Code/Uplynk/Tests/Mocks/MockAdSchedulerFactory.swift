//
//  MockAdSchedulerFactory.swift
//
//
//  Created by Raveendran, Aravind on 14/2/2025.
//

import Foundation
@testable import THEOplayerConnectorUplynk

final class MockAdSchedulerFactory: AdSchedulerFactory {
    static var mockAdScheduler: MockAdScheduler!
    static func makeAdScheduler(adBreaks: [UplynkAdBreak], adHandler: AdHandlerProtocol) -> AdSchedulerProtocol {
        mockAdScheduler
    }
    
    static func reset() {
        mockAdScheduler = nil
    }
}
